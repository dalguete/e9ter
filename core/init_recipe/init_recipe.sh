#!/bin/bash
#
# Functionality for the init_recipe function
#

# Function used to init a clone recipe.
#
# Arguments:
#   recipe. Name of the recipe to extract info from
#
# Returns:
#  nothing on success or a list of non initialized template vars found
#######
function init_recipe() {
  # Performs a clone
  local folder=$(btdocker clone-recipe "${ARGS[@]}")
  if [ -z "$folder" ]; then
    exit 1
  fi

  # Prepare the delimiter
  IFS=$'\n';

  # Get all the stored options
  local options=($(get_options "t"))

  # Loop through every .TEMPLATE file, as those are our targets
  for file in $(find "$folder" -name '*.TEMPLATE'); do 
    # Replace all template vars
    for opt in ${options[@]}; do
      status "...$opt***"
    done

    # Remove .TEMPLATE extension from file
    mv $file ${file%.TEMPLATE}
  done

  # Reset delimiter
  unset IFS

#  { btdocker clone-recipe "${ARGS[@]}" 1> /dev/null; } || exit $?
#    # Error checks performed, based on collected data by _consume
#    if [ ${#ARGS[@]} != 1 ]; then
#      die "Expected recipe name (only one)"
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
#      die "Recipe '$recipe' name not found"
#    fi
#
#    # Return the folder path found
#    echo "$temp/$recipe"
}
