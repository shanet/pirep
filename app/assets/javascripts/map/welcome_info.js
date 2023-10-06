import * as drawer from 'map/drawer';
import * as utils from 'shared/utils';
import * as welcomeInfo from 'shared/welcome_info';

document.addEventListener('DOMContentLoaded', () => {
  showWelcomeInfo();
}, {once: true});

function showWelcomeInfo() {
  const welcomeToast = document.getElementById('welcome-info-toast');
  if(!welcomeToast || !welcomeInfo.shouldShowWelcomeInfo()) return;

  welcomeToast.querySelector('.btn-close').addEventListener('click', hideWelcomeInfo);

  // Only show the welcome info once
  welcomeInfo.welcomeInfoShown();

  // Show the flash on mobile or the full about drawer otherwise
  if(utils.isBreakpointDown('sm')) {
    welcomeToast.classList.add('d-block');
  } else {
    drawer.loadDrawer(drawer.DRAWER_ABOUT);
    drawer.openDrawer(true);
  }
}

export function hideWelcomeInfo() {
  const welcomeToast = document.getElementById('welcome-info-toast');
  welcomeToast.classList.remove('d-block');
}
