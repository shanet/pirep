const FLASH_EXPIRATION = 5000; // ms

// These match the Rails flash types in `application_helper.rb`
export const FLASH_ERROR = 'danger';
export const FLASH_NOTICE = 'primary';
export const FLASH_WARNING = 'warning';

export function show(type, message, persistent) {
  const flash = document.createElement('div');
  const flashBody = document.createElement('div');

  flash.classList.add('toast', 'show', 'text-white', `bg-${type}`, 'mb-3');
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

// Expose this to the window so we can call it in AJAX responses
window.showFlash = show;
