const maps = require('./maps');

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('layer-switcher').addEventListener('click', () => {
    maps.toggleSectionalLayers(!maps.areSectionalLayersShown());
  });
});
