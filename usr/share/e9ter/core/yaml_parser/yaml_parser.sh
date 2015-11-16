# Functionality for the yaml_parser function
#
# Used to transform a YAML file into sh variables to be added in a given script.
# Much of the work based on https://gist.github.com/DinoChiesa/3e3c3866b51290f31243
# and https://johnlane.ie/yay-use-yaml-in-bash-scripts.html
#
# TODO: Replace this with a more complete YAML parser solution, using a thirdy party
# provider.
#

function yaml_parser {
  # Check yaml content is received
  if [ $# = 0 ]; then
    die "YAML content is needed"
  fi

  # Get params passed
  local input="$1"
  local prefix=${2:+"${2^^}_"}

  # Initializations used to parse the yaml content
  local s='[[:space:]]*'
  local w='[a-zA-Z0-9_]*'
  local fs=$(echo @|tr @ '\034')

  # Performs the YAML parsing
  echo "$input" | sed -n -e "s,^\($s\)\($w\)$s[:-]$s\"\(.*\)\"$s\$,\1$fs\2$fs\3,p" \
  -e "s,^\($s\)\($w\)$s[:-]$s\(.*\)$s\$,\1$fs\2$fs\3,p" \
  | crossos awk -F"$fs" -v prefix="$prefix" '{
    indent = length($1)/2;
    key = $2;
    value = $3;

    # No key means a collection entry is comming, so calculate it.
    if (length(key) == 0) {
      if (length(calculated_keys[indent]) == 0) {
        calculated_keys[indent] = 0;
      }
      else {
        calculated_keys[indent]++;
      }

      key = calculated_keys[indent];
    }
    else {
      calculated_keys[indent] = 0;
    }

    # Remove any calculated keys left behind if prior row was indented more than this row.
    for (i in calculated_keys) {
      if (i > indent) {
        delete calculated_keys[i]
      }
    }

    # Store the current key in a global-like array
    keys[indent] = key;

    # Remove keys left behind if prior row was indented more than this row.
    for (i in keys) {
      if (i > indent) {
        delete keys[i]
      }
    }

    # Escape apostrophe to prevent problem later, when variable interpreted
    gsub(/\047/, "\047\"\047\"\047", value);

    # Print the variable
    separator = "_"
    if (length(value) > 0) {
      result = ""

      for (i in keys) {
        if ( result != "" ) {
          result = result separator
        }
        result = result keys[i]
      }

      result = prefix toupper(result) "=$(echo -e \047" value "\047)"
      print result
    }
  }'
}
