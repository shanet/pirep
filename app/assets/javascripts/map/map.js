import 'mapbox-gl';

import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as flashes from 'map/flashes';
import * as layerSwitcher from 'map/layer_switcher';
import * as urlSearchParams from 'map/url_search_params';

const SECTIONAL_LAYERS = {
  seattle: [-124.094901, 44.634929, -116.327513, 48.995149],
  falls: [-124.079738, 40.016959, -116.727446, 44.494397],
};

const AIRPORT_LAYER = 'airports';

// Airports currently displayed on the map (with filters applied)
const displayedAirports = {
  type: 'FeatureCollection',
  features: [],
};

let map = null;

// All airports without filters
let allAirports = [];

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('map')) return;

  initMap();

  map.on('load', () => {
    fetchAirports();
    addSectionalLayersToMap();
    addEventHandlersToMap();
  });
}, {once: true});

function initMap() {
  mapboxgl.accessToken = document.getElementById('map').dataset.mapboxApiKey; // eslint-disable-line no-undef

  const [coordinates, zoomLevel] = initialMapCenter();

  map = new mapboxgl.Map({ // eslint-disable-line no-undef
    center: coordinates.reverse(),
    container: 'map',
    style: 'mapbox://styles/mapbox/satellite-streets-v11',
    zoom: zoomLevel,
    maxZoom: 18,
    attributionControl: false,
    preserveDrawingBuffer: true,
  });

  map.addControl(new mapboxgl.AttributionControl(), 'bottom-left'); // eslint-disable-line no-undef

  // Let the tests know that the map is fully ready to use (once we have the airports layer shown)
  map.on('idle', () => {
    if(map.getLayer(AIRPORT_LAYER)) {
      document.getElementById('map').dataset.ready = true;
    }
  });
}

function initialMapCenter() {
  const coordinates = urlSearchParams.getCoordinates() || [48.11, -122.06];
  const zoomLevel = urlSearchParams.getZoomLevel() || 8;

  return [coordinates, zoomLevel];
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
      paint: {
        'raster-opacity': (urlSearchParams.getLayer() === layerSwitcher.LAYER_SATELLITE ? 0 : 1),
        'raster-fade-duration': 300,
      },
    });
  });
}

function addEventHandlersToMap() {
  // Open the drawer for an airport when its marker is clicked or close if the already open airport is clicked
  map.on('click', AIRPORT_LAYER, (event) => {
    if(event.features[0].id === getSelectedAirportMarker()) {
      drawer.closeDrawer();
      closeAirport();
    } else {
      openAirportFeature(event.features[0]);
    }
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = 'pointer';
  });

  map.on('mouseleave', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = '';
  });

  // Update the URL search params after dragging the map with the current position
  map.on('moveend', () => {
    const center = map.getCenter();
    urlSearchParams.setCoordinates(center.lat.toFixed(7), center.lng.toFixed(7));
  });

  map.on('zoomend', () => {
    urlSearchParams.setZoomLevel(map.getZoom().toFixed(5));
  });
}

async function fetchAirports() {
  const {airportsPath} = document.getElementById('map').dataset;
  const response = await fetch(airportsPath);

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving airports for the map.');
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
        buffer: 0,
        maxzoom: 18,
        tolerance: 3.5,
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

      // The map is fully loaded, start manipulating it
      applyUrlSearchParamsOnMap();
      filterAirportsOnMap();
      exposeObjectsForTesting();
    });
  });
}

export function filterAirportsOnMap() {
  displayedAirports.features.length = 0;

  allAirports.forEach((airport) => {
    if(filters.showAirport(airport)) {
      displayedAirports.features.push(airport);
    }
  });

  // If a filter is clicked before the airport layer is ready it may be null
  const layer = map.getSource(AIRPORT_LAYER);
  if(layer) layer.setData(displayedAirports);
}

function applyUrlSearchParamsOnMap() {
  const airport = urlSearchParams.getAirport();

  if(airport) {
    openAirport(airport);
  }
}

export function toggleSectionalLayers(show) {
  Object.keys(SECTIONAL_LAYERS).forEach((id) => {
    // map.setLayoutProperty(id, 'visibility', (show ? 'visible' : 'none'));
    map.setPaintProperty(id, 'raster-opacity', (show ? 1 : 0));
  });
}

export function areSectionalLayersShown() {
  return (map.getPaintProperty(Object.keys(SECTIONAL_LAYERS)[0], 'raster-opacity') === 1);
}

export function openAirport(airportCode) {
  // Find the feature for the given airport code
  for(let i = 0; i < allAirports.length; i++) {
    if(allAirports[i].properties.code === airportCode) {
      openAirportFeature(allAirports[i]);
      break;
    }
  }
}

export function closeAirport() {
  urlSearchParams.clearAirport();
  setAirportMarkerSelected('');
}

function openAirportFeature(airport) {
  // Set the airport's marker as selected
  setAirportMarkerSelected(airport.id);

  // Delay moving to the airport if the drawer is closed so the map doesn't move before the drawer is finished animating
  setTimeout(() => {
    map.flyTo({center: airport.geometry.coordinates, padding: {right: 500}});
  }, (drawer.isDrawerOpen() ? 0 : 500));

  // Open the drawer for the clicked airport
  drawer.loadDrawer(drawer.DRAWER_AIRPORT, airport.properties.code);
  drawer.openDrawer();

  urlSearchParams.setAirport(airport.properties.code);
}

function setAirportMarkerSelected(airportCode) {
  map.setLayoutProperty(AIRPORT_LAYER, 'icon-image', ['match', ['id'], airportCode, 'marker_selected', 'marker']);
}

function getSelectedAirportMarker() {
  return map.getLayoutProperty(AIRPORT_LAYER, 'icon-image')[2];
}

export function flyTo(latitude, longitude, zoom) {
  map.flyTo({center: [longitude, latitude], zoom});
}

export function getZoom() {
  return map.getZoom();
}

export function getCenter() {
  return Object.values(map.getCenter()).reverse();
}

function exposeObjectsForTesting() {
  // Don't expose anything if not running tests
  if(!document.getElementById('map').dataset.isTest) return;

  // This is yucky, but we need the map object at global scope so we can access it in Capybara tests
  window.mapbox = map;
}
