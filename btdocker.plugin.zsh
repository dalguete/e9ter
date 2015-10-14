#!/bin/sh
#
# A bunch of utilities used to deal with Docker integrations and template conversion,
# in order the get all images and containers in place
#

# Command used to clone a defined recipe as defined in btdocker-templates.
#
# Arguments:
#   recipe. Name of the recipe to extract info from
#
btdocker_clone_recipe() {
  # Helper used to print directly to /dev/tty
  exec 3> /dev/tty

  # Arguments validation.
  if [ $# = 0 -o -z "$1" ]; then
    echo "Expected recipe name" >&2
    return 1
  fi

  # Status message
  #
  # Prevent messing with required output
  # http://stackoverflow.com/a/9405235
  echo "Getting recipe..." >&3

  # Get recipe name
  local recipe=$1

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
    echo "Recipe '$recipe' name not found" >&2
    return 1
  fi

  # Return the folder path found
  echo "$temp/$recipe"
}


btdocker() {
  # A local storage for inner function is started.
  # Whenever a new inner function needs to be defined, the next structure should be used
  #
  #
  #  ###########
  #  #'_abc' inner function definition
  #  #######
  #  _f[${#_f[*]}]="_abc"; . /dev/stdin <<OUTTER
  #  function ${_f[${#_f[*]}-1]}() {
  #  $(cat <<'INNER'
  #    # ... your code goes here ...
  #  }
  #INNER
  #  )
  #OUTTER
  #
  #
  # Notice the value '_abc' should be changed to a unique name, so the function
  # can be used with no problem. Change in the comment too, so you can have a better
  # reference of it.
  # Nothing more than what reads '# ... your code goes here ...' should be changed.
  # The rest of the structure must be preserved as is.
  # Code as you would do in any function, as this is a normal function in the end.
  #
  local _f=()






  # Inner functions collector, used to destroy any inner function defined, as those
  # are mean to be used only under this context.
  for _if in "${_f[@]}"
  do
    unset -f $_if
  done
}
