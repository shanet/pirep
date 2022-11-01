document.addEventListener('DOMContentLoaded', () => {
  initEditingTags();
  initTagDeleteIcons();
  initExtraRemarks();
}, {once: true});

function initEditingTags() {
  const tags = document.querySelectorAll('.tag-square.editing');

  for(let i=0; i<tags.length; i++) {
    const tag = tags[i];

    tag.addEventListener('click', () => {
      tag.classList.toggle('unselected');

      // When a tag is selected set its associated form field as selected too
      const selectedFormField = document.getElementById(`airport_tags_attributes_${i}_selected`);
      selectedFormField.value = (selectedFormField.value === 'true' ? 'false' : 'true');
    });
  }
}

function initTagDeleteIcons() {
  const addTags = document.querySelector('.tag-square.add');
  const deleteIcons = document.querySelectorAll('.tag-square .delete');

  if(!addTags) return;

  addTags.addEventListener('click', () => {
    // Show/hide the tag delete icons
    for(let i=0; i<deleteIcons.length; i++) {
      deleteIcons[i].style.display = (['none', ''].indexOf(deleteIcons[i].style.display) !== -1 ? 'block' : 'none');
    }
  });
}

function initExtraRemarks() {
  const showExtraRemarks = document.getElementById('show-extra-remarks');
  const extraRemarks = document.querySelectorAll('.extra-remark');

  if(!showExtraRemarks) return;

  showExtraRemarks.addEventListener('click', () => {
    // Update the button text accordingly
    showExtraRemarks.innerText = (extraRemarks[0].classList.contains('hidden') ? 'Show Less' : 'Show More');

    // Show/hide the extra remarks
    for(let i=0; i<extraRemarks.length; i++) {
      extraRemarks[i].classList.toggle('hidden');
    }
  });
}
