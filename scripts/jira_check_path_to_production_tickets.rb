#!/usr/bin/env ruby

require 'slop'
require 'jira-ruby'
require 'cgi'
require_relative 'credentials'

class PathToProductionChecker
  def cli_flags
    opts = Slop::Options.new
    opts.string '-c', '--component', '(required) the JIRA component that will be used in the search, e.g. iphone, Android', required: true
    opts.on '--help' do
      puts "NOTE: This script expects:"
      puts "\t• to be run from the project root"
      puts "\t• rsakey.pem (the consumer private key for Mobile Release Bot's OAuth) to exist at the project root"
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

  def buildJiraclient
    begin
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
    rescue
      raise Exception.new "An error was encountered when checking the path to production tickets. It's possibly related to the Jira client."
    end
    jira_client
  end

  def check_component(opts)
    unless ['iphone', 'Android'].include? opts[:component]
      raise Exception.new "Your component must be one of: iphone, Android"
    end
  end

  def notifyTicketsCouldBeInRelease(tickets)
    release_channel = ENV["MOBILE_RELEASE_SLACK_CHANNEL"]
    puts "notifyTicketsCouldBeInRelease: #{tickets}"
    `fastlane run slack message:"Tickets found in path to production but no fix version: #{tickets}" channel:\"#{release_channel}\"`
  end

  def main(command_line_options=ARGV)
    puts "Verifying tickets in path to production..."
    opts = parse_opts(command_line_options)
    check_component(opts)
    jira_client = buildJiraclient

    statusString = "\"Ready for Staging\", \"In Staging\", \"Ready for Integration\", \"In Integration\", \"Mobile - Prepare App for Release\", \"Mobile - In Integration\", \"Mobile - Smoke Test\""
    ticketsInPathToProduction = jira_client.Issue.jql("component = #{opts[:component]} AND status in (#{statusString}) AND issuetype != Task AND fixVersion is EMPTY", fields:[:summary, :key]).map {|issue| issue.attrs["key"] }
    notifyTicketsCouldBeInRelease(ticketsInPathToProduction) unless ticketsInPathToProduction.count == 0
  end
end
