export function debounce(callback, delay) {
  let timeout;

  return (...args) => {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => callback.apply(context, args), delay);
  };
}

document.addEventListener('DOMContentLoaded', () => {
  let collapsibleToggles = document.querySelectorAll('[data-toggle="collapse"]');

  for(let i=0; i<collapsibleToggles.length; i++) {
    collapsibleToggles[i].addEventListener('click', () => {
      let target = document.getElementById(collapsibleToggles[i].dataset.target);
      target.classList.toggle('show');
    });
  }
});
