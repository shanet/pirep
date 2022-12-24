import 'mapbox-gl';

import * as actionButtons from 'map/action_buttons';
import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as flashes from 'map/flashes';
import * as newAirportDrawer from 'map/drawer_new_airport';
import * as urlSearchParams from 'map/url_search_params';

const AIRPORT_LAYER = 'airports';
const CHART_LAYERS = ['sectional', 'terminal', 'caribbean'];

// Airports currently displayed on the map (with filters applied)
const displayedAirports = {
  type: 'FeatureCollection',
  features: [],
};

let mapElement = null;
let map = null;

// All airports without filters
let allAirports = [];

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('map')) return;

  initMap();

  map.on('load', () => {
    fetchAirports();
    addChartLayersToMap();
    addEventHandlersToMap();
    add3dTerrain();
  });
}, {once: true});

function initMap() {
  mapElement = document.getElementById('map');
  mapboxgl.accessToken = mapElement.dataset.mapboxApiKey; // eslint-disable-line no-undef

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
}

function initialMapCenter() {
  let coordinates = urlSearchParams.getCoordinates();
  let zoomLevel = urlSearchParams.getZoomLevel();

  // If there were no coordinates in the URL use the geoip lookup value
  if(!coordinates) {
    const map = mapElement;
    coordinates = [map.dataset.centerLatitude, map.dataset.centerLongitude];
    zoomLevel = map.dataset.zoomLevel;
  }

  return [coordinates, zoomLevel];
}

function addChartLayersToMap() {
  CHART_LAYERS.forEach((chartLayer) => {
    map.addLayer({
      id: chartLayer,
      type: 'raster',
      source: {
        maxzoom: 11,
        // Terminal charts only show up when zoomed in a sufficient amount
        minzoom: (chartLayer === 'terminal' ? 10 : 0),
        scheme: 'tms',
        // In test there needs to be some asset to request to avoid a "no route exists" error. Since no tiles may be
        // generated use a dummy image as a tile. This will make for an odd looking map but that won't matter in tests.
        tiles: [mapElement.dataset.isTest === 'true' ? mapElement.dataset.testTilePath : `${mapElement.dataset.assetHost}/assets/tiles/${chartLayer}/current/{z}/{x}/{y}.png`],
        tileSize: 256,
        type: 'raster',
      },
      paint: {
        'raster-opacity': (urlSearchParams.getLayer() === actionButtons.LAYER_SATELLITE ? 0 : 1),
        'raster-fade-duration': 300,
      },
    });
  });
}

