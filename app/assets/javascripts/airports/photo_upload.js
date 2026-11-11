// Photos are resized to these dimensions on the server anyway so there's no point in uploading anything larger
const MAX_PHOTO_DIMENSION = 1500;

// Use a higher quality than the server since the photos will be re-encoded again there
const PHOTO_JPEG_QUALITY = 0.9;

// API Gateway rejects requests over 10mb so leave some headroom for the rest of the multipart request
const MAX_UPLOAD_BYTES = 9 * 1024 * 1024; // 9mb

document.addEventListener('DOMContentLoaded', () => {
  initPhotoUploadForm();
}, {once: true});

function initPhotoUploadForm() {
  const form = document.querySelector('.photo-upload-form');
  if(!form) return;

  const input = form.querySelector('input[type="file"]');
  const submitButton = form.querySelector('input[type="submit"]');
  const originalSubmitButtonLabel = submitButton.value;

  // Re-enable the form if the page is restored from the back/forward cache after submitting it
  window.addEventListener('pageshow', () => {
    setSubmitButtonState(submitButton, false, originalSubmitButtonLabel);
  });

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    form.querySelector('.photo-upload-error').classList.add('d-none');

    if(input.files.length === 0) return;

    setSubmitButtonState(submitButton, true, 'Processing...');
    const resizedPhotos = await resizePhotos(input.files);

    if(!validateUploadSize(resizedPhotos, form, submitButton, originalSubmitButtonLabel)) return;

    const files = new DataTransfer();
    resizedPhotos.forEach((photo) => files.items.add(photo));
    input.files = files.files;

    // Submit the form directly so this handler isn't triggered again
    setSubmitButtonState(submitButton, true, 'Uploading...');
    form.submit();
  });
}

async function resizePhotos(photos) {
  const resizedPhotos = [];

  for(const photo of photos) {
    try {
      resizedPhotos.push(await resizePhoto(photo));
    } catch(error) {
      // Fall back to the original photo if the browser can't resize it and let the server handle (or reject) it
      console.warn(`Failed to resize ${photo.name}`, error);
      resizedPhotos.push(photo);
    }
  }

  return resizedPhotos;
}

async function resizePhoto(file) {
  // Apply the EXIF orientation since drawing to a canvas strips the EXIF data from the photo
  const bitmap = await createImageBitmap(file, {imageOrientation: 'from-image'});
  const scale = Math.min(1, MAX_PHOTO_DIMENSION / Math.max(bitmap.width, bitmap.height));

  const canvas = new OffscreenCanvas(Math.round(bitmap.width * scale), Math.round(bitmap.height * scale));
  const context = canvas.getContext('2d');

  // JPEGs don't support transparency so fill in a white background rather than letting transparent areas turn black
  context.fillStyle = 'white';
  context.fillRect(0, 0, canvas.width, canvas.height);

  context.imageSmoothingQuality = 'high';
  context.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();

  const blob = await canvas.convertToBlob({type: 'image/jpeg', quality: PHOTO_JPEG_QUALITY});
  return new File([blob], file.name.replace(/\.[^.]*$/, '') + '.jpg', {type: 'image/jpeg'});
}

function validateUploadSize(photos, form, submitButton, originalSubmitButtonLabel) {
  const uploadSize = photos.reduce((total, photo) => total + photo.size, 0);

  if(uploadSize < MAX_UPLOAD_BYTES) return true;

  const errorMessage = form.querySelector('.photo-upload-error');
  errorMessage.textContent = 'These photos are too large to upload together, try uploading fewer at once.';
  errorMessage.classList.remove('d-none');

  setSubmitButtonState(submitButton, false, originalSubmitButtonLabel);
  return false;
}

function setSubmitButtonState(submitButton, disabled, label) {
  submitButton.disabled = disabled;
  submitButton.value = label;
}
