#!/bin/bash
#
# Functionality for the clone_recipe function
#

# Function used to clone a defined recipe from source.
#
# Arguments:
#   recipe. Name of the recipe to extract info from
#   version (optional). Recipe version to use
#
# Returns:
#  folder path of cloned recipe or nothing if not found. The recipe will be
#  cloned in the current folder
function clone_recipe() {
  # Error checks performed
  if [ -z "${ARGS[*]}" ]; then
    die "Expected recipe name"
  fi

  # Get recipe name
  local recipe=${ARGS[0]}

  # Get the version to work with
  local version=
  local versions=($(get_options "n"))
  if [ "${versions[*]}" ]; then
    version=${versions[${#versions[@]}-1]}
  fi

  # Get the source to work with
  local source="$E9TER_MAIN_RECIPES_REPO"
  local sources=($(get_options "s"))
  if [ "${sources[*]}" ]; then
    sources=${sources[${#sources[@]}-1]}
  fi

  # Get destination
  local destination=${ARGS[1]:-"."}

  # Status message
  status "Getting '$recipe' recipe..."

  # Helper storage folder
  local temp=
  
  # In case no version was supplied, the last version info is obtained from recipe's info
  if [ -z "$version" ]; then
    temp=$(mktemp -d)
    pushd $temp &> /dev/null
    git init -q
    git remote add -f origin "$source" &> /dev/null
    git config core.sparsecheckout true
    echo "$recipe/version" >> .git/info/sparse-checkout
    git pull -q origin master &> /dev/null
    version=$(cat "$recipe/version" 2> /dev/null)
    popd &> /dev/null

    # Remove temp folder
    rm -rf $temp &> /dev/null

    # Check a default version could be obtained
    if [ -z "$version" ]; then
      die "No recipe default version found for recipe '$recipe'"
    fi
  fi

  # Clone recipe folder from repo.
  #
  # Idea took from http://stackoverflow.com/a/13738951
  #
  temp=$(mktemp -d)
  pushd $temp &> /dev/null
  git init -q
  git remote add -f origin "$source" &> /dev/null
  git config core.sparsecheckout true
  echo "$recipe/$version" >> .git/info/sparse-checkout
  git pull -q origin master &> /dev/null
  popd &> /dev/null

  # Recipe not found, report it
  if [ ! -d "$temp/$recipe/$version" ]; then
    # Remove temp folder and die
    rm -rf $temp &> /dev/null
    die "Recipe '$recipe' (with version '$version') not found"
  fi

  # Init the components var just to be sure a parent cloning processes won't affect us.
  unset ${!COMPONENT_@}

  # Load the recipe.sh file to know how to proceed
  . "$temp/$recipe/$version/recipe.sh"

  # Check if there are components to process to keep cloning.
  if [ "$(echo "${!COMPONENT_@}")" ]; then
    # Loop through all component vars
    for (( i=0; ; i++ ))
    do
      local c_recipe="COMPONENT_${i}_NAME"
      local c_version="COMPONENT_${i}_VERSION"
      local c_source="COMPONENT_${i}_SOURCE"
      
      # Empty var recipe empty or not defined, break
      if [ -z "${!c_recipe}" ]; then
        break
      fi

      # Performs a clone in the component found
      local c_temp=$(mktemp -d)
      btdocker clone-recipe "${!c_recipe}" -n "${!c_version}" -s "${!c_source}" "$c_temp"

      # In case the destination folder is empty, we can say there was an error
      if [ -z "$(ls -A $c_temp)" ]; then
        # Remove temp folder created for the component and die
        rm -rf $c_temp &> /dev/null
        die "Component recipe '$c_recipe' couldn't be cloned"
      fi

      # Move the component recipe into the correct place inside the main recipe
      

      # Remove temp folder created for the component
      rm -rf $c_temp &> /dev/null
    done
  fi

  # Locate where the recipe actually lives into
  local folder="recipe"
  if [ "$FOLDER" ]; then
    folder="$FOLDER"
  fi

  # Move the cloned folder to the current directory
  shopt -s dotglob
  mv "$temp/$recipe/$version/$folder/"* "$destination"
  shopt -u dotglob

  # Remove temp folder
  rm -rf $temp &> /dev/null
}
