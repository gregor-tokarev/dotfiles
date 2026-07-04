#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle OpenVPN
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🛡️
# @raycast.packageName VPN
# @raycast.description Connect/disconnect OpenVPN Connect via its menu bar tray menu.

osascript <<'EOF'
tell application "System Events"
	-- Launch the app first if it is not running
	if not (exists process "OpenVPN Connect") then
		do shell script "open -ga \"OpenVPN Connect\""
		repeat 60 times
			delay 0.25
			if exists process "OpenVPN Connect" then
				tell process "OpenVPN Connect"
					if (count of menu bars) is greater than 1 then exit repeat
				end tell
			end if
		end repeat
		delay 0.5
	end if

	tell process "OpenVPN Connect"
		if (count of menu bars) < 2 then return "OpenVPN Connect tray icon not found"
		set trayMenu to menu 1 of menu bar item 1 of menu bar 2

		-- OpenVPN Connect swaps a single item between "Connect" and "Disconnect"
		-- (unlike Amnezia, which keeps both and toggles enabled state).
		if exists menu item "Disconnect" of trayMenu then
			set disconnectItem to menu item "Disconnect" of trayMenu
			if enabled of disconnectItem then
				click disconnectItem
				return "OpenVPN off"
			else
				return "OpenVPN is busy - try again in a moment"
			end if
		else if exists menu item "Connect" of trayMenu then
			set connectItem to menu item "Connect" of trayMenu
			if enabled of connectItem then
				click connectItem
				return "OpenVPN on"
			else
				return "OpenVPN is busy - try again in a moment"
			end if
		else
			return "Connect/Disconnect item not found - is a profile imported?"
		end if
	end tell
end tell
EOF
