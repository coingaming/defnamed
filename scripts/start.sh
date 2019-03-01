#!/bin/bash

set -e

iex \
  --erl "+K true +A 32" \
  --erl "-kernel inet_dist_listen_min 9100" \
  --erl "-kernel inet_dist_listen_max 9199" \
  --erl "-kernel shell_history enabled" \
  -S mix
