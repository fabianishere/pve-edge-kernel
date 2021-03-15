#!/bin/bash
# Script to check for new kernel release
set -e
set -o pipefail

MAJOR=$(echo $1 | sed -e "s/^v//" -e "s/\.[^.]*$//")
CURRENT=$(scripts/version.sh -L)
NEW=$(curl -s https://www.kernel.org/releases.json | jq -r ".releases|sort_by(-.released.timestamp)|map(select(.version | startswith(\"$MAJOR\")))|first|.version")

if [[ "$(scripts/version.sh -p)" = "0" ]]; then
    [[ "$(scripts/version.sh -n)" = "$NEW" ]] || echo $NEW
else
    [[ "$CURRENT" = "$NEW" ]] || echo $NEW
fi
