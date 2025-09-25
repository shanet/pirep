const SESSION_STORAGE_PREVIOUS_PAGE_KEY = 'previous_page';

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
   

  return (breakpoints.indexOf(getActiveBreakpoint()) !== -1);
}

function getActiveBreakpoint() {
  // This reads the content property form a pseudo-element on a meta tag which will have the current Bootstrap breakpoint, see `breakpoints.scss`
  return getComputedStyle(document.querySelector('meta.breakpoint'), ':before').getPropertyValue('content').replaceAll('"', '');
}

export function isWebGlAvailable() {
  const canvas = document.createElement('canvas');
  return (canvas.getContext('webgl') instanceof WebGLRenderingContext);
}

export function setPreviousPage(page) {
  sessionStorage.setItem(SESSION_STORAGE_PREVIOUS_PAGE_KEY, page);
}

export function getPreviousPage() {
  const previousPage = sessionStorage.getItem(SESSION_STORAGE_PREVIOUS_PAGE_KEY);
  sessionStorage.removeItem(SESSION_STORAGE_PREVIOUS_PAGE_KEY);
  return previousPage;
}
