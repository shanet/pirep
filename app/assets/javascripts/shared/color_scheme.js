const COLOR_SCHEME_KEY = 'color_scheme';

document.addEventListener('DOMContentLoaded', () => {
  initColorSchemeSelectors();
  setPageColorScheme(getPreferredColorScheme());
}, {once: true});

function initColorSchemeSelectors() {
  document.querySelectorAll('.color-scheme-selector .dropdown-toggle').forEach((selector) => {
    setColorSchemeSelectorIcon(selector);

    selector.addEventListener('click', () => {
      initColorSchemeSelectorOptions(selector);
    });

    selector.addEventListener('blur', (event) => {
      const target = document.getElementById(selector.dataset.bsToggle);
      const options = target.querySelectorAll('.dropdown-item');

      // Don't close the menu if clicking on an option in it
      if(Array.from(options).indexOf(event.relatedTarget) !== -1) return;

      target.classList.remove('show');
    });
  });
}

function initColorSchemeSelectorOptions(toggleElement) {
  // Show the menu
  const target = document.getElementById(toggleElement.dataset.bsToggle);
  target.classList.toggle('show');

  const options = target.querySelectorAll('.dropdown-item');

  options.forEach((option) => {
    setActiveColorSchemeSelectorOption(options);

    // When switching color schemes save it in local storage then update to that schema and update the selector icon
    option.addEventListener('click', () => {
      setPreferredColorScheme(option.dataset.colorScheme);
      setPageColorScheme(getPreferredColorScheme());
      setColorSchemeSelectorIcon(toggleElement);
      setActiveColorSchemeSelectorOption(options);
      target.classList.remove('show');
    });
  });
}

function setActiveColorSchemeSelectorOption(options) {
  options.forEach((option) => {
    if(readPreferredColorScheme() === option.dataset.colorScheme) {
      option.classList.add('active');
    } else {
      option.classList.remove('active');
    }
  });
}

function setColorSchemeSelectorIcon(toggleElement) {
  const icon = toggleElement.querySelector('i');
  icon.classList = iconForColorScheme(readPreferredColorScheme());
}

function setPageColorScheme(colorScheme) {
  if(colorScheme === 'dark') {
    document.querySelector('body').setAttribute('data-bs-theme', 'dark');
  } else {
    document.querySelector('body').removeAttribute('data-bs-theme');
  }
}

function getPreferredColorScheme() {
  const colorScheme = readPreferredColorScheme();

  // If no preference set or set to auto fallback to whatever the browser's setting is
  if(colorScheme === 'auto') {
    return (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  }

  return colorScheme;
}

function readPreferredColorScheme() {
  return localStorage.getItem(COLOR_SCHEME_KEY) || 'auto';
}

function setPreferredColorScheme(colorScheme) {
  localStorage.setItem(COLOR_SCHEME_KEY, colorScheme);
}

function iconForColorScheme(colorScheme) {
  switch(colorScheme) {
    case 'light':
      return 'fa-solid fa-sun';
    case 'dark':
      return 'fa-solid fa-moon';
    default:
      return 'fa-solid fa-circle-half-stroke';
  }
}
