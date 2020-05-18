#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Checks to see if the macOS Catalina installer has already been cached to eligible systems
#
# Written by: Joshua Smith
# Created on: 02/24/2020
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

OSVERSIONMAJOR=$(sw_vers -productVersion | awk -F"." '{ print $2 }')

if [[ "$OSVERSIONMAJOR" -le 14 ]]; then
  if [[ -e "/Applications/Install macOS Catalina.app" ]]; then
    result="Cached"
  else
    result="Not Cached"
  fi
else
  result="Not Applicable"
fi
echo "<result>$result</result>"
