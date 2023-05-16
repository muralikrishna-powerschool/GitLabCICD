#!/usr/bin/env ruby
require 'slop'

# See 'slop' --help output below for script description
# Use 'slop' for enhanced script argument parsing
$opts = Slop.parse do |o|
  o.string '-n', '--version-number', 'the version number of the release, e.g. 6.5.0.', required: true
  o.string '-c', '--version-code', 'the version code of the release, e.g. 378.', required: true
  o.on '--help' do
    script_description = "This script updates the app's changelogs (located at " +
      "[project_root]/fastlane/metadata/) with the release notes associated with " +
      "the app version number passed to this script."
    puts script_description
    puts "NOTE: This script expects:"
    puts "\t• to be run from the project root"
    puts "\t• release notes files to exist at:"
    puts "\t\t• [project_root]/release_notes/[version_number]/release_notes_en.txt"
    puts "\t\t• [project_root]/release_notes/[version_number]/release_notes_es.txt"
    puts "\t\t• [project_root]/release_notes/[version_number]/release_notes_pt.txt"
    puts o
    exit 0
  end
end

$lang_maps = {
  'en'=>'en-US',
  'es'=>'es-419',
  'pt'=>'pt-BR'
}

$lang_codes = $lang_maps.keys
$file_paths_map = $lang_codes.map {|code|[code, "release_notes/#{$opts[:version_number]}/release_notes_#{code}.txt"]}.to_h

def check_that_the_release_notes_files_exist()
  if $file_paths_map.values.map {|fp| File.exists?(fp) }.include?(false) then
    puts "ERROR: 1 or more of the release notes files was not found!"
    exit(1)
  end
end

def update_app_changelogs()
  $lang_codes.each do |lang_code|
    Dir.chdir("fastlane/metadata/android/#{$lang_maps[lang_code]}/changelogs") do
      puts :version_code
      File.open("#{$opts[:version_code]}.txt", "w") {
        |f| f.write(File.read("../../../../../#{$file_paths_map[lang_code]}"))
      }
    end
  end
end

check_that_the_release_notes_files_exist()
update_app_changelogs()
