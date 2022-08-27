import * as map from 'map/map';
import * as urlSearchParams from 'map/url_search_params';

export const LAYER_SATELLITE = 'satellite';
export const LAYER_MAP = 'map';

document.addEventListener('DOMContentLoaded', () => {
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
}, {once: true});

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
