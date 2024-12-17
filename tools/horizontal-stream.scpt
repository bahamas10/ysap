#!/usr/bin/env osascript
#
# Set the terminal and browser to be in the right place

tell application "iTerm2"
    set bounds of window 1 to {900, 100, 1500, 768}
end tell
tell application "Safari"
    set bounds of window 1 to {100, 100, 800, 768}
end tell
