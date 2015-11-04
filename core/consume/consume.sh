# Functionality for the consume function
#

# Some general vars are defined, to effectively know what the script should do.
OPERATION=
ARGS=()

# Function used to consume the different operations and operations passed
function consume() {
  # Check values passed to main function
  if [ -z "$1" ]; then
    die "No operation defined"
  fi

  # Set the main operation to use.
  OPERATION=$(get_operation_data "$1")
  if [ -z "$OPERATION" ]; then
    die
  fi

  # Get operation handling info
  local _short=$(get_operation_data "$1" "short options")
  local _long=$(get_operation_data "$1" "long options")
  local _usage=$(get_operation_data "$1" "usage")
  local _consume=$(get_operation_data "$1" "consume")

  # Operation argument is no longer needed
  shift

  # Consume options. getopt transformation is called twice, first for error checkings
  # and second for actual processing
  crossos getopt -o $_short -l $_long -q -- "$@" &> /dev/null
  if [ $? -ne 0 ]; then
    $_usage
  fi

  local args=$(crossos getopt -o $_short -l $_long -q -- "$@")

  # Important to exec the eval here, as a loop latter is using positional parameters
  # to consume arguments (see below)
  eval set -- "$args"

  # Before consuming, ensure all arguments passed, when using spaces, can be treated
  # as a whole thing.
  # http://stackoverflow.com/a/1669493
  local fixed_args=()
  local whitespace="[[:space:]]"

  for arg in "$@"; do
    if [[ $arg =~ $whitespace ]]; then
      # Single quotes are used instead of double ones, to prevent incorrect variable expansion
      arg=\'$arg\'
#      arg=\'$(echo "$arg" | sed "s/'/\\\'/g")\'
    fi
    fixed_args=("${fixed_args[@]}" "$arg")
  done

  # Consume options in operation
  $_consume "${fixed_args[@]}"

  # Process arguments only
  local start_consuming=0

  while [ $# -gt 0 ]
  do
    case "$1" in
      --) # This is just used as an indicator of arguments section 'is coming'
        start_consuming=1
        ;;

      *) # Anything trapped here is considered an argument.
        if [[ $start_consuming = 0 || -z "$1" ]]; then
          # Not started consumption or no data, means discard.
          shift
          continue;
        fi

        ARGS[${#ARGS[*]}]="$1"
        ;;
    esac

    shift
  done

  # Call the operation function
  if [ "$OPERATION" ]; then
    $OPERATION
  fi
}
