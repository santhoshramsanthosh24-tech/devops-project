#!/bin/bash
ln -sf /usr/bin/docker /usr/local/bin/docker || true
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"