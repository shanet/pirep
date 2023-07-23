document.addEventListener('DOMContentLoaded', () => {
  initializePhotoGalleries();
}, {once: true});

export function initializePhotoGalleries() {
  const photoGalleries = document.getElementsByClassName('carousel');

  for(let i=0; i<photoGalleries.length; i++) {
    initializePhotoGallery(photoGalleries[i]);
    fetchUncachedPhotoGallery(photoGalleries[i]);
  }
}

function initializePhotoGallery(photoGallery) {
  const images = photoGallery.querySelectorAll('.carousel-item');
  photoGallery.dataset.activeImage = 0;

  // Don't do anything if there aren't any photos in the gallery
  if(images.length === 0) return;

  photoGallery.querySelector('.carousel-control-prev').addEventListener('click', () => {
    photoGallery.dataset.activeImage = (parseInt(photoGallery.dataset.activeImage, 10) === 0 ? images.length - 1 : parseInt(photoGallery.dataset.activeImage, 10) - 1);
    showImage(photoGallery, parseInt(photoGallery.dataset.activeImage, 10));
  });

  photoGallery.querySelector('.carousel-control-next').addEventListener('click', () => {
    photoGallery.dataset.activeImage = (parseInt(photoGallery.dataset.activeImage, 10) >= images.length - 1 ? 0 : parseInt(photoGallery.dataset.activeImage, 10) + 1);
    showImage(photoGallery, parseInt(photoGallery.dataset.activeImage, 10));
  });

  const indicators = photoGallery.querySelectorAll('.carousel-indicators button');

  for(let j=0; j<indicators.length; j++) {
    indicators[j].addEventListener('click', () => {
      photoGallery.dataset.activeImage = parseInt(indicators[j].dataset.bsTarget, 10);
      showImage(photoGallery, parseInt(photoGallery.dataset.activeImage, 10));
    });
  }
}

async function fetchUncachedPhotoGallery(photoGallery) {
  const {uncachedPhotoGalleryPath} = photoGallery.dataset;
  const response = await fetch(uncachedPhotoGalleryPath);

  // A response without any uncached photos will be a 204 No-Content
  if(response.status !== 200) {
    markPhotoGalleryAsLoaded(photoGallery.parentNode);
    return;
  }

  const body = await response.text();
  const parent = photoGallery.parentNode;
  photoGallery.outerHTML = body;
  initializePhotoGallery(parent.querySelector('.carousel'));

  markPhotoGalleryAsLoaded(parent);
}

function markPhotoGalleryAsLoaded(photoGalleryParent) {
  // Provide an attribute to tell tests when the uncached photos have been loaded
  photoGalleryParent.querySelector('.carousel').setAttribute('data-uncached-photos-loaded', 'true');
}

function showImage(photoGallery, activeIndex) {
  const images = photoGallery.querySelectorAll('.carousel-item');
  const indicators = photoGallery.querySelectorAll('.carousel-indicators button');

  for(let i=0; i<images.length; i++) {
    images[i].classList.remove('active');
    indicators[i].classList.remove('active');
  }

  images[activeIndex].classList.add('active');
  indicators[activeIndex].classList.add('active');
}
