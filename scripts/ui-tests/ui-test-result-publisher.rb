#!/usr/bin/env ruby
require 'rexml/document'
require 'json'
require 'net/http'
require 'uri'

include REXML

class UiTestResultPublisher

    def sendToAirTable(jsonObjects)
      uri = URI.parse("https://api.airtable.com:443/v0/appByMvr81HmJLpK8/android")
      header = {
        "Content-Type": "application/json",
        "Authorization": "Bearer #{ENV['AIRTABLE_API_KEY']}"
      }

      data = {
        records: jsonObjects
      }

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = data.to_json

      # Send the request
      response = http.request(request)
      puts "AirTable response: #{response.inspect}"
      if response.code != "200"
        puts "Received an error from AirTable. The response code is #{response.code}. Printing out the airtable data:"
        puts "##############"
        puts "#{data}"
        puts "##############"
      end
    end

    def main(command_line_options=ARGV)
      # Use "fastlane/test_output/report/report.xml" if running the script directly - not using "bundle exec fastlane"
      reportFolderPath = "../schoologyApp/build/outputs/androidTest-results/connected/flavors/debugAndroidTest/"
      files = Dir["#{reportFolderPath}/*.xml"]
      reportFilePath = files[0]

      puts "reportFilePath: #{reportFilePath}"

      xmlfile = File.new(reportFilePath)
      xmldoc = Document.new(xmlfile)

      jsonObjects = []
      XPath.each(xmldoc, "//testsuite/testcase") { |testcase|
        XPath.each(testcase, "./failure") { |failure|
          jsonObject = {
            "fields" => {
              "test_name" => testcase["name"],
              "error_message" => failure.text.dump[1..-2],
              "class_name" => testcase["classname"],
              "duration" => testcase["time"]
            }
          }
          jsonObjects << jsonObject
        }
      }
      sendToAirTable(jsonObjects)
    end
end

# Uncomment for local tests using terminal
# UiTestResultPublisher.new.main

# Command to run it from the terminal
# ./scripts/ui-tests/ui-test-result-publisher.rb
