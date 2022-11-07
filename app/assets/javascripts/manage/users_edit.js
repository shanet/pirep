document.addEventListener('DOMContentLoaded', () => {
  const clearButtons = document.querySelectorAll('a.clear-timestamp');
  const setButtons = document.querySelectorAll('a.set-timestamp');

  for(let i=0; i<clearButtons.length; i++) {
    clearButtons[i].addEventListener('click', () => {
      document.getElementById(clearButtons[i].dataset.target).value = '';
    });
  }

  for(let i=0; i<setButtons.length; i++) {
    setButtons[i].addEventListener('click', () => {
      document.getElementById(setButtons[i].dataset.target).value = new Date(Date.now()).toISOString();
    });
  }
}, {once: true});
