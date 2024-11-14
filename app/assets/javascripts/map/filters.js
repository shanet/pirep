import * as drawerOrigin from 'map/drawer_origin';
import * as map from 'map/map';
import * as urlSearchParams from 'map/url_search_params';
import * as utils from 'map/utils';

const FILTER_GROUP_HOVER_TEXT = ' (clear all)';

export const FILTER_GROUP_FACILITY_TYPES = 'facility_types';
export const FILTER_GROUP_TAGS = 'tags';

export const FACILITY_TYPE_AIRPORT = 'airport';
export const TAG_POPULATED = 'populated';
export const TAG_PRIVATE = 'private_';
export const TAG_PUBLIC = 'public_';

const enabledFilters = {};
const filterLabels = {};

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('filters')) return;

  initFilterHandles();
  initFilterLabels();
  initFilterGroupLabels();
  initFilters();
  initFiltersDrawer();
}, {once: true});

function initFilters() {
  const filters = document.getElementsByClassName('filter');

  for(let i = 0; i < filters.length; i++) {
    const filter = filters[i];
    const {filterName, filterGroup, defaultFilter} = filter.dataset;
    const {filterLabel} = filterLabels[filterName];

    enabledFilters[filterGroup] ||= new Set();

    // Don't set default filters if there is a URL param for the filter group which should take precedence
    if((!urlSearchParams.hasFilterGroup(filterGroup) && defaultFilter === 'true') || urlSearchParams.hasFilter(filterGroup, filterName)) {
      enabledFilters[filterGroup].add(filterName);
      filter.classList.remove('disabled');
    } else {
      filter.classList.add('disabled');
      filterLabel.classList.add('disabled');
    }

    filter.addEventListener('click', () => {
      if(enabledFilters[filterGroup].has(filterName)) {
        disableFilter(filter);
      } else {
        enableFilter(filter);
      }
    });

    // Change the color of the filter label as well when hovering over the filter
    filter.addEventListener('mouseenter', () => {filterLabel.classList.add('hover');});
    filter.addEventListener('mouseleave', () => {filterLabel.classList.remove('hover');});
  }
}

export function enableFilter(filter, skipCallbacks) {
  const {filterName, filterGroup} = filter.dataset;
  const {filterLabel} = filterLabels[filterName];

  enabledFilters[filterGroup].add(filterName);

  // Disable the populated filter if another tag filter was enabled
  if(filterGroup === FILTER_GROUP_TAGS && filterName !== TAG_POPULATED) {
    disableFilter(getFilter(FILTER_GROUP_TAGS, TAG_POPULATED), true);
  }

  // Enable all filter elements for the selected filter group/name
  // There are multiple filter elements for the responsive elements on the page
  const filters = document.querySelectorAll(`.filter[data-filter-group="${filterGroup}"][data-filter-name="${filterName}"]`);

  for(let i=0; i<filters.length; i++) {
    filters[i].classList.remove('disabled');
  }

  // Also enable the filter label (there are only one of these)
  filterLabel.classList.remove('disabled');

  urlSearchParams.addFilter(filterGroup, filterName);

  if(!skipCallbacks) {
    // Update the map with the new filter state
    map.filterAirportsOnMap();

    // Update the state of the origin filters too
    drawerOrigin.enableFilter(filterName);
  }
}

export function disableFilter(filter, skipCallbacks) {
  const {filterName, filterGroup} = filter.dataset;
  const {filterLabel} = filterLabels[filterName];

  enabledFilters[filterGroup].delete(filterName);

  // Enable the populated filter when all other tag filters are disabled
  if(filterGroup === FILTER_GROUP_TAGS && filterName !== TAG_POPULATED && enabledFilters[filterGroup].size === 0) {
    enableFilter(getFilter(FILTER_GROUP_TAGS, TAG_POPULATED), true);
  }

  const filters = document.querySelectorAll(`.filter[data-filter-group="${filterGroup}"][data-filter-name="${filterName}"]`);

  for(let i=0; i<filters.length; i++) {
    filters[i].classList.add('disabled');
  }

  filterLabel.classList.add('disabled');

  urlSearchParams.removeFilter(filterGroup, filterName);

  if(!skipCallbacks) {
    // Update the map with the new filter state
    map.filterAirportsOnMap();

    // Update the state of the origin filters too
    drawerOrigin.disableFilter(filterName);
  }
}

