const maps = require('./maps');

const enabledTagFilters = new Set();

// Initialize the filters
document.addEventListener('DOMContentLoaded', () => {
  const tagFilters = document.getElementsByClassName('tag-filter');

  for(let i = 0; i < tagFilters.length; i++) {
    const tagFilter = tagFilters[i];
    const { tag } = tagFilter.dataset;
    const icon = tagFilter.querySelector('.icon');

    // Set default filters as enabled
    if(tagFilter.dataset.defaultTag === 'true') {
      enabledTagFilters.add(tag);
    } else {
      icon.style.backgroundColor = 'black';
    }

    tagFilter.addEventListener('click', () => {
      if(enabledTagFilters.has(tag)) {
        enabledTagFilters.delete(tag);
        icon.style.backgroundColor = 'black';
      } else {
        enabledTagFilters.add(tag);
        icon.style.backgroundColor = icon.dataset.color;
      }

      // Update the map with the new filter state
      maps.filterAirportsOnMap(enabledFilters());
    });
  }
});

export function enabledFilters() {
  return enabledTagFilters;
}
