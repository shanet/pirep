FROM ruby:3.4.1-slim-bookworm AS base

ARG PORT=8080

ENV \
  BUNDLE_WITHOUT="development test" \
  RAILS_ENV=production \
  RAILS_LOG_TO_STDOUT=true \
  RAILS_SERVE_STATIC_FILES=true \
  RUBY_YJIT_ENABLE=1
  # GOOD_JOB_PROBE_PORT=${PORT} \

WORKDIR /srv/http

RUN apt-get update && apt-get upgrade --yes
RUN apt-get install --yes --no-install-recommends \
  chromium \
  curl \
  dnsutils \
  fish \
  gdal-bin \
  gnupg \
  htop \
  libjemalloc2 \
  libpq-dev \
  libvips \
  nano \
  unzip

# Install Postgres client
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --output /usr/share/keyrings/postgresql.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/postgresql.list
RUN apt-get update && apt-get install --yes postgresql-client-14

# Install NodeJS
RUN curl https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --output /usr/share/keyrings/nodejs.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nodejs.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodejs.list
RUN apt-get update && apt-get install --yes nodejs

# -----------------------------------------------------------------------------
FROM base AS build

RUN apt-get install --yes build-essential

# Install Yarn
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor --output /usr/share/keyrings/yarn.gpg
RUN echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/yarn.gpg] http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install --yes yarn

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
COPY package.json package.json

RUN bundle install
RUN yarn install

COPY . .
RUN SECRET_KEY_BASE=1 bundle exec rails assets:precompile

# # -----------------------------------------------------------------------------
# Do everything above in a separate stage so we can only copy out the compiled assets and discard all the other junk we don't need to run the application
FROM base AS final

# Use jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# The UID and GID should match the values in the EFS config (efs.tf)
RUN addgroup --gid 1000 pirep
RUN adduser --shell /bin/fish --disabled-password --gecos "" --uid 1000 --gid 1000 pirep

# Copy the application code and compiled assets & gems from the previous stage
COPY . .
COPY --from=build /srv/http/node_modules node_modules
COPY --from=build /srv/http/public/assets public/assets
COPY --from=build /usr/local/bundle /usr/local/bundle

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app lib

# Create the symlink for the airports cache directory to the EFS volume
RUN ln -s /mnt/efs/airports_cache public/assets/airports_cache

# Set fish shell preferences
RUN fish --command "set --universal fish_greeting \"\""

RUN chown -R pirep:pirep .
USER pirep

EXPOSE ${PORT}

# The command is set in the task definition as an override since it will vary per service
CMD []