function initFilterGroupLabels() {
  const filterGroups = document.querySelectorAll('#filters .filter-group');

  for(let i=0; i<filterGroups.length; i++) {
    const filterGroup = filterGroups[i];
    const filterGroupName = filterGroup.dataset.filterName;

    const filterLabel = initFilterLabel(filterGroup);

    // Kind of hacky, but "disable" the filter label so it's text shows up as white since it doesn't have a theme color and can't be "enabled"
    filterLabel.classList.add('disabled');

    // Clear all filters in the group when clicked
    filterGroup.addEventListener('click', () => {
      Object.keys(filterLabels).forEach((filterName) => {
        const {filter} = filterLabels[filterName];

        if(enabledFilters[filterGroupName].has(filterName) && filter.dataset.filterGroup === filterGroupName) {
          disableFilter(filter);
        }
      });

      // Update the map with the new filter state
      map.filterAirportsOnMap();
    });

    // Show/hide the hover text when hovering over the filter group icon/label
    filterGroup.addEventListener('mouseenter', () => {showFilterGroupHoverText(filterLabel);});
    filterLabel.addEventListener('mouseenter', () => {showFilterGroupHoverText(filterLabel);});
    filterGroup.addEventListener('mouseleave', () => {hideFilterGroupHoverText(filterLabel);});
    filterLabel.addEventListener('mouseleave', () => {hideFilterGroupHoverText(filterLabel);});

    // Change the color of the filter label as well when hovering over the filter
    filterGroup.addEventListener('mouseenter', () => {filterLabel.classList.add('hover');});
    filterGroup.addEventListener('mouseleave', () => {filterLabel.classList.remove('hover');});
  }
}

function showFilterGroupHoverText(filterLabel) {
  filterLabel.querySelector('span').innerText += FILTER_GROUP_HOVER_TEXT; // eslint-disable-line no-param-reassign
}

function hideFilterGroupHoverText(filterLabel) {
  const span = filterLabel.querySelector('span');
  span.innerText = span.innerText.replace(FILTER_GROUP_HOVER_TEXT, '');
}

function initFilterLabels() {
  const filters = document.querySelectorAll('#filters .filter');

  for(let i=0; i<filters.length; i++) {
    initFilterLabel(filters[i]);
  }

  // Scroll the filter labels when the nav is scrolled
  document.querySelector('#filters > nav').addEventListener('scroll', () => {
    Object.keys(filterLabels).forEach((filterName) => {
      updateFilterLabel(filterLabels[filterName].filterLabel, filterLabels[filterName].filter);
    });
  });

  // When resizing the window we need to refresh the filter labels so they're shown in the right spot for the adjusted viewport size
  window.addEventListener('resize', () => {
    Object.keys(filterLabels).forEach((filterName) => {
      // This is kind of hacky, but the usual trick of setting `translate` to redraw an element won't work here since we're actually
      // using `translate` to position these elements. Instead if we move them by 1 pixel and then back again they get redrawn as expected.
      updateFilterLabel(filterLabels[filterName].filterLabel, filterLabels[filterName].filter, 1);
      updateFilterLabel(filterLabels[filterName].filterLabel, filterLabels[filterName].filter);
    });
  });
}

function initFilterLabel(filter) {
  const filterLabel = createFilterLabel(filter);
  filterLabels[filter.dataset.filterName] = {filter, filterLabel};

  // Clicking on a filter label should apply the filter
  filterLabel.addEventListener('click', () => {
    filter.click();
  });

  // Change the color of the filter as well when hovering over the filter label
  filterLabel.addEventListener('mouseenter', () => {filter.classList.add('hover');});
  filterLabel.addEventListener('mouseleave', () => {filter.classList.remove('hover');});

  // Add the filters to the DOM and trigger an update event so they're rendered next to their respective icons
  filter.parentNode.appendChild(filterLabel);
  updateFilterLabel(filterLabel, filter);

  return filterLabel;
}

function createFilterLabel(filter) {
  const filterLabel = document.createElement('div');
  const filterLabelSpan = document.createElement('span');

  filterLabel.classList.add(...['filter-label', `theme-${filter.dataset.theme}`, 'd-none', 'd-md-block']);
  filterLabelSpan.appendChild(document.createTextNode(filter.dataset.label));
  filterLabel.appendChild(filterLabelSpan);

  // Scroll the nav bar when scrolling on the filter labels
  filterLabel.addEventListener('wheel', async (event) => {
    document.querySelector('#filters > nav').scrollBy(0, event.deltaY);
  });

  return filterLabel;
}

