#!/bin/bash
#
# Functionality for the set_option function
#

# Options data is handled in per option array. To make this compatible with old
# bash version that do not work with assoc arrays.
# Use the format below as an example to store your options:
#
#   OPTION__<option key>=()
#
# Where <option key> will be the option letter
#
# But for now, we have to remove all variable definitions, just to have a complete
# and good experience
for entry in ${!OPTION__*}; do
  unset $entry
done  

# Function used to store the interpretation of an option obtained
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
