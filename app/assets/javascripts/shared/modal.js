export function open(modal) {
  const backdrop = createBackdrop();

  modal.classList.add('d-block');

  setTimeout(() => {
    backdrop.classList.add('show');
    modal.classList.add('show');
  }, 0);

  modal.querySelectorAll('[data-bs-dismiss="modal"]').forEach((closeElement) => {
    const listener = () => {
      closeElement.removeEventListener('click', listener);
      close(modal);
    };

    closeElement.addEventListener('click', listener);
  });

  modal.addEventListener('click', (event) => {
    if(event.target === modal) {
      close(modal);
      modal.dispatchEvent(new Event('close'));
    }
  });
}

export function close(modal) {
  // Do nothing if the modal isn't open already
  if(!modal.classList.contains('show')) return;

  const backdrop = document.querySelector('div.modal-backdrop');

  // Some users may have reduced motion set so we should not use the transitionend event, but most notably this transition won't happen in tests
  const noTransitions = window.matchMedia('(prefers-reduced-motion: reduce)').matches === true;

  if(noTransitions) {
    modal.classList.remove('d-block');
    backdrop.remove();
  }

  executeAfterEvent(modal, 'transitionend', () => {
    modal.classList.remove('d-block');
  });

  executeAfterEvent(backdrop, 'transitionend', () => {
    backdrop.remove();
  });

  modal.classList.remove('show');
  backdrop.classList.remove('show');
}

function executeAfterEvent(element, eventName, callback) {
  const listener = (event) => {
    element.removeEventListener(eventName, listener);
    callback(event);
  };

  element.addEventListener(eventName, listener);
}

function createBackdrop() {
  const backdrop = document.createElement('div');
  backdrop.classList.add('modal-backdrop');
  backdrop.classList.add('fade');

  document.querySelector('body').append(backdrop);
  return backdrop;
}
