#!/usr/bin/env bash
#
# Functionality for the get_options function
#

# Used to return all stored value item for a given key
function get_options() {
  # Check a key is received
  if [ $# != 1 ]; then
    return
  fi

  # Get all the options
  local var="OPTION__$1"
  local array="$var[@]"

  # Return array
  printf "%s\n" "${!array}"
}
