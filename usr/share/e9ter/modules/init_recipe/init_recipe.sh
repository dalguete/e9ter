#!/usr/bin/env bash
#
# Functionality for the init_recipe function
#
# Operation must be registerd with "set_operation"
# Internal process requires some functions to be defined, as explained next
# 
#   <OPERATION>_usage
#     Used when usage message should be displayed for the operation defined.
# 
#   <OPERATION>_consume
#     Used when the operation options should be consumed.
# 
# Be sure to implement them.
# 

set_operation "init-recipe" "v:s:t:e:" "version:,source:,template-var-key:,template-var-value:"

# Function used to display operation usage
function init_recipe_usage() {
  die "TODO: Init recipe usage"
}

# Function used to consume operation passed options
function init_recipe_consume() {
  local key_name=

  # Process all input data. Only valid entries will live here. Non valid ones are
  # filtered in the main consume process
  while [ $# -gt 0 ]
  do
    case "$1" in
      -v|--version) # Indicates the recipe version to use.
        set_option "version" "$2"
        shift
        ;;

      -s|--source) # Indicates the recipes source of info.
        set_option "source" "$2"
        shift
        ;;

      -t|--template-key) # Store the template key passed
        set_option "template-key" "$2"
        
        # Uses an intermediate var to let the next template value received be associated
        # with this key
        key_name=$(echo "$2" | tr '-' '_')

        shift
        ;;

      -e|--template-value) # Store the template value passed
        # To actually store something, a previous key name should be set first
        if [ "$key_name" ]; then
          set_option "template-value_${key_name}" "$2"
          key_name=
        fi

        shift
        ;;
    esac

    shift
  done
}

# Function used to init a cloned recipe from source, into current or specified folder
#
# Operation:
#   init-recipe 
#
# Arguments:
#  <recipe-name> [-v|--version <version>] [-s|--source <source>] [-t|--template-key <template-var-key>]* [-e|--template-value <template-var-value>]* [<destination>]
#     Init a given recipe.
#     A specific version can be defined, if not, the default one as set in recipe
#     repository will be used.
#     Set a different repository as recipe source. By default '$E9TER_MAIN_RECIPES_REPO'
#     will be used.
#     Template var definitions in recipe will be replaced with data passed
#     Destination can be defined, if not, current working directory will be used
function init_recipe() {
  # Error checks performed
  if [ -z "${ARGS[*]}" ]; then
    die "Expected recipe name"
  fi

  # Get recipe name
  local recipe=${ARGS[0]}

  # Get the version to work with
  local version=($(get_last_option "version"))

  # Get the source to work with
  local src=($(get_last_option "source"))
  src=${src:-"$E9TER_MAIN_RECIPES_REPO"}

  # Get all the variable template keys passed
  local options=($(get_options "template-key"))

  # Get destination
  local destination=${ARGS[1]:-"."}

  # Clone the recipe
  IFS=$'\n'

  local recipe_entries=($(btdocker clone-recipe "${ARGS[0]}" -v "$version" -s "$src" "$destination"))
  if [ -z "${recipe_entries[*]}" ]; then
    die
  fi

  # Status message
  status "Setting up '$recipe' recipe..."

  # As files and folders returned names could be manipulated, we need to be sure
  # of working with a stable version of them, that's when inodes come into play
  local recipe_inodes=()
  
  for entry in "${recipe_entries[@]}"; do
    recipe_inodes=("${recipe_inodes[@]}" "$(find "$entry" -maxdepth 0 -printf '%i')")
  done

  # Loop through all entries searching for the ones with the .TEMPLATE suffix, to transform
  # them and remove that extension.
  for inode in "${recipe_inodes[@]}"; do
    local inode_item="$(find . -inum "$inode")"

    # Search all items that have as suffix ".TEMPLATE", and perform replacements
    local matches=($(find "$inode_item" -name '*.TEMPLATE' -printf '%i\n'))
    for match in "${matches[@]}"; do
      local match_item="$(find . -inum $match)"
  
      # Perform the replacements only on files
      if [ -f "$match_item" ]; then
        for option in "${options[@]}"; do
          # Get the value for the current option
          local option_value=$(get_last_option "template-value_${option}")

          # Perform template vars replacement. Ensure the inode is kept 
          local template_var_name=$(printf "%q" "[TEMPLATE:$option]")
          local new_content="$(cat "$match_item" | sed -e "s/${template_var_name}/${option_value}/g")"
          echo "$new_content" > "$match_item"
        done
      fi

      # Remove the .TEMPLATE suffix=
      mv "$match_item" "${match_item%.TEMPLATE}"
    done
  done

  # Loop through all options to find and replace any [TEMPLATE:*] name pattern in
  # files and folders.
  for option in "${options[@]}"; do
    # Get the value for the current option
    local option_value=$(get_last_option "template-value_${option}")
    local template_var_name=$(printf "%q" "[TEMPLATE:$option]")

    for inode in "${recipe_inodes[@]}"; do
      local inode_item="$(find . -inum "$inode")"

      # Search all items that have as suffix ".TEMPLATE", and perform replacements
      local matches=($(find "$inode_item" -name "$template_var_name" -printf '%i\n'))
      for match in "${matches[@]}"; do
        local match_item="$(find . -inum "$match")"
        local basename_match_item=$(basename "$match_item")
        local dirname_match_item=$(dirname "$match_item")
        local new_match_item=$(echo "$basename_match_item" | sed "s/${template_var_name}/${option_value}/g")

        mv "$match_item" "${dirname_match_item}/${new_match_item}"
      done
    done
  done        

  unset IFS
}
