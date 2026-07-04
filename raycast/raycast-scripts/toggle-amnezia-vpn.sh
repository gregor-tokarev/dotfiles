#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Amnezia VPN
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🛡️
# @raycast.packageName VPN
# @raycast.description Connect/disconnect AmneziaVPN via its menu bar tray menu.

osascript <<'EOF'
tell application "System Events"
	-- Launch the app first if it is not running
	if not (exists process "AmneziaVPN") then
		do shell script "open -ga AmneziaVPN"
		repeat 60 times
			delay 0.25
			if exists process "AmneziaVPN" then
				tell process "AmneziaVPN"
					if (count of menu bars) is greater than 1 then exit repeat
				end tell
			end if
		end repeat
		delay 0.5
	end if

	tell process "AmneziaVPN"
		if (count of menu bars) < 2 then return "Amnezia tray icon not found"
		set trayMenu to menu 1 of menu bar item 1 of menu bar 2

		-- Resolve items by name, falling back to position if the UI language changes
		if exists menu item "Connect" of trayMenu then
			set connectItem to menu item "Connect" of trayMenu
			set disconnectItem to menu item "Disconnect" of trayMenu
		else
			set connectItem to menu item 3 of trayMenu
			set disconnectItem to menu item 4 of trayMenu
		end if

		if enabled of disconnectItem then
			click disconnectItem
			return "Amnezia off"
		else if enabled of connectItem then
			click connectItem
			return "Amnezia on"
		else
			return "Amnezia is busy - try again in a moment"
		end if
	end tell
end tell
EOF
