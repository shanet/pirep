import * as flashes from 'map/flashes';
import * as actionButtons from 'map/action_buttons';
import * as map from 'map/map';
import * as photoGallery from 'shared/photo_gallery';
import * as textareaEditors from 'shared/textarea_editors';
import * as urlSearchParams from 'map/url_search_params';

const DRAWER_CONTENT_ID = 'drawer-show-airport';

let previousZoomLevel;
let wereSectionalLayersShown;

export async function loadDrawer(airportCode) {
  // Get the path to request airport info from dynamically
  // This means swapping out a placeholder value with the airport code we want to get
  const {showAirportPath} = document.getElementById('map').dataset;
  const {airportPathPlaceholder} = document.getElementById('map').dataset;

  const response = await fetch(showAirportPath.replace(airportPathPlaceholder, airportCode));

  if(!response.ok) {
    return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving airport details.');
  }

  document.getElementById(DRAWER_CONTENT_ID).innerHTML = await response.text();

  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  // Zoom out/in
  document.querySelector(`#${DRAWER_CONTENT_ID} .zoom-btn`).addEventListener('click', zoomAirport);

  photoGallery.initializePhotoGallery();
  textareaEditors.initEditors();
}

function zoomAirport(event) {
  const button = event.target;

  if(button.dataset.zoomedIn === 'true') {
    // Go back to the previous zoom level and show the sectional layers if they were previously shown
    map.flyTo(button.dataset.latitude, button.dataset.longitude, previousZoomLevel);

    if(wereSectionalLayersShown) {
      actionButtons.updateactionButtonsIcon(actionButtons.LAYER_SATELLITE);
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
  }
}
