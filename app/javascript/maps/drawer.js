const layerSwitcher = require('./layer_switcher');
const maps = require('./maps');
const photoGallery = require('../shared/photo_gallery');
const textareaEditors = require('../shared/textarea_editors');
const urlSearchParams = require('./url_search_params');

let previousZoomLevel;
let wereSectionalLayersShown;

document.addEventListener('DOMContentLoaded', () => {
  // Close the drawer when clicking the drawer handle
  let drawerHandle = document.querySelector('#airport-drawer .handle button');
  if(!drawerHandle) return;

  drawerHandle.addEventListener('click', () => {
    closeDrawer();
    maps.closeAirport();
  });
});

export async function loadDrawer(airportCode) {
  // Hide the drawer content and show the loading icon
  document.getElementById('drawer-loading').style.display = 'flex';
  document.getElementById('airport-info').style.display = 'none';

  // Get the path to request airport info from dynamically
  // Tthis means swapping out a placeholder value with the airport code we want to get
  const {airportPath} = document.getElementById('map').dataset;
  const {placeholder} = document.getElementById('map').dataset;

  const response = await fetch(airportPath.replace(placeholder, airportCode));

  if(!response.ok) {
    // TODO: make this better
    return alert('fetching airport failed');
  }

  setDrawerContent(airportCode, await response.text());
}

function setDrawerContent(airportCode, body) {
  // Hide the loading icon
  document.getElementById('drawer-loading').style.display = 'none';

  // Set the drawer's content to the given body
  const drawerInfo = document.getElementById('airport-info');
  drawerInfo.innerHTML = body;
  drawerInfo.style.display = 'block';

  // Set necessary event handlers on the drawer elements
  initializeDrawer();
}

function initializeDrawer() {
  // Zoom out/in
  document.querySelector('.zoom-btn').addEventListener('click', zoomAirport);

  photoGallery.initializePhotoGallery();
  textareaEditors.initEditors();
}

function zoomAirport(event) {
  const button = event.target;

  if(button.dataset.zoomedIn === 'true') {
    // Go back to the previous zoom level and show the sectional layers if they were previously shown
    maps.flyTo(button.dataset.latitude, button.dataset.longitude, previousZoomLevel);

    if(wereSectionalLayersShown) {
      layerSwitcher.updateLayerSwitcherIcon(layerSwitcher.LAYER_SATELLITE);
      maps.toggleSectionalLayers(true);
      urlSearchParams.clearLayer();
    }

    button.innerText = 'Zoom In';
    button.dataset.zoomedIn = 'false';
  } else {
    // Save the previous state to restore when zooming back out
    previousZoomLevel = maps.getZoom();
    wereSectionalLayersShown = maps.areSectionalLayersShown();

    maps.flyTo(button.dataset.latitude, button.dataset.longitude, 15);
    maps.toggleSectionalLayers(false);
    layerSwitcher.updateLayerSwitcherIcon(layerSwitcher.LAYER_MAP);

    button.innerText = 'Zoom Out';
    button.dataset.zoomedIn = 'true';

    urlSearchParams.setLayer(layerSwitcher.LAYER_SATELLITE);
  }
}

export function openDrawer() {
  const drawer = document.getElementById('airport-drawer');
  drawer.classList.remove('slide-out');
  drawer.classList.add('slide-in');
}

export function closeDrawer() {
  const drawer = document.getElementById('airport-drawer');
  drawer.classList.remove('slide-in');
  drawer.classList.add('slide-out');
}

export function isDrawerOpen() {
  return (document.getElementById('airport-drawer').classList.contains('slide-in'));
}
