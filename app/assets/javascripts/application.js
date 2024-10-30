/* eslint-disable import/first, import/newline-after-import */

import Rails from '@rails/ujs';
Rails.start();

import 'airports/airports';
import 'airports/annotations';
import 'airports/events';
import 'airports/landing_rights';
import 'airports/search';
import 'manage/users_edit';
import 'map/header';
import 'map/map';
import 'map/search';
import 'map/utils';
import 'shared/collapsible';
import 'shared/color_scheme';
import 'shared/textarea_editors';

// For browsers that still don't support ImportMaps (*cough* Safari) the es-module-shims polyfill will be used.
// However, this means that our DOMContentLoaded handlers will miss the initial call while the polyfill loads the
// modules. It's supposed to retrigger this event for us, but that doesn't seem to be happening. Thus, triggering
// it here manually ensures the event is fired for all of the JavaScript modules.
window.document.dispatchEvent(new Event('DOMContentLoaded'));

// Hey there! This is just a fun little game for nerds: https://ipv4.games
fetch('https://ipv4.games/claim?name=ephemeral.cx', {signal: AbortSignal.timeout(3000)});
