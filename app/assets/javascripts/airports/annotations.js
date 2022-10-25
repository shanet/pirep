import Rails from '@rails/ujs';

const EMPTY_LABEL = '[empty]';
const POSITION_ADJUSTMENT = 10; // px

let annotationsContainer = null;
let annotationsHelp = null;
let movingAnnotation = null;

document.addEventListener('DOMContentLoaded', () => {
  // The annotations container size is dependent on the image size which won't be known until it's fully loaded.
  // Only initialize everything here once that's completed.
  const image = document.querySelector('.airport-diagram img');
  if(!image) return;

  // If the image loaded before this the DOM loaded event fired go ahead and initialize everything now. Otherwise, add a listener for the image to finish.
  if(image.complete) {
    initAnnotations();
    initEditingSwitch();
  } else {
    image.addEventListener('load', () => {
      initAnnotations();
      initEditingSwitch();
    });
  }
}, {once: true});

function initAnnotations() {
  annotationsContainer = document.querySelector('.airport-diagram .annotations');
  annotationsHelp = annotationsContainer.querySelector('.help');
  if(!annotationsContainer) return;

  // Deserialize the annotations and add them to the image
  restoreAnnotations();

  annotationsContainer.addEventListener('click', (event) => {
    // Only create new annotations in editing mode
    if(!isEditing()) return;

    createAnnotation(event.clientX, event.clientY, 'px', null, true);
  });
}

function initEditingSwitch() {
  const editingSwitch = document.getElementById('annotations-editing');
  if(!editingSwitch) return;

  // When editing mode is enabled, show the help text, put all annotations into edit mode
  // When editing mode is disabled, do the reverse but also do a save of the annotations
  editingSwitch.addEventListener('change', () => {
    if(editingSwitch.checked) {
      annotationsContainer.classList.add('editing');
      annotationsHelp.classList.remove('d-none');
      toggleAnnotationsEditingMode(true);
    } else {
      annotationsContainer.classList.remove('editing');
      annotationsHelp.classList.add('d-none');
      toggleAnnotationsEditingMode(false);
      saveAnnotations();
    }
  });
}

function toggleAnnotationsEditingMode(enable) {
  const annotations = annotationsContainer.querySelectorAll('.annotation');

  for(let i=0; i<annotations.length; i++) {
    if(enable) {
      annotations[i].classList.add('editing');
    } else {
      annotations[i].classList.remove('editing');
    }
  }
}

function createAnnotation(centerX, centerY, units, label, editing) {
  const annotation = createAnnotationElement(label, editing);
  annotationsContainer.appendChild(annotation);

  // Remove the annotation if it was outside of the annotations container (must be done after added to the DOM so we know the size of the annotation)
  if(!moveAnnotationTo(annotation, centerX, centerY, (units === '%'))) {
    annotation.remove();
    return;
  }

  // Give the new annotation focus (must be done after it's added to the DOM)
  annotation.querySelector('input').focus();

  function annotationMoveStart() {
    // Don't move when not in editing mode
    if(!isEditing()) return;

    movingAnnotation = annotation;

    document.addEventListener('mousemove', annotationMove);
    document.addEventListener('touchmove', annotationMove);
    document.addEventListener('mouseup', annotationMoveStop);
    document.addEventListener('touchend', annotationMoveStop);
  }

  annotation.addEventListener('mousedown', annotationMoveStart);
  annotation.addEventListener('touchstart', annotationMoveStart);
}

function createAnnotationElement(labelValue, editing) {
  const annotation = document.createElement('div');

  annotation.innerHTML = `
    <div class="annotation-header d-flex flex-column justify-content-end mb-2">
      <div class="input-group">
        <button type="button" class="btn btn-success px-2 py-1 save">
          <i class="fa-solid fa-check"></i>
        </button>

        <input type="text" class="form-control py-1" placeholder="What's here?"></input>

        <button type="button" class="btn btn-danger px-2 py-1 delete">
          <i class="fa-solid fa-trash"></i>
        </button>
      </div>

      <div>
        <span class="label px-2 border border-white border-2 rounded-2 text-white text-nowrap overflow-hidden">${EMPTY_LABEL}</span>
      </div>
    </div>

    <div>
      <i class="icon fa-solid fa-location-dot"></i>
    </div>
  `;

  annotation.classList.add('annotation', 'text-center');
  if(editing) annotation.classList.add('editing');

  const header = annotation.querySelector('.annotation-header');
  const labelInput = annotation.querySelector('input');
  const saveButton = annotation.querySelector('button.save');
  const deleteButton = annotation.querySelector('button.delete');
  const label = annotation.querySelector('.label');

  // Set the label value when it's input field is changed
  labelInput.addEventListener('change', () => {
    annotation.querySelector('.label').textContent = (labelInput.value === '' ? EMPTY_LABEL : labelInput.value);
  });

  // If enter is pressed on the input field, disable editing mode, and save the annotations
  labelInput.addEventListener('keydown', (event) => {
    if(event.key !== 'Enter') return;
    annotation.classList.remove('editing');
    saveAnnotations();
  });

  // Don't propagate any clicks/mouse/touch events beyond the header as they would be treated as move events and start moving the annotation
  ['click', 'mousedown', 'touchstart'].forEach((event) => {
    header.addEventListener(event, (event) => {event.stopPropagation();});
  });

  saveButton.addEventListener('click', () => {
    annotation.classList.remove('editing');
    saveAnnotations();
  });

  deleteButton.addEventListener('click', () => {
    annotation.remove();
    saveAnnotations();
  });

  // Clicking the label in global editing mode should put the annotation into editing mode if not already
  label.addEventListener('click', () => {
    if(!isEditing()) return;
    annotation.classList.add('editing');
    labelInput.focus();
  });

  // Set an initial label if one was given (restored annotations will have one)
  if(labelValue) {
    label.textContent = labelValue;
    labelInput.value = labelValue;
  }

  return annotation;
}

