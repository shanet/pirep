const maps = require('./maps');
const urlSearchParams = require('./url_search_params');

export const LAYER_SATELLITE = 'satellite';

document.addEventListener('DOMContentLoaded', () => {
  let layerSwitcher = document.getElementById('layer-switcher');
  if(!layerSwitcher) return;

  layerSwitcher.addEventListener('click', () => {
    maps.toggleSectionalLayers(!maps.areSectionalLayersShown());

    if(!maps.areSectionalLayersShown()) {
      urlSearchParams.setLayer(LAYER_SATELLITE);
    } else {
      urlSearchParams.clearLayer(LAYER_SATELLITE);
    }
  });
});
