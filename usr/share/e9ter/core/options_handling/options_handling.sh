# Functionality to work with option handling
#

# Options data is handled in per option array. To make this compatible with old
# bash version that do not work with assoc arrays.
# The next format is used to store options:
#
#   OPTION__<option key>=()
#
# Where <option key> will be the option letter

# As first step, all set of options is removed to have a clean start.
for entry in ${!OPTION__*}; do
  unset $entry
done  

# Functionality live in other files. Set that way for convenience, and to keep this file
# as short an clean as possible
# Load components
_load "${BASH_SOURCE%/*}/components/*.sh"

