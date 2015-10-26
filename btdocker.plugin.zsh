#!/usr/bin/env bash
#
# A bunch of utilities used to deal with Docker integrations and template conversion,
# in order the get all images and containers in place; all encapsulated in a single
# command, 'btdocker'.
#


# Main operative function where all the magic happens
# This uses a bunch of other functions defined internally, as everything works under
# a subshell (give the code a look) so there's no risk of accidentally expose a
# utility function other than the main one.
btdocker() {
  ###################################
  # Start almost unnoticed subshell #
  ###################################
  # This is key, to let inner processes use the main function to get results.
  # This causes the whole processing to be run in an isolated new subshell,
  # avoiding pollute shell with vars, and second and most important giving the chance
  # for inner processes to directly call the main function with total confidence, knowing
  # that changes made there won't affect variables already set in a current call.
  # Without this, any inner main function call would override variables set in parent
  # call, possible producing undesirable results.
  (
  
  # Functionality is defined in so called, modules. There live some functions
  # that will perform specific tasks. Use that approach to add functionality, do
  # not add it here directly.
  #
  # There are no mandatory rules for naming module folder or inner files, but it's
  # recommended to use same function name in main folder and in inner definition
  # file, to keep things consistent.
  #
  # Talking about error handling in functions, as everything in run in a subshell, error can
  # be reported with 'exit' instead of return, and actually that's the recommended
  # way (if you wanna use return, be warned your function won't be as usable as
  # you'd like, as user will have to do custom checks)
  # When calling the main function internally, you must be aware you'll have to do further
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

  # Functionality live in other files. Set that way for convenience, and to keep this file
  # as short an clean as possible
  function _load() {
    for i in $(find `echo "$1"`); do
      if [ -r "$i" ]; then
        . "$i"
      fi
    done
  }

  # Load core modules (basic functionality)
  _load "${BASH_SOURCE%/*}/core/*/*.sh"
  # Load main modules (basic functionality)
  _load "${BASH_SOURCE%/*}/modules/*/*.sh"
  # TODO: Load other modules (extended functionality), third party
  # _load "<path/to/more/scripts>"

  # Checks the main recipes folder is set and has a value. Nothing will work without it.
  if [ -z "$E9TER_MAIN_RECIPES_REPO" ]; then
    die "No main recipes repo defined"
  fi

  # Arguments passed are consumed, and operation called, if any found
  consume "$@"

  ##########################################
  # Finish almost unnoticed subshell start #
  ##########################################
  )
}
