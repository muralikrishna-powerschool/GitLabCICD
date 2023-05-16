#!/bin/bash

git pull

git log remotes/origin/master..HEAD --pretty=oneline | ./scripts/parseTicketNumber.py | ./scripts/open_tickets.rb