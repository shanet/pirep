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

export function debounce(callback, delay) {
  let timeout;

  return (...args) => {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => callback.apply(context, args), delay);
  };
}

export function isBreakpointDown(breakpoint) {
  const breakpoints = [];

  // We want to know if the given breakpoint is at or below the active breakpoint so we need to collect everything below that level
  /* eslint-disable no-fallthrough */
  switch(breakpoint) {
    case 'xxl':
      breakpoints.push('xxl');
    case 'xl':
      breakpoints.push('xl');
    case 'lg':
      breakpoints.push('lg');
    case 'md':
      breakpoints.push('md');
    case 'sm':
      breakpoints.push('sm');
    case 'xs':
      breakpoints.push('xs');
    default:
  }
  /* eslint-enable no-fallthrough */

  return (breakpoints.indexOf(getActiveBreakpoint()) !== -1);
}

function getActiveBreakpoint() {
  // This reads the content property form a pseudo-element on a meta tag which will have the current Bootstrap breakpoint, see `breakpoints.scss`
  return getComputedStyle(document.querySelector('meta.breakpoint'), ':before').getPropertyValue('content').replaceAll('"', '');
}
