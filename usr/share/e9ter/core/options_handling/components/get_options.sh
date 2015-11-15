# Functionality for the get_options function
#

# Used to return all stored value item for a given key
function get_options() {
  # Check a key is received
  if [ $# != 1 ]; then
    die "Options repository key needed"
  fi

  # Get the items passed
  local key=$(echo "$1" | tr '-' '_')

  # Get all the options
  local var="OPTION__$key"
  local array="$var[@]"

  # Return array
  printf "%s\n" "${!array}"
}
