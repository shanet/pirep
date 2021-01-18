const maps = require('./maps');
const urlSearchParams = require('./url_search_params');

const enabledFilters = {};

document.addEventListener('DOMContentLoaded', () => {
  const filters = document.getElementsByClassName('filter');

  for(let i = 0; i < filters.length; i++) {
    const filter = filters[i];
    const {filterName, filterGroup, defaultFilter} = filter.dataset;

    enabledFilters[filterGroup] ||= new Set();

    if(defaultFilter === 'true' || urlSearchParams.hasFilter(filterGroup, filterName)) {
      enabledFilters[filterGroup].add(filterName);
      filter.classList.remove('disabled');
    }

    filter.addEventListener('click', () => {
      if(enabledFilters[filterGroup].has(filterName)) {
        enabledFilters[filterGroup].delete(filterName);
        filter.classList.add('disabled');
        urlSearchParams.removeFilter(filterGroup, filterName);
      } else {
        enabledFilters[filterGroup].add(filterName);
        filter.classList.remove('disabled');
        urlSearchParams.addFilter(filterGroup, filterName);
      }

      // Update the map with the new filter state
      maps.filterAirportsOnMap();
    });
  }
});

export function showAirport(airport) {
  // Filter by facility type
  if(!enabledFilters['facility_types'].has(airport.properties.facility_type)) return false;

  // Show all airports if no filters are selected
  if(enabledFilters['tags'].size === 0) return true;

  // Filter by tag
  for(let i=0; i<airport.properties.tags.length; i++) {
    if(enabledFilters['tags'].has(airport.properties.tags[i])) {
      return true;
    }
  }

  return false;
}
