#!/usr/bin/env ruby

fastlane_require 'slop'

class IncrementedVersionNumbersBranchCreator
  # Use 'slop' for enhanced script arguments parsing
  def cli_flags
    opts = Slop::Options.new
    opts.string '-j', '--jira-ticket', '(required) the ticket number of the associated Release Ticket in JIRA, e.g. PE-12345', required: true
    opts.string '-r', '--repo-id', "the Bitbucket id number of the repository in which to create the branch. Defaults to Android repo 104", default: "104"
    opts.on '--help' do
      script_description = "This script creates, if necessary, a branch off of the " +
      "current branch, increments the build version and/or code number on it, " +
      "commits that change, and then sends a message in Slack with a handy link " +
      "that can be used to create the PR for the build-number-increment branch. " +
      "Assuming no errors occur, the script will return to the original branch."
      puts script_description
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• to have sufficient git credentials to read and write to the repository"
      puts opts
      exit 0
    end

    opts
  end

  def parse_opts(command_line_options)
    begin
      parser = Slop::Parser.new cli_flags
      result = parser.parse(command_line_options)
      result.to_hash
    rescue Slop::UnknownOption
      raise Exception.new "Unknown option passed in. Command line options that were passed in: #{command_line_options}. Accepted flags: #{cli_flags}"
    end
  end

  def get_current_branch_name
    puts "Retrieving the current branch name..."
    branch_name = `git rev-parse --abbrev-ref HEAD`
    if !$?.success? then
      raise Exception.new "Unable to retrieve current branch name when creating the increment version number branch"
    end
    branch_name
  end

  def enforce_clean_working_copy
    puts "Enforcing a clean working copy..."
    `git update-index --refresh && git diff-index --quiet HEAD`
    if !$?.success? then
      raise Exception.new "Unable to enforce a clean working copy when creating the increment version number branch"
    end
  end

  def create_increment_branch_if_necessary(increment_branch_name)
    puts "Checking if increment branch already exists..."
    all_branches = `git branch --all`
    if !$?.success? then
      raise Exception.new "Unable to check if increment version number branch already exists"
    end

    if all_branches =~ /#{increment_branch_name}$/ then
      puts "#{increment_branch_name} already exists! Nothing more to do."
    end

    puts "Creating local copy of increment branch named #{increment_branch_name}..."
    `git checkout -b #{increment_branch_name}`
    if !$?.success? then
      raise Exception.new "Unable to retrieve current branch name when creating the increment version number branch"
    end
  end

  def increment_version_numbers(jira_ticket_key, increment_branch_name)
    puts "Incrementing version number(s)..."
    `cd .. && bundle exec fastlane increment_minor_version`
    if !$?.success? then
      raise Exception.new "Error incrementing the version number for jira ticket #{jira_ticket_key}"
    end

    puts "Committing incremented files..."
    `git commit -a -m "build(Release): Incrementing build version numbers #{jira_ticket_key}" && git push -u origin #{increment_branch_name}`
    if !$?.success? then
      raise Exception.new "Error occured when commiting incremented files to increment version branch"
    end
  end

  def return_to_original_branch(original_branch)
    puts "Returning to the original branch: #{original_branch}"
    `git checkout #{original_branch}`
    if !$?.success? then
      raise Exception.new "An error occured when checking out #{original_branch} after creating the increment version branch"
    end
  end

  def deliver_slack_message(opts, increment_branch_name)
    release_channel = ENV["MOBILE_RELEASE_SLACK_CHANNEL"]
    puts "Telling devs via Slack to create a PR for the increment branch..."
    `fastlane run slack message:"Android version numbers incremented. Make a PR against dev: https://bitbucket.schoologize.com/projects/MOB/repos/android/pull-requests?create&targetBranch=refs%2Fheads%2Fdev&sourceBranch=refs%2Fheads%2F#{increment_branch_name}&targetRepoId=#{opts[:repo_id]}" channel:\"#{release_channel}\"`
  end

  def main(command_line_options=ARGV)
    opts = parse_opts(command_line_options)
    increment_branch_name = "#{opts[:jira_ticket]}-increment-version-number"
    # Primary script body
    original_branch = get_current_branch_name()
    enforce_clean_working_copy()
    create_increment_branch_if_necessary(increment_branch_name)
    increment_version_numbers(opts[:jira_ticket], increment_branch_name)
    return_to_original_branch(original_branch)
    deliver_slack_message(opts, increment_branch_name)
  end
end

# Uncomment for local tests
# IncrementedVersionNumbersBranchCreator.new.main
