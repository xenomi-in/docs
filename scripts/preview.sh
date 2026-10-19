#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ -f .local-gems/bin/bundle ]; then
  export GEM_HOME="$PWD/.local-gems"
  export GEM_PATH="$PWD/.local-gems"
  exec ruby .local-gems/bin/bundle exec jekyll serve --host 127.0.0.1 --baseurl "" "$@"
fi
exec bundle exec jekyll serve --host 127.0.0.1 --baseurl "" "$@"
