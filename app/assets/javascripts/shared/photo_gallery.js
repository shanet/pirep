let currentImageIndex = 0;

document.addEventListener('DOMContentLoaded', () => {
  initializePhotoGallery();
}, {once: true});

export function initializePhotoGallery() {
  if(!document.querySelector('.photo-gallery .next')) return;

  const images = document.querySelectorAll('.photo-gallery .image');

  document.querySelector('.photo-gallery .next').addEventListener('click', () => {
    currentImageIndex = (currentImageIndex === images.length - 1 ? 0 : currentImageIndex + 1);
    showImage();
  });

  document.querySelector('.photo-gallery .previous').addEventListener('click', () => {
    currentImageIndex = (currentImageIndex === 0 ? images.length - 1 : currentImageIndex - 1);
    showImage();
  });
}

function showImage() {
  const images = document.querySelectorAll('.photo-gallery .image');

  for(let i = 0; i < images.length; i++) {
    if(i !== currentImageIndex) {
      images[i].classList.remove('active');
    }
  }

  images[currentImageIndex].classList.add('active');
}
