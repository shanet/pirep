import * as maps from 'maps/maps';
import * as urlSearchParams from 'maps/url_search_params';
import * as utils from 'shared/utils';

const FILTER_GROUP_HOVER_TEXT = ' (remove all)';

const enabledFilters = {};
const filterLabels = {};

let initialized = false;

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('filters') || initialized) return;
  initialized = true;

  initFilterHandles();
  initFilterLabels();
  initFilterGroupLabels();
  initFilters();
});

function initFilters() {
  const filters = document.getElementsByClassName('filter');

  for(let i = 0; i < filters.length; i++) {
    const filter = filters[i];
    const {filterName, filterGroup, defaultFilter} = filter.dataset;
    const filterLabel = filterLabels[filterName]['filterLabel'];

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
        disableFilter(filter)
      } else {
        enableFilter(filter);
      }

      // Update the map with the new filter state
      maps.filterAirportsOnMap();
    });

    // Change the color of the filter label as well when hovering over the filter
    filter.addEventListener('mouseenter', () => {filterLabel.classList.add('hover')});
    filter.addEventListener('mouseleave', () => {filterLabel.classList.remove('hover')});
  }
}

function enableFilter(filter) {
  const {filterName, filterGroup, defaultFilter} = filter.dataset;
  const filterLabel = filterLabels[filterName]['filterLabel'];

  enabledFilters[filterGroup].add(filterName);

  filter.classList.remove('disabled');
  filterLabel.classList.remove('disabled');

  urlSearchParams.addFilter(filterGroup, filterName);
}

function disableFilter(filter) {
  const {filterName, filterGroup, defaultFilter} = filter.dataset;
  const filterLabel = filterLabels[filterName]['filterLabel'];

  enabledFilters[filterGroup].delete(filterName);

  filter.classList.add('disabled');
  filterLabel.classList.add('disabled');

  urlSearchParams.removeFilter(filterGroup, filterName);
}

function initFilterGroupLabels() {
  const filterGroups = document.getElementsByClassName('filter-group');

  for(let i=0; i<filterGroups.length; i++) {
    let filterGroup = filterGroups[i];
    let filterGroupName = filterGroup.dataset.filterName;

    let filterLabel = initFilterLabel(filterGroup);

    // Kind of hacky, but "disable" the filter label so it's text shows up as white since it doesn't have a theme color and can't be "enabled"
    filterLabel.classList.add('disabled');

    // Clear all filters in the group when clicked
    filterGroup.addEventListener('click', () => {
      Object.keys(filterLabels).forEach((filterName) => {
        let filter = filterLabels[filterName]['filter'];

        if(enabledFilters[filterGroupName].has(filterName) && filter.dataset.filterGroup === filterGroupName) {
          disableFilter(filter);
        }
      });

      // Update the map with the new filter state
      maps.filterAirportsOnMap();
    });

    // Show/hide the hover text when hovering over the filter group icon/label
    filterGroup.addEventListener('mouseenter', () => {showFilterGroupHoverText(filterLabel)});
    filterLabel.addEventListener('mouseenter', () => {showFilterGroupHoverText(filterLabel)});
    filterGroup.addEventListener('mouseleave', () => {hideFilterGroupHoverText(filterLabel)});
    filterLabel.addEventListener('mouseleave', () => {hideFilterGroupHoverText(filterLabel)});

    // Change the color of the filter label as well when hovering over the filter
    filterGroup.addEventListener('mouseenter', () => {filterLabel.classList.add('hover')});
    filterGroup.addEventListener('mouseleave', () => {filterLabel.classList.remove('hover')});
  }
}

function showFilterGroupHoverText(filterLabel) {
  filterLabel.querySelector('span').innerText += FILTER_GROUP_HOVER_TEXT;
}

function hideFilterGroupHoverText(filterLabel) {
  let span = filterLabel.querySelector('span');
  span.innerText = span.innerText.substring(0, FILTER_GROUP_HOVER_TEXT.length + 1);
}

