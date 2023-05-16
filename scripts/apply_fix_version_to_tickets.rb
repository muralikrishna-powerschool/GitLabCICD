#!/usr/bin/env ruby

require 'slop'
require 'jira-ruby'
require_relative 'credentials'

class FixVersionApplier
  # Use 'slop' for enhanced script argument parsing
  def cli_flags
    opts = Slop::Options.new
    opts.string '-f', '--fix-version', '(required) the version number to use in the generated JIRA Fix Version, e.g. 6.5.0', required: true
    opts.string '-c', '--component', '(required) the JIRA component that will be used in the JIRA Fix Version, e.g. iOS, Android', required: true
    opts.bool '-e', '--fail-if-exists', 'whether or not the script should fail if a different fix version is already applied to any releasable tickets (defaults to true)', default: true
    opts.bool '-d', '--dry-run', 'prints the changes that would take place during a wet run rather than actually doing them (defaults to false)', default: false
    opts.on '--help' do
      puts "This script mines your conventional commit log messages to find all the JIRA issues for which there have been commits since the last release and applies a Fix Version to them."
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• rsakey.pem (the consumer private key for Mobile Release Bot's OAuth) to exist at the project root"
      puts opts
      exit 0
    end
    opts
  end

  def validate_opts(opts)
    # Verify that a valid component was provided
    if !['iOS', 'Android'].include? opts[:component] then
      raise Exception.new "Your component must be one of: iOS, Android"
    end
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

  def main(command_line_options=ARGV)
    opts = parse_opts(command_line_options)
    validate_opts(opts)

    # Build the fix_version string based on the script inputs
    fix_version = "Mobile - #{opts[:component]} - #{opts[:fix_version]}"

    # Make sure we're dealing with the latest state of the git world
    puts "Fetching git history..."
    `git fetch`
    if !$?.success? then
      error_message = "Unable to fetch git history when applying fix version to tickets"
      if opts[:fail_if_exists]
        raise Exception.new error_message
      else
        puts error_message
        exit 0
      end
    end

    # Get the list of tickets that, according to the git logs, are in the upcoming release
    puts "Getting list of tickets..."
    # Note: '\+' is double escaped to work around Ruby escape sequences
    # Note: Using .downcase on issue key strings due to this jql bug:
    #   https://community.atlassian.com/t5/Jira-questions/JQL-search-by-issueId-fails-if-issue-key-LIST-has-a-deleted/qaq-p/99570
    tickets = `git log --pretty=oneline origin/master..HEAD | grep -o -e "PE-[0-9]\\+$" | sort | uniq`.lines.map{|l| l.strip.downcase }
    if !$?.success? then
      error_message = "Unable to get list of tickets to be included in the release"
      if opts[:fail_if_exists]
        raise Exception.new error_message
      else
        puts error_message
      end
    end

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
      #jira_client.set_access_token("", "")

      # Make sure the fix version actually exists
      pe_project = jira_client.Project.find("PE")
      matching_versions = pe_project.versions.select{|version| version.attrs["name"] == fix_version }
      if matching_versions.count != 1
        raise Exception.new "There are unexpectedly #{matching_versions.count} fix versions named #{fix_version}! (Expected 1)"
      end
      jira_fix_version = matching_versions[0]

      # Select only the ticket types that we would want to apply the Fix Version to
      ticket_types = ["Story", "Defect"]
      puts "Fetching the following discovered tickets from JIRA: #{tickets.join(', ')}..."
      fetched_issues = jira_client.Issue.jql("key in (#{tickets.join(',')})")
      missing_issue_keys = tickets-(fetched_issues.map{|issue| issue.key.downcase})
      if missing_issue_keys.count > 0 then
        raise Exception.new "The following ticket numbers could not be found in JIRA: #{missing_issue_keys.join(', ')}!"
      end
      if fetched_issues.count != tickets.count then
        puts "WARNING: Different number of tickets found in JIRA than expected!"
      end
      puts "Selecting tickets with issueType in (#{ticket_types.join(", ")})..."
      dropped_issues = fetched_issues.select{|issue| !ticket_types.include?(issue.fields["issuetype"]&.[]("name"))}
      puts "Dropped these JIRA tickets with ignored issueTypes: #{dropped_issues.map{|i| i.key}.join(', ')}"
      fetched_issues.select!{|issue| ticket_types.include?(issue.fields["issuetype"]&.[]("name"))}
      puts "Selected these JIRA tickets to apply Fix Version to: #{fetched_issues.map{|i| i.key}.join(', ')}"

      # Notify the team via slack on which tickets are to be assigned the fix version
      release_channel = ENV["MOBILE_RELEASE_SLACK_CHANNEL"]
      slack_msg = "The following tickets will be included in the release of #{fix_version}: #{fetched_issues.map{|i| i.key}.join(', ')}"
      `fastlane run slack message:\"#{slack_msg}\" channel:\"#{release_channel}\" default_payloads:"test_result" success:true`

      # Apply the fix version to each of the selected tickets
      fetched_issues.each do |issue|
        if issue.fields["fixVersions"].select{|fv| fv["id"] == jira_fix_version.id }.count > 0
          puts "#{issue.key} already has #{fix_version} set as its Fix Version."
        elsif issue.fields["fixVersions"].count > 0 && opts[:fail_if_fixed]
          raise Exception.new "Error Occured when applying fix versions to tickets -- Unexpected Fix Versions encountered on issue #{issue.key}: #{issue.fields["fixVersions"].map{|fv| fv["name"]}}"
        else
          puts_msg = opts[:dry_run] ? "Would have applied" : "Applying"
          puts "#{puts_msg} Fix Version #{fix_version} to issue #{issue.key}..."
          next if opts[:dry_run]
          issue.save({
            "fields" => {
              "fixVersions" => issue.fields["fixVersions"] + [jira_fix_version]
            }
          })
        end
      end
    rescue
      raise Exception.new "An error was encountered when applying fix version, #{fix_version}. It's possibly related to the Jira client."
    end
  end
end
