document.addEventListener('DOMContentLoaded', () => {
  addCollapseListeners();
}, {once: true});

function addCollapseListeners() {
  const collapsibleToggles = document.querySelectorAll('[data-bs-toggle="collapse"]');

  for(let i=0; i<collapsibleToggles.length; i++) {
    collapsibleToggles[i].addEventListener('click', () => {
      const target = document.getElementById(collapsibleToggles[i].dataset.bsTarget);
      target.classList.toggle('show');
    });
  }
}
