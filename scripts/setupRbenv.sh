#!/bin/bash

# Check if rbenv is installed
which rbenv > /dev/null
if [[ $? != 0 ]]
then
	echo "rbenv does not exist"
	brew install rbenv
fi

# Check if ruby version exists
rbenv versions | grep "\s`cat .ruby-version`\s" > /dev/null
if [[ $? != 0 ]]
then
	echo "Installing Ruby Version" `cat .ruby-version`
	rbenv install `cat .ruby-version`
fi

# Install Bundler and Ruby Gems
rbenv local `cat .ruby-version` && gem install bundler -v 2.0.1 && bundle
