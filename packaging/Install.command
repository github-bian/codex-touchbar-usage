#!/bin/bash
cd "$(dirname "$0")" || exit 1
status=0
./install.sh || status=$?
if [ "$status" -eq 0 ]; then
  printf '\nInstallation complete. You can close this window.\n'
else
  printf '\nInstallation failed. See the message above.\n'
fi
printf 'Press Return to close this window. '
read -r
exit "$status"
