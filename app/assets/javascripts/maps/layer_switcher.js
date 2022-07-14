import * as maps from 'maps/maps';
import * as urlSearchParams from 'maps/url_search_params';

export const LAYER_SATELLITE = 'satellite';
export const LAYER_MAP = 'map';

let initialized = false;

document.addEventListener('DOMContentLoaded', () => {
  const layerSwitcher = document.getElementById('layer-switcher');
  if(!layerSwitcher || initialized) return;
  initialized = true;

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
