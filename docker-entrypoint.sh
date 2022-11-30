#!/bin/bash -e

CMD=${1:-./archivesspace.sh}

# Load secrets files into the environment so ASpace can read them
for FILE in /run/secrets/*; do
    if [[ -f "$FILE" ]]; then
        secret_name="$(basename $FILE)";
        export $secret_name="$(cat $FILE | xargs)"
    fi
done

exec "$CMD"
