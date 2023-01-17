document.addEventListener('DOMContentLoaded', () => {
  initializePhotoGalleries();
}, {once: true});

export function initializePhotoGalleries() {
  const photoGalleries = document.getElementsByClassName('carousel');

  for(let i=0; i<photoGalleries.length; i++) {
    const photoGallery = photoGalleries[i];
    const images = photoGallery.querySelectorAll('.carousel-item');
    photoGallery.dataset.activeImage = 0;

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
