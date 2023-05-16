#!/usr/bin/env python

from lxml import etree
import os
import re

lintFilePath = "./schoologyApp/build/reports/lint-results-rc.xml"

lintIssuesDom = etree.parse(lintFilePath).getroot().xpath('//issues/issue')

currentFolder = os.getcwd()
homeFolder = os.path.expanduser("~")

def parseOutAbsolutePath(filePath):
    parsedFolder = re.sub(currentFolder, ".", filePath)
    # Fixes possibility that warnings come from ~/.gradle cache folder
    if (homeFolder in parsedFolder):
        parsedFolder = re.sub(homeFolder, ".", parsedFolder)
    return parsedFolder


# Sanatize unstable messages
def cleanMessage(message):
    # Clean the IconDipSize message
    dipSizeMatch = re.match(
        "The image `(.*)` varies significantly in its density-independent \(dip\) size across the various density versions: (.*)",
        message)
    if dipSizeMatch:
        message = "The image `" + dipSizeMatch.group(1) + \
                  "` varies significantly in its density-independent (dip) size across the various density versions:"

    return message


for issueElement in lintIssuesDom:
    issue = {}
    issue["id"] = issueElement.get('id')
    issue["severity"] = issueElement.get('severity')
    issue["warning"] = issueElement.get('warning')
    issue["priority"] = issueElement.get('priority')
    issue["message"] = cleanMessage(issueElement.get('message'))
    issue["category"] = issueElement.get('category')

    # There may be multiple Files involved, so let's add this list of files delimited by ::
    filesDict = {}
    files = ""
    for locationElement in issueElement:
        lineNum = locationElement.get("line")
        column = locationElement.get("column")
        # Not all files contain line / columns
        if lineNum and column:
            filesDict[parseOutAbsolutePath(locationElement.get("file"))] = " line: " + locationElement.get("line") + \
                                                                           ", column: " + locationElement.get("column")
        else:
            filesDict[parseOutAbsolutePath(locationElement.get("file"))] = ""

    for file in sorted(filesDict.keys()):
        files += file + filesDict[file] + "::"
    # Remove last :: delimiter which is just 2 characters
    files = files[:-2]

    issue["files"] = files

    print issue
