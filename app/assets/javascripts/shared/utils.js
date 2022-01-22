let initialized = false;

document.addEventListener('DOMContentLoaded', () => {
  if(initialized) return;
  initialized = true;

  addCollapseListeners();
});

function addCollapseListeners() {
  let collapsibleToggles = document.querySelectorAll('[data-bs-toggle="collapse"]');

  for(let i=0; i<collapsibleToggles.length; i++) {
    collapsibleToggles[i].addEventListener('click', () => {
      let target = document.getElementById(collapsibleToggles[i].dataset.bsTarget);
      target.classList.toggle('show');
    });
  }
}

export function debounce(callback, delay) {
  let timeout;

  return (...args) => {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => callback.apply(context, args), delay);
  };
}
