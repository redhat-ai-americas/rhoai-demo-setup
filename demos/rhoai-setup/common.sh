#!/bin/bash

retry(){
  local attempts=30
  local delay=20

  echo "Running:" "${@}"
  echo "Attempts:  ${attempts}"
  echo "Delay:     ${delay}s"

  # until "${@}" 1>&2
  until "${@}"
  do
    if [[ $attempts -gt "1" ]]; then
      ((attempts--))
      echo "Remaining attempts: $attempts - waiting ${delay}s"
      sleep $delay
    else
      echo "[FAILED]"
        return 1
    fi
  done
  echo "[OK]"
}