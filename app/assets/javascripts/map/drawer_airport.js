import * as flashes from 'map/flashes';
import * as layerSwitcher from 'map/layer_switcher';
import * as map from 'map/map';
import * as photoGallery from 'shared/photo_gallery';
import * as textareaEditors from 'shared/textarea_editors';
import * as urlSearchParams from 'map/url_search_params';

const DRAWER_CONTENT_ID = 'drawer-airport';

let previousZoomLevel;
let wereSectionalLayersShown;

export async function loadDrawer(airportCode) {
  // Get the path to request airport info from dynamically
  // Tthis means swapping out a placeholder value with the airport code we want to get
  const {airportPath} = document.getElementById('map').dataset;
  const {placeholder} = document.getElementById('map').dataset;

  const response = await fetch(airportPath.replace(placeholder, airportCode));

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
      layerSwitcher.updateLayerSwitcherIcon(layerSwitcher.LAYER_SATELLITE);
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
    layerSwitcher.updateLayerSwitcherIcon(layerSwitcher.LAYER_MAP);

    button.innerText = 'Zoom Out';
    button.dataset.zoomedIn = 'true';

    urlSearchParams.setLayer(layerSwitcher.LAYER_SATELLITE);
  }
}
