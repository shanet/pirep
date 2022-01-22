import Rails from '@rails/ujs';
import 'easymde';

let editors = [];
let initialized = false;

document.addEventListener('DOMContentLoaded', () => {
  if(initialized) return;
  initialized = true;

  initEditorEditIcons();
  initEditors();
});

function initEditorEditIcons() {
  let editIcons = document.querySelectorAll('.editor-edit-icon');

  for(let i=0; i<editIcons.length; i++) {
    editIcons[i].addEventListener('click', () => {
      editMode(editors[i]);
    });
  }
}

export function initEditors() {
  let textareas = document.querySelectorAll('textarea[data-editor="true"]');

  for(let i=0; i<textareas.length; i++) {
    let editor = initEditor(textareas[i]);
    editors[i] = editor;
  }
}

function initEditor(textarea) {
  let editor = new EasyMDE({
    autoDownloadFontAwesome: false,
    element: textarea,
    status: false,
    minHeight: (textarea.dataset.height || undefined),
    hideIcons: ['image'],
    showIcons: ['code', 'table', 'horizontal-rule'],
  });

  let container = editorContainer(editor);
  let dirty = false;

  // Set read mode by default
  readMode(editor);

  // Enter edit mode when the preview is clicked
  container.querySelector('.editor-preview').addEventListener('click', (event) => {
    // Ignore clicks on links within the preview
    if(event.target.nodeName === 'A') return;

    editMode(editor);
  });

  // Exit editing mode when clicking off of the editor
  document.addEventListener('click', (event) => {
    // Ignore clicks that happen within the editor / the edit icon or while the editor is not editing
    // Also ignore elements without parent nodes as there is a race condition when switching from
    // reading to editing mode where the preview elements will be detacted from the DOM causing the
    // `contains` call to return false and then re-enter read mode.
    if(container.contains(event.target) || !isEditing(editor) || event.target.classList.contains('editor-edit-icon') || !event.target.parentNode) return;

    readMode(editor);

    // Write changes if a change was made
    if(dirty) {
      writeEditorChanges(editor);
      dirty = false;
    }
  });

  // Mark the editor as dirty when a change is made
  editor.codemirror.on('change', () => {
    dirty = true;
  });

  return editor;
};

function isEditing(editor) {
  return !editor.isPreviewActive();
}

function editMode(editor) {
  // Don't enter edit mode if the editor is marked as read only
  if(editor.element.dataset.readOnly === "true") return;

  editorCardHeader(editor).style.display = 'none';
  editor.togglePreview();
  editorContainer(editor).classList.add('editing');
  editor.codemirror.focus();
}

function readMode(editor) {
  editorCardHeader(editor).style.display = 'block';
  editor.togglePreview();
  editorContainer(editor).classList.remove('editing');
}

function writeEditorChanges(editor) {
  // Get the hidden form field, update its value with the current editor value, and submit the form
  let formField = editorContainer(editor).parentNode.querySelector('input[data-column-field="true"]');
  formField.value = editor.codemirror.getValue();
  Rails.fire(formField.parentNode, 'submit');
}

function editorContainer(editor) {
  return editor.codemirror.getWrapperElement().parentNode;
}

function editorCardHeader(editor) {
  return editor.element.parentNode.parentNode.querySelector('.card-header');
}
