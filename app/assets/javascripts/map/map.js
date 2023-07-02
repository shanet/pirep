import 'mapbox-gl';

import * as actionButtons from 'map/action_buttons';
import * as annotationFactory from 'shared/annotation_factory';
import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as flashes from 'map/flashes';
import * as mapUtils from 'shared/map_utils';
import * as newAirportDrawer from 'map/drawer_new_airport';
import * as search from 'map/search';
import * as urlSearchParams from 'map/url_search_params';
import * as utils from 'shared/utils';

const AIRPORT_LAYER = 'airports';
const CHART_LAYERS = ['sectional', 'terminal'];

export const MARKER_VISIBLE = 'marker_visible';
export const MARKER_INVISIBLE = 'marker_invisible';
export const MARKER_SELECTED = 'marker_selected';

let mapElement = null;
let map = null;

const airports = {
  type: 'FeatureCollection',
  features: [],
};

// Cache of airport annotations so we don't have to repeatedly fetch them when the map is panned
const annotationsCache = {};

// Mutex to prevent repeated annotation fetching
let fetchingAnnotations = false;

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('map')) return;

  if(!utils.isWebGlAvailable()) {
    flashes.show(flashes.FLASH_ERROR, 'Your browser does not support WebGL which is required for this website.', true);
    return;
  }

  initMap();

  map.on('load', async () => {
    await fetchMapImages();
    await fetchAirports();
    addAirportLayerToMap(AIRPORT_LAYER, airports);
    filterAirportsOnMap();
    applyUrlSearchParamsOnMap();
    set3dButtonLabel();
    addChartLayersToMap();
    addEventHandlersToMap();
    mapUtils.add3dTerrain(map);
    search.enable();
  });
}, {once: true});

function initMap() {
  mapElement = document.getElementById('map');
  mapboxgl.accessToken = mapElement.dataset.mapboxApiKey; // eslint-disable-line no-undef

  const [coordinates, zoomLevel] = initialMapCenter();

  map = new mapboxgl.Map({ // eslint-disable-line no-undef
    attributionControl: false,
    center: coordinates.reverse(),
    container: 'map',
    hash: true,
    maxZoom: 18,
    preserveDrawingBuffer: true,
    style: 'mapbox://styles/mapbox/satellite-streets-v11',
    zoom: zoomLevel,
  });

  map.addControl(new mapboxgl.AttributionControl(), 'bottom-left'); // eslint-disable-line no-undef
}

function initialMapCenter() {
  // If there is a Mapbox hash in the URL don't use the provided initial map center values
  if(window.location.hash.length > 0) return [[null, null], null];

  return [
    [mapElement.dataset.centerLatitude, mapElement.dataset.centerLongitude],
    mapElement.dataset.zoomLevel,
  ];
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
        tiles: [mapElement.dataset.isTest === 'true' ? mapElement.dataset.tilesPathTest : `${mapElement.dataset.tilesPath}${chartLayer}/{z}/{x}/{y}.webp`],
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
    if(!mapElement.classList.contains('adding')) return;

    flyTo(event.lngLat.lat, event.lngLat.lng, 16);
    const elevation = map.queryTerrainElevation([event.lngLat.lng, event.lngLat.lat]);
    newAirportDrawer.locationSelected(event.lngLat.lat, event.lngLat.lng, elevation);
  });

  // Open the drawer for an airport when its marker is clicked or close if the already open airport is clicked
  map.on('click', AIRPORT_LAYER, (event) => {
    // Don't do anything if a new airport is being added
    if(mapElement.classList.contains('adding')) return;

    // If the airport is already selected, close it. Unless we're on a small screen size in which case open the drawer again in case it was closed by zooming in
    const selectedAirport = getSelectedAirport();

    if(event.features[0].id === selectedAirport?.id && !utils.isBreakpointDown('sm')) {
      drawer.closeDrawer();
      closeAirport(selectedAirport);
    } else {
      openAirport(event.features[0].properties.code);
    }
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = 'pointer';
  });

  map.on('mouseleave', AIRPORT_LAYER, () => {
    map.getCanvas().style.cursor = '';
  });

  map.on('moveend', fetchAirportAnnotations);
  map.on('move', fetchAirportAnnotations);

  map.on('pitchend', set3dButtonLabel);

  // If coming from an airport page the zoom level may have a default value. We want to clear
  // this as soon as the zoom is changed on the map as Mapbox stores its own state in the URL.
  map.on('zoomstart', () => {
    urlSearchParams.setZoomLevel(null);
  });

  map.on('error', (error) => {
    // Since the chart layers are not rectangles we can't use a bounding box for them. Instead, the server is configured to return
    // a 204 response to denote a tile with no content. This is faster than a 404 since Mapbox seems to not try to parse the response
    // but it does put all of these error messages in the JS console. We can ignore these since they're not actually errors.
    if(String(error.error).startsWith('Error: Could not load image because of The source image could not be decoded')) return;

    console.error(error); // eslint-disable-line no-console
  });

  map.on('idle', initialAirportAnnotationsFetch);
  map.on('sourcedata', exposeObjectsForTesting);
}

