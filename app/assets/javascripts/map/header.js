import * as drawer from 'map/drawer';
import * as utils from 'map/utils';

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementsByClassName('map-header').length) return;

  initHeaderLinks();
  initHamburgerMenu();
}, {once: true});

function initHeaderLinks() {
  const aboutLinks = document.getElementsByClassName('about-link');

  for(let i=0; i<aboutLinks.length; i++) {
    aboutLinks[i].addEventListener('click', () => {
      drawer.loadDrawer(drawer.DRAWER_ABOUT);
      drawer.openDrawer();
    });
  }

  const loginLinks = document.getElementsByClassName('login-link');

  for(let i=0; i<loginLinks.length; i++) {
    loginLinks[i].addEventListener('click', () => {
      drawer.loadDrawer(drawer.DRAWER_LOGIN);
      drawer.openDrawer();
    });
  }
}

function initHamburgerMenu() {
  const hamburgerIcon = document.getElementById('hamburger-icon');
  if(!hamburgerIcon) return;

  hamburgerIcon.addEventListener('click', toggleHamburgerMenu);

  // Close the menu when it loses focus
  hamburgerIcon.querySelector('button').addEventListener('blur', (event) => {
    // Don't close the menu if clicking on a link in it
    if(Array.from(document.getElementById(hamburgerIcon.dataset.target).querySelectorAll('a')).indexOf(event.relatedTarget) !== -1) return;

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
