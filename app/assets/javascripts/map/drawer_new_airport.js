import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as flashes from 'map/flashes';
import * as landingRights from 'airports/landing_rights';
import * as map from 'map/map';
import * as utils from 'shared/utils';

const NEW_AIRPORT_LAYER = 'new_airport';
const DRAWER_CONTENT_ID = 'drawer-new-airport';

export async function loadDrawer() {
  // Get the path to request airport info from dynamically
  // Tthis means swapping out a placeholder value with the airport code we want to get
  const {newAirportPath} = document.getElementById('map').dataset;
  const response = await fetch(newAirportPath);

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving the new airport form.');
  }

  document.getElementById(DRAWER_CONTENT_ID).innerHTML = await response.text();

  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  // Put the map into adding mode when the select coordinates button is clicked so a crosshair cursor is shown
  document.querySelector('#new-airport .select-coordinates').addEventListener('click', () => {
    document.getElementById('map').classList.add('adding');
    flashes.show(flashes.FLASH_NOTICE, 'Select the center of the airport on the map.');
    if(utils.isBreakpointDown('sm')) drawer.closeDrawer();

    // Change the filters to show all airports too to prevent people from thinking something is unmapped because it's hidden by the filters
    filters.enableFilter(filters.getFilter(filters.FILTER_GROUP_FACILITY_TYPES, filters.FACILITY_TYPE_AIRPORT));
    filters.enableFilter(filters.getFilter(filters.FILTER_GROUP_TAGS, filters.TAG_PUBLIC));
    filters.enableFilter(filters.getFilter(filters.FILTER_GROUP_TAGS, filters.TAG_PRIVATE));
  });

  landingRights.initLandingRightsForm();

  // Hide the landing rights form fields when an airport is marked closed
  document.getElementById('airport_state_active').addEventListener('click', () => {
    document.getElementById('landing-rights-container').classList.remove('d-none');
  });

  document.getElementById('airport_state_closed').addEventListener('click', () => {
    document.getElementById('landing-rights-container').classList.add('d-none');
  });
}

export function locationSelected(latitude, longitude, elevation) {
  // Re-open the drawer if it was closed on a small screen
  drawer.openDrawer();

  // Ensure the satellite view is shown when zoomed in
  map.toggleSectionalLayers(false);

  // Convert meters to feet
  const elevationFeet = Math.round(elevation * 3.28084);

  // Populate the form fields with the selected location
  document.querySelector('#new-airport .coordinates').textContent = `Location: ${latitude.toFixed(7)}, ${longitude.toFixed(7)} / ${elevationFeet}ft`;
  document.querySelector('#new-airport #airport_latitude').value = latitude;
  document.querySelector('#new-airport #airport_longitude').value = longitude;
  document.querySelector('#new-airport #airport_elevation').value = elevationFeet;

  // Take the map out of adding mode so clicking again doesn't change the location
  document.getElementById('map').classList.remove('adding');

  // Add a temporary pin for the new airport
  const airportId = -1;

  // Remove the existing pin if one was already added to the map
  removeNewAirportLayer();

  map.addAirportToMap(NEW_AIRPORT_LAYER, {
    id: airportId,
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [longitude, latitude],
    },
  });

  map.setAirportMarkerSelected(airportId, NEW_AIRPORT_LAYER);

  // Give focus to the name field now that a location is selected
  document.getElementById('airport_name').focus();
}

export function removeNewAirportLayer() {
  map.removeLayer(NEW_AIRPORT_LAYER);
}
