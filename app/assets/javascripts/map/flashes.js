const FLASH_EXPIRATION = 5000; // ms

// These match the Rails flash types in `application_helper.rb`
export const FLASH_ERROR = 'danger';
export const FLASH_NOTICE = 'primary';
export const FLASH_WARNING = 'warning';

document.addEventListener('DOMContentLoaded', () => {
  showInitialFlashes();
}, {once: true});

export function show(type, message, persistent) {
  const flash = document.createElement('div');
  const flashBody = document.createElement('div');

  flash.classList.add('toast', 'show', `text-${type === FLASH_WARNING ? 'dark' : 'light'}`, `bg-${type}`, 'mb-3');
  flashBody.classList.add('toast-body');

  flashBody.textContent = message;

  flash.appendChild(flashBody);
  document.getElementById('flashes').appendChild(flash);

  if(!persistent) {
    // Fade out the flash after a set time and then remove it from the DOM once the animation is over
    setTimeout(() => {
      flash.classList.add('hide');
      flash.addEventListener('animationend', () => {flash.remove();});
    }, FLASH_EXPIRATION);
  }
}

function showInitialFlashes() {
  // Display any initial flashes that are present on the page at page load. This is also important to do here
  // as calling `window.showFlash` immediately on page load will fail if the browser is using the import map
  // polyfill and does not load this file until after the DOM is ready
  if(!window.flashes) return;

  window.flashes.forEach((flash) => {
    show(flash.type, flash.message, flash.persistent);
  });
}

// Expose this to the window so we can call it in AJAX responses
window.showFlash = show;
