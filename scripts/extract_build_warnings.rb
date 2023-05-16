#!/usr/bin/env ruby

##
# DESCRIPTION:
#   This script takes gradle build output as input and extracts compile time
#   warnings, including Kotlin warnings, and outputs the sanitized results to
#   STDOUT.
# USAGE EXAMPLES:
# 	[some gradle output stream] | [this script]
#       ./gradlew assembleRc |& tee | [this script]
#       bundle exec fastlane android buildRC |& tee | [this script]
#       cat mygradleoutputfile.txt | [this script]
#   [this script] [filepath containing gradle output]
#       [this script] mygradleoutputfile.txt
#   <this script> < [filepath containing gradle output]
#       [this script] < mygradleoutputfile.txt
#   <this script> [filepath containing gradle output]
#       [this script] mygradleoutputfile.txt

# Obtain the project root path in order to remove it from the gradle output
currentDir = `pwd`.strip

ARGF.each do |line|
  # Make absolute path relative
  line.gsub!(currentDir, '.')

  # Strip possible Color encodings that fastlane may output
  line.gsub!(/\e\[\d+m/, '')

  # Parse out any time stamps that Fastlane may add:
  line.gsub!(/^(\[(.*)\]: ▸ )/, '')

  # Kotlin warnings are prefixed with w:
  # Android warnings are prefixed with Warning: com.schoology.. or warning:
  #   with lowercase "w"
  if line =~ /^(w)|(Warning: com.schoology)|^(warning: ): / then
    puts line
  end
end