import * as flashes from 'map/flashes';
import * as landingRights from 'airports/landing_rights';
import * as map from 'map/map';

const DRAWER_CONTENT_ID = 'drawer-new-airport';

export async function loadDrawer() {
  // Get the path to request airport info from dynamically
  // Tthis means swapping out a placeholder value with the airport code we want to get
  const newAirportPath = document.getElementById('map').dataset.newAirportPath;

  const response = await fetch(newAirportPath);

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving the new airport form.');
  }

  document.getElementById(DRAWER_CONTENT_ID).innerHTML = await response.text();

  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  // Put the map into editing mode when the select coordinates button is clicked so a crosshair cursor is shown
  document.querySelector('#new-airport .select-coordinates').addEventListener('click', () => {
    document.getElementById('map').classList.add('editing');
    flashes.show(flashes.FLASH_NOTICE, 'Select the center of the airport on the map.');
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
  // Convert meters to feet
  const elevationFeet = Math.round(elevation * 3.28084);

  // Populate the form fields with the selected location
  document.querySelector('#new-airport .coordinates').textContent = `Location: ${latitude.toFixed(7)}, ${longitude.toFixed(7)} / ${elevationFeet}ft`;
  document.querySelector('#new-airport #airport_latitude').value = latitude;
  document.querySelector('#new-airport #airport_longitude').value = longitude;
  document.querySelector('#new-airport #airport_elevation').value = elevationFeet;

  // Take the map out of editing mode so clicking again doesn't change the location
  document.getElementById('map').classList.remove('editing');

  // Add a temporary pin for the new airport
  const layerId = 'new_airport';
  const airportId = -1;

  // Remove the existing pin if one was already added to the map
  map.removeLayer(layerId);

  map.addAirportToMap(layerId, {
    id: airportId,
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [longitude, latitude],
    },
  });

  map.setAirportMarkerSelected(airportId, layerId);
}
