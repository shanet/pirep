#!/bin/bash

bundle exec good_job start &
puma --config config/puma.rb
