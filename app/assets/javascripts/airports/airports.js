let initialized = false;

document.addEventListener('DOMContentLoaded', () => {
  if(initialized) return;
  initialized = true;

  initEditingTags();
  initTagDeleteIcons();
  initLandingRightsForm();
  initExtraRemarks();
});

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

function initLandingRightsForm() {
  const landingRightsBoxes = document.querySelectorAll('.landing-rights-box');

  for(let i=0; i<landingRightsBoxes.length; i++) {
    const landingRightsBox = landingRightsBoxes[i];
    const {landingRightsType} = landingRightsBox.dataset;

    landingRightsBox.addEventListener('click', () => {
      // Deselect all landing rights boxes
      for(let j=0; j<landingRightsBoxes.length; j++) {
        landingRightsBoxes[j].classList.remove('btn-primary');
        landingRightsBoxes[j].classList.add('btn-outline-primary');
      }

      // Select the clicked landing rights box
      landingRightsBox.classList.add('btn-primary');
      landingRightsBox.classList.remove('btn-outline-primary');

      const landingRestrictionsLabels = document.querySelectorAll('label[data-landing-rights-type]');

      // Hide all landing restrictions labels for the textarea
      for(let j=0; j<landingRestrictionsLabels.length; j++) {
        landingRestrictionsLabels[j].classList.add('d-none');
      }

      const label = document.querySelector(`label[data-landing-rights-type="${landingRightsType}"]`);
      const textarea = document.getElementById('airport_landing_requirements');

      // If private selected don't show the textarea & label. Otherwise, show them.
      if(landingRightsType === 'private_') {
        label.classList.add('d-none');
        textarea.classList.add('d-none');
      } else {
        label.classList.remove('d-none');
        textarea.classList.remove('d-none');
      }

      // Set the selected landing rights type in the hidden field
      document.getElementById('airport_landing_rights').value = landingRightsType;
    });
  }
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