function annotationMove(event) {
  // This method is called for both mouse and touch events; handle both here
  const newX = (event.type === 'touchmove' ? event.targetTouches[0].clientX : event.clientX);
  const newY = (event.type === 'touchmove' ? event.targetTouches[0].clientY : event.clientY);

  moveAnnotationTo(movingAnnotation, newX, newY);
}

function moveAnnotationTo(annotation, x, y, isPercent) {
  /* eslint-disable no-param-reassign */
  // Don't move outside the bounds of the annotations container
  if(!isPositionInAnnotationsContainer(x, y, isPercent)) return false;

  const containerBoundingRect = annotationsContainer.getBoundingClientRect();
  const annotationBoundingRect = annotation.getBoundingClientRect();

  // Translate the absolute X & Y position to percentages relative to the container
  // This will keep the annotation in the same location as the page resizes
  // Skip this if the given numbers are already a percentage
  if(!isPercent) {
    x = (1 - (containerBoundingRect.right - x) / containerBoundingRect.width) * 100;
    y = (1 - (containerBoundingRect.bottom - y) / containerBoundingRect.height) * 100;
  }

  // Subtract the width and height from the percentage so it's centered around the middle bottom of the annotation
  // Subtract a position adjustment from the height so the annotation is draggable from the where it's added without needing to move the mouse up
  annotation.style.left = `calc(${x}% - ${annotationBoundingRect.width / 2}px)`;
  annotation.style.top = `calc(${y}% - ${annotationBoundingRect.height - POSITION_ADJUSTMENT}px)`;

  // Save the raw percentage for the serialization logic (the style values above will have the offsets added to them)
  annotation.dataset.xPercent = x;
  annotation.dataset.yPercent = y;

  return true;
  /* eslint-enable no-param-reassign */
}

function annotationMoveStop(event) {
  // We're done with these once the annotation is finished moving
  // If it moves again new event listeners will be set by the start move function
  document.removeEventListener('mousemove', annotationMove);
  document.removeEventListener('touchmove', annotationMove);
  document.removeEventListener('mouseup', annotationMoveStop);
  document.removeEventListener('touchstop', annotationMoveStop);

  if(event.type !== 'touchend') {
    // Set an capture event listener (top down, not bottom up) to stop any the click event
    // that will come after the mouseup event from triggering and creating a new annotation
    document.addEventListener('click', preventClick, true);
  }
}

function preventClick(event) {
  event.stopPropagation();
  document.removeEventListener('click', preventClick, true);
}

function isEditing() {
  return annotationsContainer.classList.contains('editing');
}

function isPositionInAnnotationsContainer(x, y, isPercent) {
  const containerBoundingRect = annotationsContainer.getBoundingClientRect();
  const icon = annotationsContainer.querySelector('.annotation .icon');

  // Convert to pixels if given a percent
  if(isPercent) {
    x = containerBoundingRect.left + ((x / 100) * containerBoundingRect.width); // eslint-disable-line no-param-reassign
    y = containerBoundingRect.top + ((y / 100) * containerBoundingRect.height); // eslint-disable-line no-param-reassign
  }

  return (x >= containerBoundingRect.left + icon.offsetWidth/2
       && y >= containerBoundingRect.top + icon.offsetHeight
       && x <= containerBoundingRect.right - icon.offsetWidth/2
       && y <= containerBoundingRect.bottom);
}

function restoreAnnotations() {
  const annotations = JSON.parse(annotationsContainer.dataset.annotations);
  if(!annotations) return;

  for(let i=0; i<annotations.length; i++) {
    createAnnotation(annotations[i].x, annotations[i].y, '%', annotations[i].label, false);
  }
}

function saveAnnotations() {
  const annotations = annotationsContainer.querySelectorAll('.annotation');
  const seralizedAnnotations = [];

  for(let i=0; i<annotations.length; i++) {
    // Skip annotations with empty labels
    const label = annotations[i].querySelector('.label').textContent;
    if(label === '' || label === EMPTY_LABEL) continue;

    seralizedAnnotations.push({
      x: annotations[i].dataset.xPercent,
      y: annotations[i].dataset.yPercent,
      label,
    });
  }

  // Send the serialized annotations to Rails
  const formField = annotationsContainer.querySelector('form #airport_annotations');
  formField.value = JSON.stringify(seralizedAnnotations);
  Rails.fire(formField.parentNode, 'submit');

  showSavedIndicator();
}

function showSavedIndicator() {
  const saved = document.querySelector('.airport-diagram-saved');
  saved.classList.replace('hide', 'show');

  setTimeout(() => {
    saved.classList.replace('show', 'hide');
  }, 3000);
}
