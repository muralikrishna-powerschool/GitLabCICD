#!/usr/bin/env bash

##
# DESCRIPTION:
#   This script processes the warnings output and does a diff to compare lint warnings

# Temporary file to sort and dedupe current warnings
tmp_filename="process_lint_output.XXX"
mktemp -t $tmp_filename

source ./virtualenv/bin/activate
./scripts/extract_lint_warnings.py > $tmp_filename
deactivate

# By default the sort command works differently in linux and OSX systems
# The C locale guarantees that each character is a single byte and each character
# has a different sorting order, which is the default behavior on OSX.
# See https://unix.stackexchange.com/questions/87745/what-does-lc-all-c-do
if [ "$(uname -s)" == "Linux" ]; then
  export LC_ALL=C
fi
sort $tmp_filename | uniq > current_lint_warnings.txt
rm $tmp_filename

# Diff the known warnings and current warnings
bundle exec ./scripts/compare_warnings.rb known_lint_warnings.txt current_lint_warnings.txt
