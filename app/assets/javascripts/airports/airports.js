import * as originInfo from 'shared/origin_info';
import * as utils from 'shared/utils';
import * as verificationModal from 'shared/verification_modal';

document.addEventListener('DOMContentLoaded', () => {
  if(!document.querySelector('.airport-header')) return;

  verificationModal.initVerificationModal();
  initEditingTags();
  initTagDeleteIcons();
  initTagScrollTargets();
  initShowMoreWebcams();
  initTafs();
  initExtraRemarks();
  initMapBackButton();
  initCoverImageForm();
  initOriginInfo();
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
    deleteIcons.forEach((deleteIcon) => {
      deleteIcon.style.display = (['none', ''].indexOf(deleteIcon.style.display) !== -1 ? 'block' : 'none');
    });
  });
}

function initTagScrollTargets() {
  const scrollTags = document.querySelectorAll('.tag-square[data-scroll-target]');

  scrollTags.forEach((scrollTag) => {
    scrollTag.addEventListener('click', () => {
      // Don't scroll if the tags are being edited
      if(document.querySelector('#add-tag-form.show')) return;

      document.getElementById(scrollTag.dataset.scrollTarget).scrollIntoView({behavior: 'smooth'});
    });
  });
}

function initShowMoreWebcams() {
  const showMoreWebcams = document.getElementById('show-more-webcams');
  if(!showMoreWebcams) return;

  showMoreWebcams.addEventListener('click', () => {
    // Update the button text accordingly
    showMoreWebcams.innerText = (showMoreWebcams.innerText === 'Show More' ? 'Show Less' : 'Show More');
  });
}

function initTafs() {
  const showTafs = document.getElementById('show-tafs');
  const tafs = document.querySelectorAll('.taf');

  if(!showTafs) return;

  showTafs.addEventListener('click', () => {
    // Update the button text accordingly
    showTafs.innerText = (tafs[0].classList.contains('d-none') ? 'Hide TAFs' : 'Show TAFs');

    // Show/hide the TAFs
    tafs.forEach((taf) => {
      taf.classList.toggle('d-none');
    });

    // Go back to the top of the weather report list when hiding the TAFs
    if(tafs[0].classList.contains('d-none')) {
      document.querySelector('.weather-reports').scrollIntoView({behavior: 'smooth'});
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
    extraRemarks.forEach((remark) => {
      remark.classList.toggle('hidden');
    });
  });
}

function initMapBackButton() {
  const mapBackButtons = document.querySelectorAll('.map-back');
  if(mapBackButtons.length === 0) return;

  // If arrived at this page from the map index then try to use the history API to go back so it uses the cached map state rather than doing a full page load
  const useHistoryApi = (utils.getPreviousPage() === 'map');

  // Let the map index know we're coming from the airport page to customize the drawer loading
  utils.setPreviousPage('airport');

  mapBackButtons.forEach((backButton) => {
    backButton.addEventListener('click', (event) => {
      if(useHistoryApi && window.history.length > 1) {
        window.history.back();
        event.preventDefault();
      }
    });
  });
}

function initCoverImageForm() {
  const coverImageDropdowns = document.querySelectorAll('.cover-image-dropdown');

  coverImageDropdowns.forEach((dropdown) => {
    const toggleButton = dropdown.querySelector('.dropdown-toggle');

    toggleButton.addEventListener('click', () => {
      dropdown.querySelector('.dropdown-menu').classList.toggle('d-block');
    });

    const options = dropdown.querySelectorAll('.dropdown-menu li');
    const form = dropdown.querySelector('form');

    options.forEach((option) => {
      option.addEventListener('click', () => {
        form.querySelector('input[name="airport[cover_image]"]').value = option.dataset.coverImage;

        // Manually trigger a submit event so the verification modal can intercept it if verification is required, otherwise just submit the form
        if(verificationModal.isVerificationRequired()) {
          form.dispatchEvent(new Event('submit'));
        } else {
          form.submit();
        }
      });
    });

    // Close the dropdown when it loses focus
    toggleButton.addEventListener('blur', (event) => {
      // Don't close the dropdown if clicking on an option in it
      if(Array.from(options).indexOf(event.relatedTarget) !== -1) return;
      if(Array.from(options).indexOf(event.relatedTarget?.parentNode) !== -1) return;

      dropdown.querySelector('.dropdown-menu').classList.toggle('d-block');
    });
  });
}

function initOriginInfo() {
  const originNotice = document.getElementById('origin-info-notice');
  if(!originNotice || !originInfo.shouldShowOriginInfo()) return;

  // Only show the origin info once
  originInfo.originInfoShown();

  originNotice.classList.remove('d-none');
}
