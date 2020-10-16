const maps = require('./maps');

let sectional_layer_shown = true;

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('layer-switcher').addEventListener('click', () => {
    sectional_layer_shown = !sectional_layer_shown;
    maps.toggleSectionalLayers(sectional_layer_shown);
  });
});
