# Functionality for the remove_duplicates_array function
#

# Utility function used to remove duplicate entries in an array.
# Caller must pass array var in the form array[@] (not quotes, no dollar sign)
function remove_duplicates_array() {
  # Remove duplicates in the array string data passed
  local array=("${!1}")

  for (( i=0; i<${#array[@]}; i++ ));
  do
    for (( j=$((i+1)); j<${#array[@]}; j++ ));
    do
      if [ "${array[$i]}" = "${array[$j]}" ]; then
        unset array[$j]
      fi
    done
  done

  # Return array
  printf "%s\n" "${array[@]}"
}
