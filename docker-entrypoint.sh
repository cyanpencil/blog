#!/usr/bin/env bash
set -euo pipefail

# When bind-mounting the site into /site, the container image's bundle
# may not match the mounted Gemfile.lock. Ensure gems are present.
bundle check >/dev/null 2>&1 || bundle install

exec "$@"
