#!/bin/bash
#
# A bunch of utilities used to deal with Docker integrations and template conversion,
# in order the get all images and containers in place; all encapsulated in a single
# command, 'btdocker'.
#
# USAGE OPTIONS
# -------------
#
#  clone-recipe <recipe-name>
#     Clone a given recipe.
#
#  init-recipe <recipe-name> [-t <template-var-key>:<value>]*
#     Init template vars found in a cloned recipe, using given vars
#


# Main operative function where all the magic happens
# This uses a bunch of other function defined internally (give the code a look) just
# to encapsulate functionality, but actually only this one is user exposed.
btdocker() {
  ###################################
  # Start almost unnoticed subshell #
  ###################################
  # This is key, to let inner processes use the main function to get results.
  # This causes the whole processing to be run in an isolated new subshell,
  # avoiding pollute shell with vars, and second and most important giving the chance
  # for inner processes to directly call the main functionwith total confidence, knowing
  # that changes made there won't affect variables already set in a current call.
  # Without this, any inner main function call would override variables set in parent
  # call, possible producing undesirable results.
  (

  # A local storage for inner functions is started. See below for more info on inner
  # functions
  local _f=()

  # About Inner Functions
  # Whenever a new inner function needs to be defined, the next structure should be used:
  #
  #
  #  ###########
  #  #'<name>' inner function definition
  #  #
  #  # <Description goes here>
  #  #######
  #  _f[${#_f[@]}]="<name>"; . /dev/stdin <<OUTTER
  #  function ${_f[${#_f[@]}-1]}() {
  #  $(cat <<'INNER'
  #    # ... your code goes here ...
  #INNER
  #  )
  #  }
  #OUTTER
  #
  #
  # Notice the value '<name>' should be changed to a unique name, so the function
  # can be used with no problem. Change in the comment too, so you can have a better
  # reference of it.
  # Nothing more than what reads '# ... your code goes here ...' should be changed.
  # The rest of the structure must be preserved as is.
  # Code as you would do in any function, as this is a normal function.
  #
  # Now, to return info from the function, just use traditional methods like echo
  # or similar. The idea is this functions to be used in pipes.
  #
  # Talking about error handling, as everything in run in a subshell, error can
  # be reported with 'exit' instead of return, and actually that's the recommended
  # way (if you wanna use return, be warned your function won't be as usable as
  # you'd like, as user will have to do custom checks)
  # When calling main function internally, you must be aware you'll have to do further
  # error checks to decide if the execution must stop or continue. Exiting a main
  # function call won't halt the process, because it's contained in a subshell; while
  # exiting any other function will actually do.
  #
  # As a convenience, when dealing with main function call, the next format for
  # error handling is suggested:
  #
  #   { <function call plus params>; } || exit $?
  #
  # That way we guarantee that in case of a execution failure, the whole process
  # will exit, no matter how many levels deep. Obviously you can turn the bracketed
  # code, in something a lot more complex.

  ###########
  #'_die' inner function definition
  #
  # Function used to print a message to stderr and return an error value.
  # It will fail, always.
  #######
  _f[${#_f[@]}]="_die"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Just prints to stderr
    echo "$@" 1>&2
    exit 1
INNER
  )
  }
OUTTER

  ###########
  #'_status' inner function definition
  #
  # Function used to print a message directly /dev/tty, without messing with stdout
  # or stderr. Useful for those user aimed messages
  #######
  _f[${#_f[@]}]="_status"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Just prints to stderr
    # http://stackoverflow.com/a/9405235
    echo "$@" 1> /dev/tty
INNER
  )
  }
OUTTER

  ###########
  #'_reverse_array' inner function definition
  #
  # Utility function used to reverse a given array. Must supply its string form, 
  # like "${array[*]}" for this to work
  #######
  _f[${#_f[@]}]="_reverse_array"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Reverse the array string data passed
    local array=("${!1}")
    local revarray=()

    for item in "${array[@]}"
    do
      revarray=("$item" "${revarray[@]}")
    done

    # Return array reversed
    printf "%s\n" "${revarray[@]}"
INNER
  )
  }
OUTTER

  ###########
  #'_remove_duplicates_array' inner function definition
  #
  # Utility function used to remove duplicate entries in an array. Must supply its
  # string form, like "${array[*]}" for this to work
  #######
  _f[${#_f[@]}]="_remove_duplicates_array"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
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
INNER
  )
  }
OUTTER

  # Some general vars are defined, to effectively know what the script should do.
  OPERATION=
  ARGS=()
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

  ###########
  #'_set_option' inner function definition
  #
  # Function used to store the interpretation of an option obtained
  #######
  _f[${#_f[@]}]="_set_option"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
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
    _reverse_array $array 1> /dev/null;
#    local arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)
echo "-aa--${#arrayAux[@]}**aa*"
echo "-aa--${arrayAux[@]}**aa*"

    _remove_duplicates_array arrayAux[@] 1> /dev/null;
#    local arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)

    _reverse_array arrayAux[@] 1> /dev/null
#    arrayAux=(`cat $_BTDOCKER_LAST_RESULT`)
    eval "${var}=(${arrayAux[@]})"
echo "-zz--${#OPTION__t[@]}**zz*"
echo "-zz--${OPTION__t[@]}**zz*"
INNER
  )
  }
OUTTER

  ###########
  #'_consume' inner function definition
  #
  # Function used to consume the different operations and operations passed
  #######
  _f[${#_f[@]}]="_consume"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Check values passed to main function
    if [ ! $# ]; then
      _die "No args passed"
    fi
    if [ -z "$1" ]; then
      _die "No operation defined"
    fi

    # Set the main operation to use.
    OPERATION=$1
    shift

    # Check the operation is a valid one, and assoc it valid function name to call
    case "$OPERATION" in
      clone-recipe)
        OPERATION="_clone_recipe"
        ;;

      init-recipe)
        OPERATION="_init_recipe"
        ;;

      *)
        _die "Operation not recognized"
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
          _set_option "t" "$2"
          _set_option "t" "es content"
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
INNER
  )
  }
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
  #  folder path of cloned recipe or nothing if not found. The recipe will be
  #  cloned in the current folder
  #######
  _f[${#_f[@]}]="_clone_recipe"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Error checks performed, based on collected data by _consume
    if [ ${#ARGS[@]} != 1 ]; then
      _die "Expected recipe name (only one)"
    fi

    # Get the recipe name
    local recipe=${ARGS[0]}

    # Status message
    _status "Getting recipe..."

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
      _die "Recipe '$recipe' name not found"
    fi

    # Move the cloned folder to the current directory
    rm -rf "`pwd`/$recipe" &> /dev/null
    mv "$temp/$recipe" .

    # Remove temp folder
    rm -rf $temp

    # Return the folder path found
    echo "`pwd`/$recipe"
INNER
  )
  }
OUTTER

  ###########
  #'_init_recipe' inner function definition
  #
  # Function used to init a clone recipe.
  #
  # Arguments:
  #   recipe. Name of the recipe to extract info from
  #
  # Returns:
  #  nothing on success or a list of non initialized template vars found
  #######
  _f[${#_f[@]}]="_init_recipe"; . /dev/stdin <<OUTTER
  function ${_f[${#_f[@]}-1]}() {
  $(cat <<'INNER'
    # Performs a clone
    { btdocker clone-recipe "${ARGS[@]}" 1> /dev/null; } || exit $?
echo "${OPTION__t[@]}"
echo "${#OPTION__t[@]}"
#    # Error checks performed, based on collected data by _consume
#    if [ ${#ARGS[@]} != 1 ]; then
#      _die "Expected recipe name (only one)"
#    fi
#
#    # Get the recipe name
#    local recipe=${ARGS[0]}
#
#    # Helper used to print directly to /dev/tty
#    exec 3> /dev/tty
#
#    # Status message
#    #
#    # Prevent messing with required output
#    # http://stackoverflow.com/a/9405235
#    echo "Getting recipe..." >&3
#
#    # Clone recipe folder from repo.
#    #
#    # Idea took from http://stackoverflow.com/a/13738951
#    #
#    local temp=$(mktemp -d)
#    pushd $temp &> /dev/null
#    git init -q
#    git remote add -f origin git@github.com:bluetent/btdocker-templates.git &> /dev/null
#    git config core.sparsecheckout true
#    echo "$recipe" >> .git/info/sparse-checkout
#    git pull -q origin master &> /dev/null
#    popd &> /dev/null
#
#    # Recipe not found, report it
#    if [ ! -d "$temp/$recipe" ]; then
#      _die "Recipe '$recipe' name not found"
#    fi
#
#    # Return the folder path found
#    echo "$temp/$recipe"
INNER
  )
  }
OUTTER

  ###################
  # ALL STARTS HERE #
  ###################
  _consume "$@"

  # Call the operation function
  if [ -n "$OPERATION" ]; then
    $OPERATION
  fi

  # Inner functions collector, used to destroy any inner function defined, as those
  # are mean to be used only under this context.
  for _if in "${_f[@]}"
  do
    unset -f $_if
  done

  ##########################################
  # Finish almost unnoticed subshell start #
  ##########################################
  )
}
