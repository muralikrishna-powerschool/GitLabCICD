#!/usr/bin/env ruby

fastlane_require 'slop'
fastlane_require 'jira-ruby'
fastlane_require 'cgi'
require_relative 'credentials'

opts = Slop.parse do |o|
  o.string '-f', '--fix-version', '(required) the version number to use in the generated JIRA Fix Version, e.g. 6.5.0', required: true
  o.string '-c', '--component', '(required) the JIRA component that will be used in the JIRA Fix Version, e.g. iOS, Android', required: true
  o.on '--help' do
    puts "NOTE: This script expects:"
    puts "\t• to be run from the project root"
    puts "\t• rsakey.pem (the consumer private key for Mobile Release Bot's OAuth) to exist at the project root"
    puts o
    exit 0
  end
end

def hasTickets(client, jql)
  client.Issue.jql(jql).count > 0
end

def openJiraIssuesJqlLink(jql)
  escapedJql = CGI.escape(jql)
  link = "https://powerschoolgroup.atlassian.net/issues/?jql=#{escapedJql}"

  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    system "start #{link}"
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    system "open #{link}"
  elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
    system "xdg-open #{link}"
  end
end

def buildJiraclient
  jira_client_options = {
      username: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_EMAIL,
      password: CREDENTIALS::SCHOOLOGY_MOBILE_JIRA_USER_API_TOKEN,
      site: CREDENTIALS::POWERSCHOOL_JIRA_URL,
      context_path: '',
      auth_type: :basic,
      use_ssl: true
  }
  jira_client = JIRA::Client.new(jira_client_options)
  jira_client.set_access_token("", "")
  jira_client
end

def findRelease(jira_client, opts)
  unless ['iOS', 'Android'].include? opts[:component]
    puts "Your component must be one of: iOS, Android"
    exit 1
  end

  fix_version = "Mobile - #{opts[:component]} - #{opts[:fix_version]}"

  pe_project = jira_client.Project.find("PE")
  release_versions = pe_project.versions

  found_releases = release_versions.select {|v| v.attrs["name"] == fix_version}

  unless found_releases.count == 1
    puts "Wrong number of releases matching #{fix_version} found. Expected 1 found #{found_releases.count}"
    exit 1
  end

  found_releases[0]
end

jira_client = buildJiraclient
current_release = findRelease(jira_client, opts)

customerFixesJql = "fixVersion = \"#{current_release.attrs["name"]}\" AND \"Zendesk Ticket IDs\" is not EMPTY"
nonCustomerFixes = "fixVersion = \"#{current_release.attrs["name"]}\" AND \"Zendesk Ticket IDs\" is EMPTY"

if hasTickets(jira_client, customerFixesJql)
  openJiraIssuesJqlLink(customerFixesJql)
else
  puts "No customer-specific fixes were released."
end

if hasTickets(jira_client, nonCustomerFixes)
  openJiraIssuesJqlLink(nonCustomerFixes)
else
  puts "No non customer tickets."
end
