const maps = require('./maps');
const urlSearchParams = require('./url_search_params');

export const LAYER_SATELLITE = 'satellite';
export const LAYER_MAP = 'map';

document.addEventListener('DOMContentLoaded', () => {
  let layerSwitcher = document.getElementById('layer-switcher');
  if(!layerSwitcher) return;

  // Set the layer switcher icon to map by default if the URL params are set to show the satellite layer
  updateLayerSwitcherIcon((urlSearchParams.getLayer() === LAYER_SATELLITE ? LAYER_MAP : LAYER_SATELLITE));

  layerSwitcher.addEventListener('click', () => {
    maps.toggleSectionalLayers(!maps.areSectionalLayersShown());

    if(!maps.areSectionalLayersShown()) {
      urlSearchParams.setLayer(LAYER_SATELLITE);
      updateLayerSwitcherIcon(LAYER_MAP);
    } else {
      urlSearchParams.clearLayer();
      updateLayerSwitcherIcon(LAYER_SATELLITE);
    }
  });
});

export function updateLayerSwitcherIcon(shownIcon) {
  let layerSwitcher = document.getElementById('layer-switcher');
  let satelliteIcon = layerSwitcher.querySelector('.satellite-icon');
  let mapIcon = layerSwitcher.querySelector('.map-icon');

  if(shownIcon == LAYER_SATELLITE) {
    satelliteIcon.classList.remove('d-none');
    mapIcon.classList.add('d-none');
  } else {
    satelliteIcon.classList.add('d-none');
    mapIcon.classList.remove('d-none');
  }
}
