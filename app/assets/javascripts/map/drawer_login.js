const DRAWER_CONTENT_ID = 'drawer-login';

let initialized = false;

export async function loadDrawer() {
  return DRAWER_CONTENT_ID;
}

export function initializeDrawer() {
  if(initialized) return;
  initialized = true;

  const tabs = document.querySelectorAll('#login-tabs a.nav-link');

  for(let i=0; i<tabs.length; i++) {
    tabs[i].addEventListener('click', () => {
      showTab(tabs, tabs[i]);
    });
  }
}

function showTab(tabs, tab) {
  for(let i=0; i<tabs.length; i++) {
    const target = document.getElementById(tabs[i].dataset.target);

    if(tabs[i] === tab) {
      tabs[i].classList.add('active');
      target.style.display = 'block';
    } else {
      tabs[i].classList.remove('active');
      target.style.display = 'none';
    }
  }
}
