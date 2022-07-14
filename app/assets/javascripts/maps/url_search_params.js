const AIRPORT_KEY = 'airport';
const COORDINATES_KEY = 'coordinates';
const ZOOM_LEVEL_KEY = 'zoom';
const LAYER_KEY = 'layer';
const FILTERS_KEY = 'filters';

export function getAirport() {
  return normalizeAirportCode(searchParams().get(AIRPORT_KEY));
}

export function setAirport(airportCode) {
  updateUrl(AIRPORT_KEY, airportCode);
}

export function clearAirport() {
  updateUrl(AIRPORT_KEY, null);
}

export function getCoordinates() {
  const coordinates = searchParams().get(COORDINATES_KEY);
  if(!coordinates) return coordinates;

  return coordinates.split(',');
}

export function setCoordinates(latitude, longitude) {
  updateUrl(COORDINATES_KEY, `${latitude},${longitude}`);
}

export function getZoomLevel() {
  return searchParams().get(ZOOM_LEVEL_KEY);
}

export function setZoomLevel(zoomLevel) {
  updateUrl(ZOOM_LEVEL_KEY, zoomLevel);
}

export function getLayer() {
  return searchParams().get(LAYER_KEY);
}

export function setLayer(layer) {
  updateUrl(LAYER_KEY, layer);
}

export function clearLayer() {
  updateUrl(LAYER_KEY, null);
}

export function hasFilterGroup(filterGroup) {
  return searchParams().has(`${FILTERS_KEY}_${filterGroup}`);
}

export function hasFilter(filterGroup, filterName) {
  const key = `${FILTERS_KEY}_${filterGroup}`;
  return getFilters(key).has(filterName);
}

export function addFilter(filterGroup, filterName) {
  updateFilters(filterGroup, filterName, (filters) => {
    filters.add(filterName);
  });
}

export function removeFilter(filterGroup, filterName) {
  updateFilters(filterGroup, filterName, (filters) => {
    filters.delete(filterName);
  });
}

function updateFilters(filterGroup, filterName, callback) {
  const key = `${FILTERS_KEY}_${filterGroup}`;
  const filters = getFilters(key);
  callback(filters);
  updateUrl(key, Array.from(filters).join(','));
}

function getFilters(key) {
  const filters = searchParams().get(key);
  return new Set(filters ? filters.split(',') : []);
}

function updateUrl(key, value) {
  const params = searchParams();

  // If a null value was given clear its respective key rather than trying to set it
  if(value === null) {
    params.delete(key);
  } else {
    params.set(key, value);
  }

  window.history.replaceState({}, '', `/?${params}`);
}

function searchParams() {
  return new URL(window.location).searchParams;
}

function normalizeAirportCode(airportCode) {
  if(!airportCode) return airportCode;

  let normalizedAirportCode = airportCode.toUpperCase();

  // Remove leading K, eg KPAE -> PAE
  if(normalizedAirportCode.length === 4 && normalizedAirportCode[0] === 'K') {
    normalizedAirportCode = normalizedAirportCode.substring(1);
  }

  return normalizedAirportCode;
}
