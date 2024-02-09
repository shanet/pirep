document.addEventListener('DOMContentLoaded', () => {
  addCollapseListeners();
}, {once: true});

function addCollapseListeners() {
  const collapsibleToggles = document.querySelectorAll('[data-bs-toggle="collapse"]');

  collapsibleToggles.forEach((toggle) => {
    toggle.addEventListener('click', () => {
      const target = document.getElementById(toggle.dataset.bsTarget);

      if(target.classList.contains('show-instant')) {
        target.classList.remove('show-instant');
      } else {
        target.classList.toggle('show');
      }

      // Let observers know this element was changed
      toggle.dispatchEvent(new Event('collapsible'));
    });
  });
}
