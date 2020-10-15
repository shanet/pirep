const mapboxgl = require('mapbox-gl/dist/mapbox-gl.js');

let map = null;
let allAirports = [];

const displayedAirports = {
  type: 'FeatureCollection',
  features: [],
};
const enabledTagFilters = new Set();

const SECTIONAL_LAYERS = {
  seattle: [-124.094901, 44.634929, -116.327513, 48.995149],
  falls: [-124.079738, 40.016959, -116.727446, 44.494397],
};

document.addEventListener('DOMContentLoaded', () => {
  document.querySelector('#airport-drawer .handle button').addEventListener('click', () => {
    closeDrawer();
  });

  const tagFilters = document.getElementsByClassName('tag-filter');
  for(let i = 0; i < tagFilters.length; i++) {
    const tagFilter = tagFilters[i];
    const { tag } = tagFilter.dataset;
    const icon = tagFilter.querySelector('.icon');

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

      updateMapWithAirports();
    });
  }

  mapboxgl.accessToken = 'pk.eyJ1Ijoic2hhbmV0IiwiYSI6ImNpbXZnbnBhMjAydDl3a2x1ejNoNWoydHMifQ.WIi_Jv4TO3hOzj-E120rYg';

  map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/satellite-streets-v11',
    center: [-122.06, 48.11],
    zoom: 8,
  });

  map.on('load', () => {
    fetchAirports();

    Object.keys(SECTIONAL_LAYERS).forEach((id) => {
      map.addLayer({
        id,
        type: 'raster',
        source: {
          type: 'raster',
          tiles: [`http://localhost:3000/assets/tiles/${id}/{z}/{x}/{y}.png`],
          tileSize: 256,
          scheme: 'tms',
          minzoom: 5,
          maxzoom: 11,
          bounds: SECTIONAL_LAYERS[id],
        },
      });
    });
  });
});

function fetchAirports() {
  const request = new XMLHttpRequest();

  request.onload = () => {
    if(request.status === 200) {
      allAirports = JSON.parse(request.response);
      populateMap();
    } else {
      alert('fetching airports failed');
    }
  };

  const { airportsPath } = document.getElementById('map').dataset;
  request.open('GET', airportsPath);
  request.send();
}

function updateMapWithAirports() {
  displayedAirports.features.length = 0;

  allAirports.forEach((airport) => {
    airport.properties.tags.forEach((tag) => {
      if(enabledTagFilters.has(tag)) {
        displayedAirports.features.push(airport);
      }
    });
  });

  map.getSource('airports').setData(displayedAirports);
}

function populateMap() {
  map.loadImage(document.getElementById('map').dataset.markerImagePath, (error, image) => {
    if(error) throw error;

    map.addImage('marker', image);

    map.addSource('airports', {
      type: 'geojson',
      data: displayedAirports,
    });

    map.addLayer({
      id: 'airports',
      type: 'symbol',
      source: 'airports',
      layout: {
        'icon-image': 'marker',
        // 'icon-size': 0.8,
        // 'icon-padding': 5,
        // 'icon-anchor': 'bottom-left',
        'icon-allow-overlap': true,
      },
    });

    updateMapWithAirports();
  });

  map.on('click', 'airports', (event) => {
    loadDrawer(event.features[0].properties.code);
    openDrawer();
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', 'airports', () => {
    map.getCanvas().style.cursor = 'pointer';
  });

  map.on('mouseleave', 'airports', () => {
    map.getCanvas().style.cursor = '';
  });
}

function loadDrawer(airportCode) {
  document.getElementById('drawer-loading').style.display = 'block';
  document.getElementById('airport-info').style.display = 'none';

  const request = new XMLHttpRequest();

  request.onload = () => {
    if(request.status === 200) {
      populateDrawer(request.response);
    } else {
      alert('fetching airport failed');
    }
  };

  const { airportPath } = document.getElementById('map').dataset;
  const { placeholder } = document.getElementById('map').dataset;

  request.open('GET', airportPath.replace(placeholder, airportCode));
  request.send();
}

function populateDrawer(html) {
  document.getElementById('drawer-loading').style.display = 'none';
  document.getElementById('airport-info').innerHTML = html;
  document.getElementById('airport-info').style.display = 'block';
}

function openDrawer() {
  document.getElementById('airport-drawer').classList.remove('slide-out');
  document.getElementById('airport-drawer').classList.add('slide-in');
}

function closeDrawer() {
  document.getElementById('airport-drawer').classList.remove('slide-in');
  document.getElementById('airport-drawer').classList.add('slide-out');
}
