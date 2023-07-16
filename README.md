![](/public/error_logo.png?raw=true#gh-light-mode-only)
![](/public/error_logo_light.png?raw=true#gh-dark-mode-only)

Pirep
=====

Pirep is a free, collaborative database of all public and private airports located within the United States. All pilots are welcome to contribute, edit, and improve any airport they have local knowledge about, no registration required.

While there are a handful of other websites that contain databases like this, none of them allow for open contributions. Pirep brings together information from a multitude of public sources combined with user contributions to create a database of local airport knowledge accessible in one location. The main navigation for the website is the map which encourages exploration of new destinations pilots may have not considered visiting before.

[![CI](https://github.com/shanet/pirep/actions/workflows/ci.yml/badge.svg)](https://github.com/shanet/pirep/actions/workflows/ci.yml)
[![View performance data on Skylight](https://badges.skylight.io/typical/71SQvzBzGg2M.svg?token=7Bj4x27asMBxs2BZlnIRqX-yJrQ5LCCojLJwpfAg8e4)](https://oss.skylight.io/app/applications/71SQvzBzGg2M/recent/5m/endpoints)

## Philosophy

Pirep is intended to be a minimalist website. Its development adheres to the following high-level principles:

* Prefer a heavy backend with a lightweight frontend.
* Use third party libraries sparingly and only where strictly necessary to avoid bloat and abandonware.

To those ends, Pirep is written as a Rails application that follows Rails conventions as closely as possible. Minimal third party gems are used only where they provide a large degree of value. For example, Devise for user authentication, Papertrail for record versioning, and GoodJob for background job processing.

For the frontend, Pirep makes use of only vanilla JavaScript. Through the use of Importmaps there is no transpiling or asset pack compilation. The only JavaScript libraries used are Mapbox for the sectional charts and [EasyMDE](https://github.com/Ionaru/easy-markdown-editor) for a WYSIWYG markdown editor. For CSS, Bootstrap is used and is compiled via Dart Sass for the frontend. In general, AJAX is used sparingly only where it provides significant UX benefits. Otherwise, full page renders are preferred for operations and general browsing of the website.

## Development Environment Setup

### Prerequisites

* Ruby (the expected version is defined in `.ruby-version`, `rvm`, `rbenv`, `asdf`, or any other version manager can install the correct version)
* Postgres (14.6 is currently used, but fairly standard SQL is used everywhere so other minor versions should be fine too)
* [GDAL](https://gdal.org) version >= 3.6.2 for generating sectional chart map tiles (older versions will generate bad looking map tiles)
  * Some distributions may require an additional `python-gdal` package too depending on where the `gdal2tiles.py` script is included
* [libvips](https://www.libvips.org) for converting airport diagram PDFs to PNGs and processing user photo uploads
* Yarn version 1.x

Pirep's development has been done on Linux. Other operating systems may work but have not been tested.

Postgres initial setup if not already configured (some distros, such as Debian/Ubuntu, will do this as part of the package install):

```
sudo su - postgres -c "initdb --locale en_US.UTF-8 -D '/var/lib/postgres/data'"
sudo systemctl start postgresql
```

### Third Party API Credentials

Two third-party APIs are used that you may want to set credentials for in order for them to work locally. The application will run without them, but not all features will work.

* Mapbox: Mapbox is used extensively for the core functionality of the application's home page. It is recommended to set a Mapbox access key for development, although the application will still work without one set. With a Mapbox account, a free access token can be created at https://account.mapbox.com/access-tokens.
* Google Place Photos API: Google Photos is used to get photos of airports for display. Skipping this is recommended for development as this is only a small feature and getting a Google Photos API key is a hassle. See [Google's documentation](https://developers.google.com/maps/documentation/places/web-service/get-api-key) for getting an API key if desired, however.

To set these credentials run `rails credentials:edit --environment development` and enter the following:

```
google_api_key: [Google Place Photos API key]
mapbox_api_key: [Mapbox access token]
```

### Setup

```
git clone git@github.com:shanet/pirep.git
bundle install
yarn install
sudo -u postgres createuser --createdb `whoami`  # Potentially not needed if this default user & database already exists
rails db:create
rails db:schema:load
rails db:seed                                    # Note the admin account credentials that will be printed
bin/dev                                          # Starts web server, Dart SASS compiler, and background jobs runner
```

The server will be running on `http://localhost:3000`.

### Importing FAA Products & Generating Maps Tiles

The `rails db:seed` task will prompt which FAA products to initially download. Generating map tiles for all sectional charts will require about 10gb of disk space and take hours to fully generate. Because of this you may only want to generate tiles for one or two sectional charts. The `db:seed` task will prompt for this.

#### Updating FAA Products

Updating to a new data cycle is an automated process, but must be started manually in development. Running `rails db:seed` again is sufficient to update to the next data cycle or re-import the existing one by following the prompts.

#### Cache

In order to avoid downloading large files from the FAA's servers unnecessarily a cache exists in `.faa_cache` with the archives of sectional charts and airport diagrams. If you wish to download new archives simply delete this directory.

### Running Tests

* Unit tests can be run with `rails test`.
* Unit tests and integration/system tests are run with `rails test:all`.
* Linters & security checks are run with `rails lint`.
* All pull requests should have passing tests before merged.

Integration/system tests are written with Capybara. `HEADLESS=false` can be used to show the browser while running tests for debugging. Note that failed Capybara tests are not re-run purposefully on CI. Flakes, when found, should be addressed immediately to avoid a build up of flakes hidden behind test re-runs.

## Runbook

See [`docs/runbook.md`](docs/runbook.md) for runbook information on production management & deployments.

## License

AGPLv3
