#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Happ
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🛡️
# @raycast.packageName VPN
# @raycast.description Connect/disconnect Happ via its menu bar tray menu.

osascript <<'EOF'
tell application "System Events"
	-- Launch the app first if it is not running
	if not (exists process "Happ") then
		do shell script "open -ga Happ"
		repeat 60 times
			delay 0.25
			if exists process "Happ" then
				tell process "Happ"
					if (count of menu bars) is greater than 1 then exit repeat
				end tell
			end if
		end repeat
		delay 0.5
	end if

	tell process "Happ"
		if (count of menu bars) < 2 then return "Happ tray icon not found"
		set trayMenu to menu 1 of menu bar item 1 of menu bar 2

		-- Happ swaps a single item between "Connect" and "Disconnect"
		-- (unlike Amnezia, which keeps both and toggles enabled state).
		if exists menu item "Disconnect" of trayMenu then
			set disconnectItem to menu item "Disconnect" of trayMenu
			if enabled of disconnectItem then
				click disconnectItem
				return "Happ off"
			else
				return "Happ is busy - try again in a moment"
			end if
		else if exists menu item "Connect" of trayMenu then
			set connectItem to menu item "Connect" of trayMenu
			if enabled of connectItem then
				click connectItem
				return "Happ on"
			else
				return "Happ is busy - try again in a moment"
			end if
		else
			return "Connect/Disconnect item not found - is a profile imported?"
		end if
	end tell
end tell
EOF
