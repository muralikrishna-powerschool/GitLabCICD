#!/bin/sh

configure_commit_msg_hook(){
  echo "Configuring commit-msg hook..."
  GIT_COMMIT_MSG_HOOK_PATH=./.git/hooks/commit-msg
  #check if GIT_COMMIT_MSG_HOOK_PATH is a file
  if [ ! -f $GIT_COMMIT_MSG_HOOK_PATH ]; then
    # make a symbolic link to the commit-msg hook
    ln -s -f ../../Scripts/git-hooks/commit-msg.rb $GIT_COMMIT_MSG_HOOK_PATH
    echo "Done"
  else
    echo A commit-msg hook exists already.
  fi
}

DIR_PATH=./.git/hooks
#check if DIR_PATH exists
if [ -e  $DIR_PATH ]; then
    echo file/directory exists
    #check if DIR_PATH is a directory
    if [ -d $DIR_PATH ]; then
      echo directory exists
      configure_commit_msg_hook
    else
      echo hook is expected to be a directory, but it is a file. Please remove it and try it again.
      exit 1
    fi
else
    echo hook directory not found. Creating hooks directory...
    if mkdir $DIR_PATH ; then
      echo Done
      configure_commit_msg_hook
    fi
fi
