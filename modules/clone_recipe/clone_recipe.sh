#!/bin/bash
#
# Functionality for the clone_recipe function
#

# Function used to clone a defined recipe as defined in btdocker-templates.
#
# Arguments:
#   recipe. Name of the recipe to extract info from
#
# Returns:
#  folder path of cloned recipe or nothing if not found. The recipe will be
#  cloned in the current folder
function clone_recipe() {
  # Error checks performed, based on collected data by _consume
  if [ ${#ARGS[@]} != 1 ]; then
    die "Expected recipe name (only one)"
  fi

  # Get the recipe name
  local recipe=${ARGS[0]}

  # Status message
  status "Getting recipe..."

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
    die "Recipe '$recipe' name not found"
  fi

  # Move the cloned folder to the current directory
  rm -rf "`pwd`/$recipe" &> /dev/null
  mv "$temp/$recipe" .

  # Remove temp folder
  rm -rf $temp

  # Return the folder path found
  echo "`pwd`/$recipe"
}
