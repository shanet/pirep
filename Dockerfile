FROM ruby:3.2.2-slim-bullseye AS base

ARG PORT=8080

ENV \
  BUNDLE_WITHOUT="development test" \
  GOOD_JOB_PROBE_PORT=${PORT} \
  RAILS_ENV=production \
  RAILS_LOG_TO_STDOUT=true \
  RAILS_SERVE_STATIC_FILES=true \
  RUBY_YJIT_ENABLE=1

WORKDIR /srv/http

RUN apt-get update && apt-get upgrade --yes
RUN apt-get install --yes \
  curl \
  dnsutils \
  gnupg \
  htop \
  libjemalloc2 \
  libpq-dev \
  libvips \
  nano \
  unzip \
  zsh

# Install Postgres client
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/postgres.list
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install --yes postgresql-client-14

# Install a newer version of GDAL (version >= 3.6.2, we may be able to go back to stable in a future Debian version)
RUN mv /etc/apt/sources.list /etc/apt/sources.list.d/stable.list
RUN cat /etc/apt/sources.list.d/stable.list | sed "s/bullseye/testing/" > /etc/apt/sources.list.d/testing.list
RUN apt-get update && apt-get install --yes --target-release testing gdal-bin

# -----------------------------------------------------------------------------
FROM base AS build

RUN apt-get install --yes build-essential

# Install NodeJS
RUN echo "deb https://deb.nodesource.com/node_18.x bullseye main" > /etc/apt/sources.list.d/node.list
RUN curl https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

# Install Yarn
RUN echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -

RUN apt-get update && apt-get install --yes nodejs yarn

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
RUN adduser --shell /bin/zsh --disabled-password --gecos "" --uid 1000 --gid 1000 pirep

# Set some nice zsh preferences for SSH shells
COPY scripts/zshrc /root/.zshrc
COPY scripts/zshrc /home/pirep/.zshrc

# Copy the application code and compiled assets & gems from the previous stage
COPY . .
COPY --from=build /srv/http/public/assets public/assets
COPY --from=build /usr/local/bundle /usr/local/bundle

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app lib

# Create the symlink for the airports cache directory to the EFS volume
RUN ln -s /mnt/efs/airports_cache public/assets/airports_cache

RUN chown -R pirep:pirep .
USER pirep
EXPOSE ${PORT}

# The command is set in the task definition as an override since it will vary per service
CMD []
