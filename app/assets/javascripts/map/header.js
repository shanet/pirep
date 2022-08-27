import * as drawer from 'map/drawer';

document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementsByClassName('header')) return;

  initHeaderLinks();
}, {once: true});

function initHeaderLinks() {
  document.getElementById('about-link').addEventListener('click', () => {
    drawer.loadDrawer(drawer.DRAWER_ABOUT);
    drawer.openDrawer();
  });

  document.getElementById('login-link').addEventListener('click', () => {
    drawer.loadDrawer(drawer.DRAWER_LOGIN);
    drawer.openDrawer();
  });
}
