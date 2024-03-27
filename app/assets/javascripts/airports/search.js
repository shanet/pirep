const BADGE_INCREMENT = 1;
const BADGE_DECREMENT = 2;

const activeFilters = {};

document.addEventListener('DOMContentLoaded', () => {
  if(!getSearchForm()) return;

  initFilterGroupHeaders();
  initFilterGroupBadges();
  initRangeFields();
  initLocationFilterToggle();
  initTagFields();

  // This should be called last so the event listeners set above are called when the form inputs are set
  initSearchFieldsFromUrl();
}, {once: true});

function initFilterGroupHeaders() {
  // Flip the header arrow when opened/closed
  getSearchForm().querySelectorAll('.filter-header').forEach((header) => {
    header.addEventListener('collapsible', () => {
      const arrow = header.querySelector('.arrow');
      arrow.classList.toggle('fa-chevron-down');
      arrow.classList.toggle('fa-chevron-up');
    });
  });
}

function initFilterGroupBadges() {
  getSearchForm().querySelectorAll('.filter-group').forEach((filterGroup) => {
    filterGroup.querySelectorAll('input, select').forEach((field) => {
      field.addEventListener('change', onSearchInputChanged(filterGroup, field));
    });
  });
}

function onSearchInputChanged(filterGroup, input) {
  return () => {
    updateUrlParams();

    // Don't update the badges for any inputs that opt-out of this behavior
    if(input.dataset.noBadge) return;

    const operation = isInputEmpty(input) ? BADGE_DECREMENT : BADGE_INCREMENT;
    const listenerElement = (input.parentNode.classList.contains('input-group') ? input.parentNode : input);

    activeFilters[filterGroup.id] ||= new Set();

    if(operation === BADGE_INCREMENT) {
      activeFilters[filterGroup.id].add(listenerElement.id);
    } else {
      // If an input group, Only decrement if all of the inputs in the group are now empty
      if(listenerElement.classList.contains('input-group') && !isInputEmpty(listenerElement)) return;

      activeFilters[filterGroup.id].delete(listenerElement.id);
    }

    updateFilterGroupHeaderBadge(filterGroup);
  };
}

function isInputEmpty(element) {
  if(element.classList.contains('input-group')) {
    const inputs = element.querySelectorAll('input');

    for(let i=0; i<inputs.length; i++) {
      if(!isInputEmpty(inputs[i])) return false;
    }

    return true;
  }

  switch(element.type) {
    case 'checkbox':
      return !element.checked;
    case 'range':
      return element.value === element.getAttribute('value');
    default:
      return element.value === '';
  }
}

function updateFilterGroupHeaderBadge(filterGroup) {
  const header = getSearchForm().querySelector(`.filter-header[data-bs-target="${filterGroup.id}"]`);
  const badge = header.querySelector('.badge');

  const count = activeFilters[filterGroup.id].size;
  badge.innerText = count;

  if(count === 0) {
    badge.classList.remove('bg-success');
    badge.classList.add('bg-secondary');
  } else {
    badge.classList.remove('bg-secondary');
    badge.classList.add('bg-success');
  }
}

function updateUrlParams() {
  const formData = new FormData(getSearchForm());

  // Remove every key with an empty value to avoid polluting the query string with a bunch of empty values
  const emptyKeys = new Set();
  formData.forEach((value, key) => {if(!value || value === '0') emptyKeys.add(key);});
  emptyKeys.forEach((key) => formData.delete(key));

  // If the page parameter is present make sure to preserve it
  const pageParam = new URLSearchParams(window.location.search).get('page');
  if(pageParam) formData.set('page', pageParam);

  const formParams = new URLSearchParams(formData);
  window.history.replaceState({}, '', `${window.location.pathname}?${formParams.toString()}${window.location.hash}`);

  updatePagerLinks(formParams);
}

function updatePagerLinks(formParams) {
  // Write the form parameters to each of the pager links so the page has the right filters when getting it
  document.querySelectorAll('.pagination .page-item > a').forEach((pageLink) => {
    formParams.set('page', pageLink.dataset.page);
    const path = `${window.location.pathname}?${formParams.toString()}${window.location.hash}`;
    pageLink.href = path;
  });
}

function initRangeFields() {
  const rangeFields = getSearchForm().querySelectorAll('input[type="range"]');

  rangeFields.forEach((rangeField) => {
    const label = document.getElementById(rangeField.dataset.target);

    // Update the corresponding label for the range input
    const updateFunction = () => {
      if(rangeField.value === rangeField.min) {
        label.innerText = rangeField.dataset.minValueLabel;
      } else {
        label.innerText = `${parseInt(rangeField.value, 10).toLocaleString()}ft`;
      }
    };

    rangeField.addEventListener('input', updateFunction);
    rangeField.addEventListener('change', updateFunction);
  });
}

function initTagFields() {
  getSearchForm().querySelectorAll('.tag-square').forEach((tag) => {
    const input = document.getElementById(`tag_${tag.dataset.tagName}`);
    if(input.value === '1') tag.classList.remove('unselected');

    tag.addEventListener('click', () => {
      tag.classList.toggle('unselected');

      input.value = (input.value === '1' ? '' : '1');
      input.dispatchEvent(new Event('change'));
    });
  });
}

function initSearchFieldsFromUrl() {
  new URL(window.location).searchParams.forEach((value, key) => {
    let input = getSearchForm().querySelector(`input[name="${key}"]`) || getSearchForm().querySelector(`#${key}`);
    if(!input) return;

    switch(input.type) {
      case 'radio':
        // If a radio button we need to iterate all buttons in the group to find the one with the given value
        getSearchForm().querySelectorAll(`input[name="${input.name}"]`).forEach((radioButton) => {
          if(radioButton.value === value) {
            radioButton.checked = true;

            // Reassign the input so when the event is dispatched below it goes to the changed radio button
            input = radioButton;
          }
        });
        break;
      case 'checkbox':
        input.checked = (value === '1');
        break;
      default:
        input.value = value;
    }

    // Let the input know its value has changed to the listeners to set the search parameters are called
    input.dispatchEvent(new Event('change'));
  });

  openActiveFilterGroups();
}

function initLocationFilterToggle() {
  const form = getSearchForm();

  form.querySelector('#location_type_miles').addEventListener('change', () => {
    form.querySelector('#distance_miles').classList.remove('d-none');
    form.querySelector('#distance_hours').classList.add('d-none');
    form.querySelector('#cruise_speed').classList.add('d-none');
    form.querySelector('#distance_units').innerText = 'miles of';
  });

  form.querySelector('#location_type_hours').addEventListener('change', () => {
    form.querySelector('#distance_miles').classList.add('d-none');
    form.querySelector('#distance_hours').classList.remove('d-none');
    form.querySelector('#cruise_speed').classList.remove('d-none');
    form.querySelector('#distance_units').innerText = 'hours from';
  });
}

function openActiveFilterGroups() {
  getSearchForm().querySelectorAll('.filter-group').forEach((filterGroup) => {
    if(activeFilters[filterGroup.id]?.size > 0) {
      filterGroup.classList.toggle('show-instant');

      // Let the header know that it was opened so the arrow can be updated
      const header = getSearchForm().querySelector(`.filter-header[data-bs-target="${filterGroup.id}"]`);
      header.dispatchEvent(new Event('collapsible'));
    }
  });
}

function getSearchForm() {
  return document.querySelector('.advanced-search form');
}
