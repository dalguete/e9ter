# Functionality for the reset_options function
#

# Used to remove all options for a given key
function reset_options() {
  # Check a key is received
  if [ $# != 1 ]; then
    die "Options repository key needed"
  fi

  # Get the items passed
  local key=$(echo "$1" | tr '-' '_')

  # Reset the options
  local var="OPTION__$key"
  eval "$var=()"
}

