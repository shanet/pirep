import * as utils from 'shared/utils';
import * as welcomeInfo from 'shared/welcome_info';

document.addEventListener('DOMContentLoaded', () => {
  initEditingTags();
  initTagDeleteIcons();
  initTagScrollTargets();
  initShowMoreWebcams();
  initExtraRemarks();
  initMapBackButton();
  initCoverImageForm();
  initWelcomeInfo();
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

function initTagScrollTargets() {
  const scrollTags = document.querySelectorAll('.tag-square[data-scroll-target]');

  for(let i=0; i<scrollTags.length; i++) {
    scrollTags[i].addEventListener('click', () => {
      // Don't scroll if the tags are being edited
      if(document.querySelector('#add-tag-form.show')) return;

      document.getElementById(scrollTags[i].dataset.scrollTarget).scrollIntoView({behavior: 'smooth'});
    });
  }
}

function initShowMoreWebcams() {
  const showMoreWebcams = document.getElementById('show-more-webcams');
  if(!showMoreWebcams) return;

  showMoreWebcams.addEventListener('click', () => {
    // Update the button text accordingly
    showMoreWebcams.innerText = (showMoreWebcams.innerText === 'Show More' ? 'Show Less' : 'Show More');
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

function initMapBackButton() {
  const mapBackButtons = document.getElementsByClassName('map-back');
  if(mapBackButtons.length === 0) return;

  // If arrived at this page from the map index then try to use the history API to go back so it uses the cached map state rather than doing a full page load
  const useHistoryApi = (utils.getPreviousPage() === 'map');

  // Let the map index know we're coming from the airport page to customize the drawer loading
  utils.setPreviousPage('airport');

  for(let i=0; i<mapBackButtons.length; i++) {
    const button = mapBackButtons[i];

    button.addEventListener('click', (event) => {
      if(useHistoryApi && window.history.length > 1) {
        window.history.back();
        event.preventDefault();
      }
    });
  }
}

function initCoverImageForm() {
  const coverImageDropdowns = document.getElementsByClassName('cover-image-dropdown');

  for(let i=0; i<coverImageDropdowns.length; i++) {
    const dropdown = coverImageDropdowns[i];
    const toggleButton = dropdown.querySelector('.dropdown-toggle');

    toggleButton.addEventListener('click', () => {
      dropdown.querySelector('.dropdown-menu').classList.toggle('d-none');
    });

    const options = dropdown.querySelectorAll('.dropdown-menu li');
    const form = dropdown.querySelector('form');

    for(let j=0; j<options.length; j++) {
      options[j].addEventListener('click', () => {
        form.querySelector('input[name="airport[cover_image]"]').value = options[j].dataset.coverImage;
        form.submit();
      });
    }

    // Close the dropdown when it loses focus
    toggleButton.addEventListener('blur', (event) => {
      // Don't close the dropdown if clicking on an option in it
      if(Array.from(options).indexOf(event.relatedTarget) !== -1) return;
      if(Array.from(options).indexOf(event.relatedTarget?.parentNode) !== -1) return;

      dropdown.querySelector('.dropdown-menu').classList.toggle('d-none');
    });
  }
}

function initWelcomeInfo() {
  const welcomeNotice = document.getElementById('welcome-info-notice');
  if(!welcomeNotice || !welcomeInfo.shouldShowWelcomeInfo()) return;

  // Only show the welcome info once
  welcomeInfo.welcomeInfoShown();

  welcomeNotice.classList.remove('d-none');
}
