/* eslint-disable import/first, import/newline-after-import */

import Rails from '@rails/ujs';
Rails.start();

import 'airports/airports';
import 'airports/annotations';
import 'airports/events';
import 'airports/landing_rights';
import 'manage/users_edit';
import 'map/header';
import 'map/map';
import 'map/search';
import 'map/utils';
import 'shared/textarea_editors';

// For browsers that still don't support ImportMaps (*cough* Safari) the es-module-shims polyfill will be used.
// However, this means that our DOMContentLoaded handlers will miss the initial call while the polyfill loads the
// modules. It's supposed to retrigger this event for us, but that doesn't seem to be happening. Thus, triggering
// it here manually ensures the event is fired for all of the JavaScript modules.
window.document.dispatchEvent(new Event('DOMContentLoaded'));
