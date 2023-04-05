export function add3dTerrain(map) {
  map.addSource('dem', {
    type: 'raster-dem',
    url: 'mapbox://mapbox.terrain-rgb',
  });

  map.setTerrain({source: 'dem'});

  map.setFog({
    range: [0.8, 8],
    color: '#dc9f9f',
    'horizon-blend': 0.5,
    'high-color': '#245bde',
    'space-color': '#000000',
  });
}
