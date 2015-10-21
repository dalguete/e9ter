#!/bin/bash
#
# Functionality for the clone_recipe function
#

# Function used to clone a defined recipe from source, into current or specified folder
#
# Operation:
#   clone-recipe 
#
# Arguments:
#  <recipe-name> [-n <version>] [-s <source>] [<destination>]
#     Clone a given recipe.
#     A specific version can be defined, if not, the default one as set in recipe
#     repository will be used.
#     Set a different repository as recipe source. By default '$E9TER_MAIN_RECIPES_REPO'
#     will be used.
#     Destination can be defined, if not, current working directory will be used
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

  # Get the last version available
  local temp=$(crossos mktemp -d)
  pushd $temp &> /dev/null
  git init -q
  git remote add -f origin "$source" &> /dev/null
  git config core.sparsecheckout true
  echo "$recipe/version" >> .git/info/sparse-checkout
  git pull -q origin master &> /dev/null
  local version_last=$(cat "$recipe/version" 2> /dev/null)
  popd &> /dev/null

  # Remove temp folder
  rm -rf $temp &> /dev/null

  # Check a default version could be obtained
  if [ -z "$version_last" ]; then
    die "Recipe '$recipe' not found or has no default version defined"
  fi

  # Set the version to the last version value in case no one defined
  if [ -z "$version" ]; then
    version=$version_last
  fi

  # Clone recipe folder from repo.
  #
  # Idea took from http://stackoverflow.com/a/13738951
  #
  temp=$(crossos mktemp -d)
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

  # Reset all recipe vars set, just to be sure a parent cloning processes won't affect us.
  unset ${!RECIPE__@}

  # Load the recipe.sh file to know how to proceed
  . "$temp/$recipe/$version/recipe.sh"

  # Locate where the recipe actually lives
  local folder=${RECIPE__FOLDER:-"recipe"}

  # Check if there are components to process to keep cloning.
  if [ "$(echo "${!RECIPE__COMPONENT_@}")" ]; then
    # Loop through all component vars
    for (( i=0; ; i++ ))
    do
      local c_recipe="RECIPE__COMPONENT_${i}_NAME"
      local c_version="RECIPE__COMPONENT_${i}_VERSION"
      local c_position=$i
      local c_source="RECIPE__COMPONENT_${i}_SOURCE"
      
      # Empty recipe or not defined, break
      if [ -z "${!c_recipe}" ]; then
        break
      fi

      # Performs a clone in the component found
      local c_temp=$(crossos mktemp -d)
      btdocker clone-recipe "${!c_recipe}" -n "${!c_version}" -s "${!c_source}" "$c_temp"

      # In case the destination folder is empty, we can say there was an error
      if [ -z "$(ls -A $c_temp)" ]; then
        # Remove temp folder created for the component and die
        rm -rf $c_temp &> /dev/null
        die
      fi

      # Move the component recipe into the correct place inside the main recipe.
      # For this to happen, we'll look for so called "Component Pivot" entries,
      # those are files or folders with a name in the format:
      #
      #   [COMPONENT:<recipe name>[_<version name>][-<position>]]
      #     wrapping square brackets [] are part of the name
      #
      # Where:
      #   <recipe name> is the name of the component recipe
      #   _<version name> is the component recipe version (important to add the leading underscore)
      #   -<position> is the component recipe position (important to add the leading dash)
      #     This last one permits to have more than one instance of the same component
      #     recipe, and avoid collisions
      #
      # A component pivot MUST have a name at least. The other two part are optional
      # and can be defined in any order, just be sure to add the correct leading
      # identification char (_ for version, and - for position)
      #
      # Position is a value as set in the recipe.sh main recipe file. As said, that
      # gives you the chance of defining the very same component more than once,
      # but still know how to tackle the correct one, by looking at its position.
      #
      #
      # That said, a component pivot entry can be a folder or a file, and depending
      # on that, the replacement behavior (when it will be modified with component
      # recipe content) will change.
      #
      # The first thing to do is to check if current component recipe contents can
      # cause name collision in the place it will live, inside main repo.
      # Collision files will be removed prior component recipe contents movement,
      # while collision folders will be merged into result folder after component
      # recipe contents movement. Folder items in main recipe have precedence over
      # new items that come with the component recipe. Useful in case you want to
      # handle some defaults.
      #
      # That's pretty much the same depending on the type of component pivot. When
      # a file, it will be entirely replaced with component recipe contents, while
      # in case of a folder, inner contents will be preserved after a merge with
      # component recipe contents. Another useful way of handling defaults.
      #
      # In case two approaches are defined, the precedence is like this:
      #   - Content of component pivot folder are top.
      #   - Then comes collision folder contents.
      #   - Then actual content from component recipe.
      #
      
      # Component recipe patterns to look for
      local patterns=(
        "${!c_recipe}_${!c_version}-${i}"
        "${!c_recipe}-${i}_${!c_version}"
        "${!c_recipe}_${!c_version}"
      )

      # In case $version and $version_last are the same, proceed to search for
      # the generic component pivot forms too
      if [ "$version" = "$version_last" ]; then
        patterns[${#patterns[@]}]="${!c_recipe}-${i}"
        patterns[${#patterns[@]}]="${!c_recipe}"
      fi

      # Loop through all pivot matches and define temporary work places to build
      # the component recipe.
      local work_list=$(crossos mktemp)

      for pattern in ${patterns[@]}; do
        for pivot in $(find "$temp/$recipe/$version/$folder/" -name "$(printf "%q" "[COMPONENT:${pattern^^}]")"); do
          # Store pattern
          echo "$pattern" >> $work_list

          # Store pivot location
          echo "$pivot" >> $work_list

          # Copy the current component recipe to a new place, so it can be built in isolation
          local build_place=$(crossos mktemp -u)
          rm -rf "$build_place" &> /dev/null
          \cp -a "$c_temp" "$build_place"

          # Store build place location
          echo "$build_place" >> $work_list
        done
      done

      # Loop through the work list to actually start building the component recipes
      local count=0

      while IFS= read -r line
      do
        ((count=count+1))

        # Get the working variables
        if [ $count = 1 ]; then
          local pattern="$line"
          continue
        elif [ $count = 2 ]; then
          local pivot="$line"
          continue
        elif [ $count = 3 ]; then
          local build_place="$line"
          count=0
        fi

        # As we'll be using * heavily, it's better to make it match hidden items too
        shopt -s dotglob;

        # Component pivot container folder
        local dir_pivot=$(dirname "$pivot")

        # Helper used to know when a component recipe with just one entry (and that
        # was a folder) was found
        local unique_folder=

        # Perform merging processes only if inside build_place there's just one item,
        # and it's a folder
        if [ $(\ls -A1 "$build_place" | wc -l) -eq 1 -a $(\ls -dA1 "$build_place/"*/ | wc -l) -eq 1 ]; then
          unique_folder=$(\ls -A1 "$build_place")

          # Merge with data from a folder with the same name as the pattern we are
          # checking.
          if [ -d "$dir_pivot/$pattern" ]; then
            \cp -af "$dir_pivot/$pattern/"* "$build_place/$unique_folder"
          fi

          # Merge with data from a folder named after the component structure
          if [ -d "$dir_pivot/[COMPONENT:${pattern^^}]" ]; then
            \cp -af "$dir_pivot/[COMPONENT:${pattern^^}]/"* "$build_place/$unique_folder"
          fi
        fi

        # Clean the way to move the build component to its final location
        rm -rf "$dir_pivot/$pattern" &> /dev/null
        rm -rf "$pivot" &> /dev/null

        # Move all data from build place to its final location
        if [ -z "$unique_folder" ]; then
          # One file entry or Multiple entries in build place
          for item in "$build_place/"*; do
            local name_item="$(basename "$item")"
            rm -rf "$dir_pivot/$name_item" &> /dev/null
            mv "$item" "$dir_pivot"
          done
        else
          # Just one entry, and a file in build place
          if [ "$unique_folder" != "$pattern" ]; then
            mv "$build_place/$unique_folder" "$build_place/$pattern"
          fi
          mv "$build_place/$pattern" "$dir_pivot"
        fi

        # Remove the build place
        rm -rf $build_place &> /dev/null
      done < "$work_list"

      # Remove the work list
      rm -rf $work_list &> /dev/null

      # Remove temp folder created for the component
      rm -rf $c_temp &> /dev/null
    done
  fi

  # Move the cloned folder to the current directory
  shopt -s dotglob
  mv "$temp/$recipe/$version/$folder/"* "$destination"

  # Remove temp folder
  rm -rf "$temp" &> /dev/null
}
