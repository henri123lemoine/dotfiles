-- Hammerspoon configuration

-- Hotkey to switch to latest Claude session
hs.hotkey.bind({ "cmd", "ctrl" }, "c", function()
	local home = os.getenv("HOME") or ""
	local switcher = home .. "/.claude/hook_scripts/switch_to_latest_claude_session.py"
	local task = hs.task.new("/opt/homebrew/bin/python3", function(exitCode, stdOut, stdErr)
		if exitCode ~= 0 then
			local output = "Exit code: " .. exitCode .. "\n"

			if stdOut and stdOut ~= "" then
				output = output .. "stdout: " .. stdOut .. "\n"
			end
			if stdErr and stdErr ~= "" then
				output = output .. "stderr: " .. stdErr .. "\n"
			end

			-- Copy to clipboard and show error alert
			hs.pasteboard.setContents(output)
			hs.alert.show("Claude switcher error (copied to clipboard)")

			-- Also print to console
			print(output)
		end
		-- Success case: silent operation
	end, { switcher })

	-- Set environment with homebrew paths
	task:setEnvironment({
		PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
		HOME = home,
	})

	task:start()
end)

-- Move current window to next screen
hs.hotkey.bind({ "cmd", "alt" }, "m", function()
	local win = hs.window.focusedWindow()
	if win then
		win:moveToScreen(win:screen():next(), true, true)
	end
end)

-- Load private hotkeys if they exist
local privateHotkeysPath = hs.configdir .. "/private/hotkeys.lua"
print("Looking for private hotkeys at: " .. privateHotkeysPath)
if hs.fs.attributes(privateHotkeysPath) then
	print("Loading private hotkeys...")
	dofile(privateHotkeysPath)
	print("Private hotkeys loaded successfully")
else
	print("Private hotkeys file not found")
end

-- Block phantom "play" media key events when Bluetooth audio devices connect/disconnect.
-- macOS sends a play event on BT reconnect, which triggers whatever app has media focus.
local blockPlayUntil = 0
hs.audiodevice.watcher.setCallback(function(event)
	if event == "dev#" then
		blockPlayUntil = hs.timer.secondsSinceEpoch() + 5
	end
end)
hs.audiodevice.watcher.start()

local playTap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
	local data = event:systemKey()
	if data and data.key == "PLAY" and not data["repeat"] then
		if hs.timer.secondsSinceEpoch() < blockPlayUntil then
			return true -- swallow the event
		end
	end
	return false
end)
playTap:start()

-- Reload config hotkey
hs.hotkey.bind({ "cmd", "ctrl", "shift" }, "r", function()
	hs.reload()
	hs.alert.show("Config reloaded")
end)