// If the map loads with an airport zoomed in on we need to fetch its annotations but this can only be done once the airports layer
// is rendered. There's no callback for when a layer is fully rendered so whenever the map becomes idle then we know it's rendered
// and can fetch any needed annotations. However, we only want to do this for the initial idle event so the event listener can be
// removed once called.
function initialAirportAnnotationsFetch() {
  fetchAirportAnnotations();
  map.off('idle', initialAirportAnnotationsFetch);
}

async function fetchMapImages() {
  try {
    Promise.all([
      fetchMapImage(MARKER_VISIBLE, mapElement.dataset.markerVisibleImagePath),
      fetchMapImage(MARKER_INVISIBLE, mapElement.dataset.markerInvisibleImagePath),
      fetchMapImage(MARKER_SELECTED, mapElement.dataset.markerSelectedImagePath),
    ]);
  } catch(error) {
    flashes.show(flashes.FLASH_ERROR, 'Failed to download map assets');
    throw error;
  }
}

function fetchMapImage(id, imagePath) {
  return new Promise((resolve, reject) => {
    map.loadImage(imagePath, (error, image) => {
      if(error) {
        flashes.show(flashes.FLASH_ERROR, 'Failed to add airports to map');
        reject(error);
      }

      map.addImage(id, image);
      resolve();
    });
  });
}

async function fetchAirports() {
  const {airportsPath} = mapElement.dataset;
  const response = await fetch(airportsPath);

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving airports for the map.');
  }

  const allAirports = await response.json();
  allAirports.forEach((airport) => airports.features.push(airport));
}

export function addAirportLayerToMap(layerId, geojson) {
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
      'icon-image': ['get', 'marker'],
      'icon-size': 0.8,
    },
  });
}

export function filterAirportsOnMap() {
  airports.features.forEach((airport) => {
    airport.properties.marker = (isAirportActive(airport) ? MARKER_VISIBLE : MARKER_INVISIBLE);
  });

  renderAirportLayer(AIRPORT_LAYER, airports);
}

function renderAirportLayer(layerId, geojson) {
  const source = map.getSource(layerId);
  if(source) source.setData(geojson);
}

function isAirportActive(airport) {
  return filters.showAirport(airport);
}

async function fetchAirportAnnotations() {
  if(fetchingAnnotations) return;

  // Don't fetch annotations if we're zoomed too far out
  if(getZoom() < 12.5) {
    annotationFactory.removeAllAnnotations();
    return;
  }

  // The airport layers may not be ready yet if the map is panned immediately after loading the page
  if(!map.getLayer(AIRPORT_LAYER)) return;

  fetchingAnnotations = true;

  // Get all airports that are within the current view of the map
  const airportsInView = map.queryRenderedFeatures({layers: [AIRPORT_LAYER]});
  const requests = [];

  for(let i=0; i<airportsInView.length; i++) {
    const airport = airportsInView[i].properties.code;
    const {annotationsPath} = mapElement.dataset;

    if(!annotationsCache[airport]) {
      const request = fetch(annotationsPath.replace('PLACEHOLDER', airport))
        .then((response) => response.json())
        .then((json) => {annotationsCache[airport] = json;})
        .catch(() => {
          console.error(`An error occurred while retrieving annotations for airport ${airport}.`); // eslint-disable-line no-console
        });

      requests.push(request);
    }
  }

  await Promise.all(requests);
  annotationFactory.removeAllAnnotations();
  addAirportAnnotations();

  fetchingAnnotations = false;
}

async function addAirportAnnotations() {
  Object.values(annotationsCache).forEach((annotations) => {
    if(!annotations) return;

    annotations.forEach((annotation) => {
      annotationFactory.addAnnotationToMap(map, annotation.latitude, annotation.longitude, annotation.label, {editing: false, readOnly: true});
    });
  });
}

