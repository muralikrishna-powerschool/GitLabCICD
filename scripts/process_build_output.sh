#!/usr/bin/env bash

##
# DESCRIPTION:
#   This script processes the warnings output and does a diff to compare build warnings

# Default output file
LOG_FILE=fastlane_build_output.log

# Customizable options -> override default warnings log file
while getopts l: option
do
    case "${option}"
    in
    l) LOG_FILE=${OPTARG};;
    esac
done

# Temporary file to sort and dedupe current warnings
tmp_filename=`mktemp -t process_build_output.XXX`
cat ./$LOG_FILE \
    | bundle exec ./scripts/extract_build_warnings.rb \
    > $tmp_filename

# By default the sort command works differently in linux and OSX systems
# The C locale guarantees that each character is a single byte and each character
# has a different sorting order, which is the default behavior on OSX.
# See https://unix.stackexchange.com/questions/87745/what-does-lc-all-c-do
if [ "$(uname -s)" == "Linux" ]; then
  export LC_ALL=C
fi
sort $tmp_filename | uniq > current_warnings.txt
rm $tmp_filename

# Diff the known warnings and current warnings
bundle exec ./scripts/compare_warnings.rb
