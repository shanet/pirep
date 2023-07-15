import * as actionButtons from 'map/action_buttons';
import * as flashes from 'map/flashes';
import * as map from 'map/map';
import * as urlSearchParams from 'map/url_search_params';
import * as utils from 'shared/utils';

let selectedSearchResultIndex = -1;

document.addEventListener('DOMContentLoaded', () => {
  const search = document.getElementById('search');
  if(!search) return;

  const {searchEndpoint} = search.dataset;

  const inputEventHandler = utils.debounce(async () => {
    const query = search.value;

    // Only start searching if three or more characters have been entered
    if(query.length < 3) return;

    // If coordinates were entered go directly to those instead of performing a search
    const coordinates = isCoordinates(query);
    if(coordinates) return flyToCoordinates(coordinates);

    const mapCenter = map.getCenter();
    const response = await fetch(`${searchEndpoint}?query=${query}&latitude=${mapCenter[0]}&longitude=${mapCenter[1]}`);

    if(!response.ok) {
      return flashes.show(flashes.FLASH_ERROR, 'An error occurred while retrieving search results.');
    }

    const results = await response.json();

    if(results.length === 0) {
      return showNoSearchResults();
    }

    showSearchResults(results);
  }, 350);

  search.addEventListener('input', inputEventHandler);

  search.addEventListener('keydown', (event) => {
    const UP_ARROW = 38;
    const DOWN_ARROW = 40;
    const resultsList = document.getElementById('search-results');

    // Ignore everything if the results list is not displayed
    if(resultsList.style.display === 'none') return;

    switch(event.keyCode) {
      case UP_ARROW:
      case DOWN_ARROW:
        // If at the ends of the list wrap around to the top/bottom
        if(event.keyCode === DOWN_ARROW && selectedSearchResultIndex === resultsList.childNodes.length - 1) {
          selectedSearchResultIndex = 0;
        } else if(event.keyCode === UP_ARROW && selectedSearchResultIndex === 0) {
          selectedSearchResultIndex = resultsList.childNodes.length - 1;
        } else {
          selectedSearchResultIndex += (event.keyCode === UP_ARROW ? -1 : 1);
        }

        selectSearchResult(selectedSearchResultIndex);
        break;
      case 13: { // Enter
        // Open the airport when a result is entered (ignore anything out of range or without an airport code like the "no results" element)
        if(selectedSearchResultIndex >= 0 && selectedSearchResultIndex < resultsList.childNodes.length && resultsList.childNodes[selectedSearchResultIndex].dataset.airportCode) {
          openAirport(resultsList.childNodes[selectedSearchResultIndex].dataset);
        }

        hideSearchResults();
        break;
      }
      default:
        // Hide the results list when any other key is hit
        hideSearchResults();
        break;
    }
  });

  search.addEventListener('blur', () => {
    hideSearchResults();
  });
}, {once: true});

function showSearchResults(results) {
  const resultsList = document.getElementById('search-results');
  selectedSearchResultIndex = -1;

  clearSearchResultsList();

  // Add new search results to the result list
  for(let i = 0; i < results.length; i++) {
    const result = results[i];

    const node = document.createElement('li');
    node.classList.add('list-group-item');
    node.innerText = `${result.code} - ${result.label}`;
    node.dataset.airportCode = result.code;
    node.dataset.boundingBox = JSON.stringify(result.bounding_box);
    node.dataset.zoomLevel = JSON.stringify(result.zoom_level);
    resultsList.appendChild(node);

    // Show airport when result is clicked (use mousedown since blur will take precedence over click)
    node.addEventListener('mousedown', () => {
      openAirport(node.dataset);
      hideSearchResults();
    });

    /* eslint-disable no-loop-func */
    node.addEventListener('mouseenter', () => {
      selectedSearchResultIndex = i;
      selectSearchResult(selectedSearchResultIndex);
    });
    /* eslint-enable no-loop-func */
  }

  resultsList.style.display = 'block';
}

function openAirport(result) {
  // Don't open the drawer if on a small screen, just fly to the airport
  map.openAirport(result.airportCode, JSON.parse(result.boundingBox), result.zoomLevel, !utils.isBreakpointDown('sm'));

  map.toggleSectionalLayers(false);
  actionButtons.updateLayerSwitcherIcon(actionButtons.LAYER_MAP);
  urlSearchParams.setLayer(actionButtons.LAYER_SATELLITE);
}

function hideSearchResults() {
  document.getElementById('search-results').style.display = 'none';
}

function selectSearchResult(selectedSearchResultIndex) {
  const resultsList = document.getElementById('search-results');

  for(let i = 0; i < resultsList.childNodes.length; i++) {
    if(i === selectedSearchResultIndex) {
      resultsList.childNodes[i].classList.add('active');
    } else {
      resultsList.childNodes[i].classList.remove('active');
    }
  }
}

function showNoSearchResults() {
  clearSearchResultsList();
  const resultsList = document.getElementById('search-results');

  const node = document.createElement('li');
  node.classList.add('list-group-item');
  node.innerText = 'No airports found';
  resultsList.appendChild(node);

  resultsList.style.display = 'block';
}

function clearSearchResultsList() {
  const resultsList = document.getElementById('search-results');

  // Remove old search results from the result list
  while(resultsList.firstChild) {
    resultsList.removeChild(resultsList.firstChild);
  }
}

export function enable() {
  // By default the search is disabled until the map is fully loaded since we can't show search results until that's done anyway
  const search = document.getElementById('search');
  search.disabled = false;
  search.placeholder = 'Search airports';
}

function isCoordinates(query) {
  const matches = query.match(/(-?\d+\.\d+)[,/ ]+(-?\d+\.\d+)/);
  if(matches?.length !== 3) return null;

  return {
    latitude: matches[1].trim(),
    longitude: matches[2].trim(),
  };
}

function flyToCoordinates(coordinates) {
  map.toggleSectionalLayers(false);
  map.flyTo(coordinates.latitude, coordinates.longitude, map.ZOOM_IN_ZOOM_LEVEL);
  actionButtons.updateLayerSwitcherIcon(actionButtons.LAYER_MAP);
  urlSearchParams.setLayer(actionButtons.LAYER_SATELLITE);
}
