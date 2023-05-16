#!/usr/bin/env ruby
require_relative 'slop'

class ReleaseBranchCreator
  # See 'slop' help section below for script description and expectations
  def cli_flags
    opts = Slop::Options.new
    opts.string '-n', '--version-number', "the version number of the release, e.g. 6.5.0. Defaults to version.name in #{$gradle_props_path}.", required: true
    opts.on '--help' do
      puts "This script checks if a release branch exists, and creates one if it does not exist."
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• git credentials to be stored in the environment"
      puts opts
      exit 0
    end

    opts
  end

  #TODO: DRY this out, it's in every file
  def parse_opts(command_line_options)
    begin
      parser = Slop::Parser.new cli_flags
      result = parser.parse(command_line_options)
      result.to_hash
    rescue Slop::UnknownOption
      raise Exception.new "Unknown option passed in. Command line options that were passed in: #{command_line_options}. Accepted flags: #{cli_flags}"
    end
  end

  # Helper functions

  def repo_origin_url()
    puts "Fetching repo origin URL..."
    retrieved_repo_origin_url = `git config --get remote.origin.url`
    if !$?.success? then
      raise Exception.new "Unable to fetch repo origin URL to create release branch"
    end
    return retrieved_repo_origin_url.strip
  end

  def release_branch_exists()
    # We're expecting EITHER a blank response which indicates that there's no
    # existing branch OR to find the branch we're looking for in the output
    puts "Checking if release branch already exists at origin..."
    command = "git ls-remote --heads #{repo_origin_url()} #{$release_branch_name_from_version_number}"
    remote_branches = `#{command}`
    if !($?.success? && (remote_branches.empty? || remote_branches =~ $branch_name_regex)) then
      raise Exception.new "Unable to fetch repo remote origin URL when creating release branch"
    end
    if remote_branches.empty? then
      puts "Release branch does not yet exist."
    else
      puts "Release branch already exists!"
    end
    return !remote_branches.empty?
  end

  def create_release_branch()
    puts "Checking out (but NOT pulling) dev..."
    `git checkout dev`
    if !$?.success? then
      raise Exception.new "Unable to checkout the dev branch"
    end

    puts "Checking if branch already exists locally..."
    all_local_branches = `git branch`
    if !$?.success? then
      raise Exception.new "Cannot get all local branches when creating release branch"
    end

    if all_local_branches =~ $branch_name_regex then
      puts "#{$release_branch_name_from_version_number} already exists locally! Checking it out..."
      `git checkout #{$release_branch_name_from_version_number}`
      if !$?.success? then
        raise Exception.new "Unable to checkout already existing local branch #{$release_branch_name_from_version_number}"
      end
      return
    end

    puts "Creating branch #{$release_branch_name_from_version_number}..."
    `git checkout -b #{$release_branch_name_from_version_number}`
    if !$?.success? then
      raise Exception.new  "Unable to create branch #{$release_branch_name_from_version_number}"
    end
  end

  def push_release_branch_to_origin()
    puts "Pushing release branch back to origin..."
    `git push -u origin #{$release_branch_name_from_version_number}`
    if !$?.success? then
      raise Exception.new "Unable to push #{$release_branch_name_from_version_number} back to origin"
    end
  end

  def main(command_line_options=ARGV)
    opts = parse_opts(command_line_options)

    $release_branch_name_from_version_number = "release/#{opts[:version_number]}"
    $branch_name_regex = /#{$release_branch_name_from_version_number.gsub('/', '\/').gsub('.','\.')}$/
    # Primary script body
    if !release_branch_exists() then
      create_release_branch()
      push_release_branch_to_origin()
    end
  end
end
