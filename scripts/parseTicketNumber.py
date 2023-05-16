#!/usr/bin/python

import sys
import re

selectedPrefix = "(PE|IPH|AND)-"

pattern = selectedPrefix+"(\d+)(.*)"

def getTicketNumberFromLine(psLine):
	m = re.search(pattern, psLine)
	if m and m.group(1):
		return m.group(1) + "-" + m.group(2)
	return None

def printSortedTickets(ticketNumbers):
	sortedTickets = sorted(ticketNumbers)
	for ticket in sortedTickets:
		print ticket

def readTicketNumbers():
	llTickets = set()
	for line in sys.stdin:
		lsTicketNumber = getTicketNumberFromLine(line)
		if lsTicketNumber:
			llTickets.add(lsTicketNumber)
	return llTickets

glTicketNumbers = set()
glTicketNumbers = readTicketNumbers()
printSortedTickets(glTicketNumbers)

