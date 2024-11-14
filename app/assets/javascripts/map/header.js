import * as drawer from 'map/drawer';
import * as utils from 'map/utils';

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementsByClassName('map-header').length) return;

  initHeaderDrawerLinks();
  initHamburgerMenu();
}, {once: true});

function initHeaderDrawerLinks() {
  document.querySelectorAll('.drawer-link').forEach((drawerLink) => {
    drawerLink.addEventListener('click', () => {
      drawer.loadDrawer(drawerLink.dataset.target);
      drawer.openDrawer();
    });
  });
}

function initHamburgerMenu() {
  const hamburgerIcon = document.getElementById('hamburger-icon');
  if(!hamburgerIcon) return;

  hamburgerIcon.addEventListener('click', toggleHamburgerMenu);

  // Close the menu when it loses focus
  hamburgerIcon.addEventListener('blur', (event) => {
    // Don't close the menu if clicking on a link in it
    if(Array.from(document.getElementById(hamburgerIcon.dataset.target).querySelectorAll('a, label, input')).indexOf(event.relatedTarget) !== -1) {
      // Give it back focus so the next blur event will still close the modal as expected
      hamburgerIcon.focus();
      return;
    }

    closeHamburgerMenu();
  });
}

function toggleHamburgerMenu() {
  const hamburgerIcon = document.getElementById('hamburger-icon');

  if(document.getElementById(hamburgerIcon.dataset.target).classList.contains('d-none')) {
    openHamburgerMenu();
  } else {
    closeHamburgerMenu();
  }
}

function openHamburgerMenu() {
  // Swap the menu icon when it's open
  const hamburgerIcon = document.getElementById('hamburger-icon');
  hamburgerIcon.querySelector('i').classList.replace('fa-bars', 'fa-xmark');

  // Close all other drawer elements to prevent overlap
  utils.closeAllDrawers();

  const menu = document.getElementById(hamburgerIcon.dataset.target);
  menu.classList.remove('d-none');
}

export function closeHamburgerMenu() {
  const hamburgerIcon = document.getElementById('hamburger-icon');
  hamburgerIcon.querySelector('i').classList.replace('fa-xmark', 'fa-bars');

  const menu = document.getElementById(hamburgerIcon.dataset.target);
  menu.classList.add('d-none');
}
