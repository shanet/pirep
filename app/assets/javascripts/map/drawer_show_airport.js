import * as actionButtons from 'map/action_buttons';
import * as drawer from 'map/drawer';
import * as flashes from 'map/flashes';
import * as map from 'map/map';
import * as photoGallery from 'shared/photo_gallery';
import * as textareaEditors from 'shared/textarea_editors';
import * as urlSearchParams from 'map/url_search_params';
import * as utils from 'shared/utils';

const DRAWER_CONTENT_ID = 'drawer-show-airport';

let currentAirport;
let previousZoomLevel;
let wereSectionalLayersShown;

export async function loadDrawer(airportCode) {
  // Don't re-load the drawer if the requested airport is the one already shown
  if(currentAirport === airportCode) return DRAWER_CONTENT_ID;

  // Get the path to request airport info from dynamically
  // This means swapping out a placeholder value with the airport code we want to get
  const {showAirportPath} = document.getElementById('map').dataset;
  const {airportPathPlaceholder} = document.getElementById('map').dataset;

  const response = await fetch(showAirportPath.replace(airportPathPlaceholder, airportCode));

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving airport details.');
  }

  document.getElementById(DRAWER_CONTENT_ID).innerHTML = await response.text();

  // Don't update the current airport until the requested airport has been successfully loaded
  currentAirport = airportCode;
  document.querySelector(`#${DRAWER_CONTENT_ID}`).dataset.initialized = null;

  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  // Don't re-initialize a drawer that was already opened, closed, and then re-opened
  if(document.querySelector(`#${DRAWER_CONTENT_ID}`).dataset.initialized === 'true') return;

  // Airport show more buttons
  const moreButtons = document.querySelectorAll(`#${DRAWER_CONTENT_ID} .airport-more-button`);

  for(let i=0; i<moreButtons.length; i++) {
    // Let the airport page know it's being accessed from the map so it knows to use the history API for back links
    moreButtons[i].addEventListener('click', () => {
      sessionStorage.setItem('from_map', true);
    });
  }

  // Zoom out/in
  document.querySelector(`#${DRAWER_CONTENT_ID} .zoom-btn`).addEventListener('click', zoomAirport);

  photoGallery.initializePhotoGalleries();
  textareaEditors.initEditors();

  document.querySelector(`#${DRAWER_CONTENT_ID}`).dataset.initialized = 'true';
}

function zoomAirport(event) {
  const button = event.target;

  if(button.dataset.zoomedIn === 'true') {
    // Go back to the previous zoom level and show the sectional layers if they were previously shown
    map.flyTo(button.dataset.latitude, button.dataset.longitude, previousZoomLevel);

    if(wereSectionalLayersShown) {
      actionButtons.updateLayerSwitcherIcon(actionButtons.LAYER_SATELLITE);
      map.toggleSectionalLayers(true);
      urlSearchParams.clearLayer();
    }

    button.innerText = 'Zoom In';
    button.dataset.zoomedIn = 'false';
  } else {
    // Save the previous state to restore when zooming back out
    previousZoomLevel = map.getZoom();
    wereSectionalLayersShown = map.areSectionalLayersShown();

    // Zoom to a bounding box if we have one for the airport
    if(JSON.parse(button.dataset.boundingBox)) {
      map.fitBounds(JSON.parse(button.dataset.boundingBox), 150);
    } else {
      map.flyTo(button.dataset.latitude, button.dataset.longitude, button.dataset.zoomLevel);
    }

    map.toggleSectionalLayers(false);
    actionButtons.updateLayerSwitcherIcon(actionButtons.LAYER_MAP);

    button.innerText = 'Zoom Out';
    button.dataset.zoomedIn = 'true';

    urlSearchParams.setLayer(actionButtons.LAYER_SATELLITE);

    // On a small screen size we should close the drawer so the airport is visible again when zooming in
    if(utils.isBreakpointDown('sm')) {
      drawer.closeDrawer();
    }
  }
}
