import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as map from 'map/map';
import * as urlSearchParams from 'map/url_search_params';

export const LAYER_SATELLITE = 'satellite';
export const LAYER_MAP = 'map';

document.addEventListener('DOMContentLoaded', () => {
  initLayerSwitcher();
  initNewAirport();
  initMapPitchButton();
  initFiltersButton();
}, {once: true});

function initLayerSwitcher() {
  const layerSwitcher = document.getElementById('layer-switcher');
  if(!layerSwitcher) return;

  // Set the layer switcher icon to map by default if the URL params are set to show the satellite layer
  updateLayerSwitcherIcon((urlSearchParams.getLayer() === LAYER_SATELLITE ? LAYER_MAP : LAYER_SATELLITE));

  layerSwitcher.addEventListener('click', () => {
    map.toggleSectionalLayers(!map.areSectionalLayersShown());

    if(!map.areSectionalLayersShown()) {
      urlSearchParams.setLayer(LAYER_SATELLITE);
      updateLayerSwitcherIcon(LAYER_MAP);
    } else {
      urlSearchParams.clearLayer();
      updateLayerSwitcherIcon(LAYER_SATELLITE);
    }
  });
}

function initNewAirport() {
  const newAirportButton = document.getElementById('new-airport-button');
  if(!newAirportButton) return;

  newAirportButton.addEventListener('click', () => {
    // Deselect any airport that is already selected
    map.closeAirport();

    drawer.loadDrawer(drawer.DRAWER_NEW_AIRPORT);
    drawer.openDrawer();
  });
}

export function updateLayerSwitcherIcon(shownIcon) {
  const layerSwitcher = document.getElementById('layer-switcher');
  const satelliteIcon = layerSwitcher.querySelector('.satellite-icon');
  const mapIcon = layerSwitcher.querySelector('.map-icon');

  if(shownIcon === LAYER_SATELLITE) {
    satelliteIcon.classList.remove('d-none');
    mapIcon.classList.add('d-none');
  } else {
    satelliteIcon.classList.add('d-none');
    mapIcon.classList.remove('d-none');
  }
}

function initMapPitchButton() {
  const button = document.getElementById('map-pitch-button');
  if(!button) return;

  button.addEventListener('click', () => {
    if(button.dataset.state === '2d') {
      map.set3dPitch();
      button.dataset.state = '3d';
      button.innerText = '2D';
    } else {
      map.resetCamera();
      button.dataset.state = '2d';
      button.innerText = '3D';
    }
  });
}

function initFiltersButton() {
  document.getElementById('filters-button')?.addEventListener('click', () => {
    document.getElementById('filters-button-tooltip').classList.add('d-none');
    filters.toggleFiltersDrawer();
  });
}
