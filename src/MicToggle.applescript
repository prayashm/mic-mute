-- muted = /tmp/mic_muted exists; launchd keeps the sox bridge (local.mic-mute.bridge) running only while it doesn't.
-- micwatch (talking-while-muted alert) runs only while muted.
-- bhvol also drops BlackHole's input volume; syncMeet sets Meet's own mute button to match.
on syncMeet(wantMuted)
	if application "Google Chrome" is not running then return
	set js to "(() => { const b = [...document.querySelectorAll('[data-is-muted]')].find(e => /microphone/i.test(e.getAttribute('aria-label') || '')); if (b && b.dataset.isMuted !== '" & wantMuted & "') b.click(); })()"
	try
		tell application "Google Chrome"
			repeat with w in windows
				repeat with t in tabs of w
					if URL of t contains "meet.google.com/" then execute t javascript js
				end repeat
			end repeat
		end tell
	end try
end syncMeet

on meetMicMuted()
	if application "Google Chrome" is not running then return false
	set js to "(() => { const b = [...document.querySelectorAll('[data-is-muted]')].find(e => /microphone/i.test(e.getAttribute('aria-label') || '')); return b ? b.dataset.isMuted : ''; })()"
	try
		tell application "Google Chrome"
			repeat with w in windows
				repeat with t in tabs of w
					if URL of t contains "meet.google.com/" then
						if (execute t javascript js) is "true" then return true
					end if
				end repeat
			end repeat
		end tell
	end try
	return false
end meetMicMuted

set uid to do shell script "id -u"
set bridgeMuted to (do shell script "test -e /tmp/mic_muted && echo 1 || echo 0") is "1"
if not (bridgeMuted or meetMicMuted()) then
	do shell script "touch /tmp/mic_muted; launchctl kill TERM gui/" & uid & "/local.mic-mute.bridge; launchctl kickstart gui/" & uid & "/local.mic-mute.watch; ~/.local/bin/bhvol 0; echo \"$(date +%T) mute\" >> /tmp/mictoggle.log; afplay ~/.local/share/mictoggle/muted.wav &>/dev/null & open -g 'swiftbar://refreshplugin?name=mic'"
	syncMeet("true")
	display notification "Mic muted" with title "🎙️"
else
	do shell script "rm -f /tmp/mic_muted; launchctl kickstart gui/" & uid & "/local.mic-mute.bridge; launchctl kill TERM gui/" & uid & "/local.mic-mute.watch; ~/.local/bin/bhvol 1; echo \"$(date +%T) live\" >> /tmp/mictoggle.log; afplay ~/.local/share/mictoggle/live.wav &>/dev/null & open -g 'swiftbar://refreshplugin?name=mic'"
	syncMeet("false")
	display notification "Mic live" with title "🎙️"
end if