function initFilterLabels() {
  const filters = document.getElementsByClassName('filter');

  for(let i=0; i<filters.length; i++) {
    initFilterLabel(filters[i]);
  }

  // Scroll the filter labels when the nav is scrolled
  document.querySelector('#filters > nav').addEventListener('scroll', () => {
    Object.keys(filterLabels).forEach((filterName) => {
      updateFilterLabel(filterLabels[filterName]['filterLabel'], filterLabels[filterName]['filter']);
    });
  });

  // When resizing the window we need to refresh the filter labels so they're shown in the right spot for the adjusted viewport size
  window.addEventListener('resize', () => {
    Object.keys(filterLabels).forEach((filterName) => {
      // This is kind of hacky, but the usual trick of setting `translate` to redraw an element won't work here since we're actually
      // using `translate` to position these elements. Instead if we move them by 1 pixel and then back again they get redrawn as expected.
      updateFilterLabel(filterLabels[filterName]['filterLabel'], filterLabels[filterName]['filter'], 1);
      updateFilterLabel(filterLabels[filterName]['filterLabel'], filterLabels[filterName]['filter']);
    });
  });
}

function initFilterLabel(filter) {
  let filterLabel = createFilterLabel(filter);
  filterLabels[filter.dataset.filterName] = {filter: filter, filterLabel: filterLabel};

  // Clicking on a filter label should apply the filter
  filterLabel.addEventListener('click', () => {filter.click()});

  // Change the color of the filter as well when hovering over the filter label
  filterLabel.addEventListener('mouseenter', () => {filter.classList.add('hover')});
  filterLabel.addEventListener('mouseleave', () => {filter.classList.remove('hover')});

  return filterLabel;
}

function createFilterLabel(filter) {
  const filterLabel = document.createElement('div');
  const filterLabelSpan = document.createElement('span');

  filterLabel.classList.add(...['filter-label', `theme-${filter.dataset.theme}`]);
  filterLabelSpan.appendChild(document.createTextNode(filter.dataset.label));
  filterLabel.appendChild(filterLabelSpan);

  document.body.appendChild(filterLabel);
  updateFilterLabel(filterLabel, filter);

  // Scroll the nav bar when scrolling on the filter labels
  // It would be really nice to make this a smooth scroll, but I can't find a way to make that work nicely :(
  filterLabel.addEventListener('wheel', async (event) => {
    document.querySelector('#filters > nav').scrollBy(0, event.deltaY);
  });

  return filterLabel;
}

function updateFilterLabel(filterLabel, filter, delta) {
  let position = updateFilterLabelPosition(filterLabel, filter, delta);
  updateFilterLabelOpacity(filterLabel);
  updateFilterLabelDisplay(filterLabel, position);
}

function updateFilterLabelPosition(filterLabel, filter, delta) {
  let filterBounds = filter.getBoundingClientRect();
  let y = filterBounds.top + (filterBounds.height / 2) - (filterLabel.getBoundingClientRect().height / 2);
  let x = filterBounds.left + filterBounds.width;

  if(delta) y += delta;

  filterLabel.style.transform = `translate(${x}px, ${y}px)`;

  return {x: x, y: y};
}

function updateFilterLabelOpacity(filterLabel) {
  let filterLabelBounds = filterLabel.getBoundingClientRect();
  let header = document.getElementById('filters-header').getBoundingClientRect();
  let footer = document.getElementById('filters-footer').getBoundingClientRect();
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

  filterLabel.style.opacity = opacity;
}

function updateFilterLabelDisplay(filterLabel, filterLabelPosition) {
  let filtersBounds = document.getElementById('filters').getBoundingClientRect();
  let filterLabelBounds = filterLabel.getBoundingClientRect();

  if(filterLabelPosition.y <= filtersBounds.top) {
    filterLabel.style.display = "none";
  } else if(filterLabelPosition.y >= filtersBounds.bottom) {
    filterLabel.style.display = "none";
  } else {
    filterLabel.style.display = "block";
  }
}

function initFilterHandles() {
  let header = document.getElementById('filters-header');
  let footer = document.getElementById('filters-footer');
  let filters = document.querySelector('#filters > nav');
  let scrollDelta = document.querySelector('.filter').offsetHeight;

  // Scroll up/down when clicking on the filter header/footer
  header.addEventListener('click', () => {
    filters.scrollBy({top: -scrollDelta, left: 0, behavior: 'smooth'});
  });

  footer.addEventListener('click', () => {
    filters.scrollBy({top: scrollDelta, left: 0, behavior: 'smooth'});
  });
}

// Called by the map to determine if a specific airport should be shown given the current filter selections
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
