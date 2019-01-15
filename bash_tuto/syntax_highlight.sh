#!/bin/bash
# In order to activate syntax highlighting in vim, use the command
#:syntax enable or :sy enable or :syn enable

clear

echo "The script starts now."
echo "Hi, $USER!"
echo

echo "I will now fetch you a list of connected users:"
echo
# activate debugging from here
# Short notation	Long notation	Result
# set -f	set -o noglob	Disable file name generation using metacharacters (globbing).
# set -v	set -o verbose	Prints shell input lines as they are read.
# set -x	set -o xtrace	Print command traces before executing command.
set -xv
w
# stop debugging from here
set +xv
echo

echo "I'm setting two variables now"
Colour="black"
Value="9"
echo "This is a string : $Colour"
echo "This is a number: $Value"
echo

echo "I'm giving back my prompt now"
echo
