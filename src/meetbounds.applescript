-- prints "left top right bottom" (global, top-left origin) of the Chrome window showing a Meet call, or nothing
if application "Google Chrome" is not running then return ""
tell application "Google Chrome"
	repeat with w in windows
		if URL of active tab of w contains "meet.google.com/" then
			set b to bounds of w
			return ((item 1 of b) as text) & " " & (item 2 of b) & " " & (item 3 of b) & " " & (item 4 of b)
		end if
	end repeat
end tell
return ""