function addEventHandlersToMap() {
  map.on('click', (event) => {
    if(!mapElement.classList.contains('editing')) return;

    flyTo(event.lngLat.lat, event.lngLat.lng, 16);
    const elevation = map.queryTerrainElevation([event.lngLat.lng, event.lngLat.lat]);
    newAirportDrawer.locationSelected(event.lngLat.lat, event.lngLat.lng, elevation);
  });

  // Open the drawer for an airport when its marker is clicked or close if the already open airport is clicked
  map.on('click', AIRPORT_LAYER, (event) => {
    // Don't do anything if a new airport is being added
    if(mapElement.classList.contains('editing')) return;

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

function add3dTerrain() {
  map.addSource('dem', {
    type: 'raster-dem',
    url: 'mapbox://mapbox.terrain-rgb',
  });

  map.setTerrain({source: 'dem'});

  map.setFog({
    range: [0.8, 8],
    color: '#dc9f9f',
    'horizon-blend': 0.5,
    'high-color': '#245bde',
    'space-color': '#000000',
  });
}

async function fetchAirports() {
  const {airportsPath} = mapElement.dataset;
  const response = await fetch(airportsPath);

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving airports for the map.');
  }

  allAirports = await response.json();
  addAirportsToMap();
}

function addAirportsToMap() {
  map.loadImage(mapElement.dataset.markerImagePath, (error, image) => {
    if(error) {
      flashes.show(flashes.FLASH_ERROR, 'Failed to add airports to map');
      throw error;
    }

    map.addImage('marker', image);

    map.loadImage(mapElement.dataset.markerSelectedImagePath, (error, image) => {
      if(error) {
        flashes.show(flashes.FLASH_ERROR, 'Failed to add airports to map');
        throw error;
      }

      map.addImage('marker_selected', image);
      addAirportToMap(AIRPORT_LAYER, displayedAirports);

      // The map is fully loaded, start manipulating it
      applyUrlSearchParamsOnMap();
      filterAirportsOnMap();
      exposeObjectsForTesting();
    });
  });
}

export function addAirportToMap(layerId, geojson) {
  map.addSource(layerId, {
    type: 'geojson',
    data: geojson,
    buffer: 0,
    maxzoom: 18,
    tolerance: 3.5,
  });

  map.addLayer({
    id: layerId,
    type: 'symbol',
    source: layerId,
    layout: {
      'icon-allow-overlap': true,
      'icon-image': 'marker',
      'icon-size': 0.8,
    },
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
  CHART_LAYERS.forEach((chartLayer) => {
    map.setPaintProperty(chartLayer, 'raster-opacity', (show ? 1 : 0));
  });
}

export function areSectionalLayersShown() {
  // We only hide/show all layers so just check if the first sectional chart is shown or not to determine the state of all charts
  return (map.getPaintProperty('sectional', 'raster-opacity') === 1);
}

export function openAirport(airportCode, boundingBox) {
  // Find the feature for the given airport code
  for(let i = 0; i < allAirports.length; i++) {
    if(allAirports[i].properties.code === airportCode) {
      openAirportFeature(allAirports[i], boundingBox);
      break;
    }
  }
}

export function closeAirport() {
  urlSearchParams.clearAirport();
  setAirportMarkerSelected('');
}

function openAirportFeature(airport, boundingBox) {
  // Set the airport's marker as selected
  setAirportMarkerSelected(airport.id);

  if(boundingBox) {
    map.fitBounds(boundingBox, {padding: 100});
  } else {
    map.flyTo({center: airport.geometry.coordinates, padding: {right: 500}});
  }

  // Open the drawer for the clicked airport
  drawer.loadDrawer(drawer.DRAWER_SHOW_AIRPORT, airport.properties.code);
  drawer.openDrawer();

  urlSearchParams.setAirport(airport.properties.code);
}

export function setAirportMarkerSelected(airportCode, layerId) {
  if(!layerId) layerId = AIRPORT_LAYER; // eslint-disable-line no-param-reassign

  // Ensure that the layer exists before manipulating it
  if(!map.getLayer(layerId)) return;

  map.setLayoutProperty(layerId, 'icon-image', ['match', ['id'], airportCode, 'marker_selected', 'marker']);
}

function getSelectedAirportMarker() {
  return map.getLayoutProperty(AIRPORT_LAYER, 'icon-image')[2];
}

export function removeLayer(layerId) {
  // Avoid an error by trying to remove a non-existant layer
  if(!map.getSource(layerId)) return false;

  map.removeLayer(layerId);
  return map.removeSource(layerId);
}

export function flyTo(latitude, longitude, zoom) {
  map.flyTo({center: [longitude, latitude], zoom});
}

export function fitBounds(boundingBox, padding) {
  map.fitBounds(boundingBox, {padding: padding || 0});
}

export function getZoom() {
  return map.getZoom();
}

export function getCenter() {
  return Object.values(map.getCenter()).reverse();
}

function exposeObjectsForTesting() {
  // Don't expose anything if not running tests
  if(!mapElement.dataset.isTest) return;

  // This is yucky, but we need the map object at global scope so we can access it in Capybara tests
  window.mapbox = map;

  // Let the tests know that the map is fully ready to use (once we have the airports layer shown)
  mapElement.dataset.ready = true;
}