function updateFilterLabel(filterLabel, filter, delta) {
  const position = updateFilterLabelPosition(filterLabel, filter, delta);
  updateFilterLabelOpacity(filterLabel);
  updateFilterLabelDisplay(filterLabel, position);
}

function updateFilterLabelPosition(filterLabel, filter, delta) {
  const filterBounds = filter.getBoundingClientRect();
  let y = filterBounds.top + (filterBounds.height / 2) - (filterLabel.getBoundingClientRect().height / 2);
  const x = filterBounds.left + filterBounds.width;

  if(delta) y += delta;

  filterLabel.style.transform = `translate(${x}px, ${y}px)`; // eslint-disable-line no-param-reassign

  return {x, y};
}

function updateFilterLabelOpacity(filterLabel) {
  const filterLabelBounds = filterLabel.getBoundingClientRect();
  const header = document.getElementById('filters-header').getBoundingClientRect();
  const footer = document.getElementById('filters-footer').getBoundingClientRect();
  let opacity;

  if(filterLabelBounds.top <= header.top) {
    // Not visible above the header
    opacity = 0;
  } else if(filterLabelBounds.top <= header.bottom) {
    // Fading out at the top
    opacity = 1 - (header.bottom - filterLabelBounds.top) / header.height;
  } else if(filterLabelBounds.bottom >= footer.top) {
    // Fading out at the bottom
    opacity = 1 - (filterLabelBounds.bottom - footer.top) / footer.height;
  } else if(filterLabelBounds.bottom >= footer.bottom) {
    // Not visible below the footer
    opacity = 0;
  } else {
    // Visible between the header and footer
    opacity = 1;
  }

  filterLabel.style.opacity = opacity; // eslint-disable-line no-param-reassign
}

function updateFilterLabelDisplay(filterLabel, filterLabelPosition) {
  const filtersBounds = document.getElementById('filters').getBoundingClientRect();

  if(filterLabelPosition.y <= filtersBounds.top) {
    filterLabel.style.display = 'none'; // eslint-disable-line no-param-reassign
  } else if(filterLabelPosition.y >= filtersBounds.bottom) {
    filterLabel.style.display = 'none'; // eslint-disable-line no-param-reassign
  } else {
    filterLabel.style.display = 'block'; // eslint-disable-line no-param-reassign
  }
}

function initFilterHandles() {
  const header = document.getElementById('filters-header');
  const footer = document.getElementById('filters-footer');
  const filters = document.querySelector('#filters > nav');

  // Scroll up/down when clicking on the filter header/footer
  header.addEventListener('click', () => {
    const scrollDelta = document.querySelector('.filter').offsetHeight;
    filters.scrollBy({top: -scrollDelta, left: 0, behavior: 'smooth'});
  });

  footer.addEventListener('click', () => {
    const scrollDelta = document.querySelector('.filter').offsetHeight;
    filters.scrollBy({top: scrollDelta, left: 0, behavior: 'smooth'});
  });
}

// Called by the map to determine if a specific airport should be shown given the current filter selections
export function showAirport(airport) {
  // Filter by facility type
  if(!enabledFilters.facility_types.has(airport.properties.facility_type)) return false;

  // Show all airports if no filters are selected
  if(enabledFilters.tags.size === 0) return false;

  // Filter by tag
  for(let i=0; i<airport.properties.tags.length; i++) {
    if(enabledFilters.tags.has(airport.properties.tags[i])) {
      return true;
    }
  }

  return false;
}

function initFiltersDrawer() {
  document.querySelector('#filters-drawer .btn-close')?.addEventListener('click', toggleFiltersDrawer);
}

export function toggleFiltersDrawer() {
  const drawer = document.getElementById('filters-drawer');

  if(drawer.style.transform) {
    closeFiltersDrawer();
  } else {
    openFiltersDrawer();
  }
}

export function openFiltersDrawer() {
  const drawer = document.getElementById('filters-drawer');

  utils.closeAllDrawers();

  drawer.style.visibility = 'visible';
  drawer.style.transform = 'none';
}

export function closeFiltersDrawer() {
  const drawer = document.getElementById('filters-drawer');
  drawer.style.transform = '';
}

export function getFilter(filterGroup, filterName) {
  return document.querySelector(`.filter[data-filter-group="${filterGroup}"][data-filter-name="${filterName}"]`);
}
