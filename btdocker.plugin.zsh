#!/bin/bash
#
# A bunch of utilities used to deal with Docker integrations and template conversion,
# in order the get all images and containers in place; all encapsulated in a single
# command, 'btdocker'.
#
# Operations (*) and options (-) available are:
#
# * clone-recipe: Clone a given recipe
#


# Main operative function where all the magic happens
# This uses a bunch of other function defined internally (give the code a look) just
# to encapsulate functionality, but actually only btdocker is user exposed.
btdocker() {
  # A local storage for inner function is started.
  # Whenever a new inner function needs to be defined, the next structure should be used
  #
  #
  #  ###########
  #  #'<name>' inner function definition
  #  #
  #  # <Description goes here>
  #  #######
  #  _f[${#_f[*]}]="<name>"; . /dev/stdin <<OUTTER
  #  function ${_f[${#_f[*]}-1]}() {
  #  $(cat <<'INNER'
  #    # ... your code goes here ...
  #  }
  #INNER
  #  )
  #OUTTER
  #
  #
  # Notice the value '<name>' should be changed to a unique name, so the function
  # can be used with no problem. Change in the comment too, so you can have a better
  # reference of it.
  # Nothing more than what reads '# ... your code goes here ...' should be changed.
  # The rest of the structure must be preserved as is.
  # Code as you would do in any function, as this is a normal function in the end.
  #
  # As a convenience, in order to exit the process when an error was detected, it's
  # suggested to call function in the form:
  #
  #   { <function call plus params>; } || return $?
  #
  # That way we guarantee that in case of a execution failure, the whole process
  # will exit, no matter how many levels deep.
  #
  local _f=()

  ###########
  #'_die' inner function definition
  #
  # Function used to print a message to stderr and return an error value. This one
  # doesn't follow the usage recommendation above, as this is meant to be as last
  # resort, so it will fail, always.
  #######
  _f[${#_f[*]}]="_die"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[*]}-1]}() {
  $(cat <<'INNER'
    # Just prints to stderr
    echo "$@" 1>&2
    return 1
  }
INNER
  )
OUTTER

  # Some general vars are defined, to effectively know what the script should do.
  OPERATION=
  ARGS=()

  ###########
  #'_consume' inner function definition
  #
  # Function used to consume the different operations and operations passed
  #######
  _f[${#_f[*]}]="_consume"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[*]}-1]}() {
  $(cat <<'INNER'
    # Check values passed to main function
    if [ ! $# ]; then
      { _die "No args passed"; } || return $?
    fi
    if [ -z "$1" ]; then
      { _die "No operation defined"; } || return $?
    fi

    # Set the main operation to use.
    OPERATION=$1
    shift

    # Check the operation is a valid one, and assoc it valid function name to call
    case "$OPERATION" in
      clone-recipe)
        OPERATION="_clone_recipe"
        ;;

      *)
        { _die "Operation not recognized"; } || return $?
    esac

    # Consume options
    local args=`getopt abo: $*`
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
  }
INNER
  )
OUTTER

  ###########
  #'_clone_recipe' inner function definition
  #
  # Function used to clone a defined recipe as defined in btdocker-templates.
  #
  # Arguments:
  #   recipe. Name of the recipe to extract info from
  #
  # Returns:
  #  folder path of cloned recipe or nothing if not found
  #######
  _f[${#_f[*]}]="_clone_recipe"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[*]}-1]}() {
  $(cat <<'INNER'
    # Error checks performed, based on collected data by _consume
    if [ ${#ARGS[@]} != 1 ]; then
      { _die "Expected recipe name (only one)"; } || return $?
    fi

    # Get the recipe name
    local recipe=${ARGS[0]}

    # Helper used to print directly to /dev/tty
    exec 3> /dev/tty

    # Status message
    #
    # Prevent messing with required output
    # http://stackoverflow.com/a/9405235
    echo "Getting recipe..." >&3

    # Clone recipe folder from repo.
    #
    # Idea took from http://stackoverflow.com/a/13738951
    #
    local temp=$(mktemp -d)
    pushd $temp &> /dev/null
    git init -q
    git remote add -f origin git@github.com:bluetent/btdocker-templates.git &> /dev/null
    git config core.sparsecheckout true
    echo "$recipe" >> .git/info/sparse-checkout
    git pull -q origin master &> /dev/null
    popd &> /dev/null

    # Recipe not found, report it
    if [ ! -d "$temp/$recipe" ]; then
      { _die "Recipe '$recipe' name not found"; } || return $?
    fi

    # Return the folder path found
    echo "$temp/$recipe"
  }
INNER
  )
OUTTER

  ###################
  # ALL STARTS HERE #
  ###################
  { _consume "$@"; } || return $?

  # Call the operation function
  if [ -n "$OPERATION" ]; then
    { $OPERATION; } || return $?
  fi

  # Inner functions collector, used to destroy any inner function defined, as those
  # are mean to be used only under this context.
  for _if in "${_f[@]}"
  do
    unset -f $_if
  done
}
