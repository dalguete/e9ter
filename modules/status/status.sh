#!/bin/bash
#
# Functionality for the status function
#

# Function used to print a message directly /dev/tty, without messing with stdout
# or stderr. Useful for those user aimed messages
function status() {
  # Just prints to stderr
  # http://stackoverflow.com/a/9405235
  echo "$@" 1> /dev/tty
}
