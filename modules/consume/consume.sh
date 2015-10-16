#!/bin/bash
#
# Functionality for the consume function
#

# Some general vars are defined, to effectively know what the script should do.
OPERATION=
ARGS=()

# Function used to consume the different operations and operations passed
function consume() {
  # Check values passed to main function
  if [ ! $# ]; then
    die "No args passed"
  fi
  if [ -z "$1" ]; then
    die "No operation defined"
  fi

  # Set the main operation to use.
  OPERATION=$1
  shift

  # Check the operation is a valid one, and assoc it valid function name to call
  case "$OPERATION" in
    clone-recipe)
      OPERATION="clone_recipe"
      ;;

    init-recipe)
      OPERATION="init_recipe"
      ;;

    *)
      die "Operation not recognized"
  esac

  # Consume options
  local args=`getopt -o t: -q -- "$@"`
  # Note the quotes around $args: they are essential!
  eval set -- "$args"

  # Process all input data
  while [ $# -gt 0 ]
  do
    case "$1" in
#        -h|--help) # General help.
#          _set_main_function "help"
#          ;;
#
#        -s|--status) # Display the status.
#          _set_main_function "status"
#          ;;
#
#        --init) # Initializes the githooks space.
#          _set_main_function "init"
#          ;;
#
#        --destroy) # Restores the git hooks space to its natural form.
#          _set_main_function "destroy"
#          ;;
#
#        -1|--on) # Activate a given hook.
#          _set_main_function "activate"
#          ;;
#
#        -0|--off) # Deactivate a given hook.
#          _set_main_function "deactivate"
#          ;;
#
#        -a|--add) # Add a new hook file entry.
#          _set_main_function "add"
#          ;;
#
#        --do-edit) # Open the favorite editor after creating the hook file entry.
#          _set_flag 'do-edit' 1
#          ;;
#
#        --do-add) # Create the script file if doens't exist, on edit.
#          _set_flag 'do-add' 1
#          ;;
#
#        -e|--edit) # Edit hook file entry.
#          _set_main_function "edit"
#          ;;
#
#        -d|--delete) # Delete hook file entry.
#          _set_main_function "delete"
#          ;;
#
#        -t) # Indicates it should process the trackedhooks/ folder.
#          _set_flag 'from-trackedhooks-folder' 1
#          ;;
#
#        -y) # Indicates any question to user will be answered yes, no asking.
#          _set_flag 'yes' 1
#          ;;

      -t) # Store the template key:value passed
        set_option "t" "$2"
        set_option "t" "es content"
        shift
        ;;

      --) # This is not considered.
        ;;

      *) # Anything trapped here is considered an argument.
        if [ -z "$1" ]; then
          # Empty data is discarded.
          shift
          continue;
        fi

        ARGS[${#ARGS[*]}]="$1"
        ;;
    esac

    shift
  done

  # Call the operation function
  if [ -n "$OPERATION" ]; then
    $OPERATION
  fi
}
