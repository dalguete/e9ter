#!/usr/bin/env bash
#
# Functionality for the init_recipe function
#

# Function used to init a cloned recipe from source, into current or specified folder
#
# Operation:
#   init-recipe 
#
# Arguments:
#  <recipe-name> [-n <version>] [-s <source>] [-t <template-var-key>:<value>]* [<destination>]
#     Init a given recipe.
#     A specific version can be defined, if not, the default one as set in recipe
#     repository will be used.
#     Set a different repository as recipe source. By default '$E9TER_MAIN_RECIPES_REPO'
#     will be used.
#     Template var definitions in recipe will be replaced with data passed
#     Destination can be defined, if not, current working directory will be used
function init_recipe() {
  btdocker clone-recipe "${ARGS[0]}"


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
}
