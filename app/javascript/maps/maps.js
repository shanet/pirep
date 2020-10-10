let mapboxgl = require('mapbox-gl/dist/mapbox-gl.js');
let map = null;

const SECTIONAL_LAYERS = {
  'seattle': [-124.094901, 44.634929, -116.327513, 48.995149],
  'falls': [-124.079738, 40.016959, -116.727446, 44.494397],
}

document.addEventListener('DOMContentLoaded', function() {
  mapboxgl.accessToken = 'pk.eyJ1Ijoic2hhbmV0IiwiYSI6ImNpbXZnbnBhMjAydDl3a2x1ejNoNWoydHMifQ.WIi_Jv4TO3hOzj-E120rYg';

  map = new mapboxgl.Map({
    'container': 'map',
    'style': 'mapbox://styles/mapbox/satellite-streets-v11',
    'center': [-122.06, 48.11],
    'zoom': 8,
  });

  map.on('load', function() {
    fetchAirports();

    for(let id in SECTIONAL_LAYERS) {
      map.addLayer({
        'id': id,
        'type': 'raster',
        'source': {
          'type': 'raster',
          'tiles': [`http://localhost:3000/assets/tiles/${id}/{z}/{x}/{y}.png`],
          'tileSize': 256,
          'scheme': 'tms',
          'minzoom': 5,
          'maxzoom': 11,
          'bounds': SECTIONAL_LAYERS[id],
        },
      });
    }
  });
});

function fetchAirports() {
  let request = new XMLHttpRequest();

  request.onload = function() {
    if(request.status == 200) {
      populateMap(JSON.parse(request.response));
    } else {
      alert('fetching airports failed');
    }
  };

  let airport_path = document.getElementById('map').dataset.airportsPath;
  request.open('GET', airport_path);
  request.send();
}

function populateMap(airports) {
  map.loadImage(document.getElementById('map').dataset.markerImagePath, function(error, image) {
    if (error) throw error;

    map.addImage('marker', image);

    map.addLayer({
      'id': 'airports',
      'type': 'symbol',
      'source': {
        'type': 'geojson',
        'data': {
          'type': 'FeatureCollection',
          'features': airports,
        },
      },
      'layout': {
        'icon-image': 'marker',
        // 'icon-size': 0.8,
        // 'icon-padding': 5,
        // 'icon-anchor': 'bottom-left',
        'icon-allow-overlap': true,
      },
    });
  });

  map.on('click', 'airports', function(event) {
    openDrawer(event.features[0].properties['code']);
  });

  // Show a pointer cursor when hovering over an airport on the map
  map.on('mouseenter', 'airports', () => {
    map.getCanvas().style.cursor = 'pointer'
  });

  map.on('mouseleave', 'airports', () => {
    map.getCanvas().style.cursor = ''
  });

  document.querySelector('#airport-drawer .close').addEventListener("click", function() {
    closeDrawer();
  });
}

function openDrawer(airportCode) {
  document.querySelector('#airport-drawer .airport-code').innerText = airportCode;
  document.getElementById('airport-drawer').classList.remove('slideOut');
  document.getElementById('airport-drawer').classList.add('slideIn');
}

function closeDrawer() {
  document.getElementById('airport-drawer').classList.remove('slideIn');
  document.getElementById('airport-drawer').classList.add('slideOut');
}
