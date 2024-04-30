#!/bin/bash

bundle exec good_job start --daemonize
puma --config config/puma.rb
