const LOCAL_STORAGE_KEY = 'returning';

export function shouldShowWelcomeInfo() {
  return (localStorage.getItem(LOCAL_STORAGE_KEY) === null);
}

export function welcomeInfoShown() {
  localStorage.setItem(LOCAL_STORAGE_KEY, true);
}
