#!/usr/bin/env osascript
#
# Set the terminal and browser to be in the right place

tell application "iTerm2"
    set bounds of window 1 to {1310, 55, 2375, 850}
end tell
tell application "Safari"
    set bounds of window 1 to {80, 55, 1100, 860}
end tell
