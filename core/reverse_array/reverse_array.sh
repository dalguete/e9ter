#!/usr/bin/env bash
#
# Functionality for the reverse_array function
#

# Utility function used to reverse a given array.
# Caller must pass array var in the form array[@] (not quotes, no dollar sign)
function reverse_array() {
  # Reverse the array string data passed
  local array=("${!1}")
  local revarray=()

  for item in "${array[@]}"
  do
    revarray=("$item" "${revarray[@]}")
  done

  # Return array reversed
  printf "%s\n" "${revarray[@]}"
}
