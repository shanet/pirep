import * as drawer from 'map/drawer';
import * as drawerOrigin from 'map/drawer_origin';
import * as originInfo from 'shared/origin_info';
import * as utils from 'shared/utils';

document.addEventListener('DOMContentLoaded', () => {
  drawerOrigin.initializeOriginFilters(document.getElementById('origin-info-modal'));
  show();
}, {once: true});

function show() {
  const originModal = document.getElementById('origin-info-modal');
  if(!originModal || !originInfo.shouldShowOriginInfo()) return;

  originModal.querySelector('.btn-close').addEventListener('click', hide);

  // Only show the origin info once
  originInfo.originInfoShown();

  // Show the flash on mobile or the full about drawer otherwise
  if(utils.isBreakpointDown('sm')) {
    originModal.classList.add('d-block');
  } else {
    drawer.loadDrawer(drawer.DRAWER_ORIGIN);
    drawer.openDrawer(true);
  }
}

export function hide() {
  const originModal = document.getElementById('origin-info-modal');
  originModal.classList.remove('d-block');
}
