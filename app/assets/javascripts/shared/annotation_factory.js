import 'mapbox-gl';

export const EMPTY_LABEL = '[empty]';

const annotations = {};

export function addAnnotationToMap(map, latitude, longitude, labelValue, options) {
  // This is kind of hacky, but since MapBox does not track markers internally we need to track them ourselves.
  // This means giving them a unique ID. There's not a good way in native JS to get a UUID or anything guaranteed to
  // be unique so instead we can simply use the array index that the marker is stored in as a unique ID.
  const annotationId = String(Object.keys(annotations).length);

  const annotation = createAnnotation(map, labelValue, annotationId, options);

  const popup = new mapboxgl.Popup({  
    closeButton: false,
    closeOnClick: false,
    closeOnMove: false,
    focusAfterOpen: false,
    offset: 45,
  }).setDOMContent(annotation);

  const marker = new mapboxgl.Marker({draggable: options.editing})  
    .setLngLat([longitude, latitude])
    .setPopup(popup)
    .addTo(map);

  marker.togglePopup();
  marker.getElement().dataset.annotationId = annotationId;
  annotations[annotationId] = marker;

  // If the popup is ever closed immediately reopen it as we don't want it to ever close
  popup.on('close', () => {
    marker.togglePopup();
  });

  if(options.editing) {
    toggleAnnotationEditingMode(annotationId, true);
    annotation.querySelector('input').focus();
  }

  return annotationId;
}

function createAnnotation(map, labelValue, id, options) {
  const annotation = document.createElement('div');
  annotation.classList.add('annotation');

  annotation.dataset.annotationId = id;

  annotation.innerHTML = `
    <div class="input-group">
      <button type="button" class="btn btn-success px-2 py-1 save">
        <i class="fa-solid fa-check"></i>
      </button>

      <input type="text" class="form-control py-1" placeholder="What's here?"></input>

      <button type="button" class="btn btn-danger px-2 py-1 delete">
        <i class="fa-solid fa-trash"></i>
      </button>
    </div>

    <div class="label px-2 border border-white border-2 rounded-2 text-white text-nowrap text-overflow-ellipsis overflow-hidden">
      ${EMPTY_LABEL}
    </div>
  `;

  const labelInput = annotation.querySelector('input');
  const saveButton = annotation.querySelector('button.save');
  const deleteButton = annotation.querySelector('button.delete');
  const label = annotation.querySelector('.label');

  const updateLabel = () => {
    annotation.querySelector('.label').textContent = (labelInput.value === '' ? EMPTY_LABEL : labelInput.value);
  };

  // Set the label value when its input field is changed
  labelInput.addEventListener('change', updateLabel);

  // If enter is pressed on the input field, disable editing mode, and save the annotations
  labelInput.addEventListener('keydown', (event) => {
    if(event.key !== 'Enter') return;
    updateLabel();
    toggleAnnotationEditingMode(id, false);
    options.saveCallback();
  });

  saveButton.addEventListener('click', () => {
    updateLabel();
    toggleAnnotationEditingMode(id, false);
    options.saveCallback();
  });

  deleteButton.addEventListener('click', () => {
    annotations[id].remove();
    delete annotations[id];
    options.saveCallback();
  });

  // Clicking the label in global editing mode should put the annotation into editing mode if not already
  if(!options.readOnly) {
    label.addEventListener('click', () => {
      if(!isEditing(map)) return;
      toggleAnnotationEditingMode(id, true);
      labelInput.focus();
    });
  }

  // Set an initial label if one was given (restored annotations will have one)
  if(labelValue) {
    label.textContent = labelValue;
    labelInput.value = labelValue;
  }

  return annotation;
}

export function toggleAnnotationEditingMode(id, enable) {
  const annotationElement = annotations[id].getPopup().getElement().querySelector('.annotation');
  const markerElement = annotations[id].getElement().querySelector('svg');

  if(enable) {
    annotationElement.classList.add('editing');
    markerElement.classList.add('editing');
    annotations[id].setDraggable(true);
  } else {
    annotationElement.classList.remove('editing');
    markerElement.classList.remove('editing');
    annotations[id].setDraggable(false);
  }
}

function isEditing(map) {
  return map.getContainer().classList.contains('editing');
}

export function removeAllAnnotations() {
  Object.keys(annotations).forEach((annotationId) => {
    annotations[annotationId].remove();
    delete annotations[annotationId];
  });
}

// These functions are here mostly to provide an abstraction layer between the backing data structure for annotations and anything using this module
export function getAnnotation(id) {
  return annotations[id];
}

export function allAnnotations() {
  return annotations;
}
