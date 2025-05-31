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

### Method 1: Simple Installation (Recommended)

1. Download the [latest release](https://github.com/YOUR_USERNAME/SuperWhisper.spoon/releases/latest) or clone this repository
2. Double-click `SuperWhisper.spoon` to install it to `~/.hammerspoon/Spoons/`
3. Add just this one line to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("SuperWhisper")
```

**That's it!** The spoon will automatically:

- Set up default hotkeys (Cmd+Shift+R, Q, C, M)
- Create a menu bar icon
- Start monitoring for transcriptions

### Method 2: Custom Configuration

If you want to customize hotkeys or behavior:

```lua
-- Load the spoon
hs.loadSpoon("SuperWhisper")

-- Custom hotkey setup (overrides defaults)
spoon.SuperWhisper:bindHotkeys({
    toggleRecording = {{"cmd", "alt"}, "r"},
    quickRecord = {{"cmd", "alt"}, "s"},
    copyLast = {{"cmd", "alt"}, "c"},
    openMenu = {{"cmd", "alt", "shift"}, "m"}
})

-- Enable auto-paste
spoon.SuperWhisper:enableAutoPaste("Google Chrome")
```

## Default Hotkeys

When using simple installation, these hotkeys are automatically configured:

- **Cmd+Shift+R**: Toggle recording on/off
- **Cmd+Shift+Q**: Quick record with default mode
- **Cmd+Shift+C**: Copy last transcription to clipboard
- **Cmd+Shift+M**: Open mode chooser dialog

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org) 0.9.90 or later
- [SuperWhisper](https://superwhisper.com) app installed and configured
- SuperWhisper modes should be stored in `~/Library/Application Support/superwhisper/modes/`

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

### Hotkey Mapping Format

The `bindHotkeys()` method accepts a table with the following keys:

- `toggleRecording` - Toggle recording on/off
- `quickRecord` - Quick record in default mode  
- `copyLast` - Copy last transcription result
- `openMenu` - Open the mode selection menu

Each hotkey is specified as `{modifiers, key}` where modifiers is a table of modifier keys (`"cmd"`, `"alt"`, `"shift"`, `"ctrl"`) and key is the key name.

## Troubleshooting

- **Hotkeys not working**: Make sure Hammerspoon has Accessibility permissions in System Preferences
- **Menu bar icon missing**: The spoon auto-starts, but you can manually call `spoon.SuperWhisper:start()`
- **No transcriptions found**: Ensure SuperWhisper is saving to the default location

## License

MIT - See LICENSE file for details

## Author

Chi Ejimofor <chi@peacockery.studio>

## Contributing

Pull requests are welcome! Please feel free to submit issues or enhancement requests.
