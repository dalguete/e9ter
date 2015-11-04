# Functionality for the die function
#
# Used to print a message to stderr and return an error value.
# It will fail, always.

function die {
  # Just prints to stderr
  if [ "$@" ]; then
    echo "$@" 1>&2
  fi

  exit 1
}
