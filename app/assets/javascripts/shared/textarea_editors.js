import Rails from '@rails/ujs';
import 'easymde';

const editors = [];

document.addEventListener('DOMContentLoaded', () => {
  initEditorEditIcons();
  initEditors();
}, {once: true});

function initEditorEditIcons() {
  const editIcons = document.querySelectorAll('.editor-edit-icon');

  for(let i=0; i<editIcons.length; i++) {
    editIcons[i].addEventListener('click', () => {
      editMode(editors[i]);
    });
  }
}

export function initEditors() {
  const textareas = document.querySelectorAll('textarea[data-editor="true"]');

  for(let i=0; i<textareas.length; i++) {
    const editor = initEditor(textareas[i]);
    editors[i] = editor;
  }
}

function initEditor(textarea) {
  const editor = new EasyMDE({ // eslint-disable-line no-undef
    autoDownloadFontAwesome: false,
    element: textarea,
    hideIcons: ['image'],
    minHeight: (textarea.dataset.height || undefined),
    showIcons: ['code', 'table', 'horizontal-rule'],
    spellChecker: false,
    status: false,
  });

  const container = editorContainer(editor);
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
}

function isEditing(editor) {
  return !editor.isPreviewActive();
}

function editMode(editor) {
  // Don't enter edit mode if the editor is marked as read only
  if(editor.element.dataset.readOnly === 'true') return;

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
  // Update the hidden form field with the current editor value to be submitted with the form
  const editorValueFormField = editorContainer(editor).parentNode.querySelector('input[data-column-field="true"]');
  editorValueFormField.value = editor.codemirror.getValue();

  // Show a saved indicator after the form is submitted
  editorValueFormField.parentNode.addEventListener('ajax:success', (response) => {
    showEditorStatus(editor, 'Saved!', true);

    // Reset the rendered at timestamp so subsequent updates to this field are not rejected as being a conflicting modification
    editorContainer(editor).parentNode.querySelector('input[data-rendered-at="true"]').value = response.detail[0].timestamp;
  });

  editorValueFormField.parentNode.addEventListener('ajax:error', (response) => {
    if(response.detail[1] !== 'Conflict') return;

    showEditorStatus(editor, 'This content was edited by another user. Copy your changes and refresh the page.', false, 10000);
  });

  Rails.fire(editorValueFormField.parentNode, 'submit');
}

function editorContainer(editor) {
  return editor.codemirror.getWrapperElement().parentNode;
}

function editorCardHeader(editor) {
  return editor.element.parentNode.parentNode.querySelector('.card-header');
}

function showEditorStatus(editor, message, isSuccess, timeout) {
  const status = editorContainer(editor).parentNode.parentNode.querySelector('.status-indicator');
  status.innerText = message;

  status.classList.remove('text-success', 'text-danger');
  status.classList.add(isSuccess ? 'text-success' : 'text-danger');
  status.classList.replace('hide', 'show');

  setTimeout(() => {
    status.classList.replace('show', 'hide');
  }, timeout || 3000);
}
