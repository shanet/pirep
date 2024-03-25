import * as modal from 'shared/modal';
import Rails from '@rails/ujs';

export function initVerificationModal() {
  const verificationModal = getVerificationModal();

  if(!isVerificationRequired()) return;

  // After verification success mark it as no longer required for future form submissions and close the modal
  verificationModal.querySelector('form').addEventListener('ajax:success', () => {
    verificationModal.dataset.verificationRequired = 'false';
    modal.close(verificationModal);
  });

  // Intercept all form submissions to verify the user before submitting anything to the server
  document.querySelectorAll('form').forEach((form) => {
    form.addEventListener('submit', (event) => {
      // Check on each form submission if verification was done by some other ajax form submission and now not required anymore
      if(!isVerificationRequired()) return;

      // The form for the verification modal should not try to intercept itself
      if(form.dataset.skipVerification) return;

      event.preventDefault();
      modal.open(verificationModal);

      // After verification success submit the intercepted form
      verificationModal.querySelector('form').addEventListener('ajax:success', () => {
        // For Ajax forms trigger the Rails UJS submission or it will submit as a normal form
        if(form.dataset.remote === 'true') {
          Rails.fire(form, 'submit');
        } else {
          form.submit();
        }
      });

      // If the modal is cancelled re-enable the form submission element
      verificationModal.querySelectorAll('[data-bs-dismiss="modal"]').forEach((closeElement) => {
        closeElement.addEventListener('click', () => {
          verificationModalCancelled(form);
        });
      });

      // Handle modal cancels from clicking on the backdrop element
      verificationModal.addEventListener('close', () => {
        verificationModalCancelled(form);
      });
    });
  });

  // Intercept Rails UJS delete links
  document.querySelectorAll('a.delete').forEach((link) => {
    link.addEventListener('click', (event) => {
      // Check on each click as the triggering logic below will call this method again after verification
      if(!isVerificationRequired()) return;

      event.preventDefault();
      event.stopPropagation();

      modal.open(verificationModal);

      // After verification success trigger the link directly with Rails UJS to submit it
      verificationModal.querySelector('form').addEventListener('ajax:success', () => {
        Rails.fire(event.target, 'click');
      });
    });
  });
}

// Rails UJS will disable submit buttons when clicked; we need to re-enable those on verification modal dismissal
function verificationModalCancelled(form) {
  const submit = form.querySelector('input[type="submit"]');
  if(submit) submit.disabled = false;
}

function getVerificationModal() {
  return document.getElementById('verification-modal');
}

export function isVerificationRequired() {
  const verificationModal = getVerificationModal();
  if(!verificationModal) return false;

  return (verificationModal.dataset.verificationRequired !== 'false');
}

// Provide a callback for Turnstile to call if it's able to do verification in the background
// This means not having to show the verification modal at all making resulting in a steamlined UX
export function verificationModalCallback() {
  if(!isVerificationRequired()) return;
  Rails.fire(getVerificationModal().querySelector('form'), 'submit');
}

window.verificationModalCallback = verificationModalCallback;
