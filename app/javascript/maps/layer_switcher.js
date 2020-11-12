const maps = require('./maps');

document.addEventListener('DOMContentLoaded', () => {
  let layerSwitcher = document.getElementById('layer-switcher');
  if(!layerSwitcher) return;

  layerSwitcher.addEventListener('click', () => {
    maps.toggleSectionalLayers(!maps.areSectionalLayersShown());
  });
});
