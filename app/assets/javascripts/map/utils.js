import * as drawer from 'map/drawer';
import * as filters from 'map/filters';
import * as header from 'map/header';

export function closeAllDrawers() {
  drawer.closeDrawer();
  header.closeHamburgerMenu();
  filters.closeFiltersDrawer();
}
