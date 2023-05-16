#!/usr/bin/env ruby

require 'slop'
require 'jira-ruby'
require_relative 'credentials'

class JiraFixVersionCreator

  def cli_flags
    opts = Slop::Options.new
    opts.string '-f', '--fix-version', '(required) the version number to use in the generated JIRA Fix Version, e.g. 6.5.0', required: true
    opts.string '-c', '--component', '(required) the JIRA component that will be used in the JIRA Fix Version, e.g. iOS, Android', required: true
    opts.bool '-e', '--fail-if-exists', 'whether or not the script should fail if the fix version already exists (defaults to false)', default: false
    opts.bool '-d', '--dry-run', 'prints the changes that would take place during a wet run rather than actually doing them (defaults to false)', default: false
    opts.on '--help' do
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• rsakey.pem (the consumer private key for Mobile Release Bot's OAuth) to exist at the project root"
      puts o
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

  def validate_opts(opts)
    # Verify that a valid component was provided
    if !['iOS', 'Android'].include? opts[:component] then
      raise Exception.new "Your component must be one of: iOS, Android"
    end
  end

  def main(command_line_options=ARGV)
    opts = parse_opts(command_line_options)
    validate_opts(opts)

    begin
      # Setup the JIRA client
     # rsakey_file = File.expand_path('../../rsakey.pem', __FILE__)
      jira_client_options = {
        username: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_EMAIL,
        password: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_API_TOKEN,
        site: CREDENTIALS::POWERSCHOOL_JIRA_URL,
        context_path: '',
        auth_type: :basic,
        use_ssl: true
      }
      jira_client = JIRA::Client.new(jira_client_options)
     # jira_client.set_access_token("", "")

      # Build the fix_version string based on the script inputs
      fix_version = "Mobile - #{opts[:component]} - #{opts[:fix_version]}"

      # Determine whether the fix_version already exists and react accordingly
      pe_project = jira_client.Project.find("PE")
      release_versions = pe_project.versions
      if release_versions.select{|v| v.attrs["name"] == fix_version }.count > 0 then
        error_message = "The Fix Version #{fix_version} already exists!"
        if opts[:fail_if_exists]
          raise error_message
        else
          puts error_message
        end
      end
    rescue StandardError => e
      puts e.message
      puts e.backtrace.inspect
      raise Exception.new "An error was encountered when creating fix version, #{fix_version}. It's possibly related to the Jira client."
    end

    # Create the fix_version via the JIRA API (or print dry run steps)
    if opts[:dry_run]then
      puts "Would create a fix version named '#{fix_version}'"
    else
      begin
        new_version = jira_client.Version.build
        new_version.save({
        "name"=> fix_version,
        "archived"=>false,
        "released"=>false,
        "projectId"=>pe_project.id
        })
      rescue
        raise Exception.new "An error was encountered when creating fix version, #{fix_version}. It's possibly related to the Jira client."
      end
    end
  end
end
