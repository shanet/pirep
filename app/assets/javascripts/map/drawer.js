import * as map from 'map/map';
import * as drawerAbout from 'map/drawer_about';
import * as drawerAirport from 'map/drawer_airport';
import * as drawerLogin from 'map/drawer_login';

export const DRAWER_ABOUT = 'about';
export const DRAWER_AIRPORT = 'airport';
export const DRAWER_LOGIN = 'login';

document.addEventListener('DOMContentLoaded', () => {
  // Close the drawer when clicking the drawer handle
  const drawerHandle = document.querySelector('#airport-drawer .handle button');
  if(!drawerHandle) return;

  drawerHandle.addEventListener('click', () => {
    closeDrawer();
    map.closeAirport();
  });

  // Open the drawer by default if an anchor is present
  const anchor = new URL(window.location).hash.slice(1);
  if([DRAWER_ABOUT, DRAWER_LOGIN].indexOf(anchor) !== -1) {
    loadDrawer(anchor);
    openDrawer(true);
  }
}, {once: true});

export async function loadDrawer(type, ...args) {
  // Hide the drawer content and show the loading icon
  document.getElementById('drawer-loading').style.display = 'flex';
  hideDrawerContent();

  let drawer;

  switch(type) {
    case DRAWER_ABOUT:
      drawer = drawerAbout;
      break;
    case DRAWER_AIRPORT:
      drawer = drawerAirport;
      break;
    case DRAWER_LOGIN:
      drawer = drawerLogin;
      break;
    default:
      console.log(`Unknown drawer type ${type}`); // eslint-disable-line no-console
      return;
  }

  const element = await drawer.loadDrawer(...args);
  setDrawerContent(element);
  if(typeof drawer.initializeDrawer === 'function') drawer.initializeDrawer();
}

function setDrawerContent(element) {
  // Hide the loading icon
  document.getElementById('drawer-loading').style.display = 'none';

  // Show the given element
  const drawerContent = document.getElementById(element);
  drawerContent.style.display = 'block';
}

function hideDrawerContent() {
  // Hide all drawer content elements
  const drawerContentElements = document.querySelectorAll('#drawer-content > *');
  for(let i=0; i<drawerContentElements.length; i++) {
    drawerContentElements[i].style.display = 'none';
  }
}

export function openDrawer(instant=false) {
  const drawer = document.getElementById('controls');
  drawer.classList.remove('slide-out-drawer');
  drawer.classList.add(`slide-in-drawer${instant ? '-instant' : ''}`);
}

export function closeDrawer() {
  const drawer = document.getElementById('controls');
  drawer.classList.remove('slide-in-drawer', 'slide-in-drawer-instant');
  drawer.classList.add('slide-out-drawer');
}

export function isDrawerOpen() {
  return (document.getElementById('controls').classList.contains('slide-in-drawer'));
}
