document.addEventListener('DOMContentLoaded', () => {
  // Close the drawer when clicking the drawer handle
  document.querySelector('#airport-drawer .handle button').addEventListener('click', () => {
    closeDrawer();
  });
});

export function loadDrawer(airportCode) {
  // Hide the drawer content and show the loading icon
  document.getElementById('drawer-loading').style.display = 'block';
  document.getElementById('airport-info').style.display = 'none';

  const request = new XMLHttpRequest();

  request.onload = () => {
    if(request.status === 200) {
      setDrawerContent(request.response);
    } else {
      // TODO: make this better
      alert('fetching airport failed');
    }
  };

  // Get the path to request airport info from dynamically
  // Tthis means swapping out a placeholder value with the airport code we want to get
  const { airportPath } = document.getElementById('map').dataset;
  const { placeholder } = document.getElementById('map').dataset;

  request.open('GET', airportPath.replace(placeholder, airportCode));
  request.send();
}

function setDrawerContent(body) {
  // Hide the loading icon
  document.getElementById('drawer-loading').style.display = 'none';

  // Set the drawer's content to the given body
  let drawerInfo = document.getElementById('airport-info');
  drawerInfo.innerHTML = body;
  drawerInfo.style.display = 'block';
}

export function openDrawer() {
  let drawer = document.getElementById('airport-drawer');
  drawer.classList.remove('slide-out');
  drawer.classList.add('slide-in');
}

function closeDrawer() {
  let drawer = document.getElementById('airport-drawer');
  drawer.classList.remove('slide-in');
  drawer.classList.add('slide-out');
}
