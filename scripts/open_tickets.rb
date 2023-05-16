#!/usr/bin/ruby


ARGF.each do |ticket|
	`open https://powerschoolgroup.atlassian.net/browse/#{ticket}`
end
