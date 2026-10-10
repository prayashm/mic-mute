#!/bin/bash
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# Mic mute indicator for MicToggle (/tmp/mic_muted) and the sox bridge (local.mic-mute.bridge).
if [ -e /tmp/mic_muted ]; then
  echo "| sfimage=mic.slash.fill sfconfig=eyJyZW5kZXJpbmdNb2RlIjoiUGFsZXR0ZSIsImNvbG9ycyI6WyIjZmYzYjMwIl19"
elif ! launchctl print gui/$(id -u)/local.mic-mute.bridge 2>/dev/null | grep -q 'pid ='; then
  echo "| sfimage=mic.badge.xmark sfconfig=eyJyZW5kZXJpbmdNb2RlIjoiUGFsZXR0ZSIsImNvbG9ycyI6WyIjZmY5NTAwIl19"
else
  echo "| sfimage=mic.fill"
fi
echo "---"
echo "Toggle mute | bash=/usr/bin/open param1=$HOME/Applications/MicToggle.app terminal=false"
