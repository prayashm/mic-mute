# AGENTS.md

Technical notes for agents working on mic-mute. Human overview: [README.md](README.md). Keep this file updated when the setup changes.

## Layout

| Source (`src/`)                          | Installed at                                            | Role                                                                 |
| ---------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------- |
| `MicToggle.applescript`                  | `~/Applications/MicToggle.app`                          | Toggle; bound to the mouse Back button via OpenLogi                   |
| `bhvol.swift`                            | `~/.local/bin/bhvol`                                    | `bhvol 0..1` sets BlackHole input volume; `bhvol inuse` exits 0 if any app has BlackHole running |
| `micvad.swift`                           | `~/.local/bin/micvad`                                   | stdin 16 kHz mono float32 → exits 0 on sustained speech (Apple SoundAnalysis `.version1`, label `speech`) |
| `mutedtoast.swift`                       | `~/.local/bin/mutedtoast`                               | Silent click-through "Muted" HUD (NSVisualEffectView .hudWindow, like the brightness overlay), ~3 s; args = Meet window bounds to centre it above Meet's controls, other screens get a fixed bottom spot |
| `micwatch`                               | `~/.local/bin/micwatch`                                 | Talking-while-muted loop (template: `__SOX__`, `__MIC__`)            |
| `launchagents/local.mic-mute.bridge.plist` | `~/Library/LaunchAgents/`                             | sox mic → BlackHole 2ch; KeepAlive PathState `/tmp/mic_muted` = false; template `__SOX__`, `__MIC__` |
| `launchagents/local.mic-mute.watch.plist`  | `~/Library/LaunchAgents/`                             | Runs `micwatch`; KeepAlive PathState `/tmp/mic_muted` = true; template `__HOME__` |
| `swiftbar/mic.10s.sh`                    | SwiftBar `PluginDirectory` (Prayash: `~/bitbar-plugins/enabled/`) | Menu bar icon                                              |
| `meet-join-muted/`                       | loaded unpacked (Prayash's copy: `~/.local/share/meet-join-muted/`) | Clicks Meet mic/camera off on page load                  |
| `meetbounds.applescript`                 | `~/.local/share/mictoggle/`                             | Prints the Chrome window bounds whose active tab is Meet (osascript needs Automation permission for Chrome, granted) |
| `chimes/{muted,live}.wav`                | `~/.local/share/mictoggle/`                             | sox-generated three-note arpeggio (option D)                         |

`script/build` installs everything except the Chrome extension: compiles the Swift helpers, renders the templates (`__HOME__`, `__SOX__` from `command -v sox`, `__MIC__` from `$MIC` or `~/.config/mic-mute/mic`), rebuilds the app, reloads a launch agent only when its rendered plist changed, and copies the SwiftBar plugin.

## State

- Muted = `/tmp/mic_muted` exists. It clears on reboot, so boot is live.
- MicToggle mute: touch flag, `launchctl kill TERM` the bridge, kickstart the watcher, `bhvol 0`, chime, refresh SwiftBar (`swiftbar://refreshplugin?name=mic`), click Meet's mic button to muted.
- MicToggle treats "Meet mic is muted" as muted too (joined muted), so the press goes live.
- Meet's mic button: `[data-is-muted]` element whose `aria-label` matches `/microphone/i`, driven via Chrome `execute javascript`.

## Gotchas

- GO II: input volume 0 is about -16 dB, not silence; no `kAudioDevicePropertyMute` on input. Do not go back to volume-based muting.
- Silent BlackHole reads -91 dB in ffmpeg `volumedetect` (its floor); voice through the bridge is about -44 dB mean.
- `bhvol inuse` (DeviceIsRunningSomewhere) is also true while the bridge writes to BlackHole, so it only means "a call is open" while muted.
- launchd kills a job's background children when the script exits; run alert commands in the foreground in `micwatch`.
- `osacompile` output is ad hoc signed; editing Info.plist (LSUIElement) invalidates it, so re-sign with `codesign --force --deep -s -`.
- OpenLogi 0.8.11: no AppleScript action in the UI (use "Open application or folder"); Fn alone cannot be a shortcut.
- SwiftBar 2.1.1 ignores `sfcolor`; use `sfconfig=<base64 {"renderingMode":"Palette","colors":["#ff3b30"]}>`.
- The bridge plist must not have RunAtLoad: it starts sox on load even while muted. PathState alone starts it when the flag is absent (e.g. after boot).
- `sed` on this Mac is GNU sed: `sed -i` without `''`.
- Speech detection tuning knobs: `MIN_CONF` (0.6) and `IN_A_ROW` (2) at the top of `micwatch`. Room noise is about -45 dB RMS, -32 dB peak.

## Rejected options

- Level threshold for talking-while-muted: fired on any sound.
- Cactus Whistle (16.9 MB STT): transcription is overkill for speech detection.
- Meet's hold-space push-to-talk: only works with the tab focused.

## Open

- Hold to talk: OpenLogi can only hold a shortcut, so it needs a key listener (Input Monitoring). Button not chosen yet; suggested the one behind the scroll wheel.
