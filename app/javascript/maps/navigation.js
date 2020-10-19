const maps = require('./maps');

const enabledTagFilters = new Set();
const allTagFilters = new Set();

// Initialize the filters
document.addEventListener('DOMContentLoaded', () => {
  const tagFilters = document.getElementsByClassName('tag-filter');

  for(let i = 0; i < tagFilters.length; i++) {
    const tagFilter = tagFilters[i];
    const { tag } = tagFilter.dataset;

    allTagFilters.add(tag);

    // Set default filters as enabled (not used yet)
    // if(tagFilter.dataset.defaultTag === 'true') {
    //   enabledTagFilters.add(tag);
    //   tagFilter.classList.remove('disabled');
    // }

    tagFilter.addEventListener('click', () => {
      if(enabledTagFilters.has(tag)) {
        enabledTagFilters.delete(tag);
        tagFilter.classList.add('disabled');
      } else {
        console.log(tag);
        enabledTagFilters.add(tag);
        tagFilter.classList.remove('disabled');
      }

      // Update the map with the new filter state
      maps.filterAirportsOnMap(enabledFilters());
    });
  }
});

export function enabledFilters() {
  // Default to showing all airports if no filters are enabled
  return (enabledTagFilters.size === 0 ? allTagFilters : enabledTagFilters);
}
