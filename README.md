# SuperWhisper.spoon

A Hammerspoon Spoon that provides deep integration with [SuperWhisper](https://superwhisper.com) - the AI-powered voice transcription app for macOS.

## Features

- 🎙️ Quick access to recording with customizable hotkeys
- 📝 Automatic mode switching and recording
- 📋 Auto-paste transcriptions to any application
- 🔄 Watch for new recordings and process them automatically
- 📊 Menu bar integration for easy access
- ⌨️ Customizable hotkey bindings

## Installation

1. Download the [latest release](https://github.com/YOUR_USERNAME/SuperWhisper.spoon/releases/latest) or clone this repository
2. Double-click `SuperWhisper.spoon` to install it to `~/.hammerspoon/Spoons/`
3. Add the following to your `~/.hammerspoon/init.lua`:

```lua
-- Load the spoon
hs.loadSpoon("SuperWhisper")

-- Basic setup with hotkeys
spoon.SuperWhisper:bindHotkeys({
    toggleRecording = {{"cmd", "alt"}, "r"},
    quickRecord = {{"cmd", "alt"}, "s"},
    copyLast = {{"cmd", "alt"}, "c"},
    openMenu = {{"cmd", "alt", "shift"}, "m"}
})

-- Start the spoon (creates menu bar item)
spoon.SuperWhisper:start()
```

## Usage Examples

### Basic Recording

```lua
-- Toggle recording on/off
spoon.SuperWhisper:toggleRecording()

-- Record with a specific mode
spoon.SuperWhisper:activateModeAndRecord("default")
```

### Auto-Paste to Browser

```lua
-- Enable auto-paste to Chrome
spoon.SuperWhisper:enableAutoPaste("Google Chrome")

-- Custom auto-paste handler
spoon.SuperWhisper:enableAutoPaste(nil, function(text, result)
    -- Do something with the transcribed text
    print("Transcribed: " .. text)
    
    -- Access the AI-processed result if available
    if result.llmResult ~= "" then
        print("AI Result: " .. result.llmResult)
    end
end)
```

### Working with Modes

```lua
-- List all available modes
local modes = spoon.SuperWhisper:loadModes()
for key, mode in pairs(modes) do
    print(key .. ": " .. mode.name)
end

-- Show mode chooser
spoon.SuperWhisper:showModeChooser()
```

### Get Latest Transcription

```lua
-- Get the last transcription
local result = spoon.SuperWhisper:getLatestResult()
if result then
    print("Text: " .. result.result)
    print("AI Result: " .. result.llmResult)
    print("Duration: " .. result.duration .. "s")
end
```

## API Documentation

See the [API documentation](docs.json) for complete method reference.

### Key Methods

- `start()` - Start the spoon with menu bar
- `stop()` - Stop the spoon and cleanup
- `bindHotkeys(mapping)` - Bind hotkeys for common actions
- `toggleRecording()` - Start/stop recording
- `activateMode(modeKey)` - Switch to a specific SuperWhisper mode
- `activateModeAndRecord(modeKey)` - Switch mode and start recording
- `getLatestResult()` - Get the most recent transcription
- `enableAutoPaste(appName, callback)` - Enable automatic pasting
- `showModeChooser()` - Display mode selection dialog

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org)
- [SuperWhisper](https://superwhisper.com) app installed and configured
- SuperWhisper modes should be stored in `~/Library/Application Support/superwhisper/modes/`

## License

MIT - See LICENSE file for details

## Author

Chi Ejimofor <chi@peacockery.studio>

## Contributing

Pull requests are welcome! Please feel free to submit issues or enhancement requests.
