# Functionality for the set_operation function
#
# Arguments:
#  <name> [<getopt short options string>] [<getopt long options string>]
#   Name of the function to register
#   The short options string to be consumed by getopt command can be supplied. Must
#   be handled in your implementation of _consume function
#   The long options string to be consumed by getopt command can be supplied. Must
#   be handled in your implementation of _consume function
#

# Used to register an operation
function set_operation() {
  # Check at least a name is given
  if [ ! $# ]; then
    die "No operation name passed to register"
  fi

  # Get some defaults
  local operation=$(echo "$1" | tr '-' '_')
  local short_options=${2:-""}
  local long_options=${3:-""}

  # Process the operation set, only if operation not found previously
  if [[ $(is_option "operations" "$1") == 1 ]]; then
    die "Operation '${1}' already set"
  fi

  # Store the operation
  set_option "operations" $operation

  # Store the operation getopt string handling
  set_option "operation_${operation}_short_options" $short_options
  set_option "operation_${operation}_long_options" $long_options  

  # Store the operation util functions
  set_option "operation_${operation}_usage" "${operation}_usage"
  set_option "operation_${operation}_consume" "${operation}_consume"
}

