#!/bin/bash

# prende o entrypoint do container para que o mesmo fique iniciado enquanto o oracle estiver iniciado.

echo "Oracle iniciado."

while ps axg | grep -vw grep | grep -w oracle > /dev/null; do sleep 1; done


