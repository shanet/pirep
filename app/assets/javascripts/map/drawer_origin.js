import * as filters from 'map/filters';
import * as originInfo from 'map/origin_info';
import * as urlSearchParams from 'map/url_search_params';

const DRAWER_CONTENT_ID = 'drawer-origin';

let initialized = false;

export async function loadDrawer() {
  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  if(initialized) return;
  initialized = true;

  initializeOriginFilters(document.getElementById('origin'));
}

// This is also called by the origin info modal so take a root element as an argument to avoid the click listeners from being added twice
export function initializeOriginFilters(rootElement) {
  if(!rootElement) return;

  rootElement.querySelectorAll('.origin-info .tag-square').forEach((tag) => {
    if(urlSearchParams.hasFilter('tags', tag.dataset.tagName)) {
      tag.classList.remove('unselected');
    }

    tag.addEventListener('click', () => {
      const filter = document.querySelector(`a.filter[data-filter-group="tags"][data-filter-name="${tag.dataset.tagName}"]`);

      if(tag.classList.contains('unselected')) {
        filters.enableFilter(filter);

        // Hide the origin info modal dialog if this tag is part of that
        if(tag.dataset.dismiss) {
          originInfo.hide();
        }
      } else {
        filters.disableFilter(filter);
      }
    });
  });
}

// Called by the filters module to keep the state of the filters here in sync with the main filters
export function enableFilter(filterName) {
  document.querySelectorAll('.origin-info .tag-square').forEach((tag) => {
    if(tag.dataset.tagName === filterName) {
      tag.classList.remove('unselected');
    }
  });
}

export function disableFilter(filterName) {
  document.querySelectorAll('.origin-info .tag-square').forEach((tag) => {
    if(tag.dataset.tagName === filterName) {
      tag.classList.add('unselected');
    }
  });
}
