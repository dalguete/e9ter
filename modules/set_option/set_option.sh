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
echo ";;;; $value"
echo "-ff--${#OPTION__t[@]}*ff**"
  # Store the options in its correct store
  local var="OPTION__$1"
  local array="${var}[@]"
  local o="${!array}"
#    local array2="\"${var}[@]\""
#    eval "${var}=(${!array} \"$value\")"
  eval "${var}=($o \"$value\")"
echo "---${#OPTION__t[@]}***"
echo "---${OPTION__t[@]}***"
  # Remove duplicate. Notice the latest entry will be preserved.
  reverse_array $array 1> /dev/null;
#    local arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)
echo "-aa--${#arrayAux[@]}**aa*"
echo "-aa--${arrayAux[@]}**aa*"

  remove_duplicates_array arrayAux[@] 1> /dev/null;
#    local arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)

  reverse_array arrayAux[@] 1> /dev/null
#    arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)
  eval "${var}=(${arrayAux[@]})"
echo "-zz--${#OPTION__t[@]}**zz*"
echo "-zz--${OPTION__t[@]}**zz*"
}
