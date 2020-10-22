const drawer = require('./drawer');
const filters = require('./filters');
const mapboxgl = require('mapbox-gl/dist/mapbox-gl.js');

const SECTIONAL_LAYERS = {
  seattle: [-124.094901, 44.634929, -116.327513, 48.995149],
  falls: [-124.079738, 40.016959, -116.727446, 44.494397],
};

const AIRPORT_LAYER = 'airports';

// Da map!
let map = null;

// All airports without filters
let allAirports = [];

// Airports currently displayed on the map (with filters applied)
const displayedAirports = {
  type: 'FeatureCollection',
  features: [],
};

document.addEventListener('DOMContentLoaded', () => {
  initMap();

  map.on('load', () => {
    fetchAirports();
    addSectionalLayersToMap();
    addEventHandlersToMap();
  });
});

function initMap() {
  mapboxgl.accessToken = 'pk.eyJ1Ijoic2hhbmV0IiwiYSI6ImNpbXZnbnBhMjAydDl3a2x1ejNoNWoydHMifQ.WIi_Jv4TO3hOzj-E120rYg';

  map = new mapboxgl.Map({
    center: [-122.06, 48.11],
    container: 'map',
    style: 'mapbox://styles/mapbox/satellite-streets-v11',
    zoom: 8,
  });
}

function addSectionalLayersToMap() {
  Object.keys(SECTIONAL_LAYERS).forEach((id) => {
    map.addLayer({
      id,
      type: 'raster',
      source: {
        bounds: SECTIONAL_LAYERS[id],
        maxzoom: 11,
        minzoom: 5,
        scheme: 'tms',
        tiles: [`http://localhost:3000/assets/tiles/${id}/{z}/{x}/{y}.png`],
        tileSize: 256,
        type: 'raster',
      },
    });
  });
}

function addEventHandlersToMap() {
  // Open the drawer for an airport when its marker is clicked
  map.on('click', AIRPORT_LAYER, (event) => {
    openAirportFeature(event.features[0]);
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = 'pointer';
  });

  map.on('mouseleave', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = '';
  });
}

async function fetchAirports() {
  const { airportsPath } = document.getElementById('map').dataset;
  const response = await fetch(airportsPath);

  if(!response.ok) {
    // TODO: make this better
    return alert('fetching airports failed');
  }

  allAirports = await response.json();
  addAirportsToMap();
}

function addAirportsToMap() {
  map.loadImage(document.getElementById('map').dataset.markerImagePath, (error, image) => {
    // TODO: make this better
    if(error) throw error;
    map.addImage('marker', image);

    map.loadImage(document.getElementById('map').dataset.markerSelectedImagePath, (error, image) => {
      if(error) throw error;
      map.addImage('marker_selected', image);

      map.addSource(AIRPORT_LAYER, {
        type: 'geojson',
        data: displayedAirports,
      });

      map.addLayer({
        id: AIRPORT_LAYER,
        type: 'symbol',
        source: AIRPORT_LAYER,
        layout: {
          'icon-allow-overlap': true,
          'icon-image': 'marker',
          'icon-size': 0.8,
        },
      });

      filterAirportsOnMap(filters.enabledFilters());
    });
  });
}

export function filterAirportsOnMap(filters) {
  displayedAirports.features.length = 0;

  allAirports.forEach((airport) => {
    airport.properties.tags.forEach((tag) => {
      if(filters.has(tag)) {
        displayedAirports.features.push(airport);
      }
    });
  });

  map.getSource(AIRPORT_LAYER).setData(displayedAirports);
}

export function toggleSectionalLayers(show) {
  Object.keys(SECTIONAL_LAYERS).forEach((id) => {
    map.setLayoutProperty(id, 'visibility', (show ? 'visible' : 'none'));
  });
}

export function openAirport(code) {
  // Find the feature for the given airport code
  for(let i=0; i<allAirports.length; i++) {
    if(allAirports[i].properties.code === code) {
      openAirportFeature(allAirports[i]);
      break;
    }
  }
}

function openAirportFeature(airport) {
  // Set the airport's marker as selected
  map.setLayoutProperty(AIRPORT_LAYER, 'icon-image', ['match', ['id'], airport.id, 'marker_selected', 'marker']);

  // Delay moving to the airport if the drawer is closed so the map doesn't move before the drawer is finished animating
  setTimeout(() => {
    map.flyTo({center: airport.geometry.coordinates, padding: {right: 500}})
  }, (drawer.isDrawerOpen() ? 0 : 500));

  // Open the drawer for the clicked airport
  drawer.loadDrawer(airport.properties.code);
  drawer.openDrawer();
}
