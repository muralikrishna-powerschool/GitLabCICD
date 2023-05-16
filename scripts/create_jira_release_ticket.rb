#!/usr/bin/env ruby

require 'slop'
require 'jira-ruby'
require_relative 'credentials'

class JiraReleaseTicketCreator
  # Use 'slop' for enhanced script arguments parsing
  def cli_flags
    opts = Slop::Options.new
    opts.string '-f', '--fix-version', '(required) the version number to use in the generated JIRA Fix Version, e.g. 6.5.0', required: true
    opts.string '-c', '--component', '(required) the JIRA component that will be used in the JIRA Fix Version, e.g. iOS, Android', required: true
    opts.bool '-e', '--fail-if-exists', 'whether or not the script should fail if the fix version already exists (defaults to false)', default: false
    opts.on '--help' do
      script_description = "This script creates a JIRA ticket from a template that " +
        "helps track progress on the release process for a new version of the " +
        "provided Mobile component."
      puts script_description
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• rsakey.pem (the consumer private key for Mobile Release Bot's OAuth) to exist at the project root"
      puts o
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

  def validate_opts(opts)
    # Verify that a valid component was provided
    if !['iOS', 'Android'].include? opts[:component] then
      raise Exception.new "Your component must be one of: iOS, Android"
    end
  end

  def create_release_ticket(jira_client, ticket_title, ticket_component, release_ticket_description)
    begin

      release_ticket = jira_client.Issue.build
      release_ticket.save({
        "fields" => {
          "summary" => ticket_title,
          "description" => release_ticket_description,
          "project" => {"key" => "PE"},
          "issuetype" => {"id" => "11979"}, # Task
          "components" => [{"name" => ticket_component}],# android
          "customfield_14675" => { "value":"xp-mobile" }, # Mobile Experience Delivery Team
          "customfield_10163" => 5.0, # Story Points
          "customfield_14363" => { "value" => "Technical Work / Usability" } # Investment Profile: Technical Work/ Usability
        }
      })
      release_ticket.fetch
    rescue
      raise Exception.new "An error occured with the Jira client when creating the release ticket, #{ticket_title}"
    end
    return release_ticket
  end

  def release_ticket_if_it_already_exists(jira_client, ticket_title)
    release_ticket_query = "project = PE AND \"Delivery Team\" = xp-mobile AND type in (task) AND summary ~ '#{ticket_title}'"
    issues = jira_client.Issue.jql(release_ticket_query, {fields: %w(summary issuetype)})
    case issues.count
    when 0
      puts "Release ticket does not yet exist"
      return nil
    when 1
      puts "Release ticket already exists with ticket number #{issues[0].key}"
      return issues[0].key
    else
      raise Exception.new "Multiple release tickets with title #{ticket_title} exist: #{issues.map{|i| i.key}.join(', ')}"
    end
  end

  def create_subtask(jira_client, parent, summary, type)
    subtask = jira_client.Issue.build
    subtask.save({
      "fields" => {
        "project"   => {"key" => "PE"},
        "summary" => summary,
        "issuetype" => {
          "name" => type,
          "subtask" => true
        },
        "parent" => {
          "id" => parent.id
        }
      }
    })
    subtask.fetch
    return subtask
  end

  def main(command_line_options=ARGV)
    opts = parse_opts(command_line_options)
    validate_opts(opts)
    begin
      jira_client_options = {
        username: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_EMAIL,
        password: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_API_TOKEN,
        site: CREDENTIALS::POWERSCHOOL_JIRA_URL,
        context_path: '',
        auth_type: :basic
      }
      jira_client = JIRA::Client.new(jira_client_options)

      # Build the title string based on the version
      version = "#{opts[:component]} #{opts[:fix_version]}"
      ticket_title = "Schoology #{version} Release"
      puts "Preparing to create release ticket '#{ticket_title}'"
    rescue
      raise Exception.new "An error was encountered when setting up the Jira client to create ticket, #{ticket_title}. It's possibly related to the Jira client."
    end

    # Do nothing if the release ticket already exists in JIRA
    existing_release_ticket = release_ticket_if_it_already_exists(jira_client, ticket_title)
    return existing_release_ticket if existing_release_ticket

    # Define the values to be used in the component and description fields
    ticket_component, release_ticket_description = case opts[:component]
    when 'Android'
      ['android', "Following the release flow document here: [https://collab.schoologize.com/display/PESE/Android+Release+Flow]\r\n * Create JIRA Release version\r\n * Apply fix versions to tickets\r\n ** Checkout master and do \"git pull\"\r\n ** Checkout release branch and do \"git pull\"\r\n ** Run this command:\r\n *** \r\n{noformat}\r\ngit log --pretty=oneline master..HEAD | grep -o -e \"PE-[0-9]\\+$\" | sort | uniq | paste -sd \"%\" - | sed \"s/%/%2C/g\" | xargs -I ^ open https://powerschoolgroup.atlassian.net/issues/\\?jql\\=key%20in%20\\(\\^\\)\r\n\r\n{noformat}\r\n\r\n * Cut release branch\r\n * Increment minor version number and build number on dev (open a new branch with the changes)\r\n * Generate release APK\r\n * Generate release notes and submit to Smartling\r\n * Integrate release note translations back into app submission\r\n * Smoke test release branch\r\n * Release to public via (step 4 of the release flow document):\r\n ** Google Play\r\n ** Amazon\r\n ** HockeyApp\r\n * Verify released tickets\r\n * Set JIRA Release to Released\r\n * Send release notes\r\n * Merge release branch to master\r\n * Apply release tag to master"]
    when 'iOS'
      ['iphone', "More detailed instructions at: [https://collab.schoologize.com/x/k4XPAQ]\r\n * Create JIRA Release version\r\n * Apply fix versions to tickets \r\n ** Checkout master and do \"git pull\"\r\n ** Checkout release branch and do \"git pull\"\r\n ** Run this command:\r\n *** \r\n{noformat}\r\ngit log --pretty=oneline master..HEAD | grep -o -e \"PE-[0-9]\\+$\" | sort | uniq | paste -sd \"%\" - | sed \"s/%/%2C/g\" | xargs -I ^ open https://powerschoolgroup.atlassian.net/issues/\\?jql\\=key%20in%20\\(\\^\\)\r\n\r\n{noformat}\r\n\r\n * \r\n ** All of the tickets (and some which might not apply, e.g. previous release ticket, automation tickets, tickets whose issue key were accidentally typed into branch names and commit messages, etc.) should show up here.\r\n * Run fastlane precheck and correct any issues (bundle exec fastlane precheck)\r\n * Cut release branch\r\n * Increment minor version number and build number on dev\r\n * Generate archive\r\n * Upload archive to Apple\r\n * Save archive to Google Team Drive\r\n * Generate release notes\r\n * Submit release notes to Smartling\r\n * Integrate release note translations back into app submission\r\n * Update release screenshots (if necessary - only when it changes)\r\n * Associate archive with new version\r\n * Submit to apple for review\r\n * Copy generated dSyms from iTunesConnect to Crashlytics\r\n * Smoke test release branch\r\n * Release to public\r\n * Validate all tickets in the release downloading the app from App Store (mark tickets as verified and put a comment on it)\r\n * Set JIRA Release to Released\r\n * Send release notes\r\n * Merge release branch to master (open a PR) and dev (if necessary)\r\n * Apply tag to master"]
    end

    # Create the release ticket via the JIRA API
    release_ticket = create_release_ticket(jira_client, ticket_title, ticket_component, release_ticket_description)
    puts "Release Ticket created. Ticket number is #{release_ticket.key}"

    # Change the ticket status to In Progress
    issue_transition = release_ticket.transitions.build()
    issue_transition.save("transition" => {"id" => "31"})

    # Create Release Integration Test Subtask
    integration_test_subtask = create_subtask(jira_client, release_ticket, "Release Integration Test", "Test Execution Task")
    puts "Integration Test Subtask created: #{integration_test_subtask.key}"

    # Create Release Smoke Test Subtask
    smoke_test_subtask = create_subtask(jira_client, release_ticket, "Release Smoke Test", "Test Execution Task")
    puts "Smoke Test Subtask created: #{smoke_test_subtask.key}"
    
    return release_ticket.key
  end
end
