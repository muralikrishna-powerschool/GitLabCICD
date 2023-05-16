#!/usr/bin/env ruby

##
# DESCRIPTION:
# 	This script takes two input files and outputs a printed report of the
#   differences introduced by the second file when compared with the first.
#   If no file parameters are provided, the following defaults are used:
#       [project_root]/known_lint_warnings.txt
#       [project_root]/current_lint_warnings.txt
#   If any changes are detected, this script exits with status '1', and exits
#   with status '0' otherwise.
#
# USAGE (ALWAYS FROM [PROJECT ROOT]!):
# 	[this script] [optional input file 1] [optional input file 2]

################################
# STEP 1 - Make sure files exist
################################
knownWarningsFilePath = (ARGV.count > 0) ? ARGV[0] : "./known_warnings.txt"
if not File.exists?(knownWarningsFilePath)
	puts "ERROR: #{knownWarningsFilePath} not found!"
	exit(1)
end
currentWarningsFilePath = (ARGV.count > 1) ? ARGV[1] : "./current_warnings.txt"
if not File.exists?(currentWarningsFilePath)
	puts "ERROR: #{currentWarningsFilePath} not found!"
	exit(1)
end


################################
# STEP 2 - Execute diff on them
################################
diff_output = `diff --strip-trailing-cr #{knownWarningsFilePath} #{currentWarningsFilePath}`


################################################################
# STEP 3 - Process diff output to create a human readable report
################################################################
lines_to_add_to_deleted = 0
lines_to_add_to_added = 0
collecting_modified_lines = false
deleted = []
added = []
modified = []
diff_output.each_line do |line|
	if lines_to_add_to_deleted > 0 then
		deleted.push(line.sub(/^\<\s/, ''))
		lines_to_add_to_deleted -= 1
		next
	end
	if lines_to_add_to_added > 0 then
		added.push(line.sub(/^\>\s/, ''))
		lines_to_add_to_added -= 1
		next
	end

	if line =~ /^\d+,\d+d\d+/ then
		firstLine, lastLine = line.match(/^(\d+),(\d+)d\d+/).captures
		lines_to_add_to_deleted = (lastLine.to_i - firstLine.to_i + 1)
		collecting_modified_lines = false
	elsif line =~ /^\d+d\d+/ then
		lines_to_add_to_deleted = 1
		collecting_modified_lines = false
	elsif line =~ /^\d+a\d+,\d+/ then
		firstLine, lastLine = line.match(/^\d+a(\d+),(\d+)/).captures
		lines_to_add_to_added = (lastLine.to_i - firstLine.to_i + 1)
		collecting_modified_lines = false
	elsif line =~ /^\d+a\d+/ then
		lines_to_add_to_added = 1
		collecting_modified_lines = false
	elsif line =~ /^(\d+,\d+|\d+)c(\d+,\d+|\d+)/ then
		modified.push("•••••••••These lines:•••••••••")
		collecting_modified_lines = true
		next
	elsif line =~ /^---/ then
		modified.push("•••••••••Became these lines:•••••••••")
	elsif collecting_modified_lines then
		modified.push(line.sub!(/^(<|>)/, '').strip!)
	end
end


################################
# STEP 4 - Print the report
################################

# Extend the string class for colored text
class String
  def colorize(color_code) "\e[#{color_code}m#{self}\e[0m" end
  def red
    colorize(31)
  end
  def yellow
    colorize(33)
  end
  def green
    colorize(32)
  end
end

if deleted.count > 0
	puts "\n######################################".green
	puts "The following warnings have gone away:".green
	deleted.each do |warning|
		puts warning.green
	end
	puts "######################################".green
end

if added.count > 0
	puts "\n######################################".red
	puts "\nThe following new warnings have appeared:".red
	added.each do |warning|
		puts warning.red
	end
	puts "######################################".red
end

if modified.count > 0
	puts "\n######################################".yellow
	puts "\nThe following warnings have been modified:".yellow
	modified.each do |warning|
		puts warning.yellow
	end
	puts "######################################".yellow
end

exit((added.count > 0 || modified.count > 0 || deleted.count > 0) ? 1 : 0)
