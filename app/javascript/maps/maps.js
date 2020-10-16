const drawer = require('./drawer');
const navigation = require('./navigation');
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
  // Open the drawer when clicking on an airport marker
  map.on('click', AIRPORT_LAYER, (event) => {
    drawer.loadDrawer(event.features[0].properties.code);
    drawer.openDrawer();
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = 'pointer';
  });

  map.on('mouseleave', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = '';
  });
}

function fetchAirports() {
  const request = new XMLHttpRequest();

  request.onload = () => {
    if(request.status === 200) {
      allAirports = JSON.parse(request.response);
      addAirportsToMap();
    } else {
      // TODO: make this better
      alert('fetching airports failed');
    }
  };

  const { airportsPath } = document.getElementById('map').dataset;
  request.open('GET', airportsPath);
  request.send();
}

function addAirportsToMap() {
  map.loadImage(document.getElementById('map').dataset.markerImagePath, (error, image) => {
    if(error) throw error;

    map.addImage('marker', image);

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

    filterAirportsOnMap(navigation.enabledFilters());
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
