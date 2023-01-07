import * as drawerAbout from 'map/drawer_about';
import * as drawerLogin from 'map/drawer_login';
import * as drawerNewAirport from 'map/drawer_new_airport';
import * as drawerShowAirport from 'map/drawer_show_airport';
import * as map from 'map/map';
import * as urlSearchParams from 'map/url_search_params';

export const DRAWER_ABOUT = 'about';
export const DRAWER_LOGIN = 'login';
export const DRAWER_NEW_AIRPORT = 'new_airport';
export const DRAWER_SHOW_AIRPORT = 'airport';

document.addEventListener('DOMContentLoaded', () => {
  // Close the drawer when clicking the drawer handle
  const drawerHandle = document.querySelector('#airport-drawer .handle button');
  if(!drawerHandle) return;

  drawerHandle.addEventListener('click', () => {
    closeDrawer();
    map.closeAirport();
  });

  // Open the drawer by default if an anchor is present
  const drawer = urlSearchParams.getDrawer();
  if([DRAWER_ABOUT, DRAWER_LOGIN, DRAWER_NEW_AIRPORT].indexOf(drawer) !== -1) {
    loadDrawer(drawer);
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
    case DRAWER_LOGIN:
      drawer = drawerLogin;
      break;
    case DRAWER_NEW_AIRPORT:
      drawer = drawerNewAirport;
      break;
    case DRAWER_SHOW_AIRPORT:
      drawer = drawerShowAirport;
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
  const grid = document.getElementById('grid');
  grid.classList.remove('slide-out-drawer');
  grid.classList.add(`slide-in-drawer${instant ? '-instant' : ''}`);
}

export function closeDrawer() {
  const grid = document.getElementById('grid');
  grid.classList.remove('slide-in-drawer', 'slide-in-drawer-instant');
  grid.classList.add('slide-out-drawer');
}

export function isDrawerOpen() {
  return (document.getElementById('grid').classList.contains('slide-in-drawer'));
}