function applyUrlSearchParamsOnMap() {
  const airport = urlSearchParams.getAirport();
  const zoomLevel = urlSearchParams.getZoomLevel();

  if(airport) {
    openAirport(airport, null, zoomLevel);
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

export function openAirport(airportCode, boundingBox, zoomLevel, openDrawer) {
  let airport = null;

  // Find the feature for the given airport code
  for(let i=0; i<airports.features.length; i++) {
    if(airports.features[i].properties.code === airportCode) {
      airport = airports.features[i];
      break;
    }
  }

  if(!airport) return console.log(`Airport ${airportCode} not found, aborting open`); // eslint-disable-line no-console

  // Deselect any currently selected airport and then set the to-be-selected airport's marker as selected
  setAirportMarkerSelected(getSelectedAirport(), AIRPORT_LAYER, airports, false);
  setAirportMarkerSelected(airport, AIRPORT_LAYER, airports);

  if(boundingBox) {
    map.fitBounds(boundingBox, {padding: 150});
  } else {
    // Move the map by the width of the drawer so the selected airport is centered. But only do this on a large screen
    // size since the drawer will cover the full width on small screens and we don't want to move the map in that case.
    const drawerPadding = (utils.isBreakpointDown('sm') ? 0 : drawer.getWidth());

    const options = {center: airport.geometry.coordinates, padding: {right: drawerPadding}};
    if(zoomLevel) options.zoom = zoomLevel;
    map.flyTo(options);
  }

  // Open the drawer for the clicked airport
  drawer.loadDrawer(drawer.DRAWER_SHOW_AIRPORT, airport.properties.code);
  if(openDrawer !== false) drawer.openDrawer();

  urlSearchParams.setAirport(airport.properties.code);
}

export function closeAirport(airport) {
  airport ||= getSelectedAirport();

  // Don't do anything if an airport is not open
  if(!airport) return;

  urlSearchParams.clearAirport();
  setAirportMarkerSelected(airport, AIRPORT_LAYER, airports, false);
}

export function setAirportMarkerSelected(airport, layerId, layerSource, selected) {
  if(!airport) return;

  if(selected !== false) {
    airport.properties.marker = MARKER_SELECTED;
  } else {
    airport.properties.marker = (isAirportActive(airport) ? MARKER_VISIBLE : MARKER_INVISIBLE);
  }

  renderAirportLayer(layerId, layerSource);
}

function getSelectedAirport() {
  for(let i=0; i<airports.features.length; i++) {
    if(airports.features[i].properties.marker === MARKER_SELECTED) {
      return airports.features[i];
    }
  }

  return null;
}

export function removeLayer(layerId) {
  // Avoid an error by trying to remove a non-existant layer
  if(!map.getSource(layerId)) return false;

  map.removeLayer(layerId);
  return map.removeSource(layerId);
}

function set3dButtonLabel() {
  // If the map is loaded with a 3D pitch the #d toggle button should be set to 3D mode
  // We can't know this until the map is initialized however so it must be done here
  // Note that the state here should reflect what's in action_buttons.js
  if(map.getPitch() > 0) {
    document.getElementById('map-pitch-button').innerText = '2D';
    document.getElementById('map-pitch-button').dataset.state = '3d';
  }
}

export function flyTo(latitude, longitude, zoom) {
  map.flyTo({center: [longitude, latitude], zoom});
}

export function fitBounds(boundingBox, padding) {
  map.fitBounds(boundingBox, {padding: padding || 0});
}

export function set3dPitch() {
  map.easeTo({pitch: 45}, {duration: 500}); // ms
}

export function resetCamera() {
  map.easeTo({bearing: 0, pitch: 0}, {duration: 500}); // ms
}

export function getZoom() {
  return map.getZoom();
}

export function getCenter() {
  return Object.values(map.getCenter()).reverse();
}

function exposeObjectsForTesting(event) {
  // Don't expose anything if not running tests
  if(!mapElement.dataset.isTest) return;

  // This function is called by a `sourcedata` event. We only want to consider events that involve the airport layer being rendered.
  if(event.sourceId !== AIRPORT_LAYER) return;

  // This is yucky, but we need the map object at global scope so we can access it in Capybara tests
  window.mapbox = map;

  // Let the tests know that the map is fully ready to use (once we have the airports layer shown)
  mapElement.dataset.ready = true;
}
