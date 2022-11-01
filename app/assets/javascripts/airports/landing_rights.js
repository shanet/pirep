document.addEventListener('DOMContentLoaded', () => {
  initLandingRightsForm();
}, {once: true});

export function initLandingRightsForm() {
  const landingRightsRadios = document.querySelectorAll('.landing-rights-form input[type="radio"]');

  for(let i=0; i<landingRightsRadios.length; i++) {
    const landingRightsRadio = landingRightsRadios[i];

    landingRightsRadio.addEventListener('click', () => {
      // Hide the textarea and all labels
      const textarea = document.getElementById('airport_landing_requirements');
      textarea.classList.add('d-none');

      const landingRestrictionsLabels = document.querySelectorAll('label[data-landing-rights-type]');
      for(let j=0; j<landingRestrictionsLabels.length; j++) {
        landingRestrictionsLabels[j].classList.add('d-none');
      }

      // If there is a textarea label for the landing rights type show it and the textarea
      const label = document.querySelector(`label[data-landing-rights-type="${landingRightsRadio.value}"]`);
      if(label) {
        label.classList.remove('d-none');
        textarea.classList.remove('d-none');
      }
    });
  }
}
