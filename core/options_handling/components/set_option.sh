#!/bin/bash
#
# Functionality for the set_option function
#

# Used to store a value in the correct options store, using the given option key
function set_option() {
  # Check a key and a value are received
  if [ $# != 2 ]; then
    return
  fi

  # Get the value to store
  local value="$2"

  # Store the options in its correct store
  local var="OPTION__$1"
  eval "$var=(\"\${$var[@]}\" \"$value\")"

  # Remove duplicate. When repeated, latest entry will be preserved.
  # As function return array separated by \n, we prepare the same env
  IFS=$'\n'
  local arrayAux=($(reverse_array $var[@]));
  arrayAux=($(remove_duplicates_array arrayAux[@]));
  arrayAux=($(reverse_array arrayAux[@]));

  # Reset delimiter to normal value
  unset IFS
  eval "$var=(\"\${arrayAux[@]}\")"
}
