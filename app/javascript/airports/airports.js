document.addEventListener('DOMContentLoaded', () => {
  initEditingTags();
  initTagDeleteIcons();
  initExtraRemarks();
});

function initEditingTags() {
  let tags = document.querySelectorAll('.tag-square.editing');

  for(let i=0; i<tags.length; i++) {
    let tag = tags[i];

    tag.addEventListener('click', () => {
      tag.classList.toggle('unselected');

      // When a tag is selected set its associated form field as selected too
      let selectedFormField = document.getElementById(`airport_tags_attributes_${i}_selected`);
      selectedFormField.value = (selectedFormField.value === 'true' ? 'false' : 'true');
    });
  }
}

function initTagDeleteIcons() {
  let addTags = document.querySelector('.tag-square.add');
  let deleteIcons = document.querySelectorAll('.tag-square .delete');

  if(!addTags) return;

  addTags.addEventListener('click', () => {
    // Show/hide the tag delete icons
    for(let i=0; i<deleteIcons.length; i++) {
      deleteIcons[i].style.display = (['none', ''].indexOf(deleteIcons[i].style.display) !== -1 ? 'block' : 'none');
    }
  });
}

function initExtraRemarks() {
  let showExtraRemarks = document.getElementById('show-extra-remarks');
  let extraRemarks = document.querySelectorAll('.extra-remark');

  if(!showExtraRemarks) return;

  showExtraRemarks.addEventListener('click', () => {
    // Update the button text accordingly
    showExtraRemarks.innerText = (extraRemarks[0].classList.contains('hidden') ? 'Hide More' : 'Show More');

    // Show/hide the extra remarks
    for(let i=0; i<extraRemarks.length; i++) {
      extraRemarks[i].classList.toggle('hidden');
    }
  });
}
