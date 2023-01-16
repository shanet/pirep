import * as drawerAbout from 'map/drawer_about';
import * as drawerLogin from 'map/drawer_login';
import * as drawerNewAirport from 'map/drawer_new_airport';
import * as drawerShowAirport from 'map/drawer_show_airport';
import * as map from 'map/map';
import * as mapUtils from 'map/utils';
import * as urlSearchParams from 'map/url_search_params';
import * as utils from 'shared/utils';

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
  const drawer = document.getElementById('airport-drawer');
  const grid = document.getElementById('grid');

  // Don't try to open the drawer if it's already open
  if(drawer.className.indexOf('slide-in-drawer-instant') !== -1) return;

  mapUtils.closeAllDrawers();

  // In small screen sizes the drawer overlaps the map controls as opposed to being inline with them on large screen sizes.
  // This requires styles applied to the drawer itself vs. the map controls grid depending on screen size. However, we also
  // want to apply the instant style to the other element so if the page is resized the drawer remains open without the
  // animation playing again.
  if(utils.isBreakpointDown('md')) {
    drawer.classList.remove('slide-out-drawer');
    drawer.classList.add(`slide-in-drawer${instant ? '-instant' : ''}`);
    grid.classList.add('slide-in-drawer-instant');
  } else {
    grid.classList.remove('slide-out-drawer');
    grid.classList.add(`slide-in-drawer${instant ? '-instant' : ''}`);
    drawer.classList.add('slide-in-drawer-instant');
  }

  // Replace the slide-in classes with the instant classes so the animation does not repeat as the window is resized
  grid.addEventListener('animationend', () => {
    grid.classList.replace('slide-in-drawer', 'slide-in-drawer-instant');
  });

  drawer.addEventListener('animationend', () => {
    drawer.classList.replace('slide-in-drawer', 'slide-in-drawer-instant');
  });
}

export function closeDrawer() {
  const drawer = document.getElementById('airport-drawer');
  const grid = document.getElementById('grid');

  // Don't try to close the drawer if it's not already open
  if(drawer.className.indexOf('slide-in-drawer') === -1) return;

  drawer.classList.remove('slide-in-drawer', 'slide-in-drawer-instant');
  grid.classList.remove('slide-in-drawer', 'slide-in-drawer-instant');

  // See comment in the open function above for why the screen size matters here
  if(utils.isBreakpointDown('md')) {
    drawer.classList.add('slide-out-drawer');
  } else {
    grid.classList.add('slide-out-drawer');
  }

  // If a new airport was being added but the drawer is closed remove the marker to clear it
  drawerNewAirport.removeNewAirportLayer();

  // Once the animation is done, remove the slide-out classes to avoid the animation from being played again on a window resize
  grid.addEventListener('animationend', () => {
    grid.classList.remove('slide-out-drawer');
  });

  drawer.addEventListener('animationend', () => {
    drawer.classList.remove('slide-out-drawer');
  });
}

export function getWidth() {
  return document.getElementById('airport-drawer').offsetWidth;
}
