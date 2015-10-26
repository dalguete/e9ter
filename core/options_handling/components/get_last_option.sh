#!/usr/bin/env bash
#
# Functionality for the get_last_option function
#

# Used to return the last option stored value item for a given key
function get_last_option() {
  # Check a key is received
  if [ $# != 1 ]; then
    die "Options repository key needed"
  fi

  # Get all the options
  local option=
  local options=($(get_options "$1"))
  if [ "${options[*]}" ]; then
    option=${options[${#options[@]}-1]}
  fi

  # Return the option found, if any
  echo $option
}
