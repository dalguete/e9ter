# Functionality for the remove_option function
#

# Used to remove a given stored value item for a given key
function remove_option() {
  # Check a key is received
  if [ $# -lt 2 ]; then
    die "Required options key storage to check value existence against"
  fi

  # Get the items passed
  local key=$(echo "$1" | tr '-' '_')
  local value="$2"

  # Get the options store place
  local var="OPTION__$key"

  # Loop through the option obtained to remove the desired one
  local array="$var[@]"
  local newArray=()

  for op in "${!array}"; do
    if [[ "$op" != "$value" ]]; then
      newArray[${#newArray[@]}]="$op"
    fi
  done

  # Reassing the new array formed
  eval "$var=(\"\${newArray[@]}\")"
}

