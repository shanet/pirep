const maps = require('./maps');
const utils = require('../shared/utils');

let selectedSearchResultIndex = -1;

document.addEventListener('DOMContentLoaded', () => {
  const search = document.getElementById('search');
  if(!search) return;
  const {searchEndpoint} = search.dataset;

  const inputEventHandler = utils.debounce(async () => {
    const query = search.value;

    // Only start searching if three or more characters have been entered
    if(query.length < 3) return;

    const response = await fetch(`${searchEndpoint}/${query}`);

    if(!response.ok) {
      // TODO: make this better
      return alert('search request failed');
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
      case 13: // Enter
        // Open the airport when a result is entered
        maps.openAirport(resultsList.childNodes[selectedSearchResultIndex].dataset.airportCode);
        hideSearchResults();
        break;
      default:
        // Hide the results list when any other key is hit
        hideSearchResults();
        break;
    }
  });

  search.addEventListener('blur', () => {
    hideSearchResults();
  });

  // TODO: debounce input
});

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
    resultsList.appendChild(node);

    // Show airport when result is clicked (use mousedown to since blur will take precedence over click)
    node.addEventListener('mousedown', () => {
      maps.openAirport(result.code);
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

function hideSearchResults() {
  document.getElementById('search-results').style.display = 'none';
}

function selectSearchResult(selectedSearchResultIndex) {
  const resultsList = document.getElementById('search-results');

  for(let i = 0; i < resultsList.childNodes.length; i++) {
    if(i === selectedSearchResultIndex) {
      resultsList.childNodes[i].classList.add('selected');
    } else {
      resultsList.childNodes[i].classList.remove('selected');
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
