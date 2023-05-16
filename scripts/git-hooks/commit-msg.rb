#!/usr/bin/env ruby

# Colorize output without needing the colorize gem
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end
end

message_file = ARGV[0]
message = File.read(message_file)

current_branch_ticket = `git rev-parse --abbrev-ref HEAD`[/PE-\d+/]

# Return early if we can't find the JIRA ticket number in the branch name
if current_branch_ticket.nil?
	puts "Couldn't parse JIRA ticket number from branch name. Not enforcing commit message formats!"
	exit 0
end

# acceptable schoology conventional commit "types"
cc_types = ["feat", "fix", "docs", "style", "refactor", "test", "build", "ci"]
cc_types_pattern = "(#{cc_types.join('|')})"
should_request_override = true

lines = message.split("\n")

puts "JIRA ticket associated with current branch is #{current_branch_ticket}"

# validate the type
if !/^#{cc_types_pattern}(\(|:)/.match(message)
  puts "Your commit message does not start with one of Schoology's prescribed Conventional Commit 'types': #{cc_types}! Are you sure you want to continue??? (y for YES)".yellow
# validate the feature, when specified
elsif /^#{cc_types_pattern}\(/.match(message) and !(/^#{cc_types_pattern}\(.+\):/.match(message) && message.slice(/.+:/).count("()") == 2)
  puts "Your commit message has a malformed Conventional Commit 'feature' specified, e.g. 'typename(featurename)'! Are you sure you want to continue??? (y for YES)".yellow
# validate the description
elsif !/.*:\s.+/.match(message)
  puts "Your commit message has a malformed Conventional Commit 'description' specified, e.g. 'typename(featurename): description'! Are you sure you want to continue??? (y for YES)".yellow
# validate the branch JIRA ticket number
elsif !/.+\s#{current_branch_ticket}\D+$/.match(message)
	puts "Your commit message is missing the expected JIRA ticket postfix, '#{current_branch_ticket}'! Are you sure you want to continue??? (y for YES)".yellow
elsif lines[1] != nil && lines[1] != ""
  puts "The summary line should be followed by a blank line when including a body for your commit message. Are you sure you want to continue? (y for YES)".yellow
else
  puts "Commit message is in the prescribed format. Continuing...".green
  should_request_override = false
end

if should_request_override
  # Git commit hooks don't run interactively so reopen tty to restore interactivity
  STDIN.reopen('/dev/tty')
  override_response = $stdin.gets.strip
  if "y" != override_response
  	puts "Aborting commit...".red
  	exit 1
  else
  	puts "Override accepted. Continuing...".green
  end
end
