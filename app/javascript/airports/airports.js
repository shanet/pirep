document.addEventListener('DOMContentLoaded', () => {
  initEditingTags();
  initTagDeleteIcons();
});

function initEditingTags() {
  let tags = document.querySelectorAll('.tag-square.editing');

  for(let i=0; i<tags.length; i++) {
    let tag = tags[i];

    tag.addEventListener('click', () => {
      tag.classList.toggle('unselected');

      let selectedFormField = document.getElementById(`airport_tags_attributes_${i}_selected`);
      selectedFormField.value = (selectedFormField.value === 'true' ? 'false' : 'true');
    });
  }
}

function initTagDeleteIcons() {
  let addTags = document.querySelector('.tag-square.add');
  let deleteIcons = document.querySelectorAll('.tag-square .delete');

  addTags.addEventListener('click', () => {
    for(let i=0; i<deleteIcons.length; i++) {
      deleteIcons[i].style.display = (['none', ''].indexOf(deleteIcons[i].style.display) !== -1 ? 'block' : 'none');
    }
  });
}
