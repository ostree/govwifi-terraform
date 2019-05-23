#!/bin/bash
set -euo pipefail

command="$1"
files=$(find .private/passwords/secrets-to-copy -type f -name '*.gpg')
for FILE in $files; do
  UNENCRYPTED_FILE_GPG=${FILE#.private/passwords/secrets-to-copy/}
  UNENCRYPTED_FILE=${UNENCRYPTED_FILE_GPG%.gpg}
  echo $UNENCRYPTED_FILE
  if [ "$command" == "unencrypt" ]; then
  PASSWORD_STORE_DIR=.private/passwords pass "secrets-to-copy/${UNENCRYPTED_FILE}" > $UNENCRYPTED_FILE
  elif [ "$command" == "delete" ]; then
    rm $UNENCRYPTED_FILE 
  fi
done
