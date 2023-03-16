import 'mapbox-gl';
import Rails from '@rails/ujs';

import * as annotationFactory from 'shared/annotation_factory';
import * as utils from 'shared/utils';

let mapElement = null;
let map = null;

document.addEventListener('DOMContentLoaded', () => {
  mapElement = document.getElementById('airport-map');
  if(!mapElement || !utils.isWebGlAvailable()) return;

  initMap();
  initEditingSwitch();
}, {once: true});

function initMap() {
  mapboxgl.accessToken = mapElement.dataset.mapboxApiKey; // eslint-disable-line no-undef

  const mapOptions = {
    container: 'airport-map',
    minZoom: 12,
    style: 'mapbox://styles/mapbox/satellite-streets-v11',
  };

  const boundingBox = JSON.parse(mapElement.dataset.boundingBox);
  if(boundingBox) {
    mapOptions.bounds = boundingBox.flat();
    mapOptions.fitBoundsOptions = {padding: 75};
  } else {
    mapOptions.center = [mapElement.dataset.centerLongitude, mapElement.dataset.centerLatitude];
    mapOptions.zoom = mapElement.dataset.zoomLevel;
  }

  map = new mapboxgl.Map(mapOptions); // eslint-disable-line no-undef

  map.on('click', (event) => {
    if(!isEditing()) return;
    annotationFactory.addAnnotationToMap(map, event.lngLat.lat, event.lngLat.lng, null, {editing: true, saveCallback: saveAnnotations});
  });

  map.on('load', () => {
    restoreAnnotations();
  });
}

function initEditingSwitch() {
  const editingSwitch = document.getElementById('annotations-editing');
  const annotationsHelp = document.getElementById('annotations-help');

  // When editing mode is enabled, show the help text, put all annotations into edit mode
  // When editing mode is disabled, do the reverse but also do a save of the annotations
  editingSwitch.addEventListener('change', () => {
    if(editingSwitch.checked) {
      mapElement.classList.add('editing');
      annotationsHelp.classList.remove('d-none');
      toggleAnnotationsEditingMode(true);
    } else {
      mapElement.classList.remove('editing');
      annotationsHelp.classList.add('d-none');
      toggleAnnotationsEditingMode(false);
      saveAnnotations();
    }
  });
}

function toggleAnnotationsEditingMode(enable) {
  Object.keys(annotationFactory.allAnnotations()).forEach((id) => {
    annotationFactory.toggleAnnotationEditingMode(id, enable);
  });
}

function isEditing() {
  return mapElement.classList.contains('editing');
}

function restoreAnnotations() {
  const annotationsJson = JSON.parse(mapElement.dataset.annotations);

  for(let i=0; i<(annotationsJson?.length || 0); i++) {
    // Ignore invalid markers
    if(annotationsJson[i].latitude < -90 || annotationsJson[i].latitude > 90) continue;
    if(annotationsJson[i].longitude < -180 || annotationsJson[i].longitude > 180) continue;

    annotationFactory.addAnnotationToMap(map, annotationsJson[i].latitude, annotationsJson[i].longitude, annotationsJson[i].label, {editing: false, saveCallback: saveAnnotations});
  }

  exposeObjectsForTesting();
}

function saveAnnotations() {
  const seralizedAnnotations = [];

  Object.values(annotationFactory.allAnnotations()).forEach((annotation) => {
    // Skip annotations with empty labels
    const label = annotation.getPopup().getElement().querySelector('.label').textContent.trim();
    if(label === '' || label === annotationFactory.EMPTY_LABEL) return;

    seralizedAnnotations.push({
      latitude: annotation.getLngLat().lat,
      longitude: annotation.getLngLat().lng,
      label,
    });
  });

  // Send the serialized annotations to Rails
  const formField = document.querySelector('form #airport_annotations');
  formField.value = JSON.stringify(seralizedAnnotations);

  formField.parentNode.addEventListener('ajax:success', () => {
    showAnnotationsStatus('Saved!', true);
  });

  formField.parentNode.addEventListener('ajax:error', () => {
    showAnnotationsStatus('Failed to save annotations', false, 10000);
  });

  Rails.fire(formField.parentNode, 'submit');
}

function showAnnotationsStatus(message, isSuccess, timeout) {
  const status = document.querySelector('.airport-annotations-saved');
  status.innerText = message;

  status.classList.remove('text-success', 'text-danger');
  status.classList.add(isSuccess ? 'text-success' : 'text-danger');
  status.classList.replace('hide', 'show');

  setTimeout(() => {
    status.classList.replace('show', 'hide');
  }, timeout || 3000);
}

function exposeObjectsForTesting() {
  // Don't expose anything if not running tests
  if(!mapElement.dataset.isTest) return;

  // Let the tests know that the map is fully ready to use (once we have the airports layer shown)
  mapElement.dataset.ready = true;
}
