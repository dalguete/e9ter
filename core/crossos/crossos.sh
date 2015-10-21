#!/usr/bin/env bash
#
# Functionality for the cross_os function
#
# Used to allow the execution of alternative commands, based on checking in the
# current OS. Despite the basic requirements imposed but this global solution, there
# are times some commands needs a different treatment in order to work properly in
# different OS. And here we define those matches.

function crossos {
  # Check a command was passed
  local command=${1:-}
  [ -z $command ] && {
    die "No command name to wrap passed"
  }

  # Set a default command to use
  local defaultCommand=$command

  # React on Mac OS X
  if [ "$(uname -s)" = "Darwin" ]; then
    # In general, to use alternative commands is enough to prepend 'g' (maybe Homebrew only)
    local altCommand="g$command"

    # In some situacion a 'g' prefix only alternative is not found, so custom processes
    # to get the actual command are required. (uses Homebrew to discover)
    case "$command" in
      getopt)
        altCommand=$(brew --prefix "gnu-$command")/bin/"$command"
        ;;
    esac

    # Check the command exists and it’s not a local alias.
    # Thanks to http://stackoverflow.com/a/7522866
    local loc=$(type -p $altCommand)
    if [ ! -z $loc ]; then
      defaultCommand=$altCommand
    fi
  fi

  # Execute the command, but removing the first param from the list, as thats the
  # command we are wrapping
  shift
  $defaultCommand "$@"
}
