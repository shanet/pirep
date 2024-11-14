const LOCAL_STORAGE_KEY = 'returning';

export function shouldShowOriginInfo() {
  return (localStorage.getItem(LOCAL_STORAGE_KEY) === null);
}

export function originInfoShown() {
  localStorage.setItem(LOCAL_STORAGE_KEY, true);
}
