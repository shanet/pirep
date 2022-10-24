import * as drawer from 'map/drawer';

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementsByClassName('map-header').length) return;

  initHeaderLinks();
}, {once: true});

function initHeaderLinks() {
  if(document.getElementById('about-link')) {
    document.getElementById('about-link').addEventListener('click', () => {
      drawer.loadDrawer(drawer.DRAWER_ABOUT);
      drawer.openDrawer();
    });
  }

  if(document.getElementById('login-link')) {
    document.getElementById('login-link').addEventListener('click', () => {
      drawer.loadDrawer(drawer.DRAWER_LOGIN);
      drawer.openDrawer();
    });
  }
}
