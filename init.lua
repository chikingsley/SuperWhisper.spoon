-- SuperWhisper.spoon/init.lua
-- A proper Hammerspoon Spoon for SuperWhisper integration
-- luacheck: globals hs

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SuperWhisper"
obj.version = "1.0"
obj.author = "Chi Ejimofor <chi@peacockery.studio>"
obj.homepage = "https://github.com/peacockery-studio/SuperWhisper.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal variables
obj.basePath = os.getenv("HOME") .. "/Library/Application Support/superwhisper"
obj.modesPath = obj.basePath .. "/modes"
obj.recordingsPath = obj.basePath .. "/recordings"
obj.modes = {}
obj.watcher = nil
obj.menubar = nil
obj.hotkeys = {}
obj.defaultHotkeysSet = false
obj.autoPasteConfig = {
    enabled = false,
    target = {
        app = nil,
        callback = nil
    }
}

--- SuperWhisper.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('SuperWhisper')

--- SuperWhisper:init()
--- Method
--- Initialize the spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:init()
    -- Load modes on init
    self:loadModes()
    
    -- Set up default hotkeys if none are configured
    if not self.defaultHotkeysSet then
        self:bindHotkeys({
            toggleRecording = {{"cmd", "shift"}, "r"},
            quickRecord = {{"cmd", "shift"}, "q"},
            copyLast = {{"cmd", "shift"}, "c"},
            openMenu = {{"cmd", "shift"}, "m"}
        })
        self.defaultHotkeysSet = true
    end
    
    -- Auto-start the spoon
    self:start()
    
    return self
end

--- SuperWhisper:start()
--- Method
--- Start the SuperWhisper spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:start()
    -- Create menubar
    if self.menubar then
        self.menubar:delete()
    end
    self.menubar = hs.menubar.new()
    self:updateMenubar()
    
    -- Start any watchers if auto-paste is enabled
    if self.autoPasteConfig.enabled then
        self:_startWatcher()
    end
    
    return self
end

--- SuperWhisper:stop()
--- Method
--- Stop the SuperWhisper spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:stop()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
    
    if self.watcher then
        self.watcher:stop()
        self.watcher = nil
    end
    
    -- Unbind any hotkeys
    for _, hk in pairs(self.hotkeys) do
        hk:delete()
    end
    self.hotkeys = {}
    
    return self
end

--- SuperWhisper:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for SuperWhisper
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * toggleRecording - Toggle recording on/off
---   * quickRecord - Quick record in default mode
---   * copyLast - Copy last transcription result
---   * openMenu - Open the mode selection menu
---
--- Returns:
---  * The SuperWhisper object
function obj:bindHotkeys(mapping)
    local def = {
        toggleRecording = function() self:toggleRecording() end,
        quickRecord = function() self:activateModeAndRecord("default") end,
        copyLast = function() self:copyLastResult() end,
        openMenu = function() self:showModeChooser() end,
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
    return self
end

--- SuperWhisper:loadModes()
--- Method
--- Load all available SuperWhisper modes
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of modes indexed by key
function obj:loadModes()
    self.modes = {}
    local iter, dir_obj = hs.fs.dir(self.modesPath)
    if iter then
        for file in iter, dir_obj do
            if file:match("%.json$") then
                local path = self.modesPath .. "/" .. file
                local content = hs.json.read(path)
                if content and content.key and content.name then
                    self.modes[content.key] = {
                        name = content.name,
                        path = path,
                        config = content
                    }
                end
            end
        end
    end
    return self.modes
end

--- SuperWhisper:toggleRecording()
--- Method
--- Toggle SuperWhisper recording on/off
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:toggleRecording()
    hs.urlevent.openURL("superwhisper://record")
    return self
end

--- SuperWhisper:activateMode(modeKey)
--- Method
--- Activate a specific SuperWhisper mode
---
--- Parameters:
---  * modeKey - The key of the mode to activate
---
--- Returns:
---  * The SuperWhisper object
function obj:activateMode(modeKey)
    local url = "superwhisper://mode?key=" .. hs.http.encodeForQuery(modeKey)
    hs.urlevent.openURL(url)
    return self
end

--- SuperWhisper:activateModeAndRecord(modeKey)
--- Method
--- Activate a mode and immediately start recording
---
--- Parameters:
---  * modeKey - The key of the mode to activate
---
--- Returns:
---  * The SuperWhisper object
function obj:activateModeAndRecord(modeKey)
    self:activateMode(modeKey)
    hs.timer.doAfter(0.3, function()
        self:toggleRecording()
    end)
    return self
end

--- SuperWhisper:getLatestResult()
--- Method
--- Get the latest transcription result
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table containing the latest result data, or nil if not found
function obj:getLatestResult()
    local dirs = {}
    for dir in hs.fs.dir(self.recordingsPath) do
        if not dir:match("^%.") then
            table.insert(dirs, dir)
        end
    end
    
    table.sort(dirs, function(a, b) return a > b end)
    
    for i = 1, math.min(30, #dirs) do
        local metaPath = self.recordingsPath .. "/" .. dirs[i] .. "/meta.json"
        local meta = hs.json.read(metaPath)
        if meta then
            return {
                path = metaPath,
                result = meta.result or "",
                llmResult = meta.llmResult or "",
                prompt = meta.prompt or "",
                datetime = meta.datetime,
                duration = meta.duration,
                raw = meta
            }
        end
    end
    return nil
end

--- SuperWhisper:copyLastResult()
--- Method
--- Copy the last transcription result to clipboard
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:copyLastResult()
    local result = self:getLatestResult()
    if result then
        local text = result.llmResult ~= "" and result.llmResult or result.result
        hs.pasteboard.setContents(text)
        hs.alert.show("Copied: " .. text:sub(1, 50) .. "...")
    else
        hs.alert.show("No recent transcription found")
    end
    return self
end

--- SuperWhisper:enableAutoPaste(appName, callback)
--- Method
--- Enable auto-paste functionality
---
--- Parameters:
---  * appName - Name of the application to paste to (optional)
---  * callback - Function to call with (text, result) when new transcription arrives
---
--- Returns:
---  * The SuperWhisper object
function obj:enableAutoPaste(appName, callback)
    self.autoPasteConfig.enabled = true
    self.autoPasteConfig.target.app = appName
    self.autoPasteConfig.target.callback = callback
    self:_startWatcher()
    return self
end

--- SuperWhisper:disableAutoPaste()
--- Method
--- Disable auto-paste functionality
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:disableAutoPaste()
    self.autoPasteConfig.enabled = false
    if self.watcher then
        self.watcher:stop()
        self.watcher = nil
    end
    return self
end

-- Private methods
function obj:_startWatcher()
    if self.watcher then
        self.watcher:stop()
    end
    
    self.watcher = hs.pathwatcher.new(self.recordingsPath, function(files)
        for _, file in ipairs(files) do
            if file:match("/meta%.json$") then
                hs.timer.doAfter(0.5, function()
                    local result = self:getLatestResult()
                    if result and self.autoPasteConfig.enabled and self.autoPasteConfig.target then
                        local text = result.llmResult ~= "" and result.llmResult or result.result
                        
                        if self.autoPasteConfig.target.callback then
                            self.autoPasteConfig.target.callback(text, result)
                        else
                            -- Default paste behavior
                            local app = hs.application.open(self.autoPasteConfig.target.app)
                            if app then
                                hs.timer.doAfter(0.5, function()
                                    app:activate()
                                    hs.timer.doAfter(0.2, function()
                                        hs.pasteboard.setContents(text)
                                        hs.eventtap.keyStroke({"cmd"}, "v")
                                    end)
                                end)
                            end
                        end
                    end
                end)
            end
        end
    end)
    self.watcher:start()
end

function obj:updateMenubar()
    if not self.menubar then return end
    
    self:loadModes()
    
    local menuItems = {
        { title = "Toggle Recording", fn = function() self:toggleRecording() end },
        { title = "-" },
        { title = "Modes", menu = {} }
    }
    
    for key, mode in pairs(self.modes) do
        table.insert(menuItems[3].menu, {
            title = mode.name,
            fn = function() self:activateModeAndRecord(key) end
        })
    end
    
    table.insert(menuItems, { title = "-" })
    table.insert(menuItems, { title = "Auto-Paste", 
        checked = self.autoPasteConfig.enabled,
        fn = function()
            if self.autoPasteConfig.enabled then
                self:disableAutoPaste()
            else
                self:enableAutoPaste("Google Chrome")
            end
            self:updateMenubar()
        end
    })
    table.insert(menuItems, { title = "-" })
    table.insert(menuItems, { title = "Settings", fn = function() 
        hs.urlevent.openURL("superwhisper://settings") 
    end })
    
    self.menubar:setMenu(menuItems)
    self.menubar:setTitle("🎙️")
end

--- SuperWhisper:showModeChooser()
--- Method
--- Show a chooser dialog for mode selection
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SuperWhisper object
function obj:showModeChooser()
    local choices = {}
    for key, mode in pairs(self.modes) do
        table.insert(choices, {
            text = mode.name,
            subText = mode.config.description or "",
            modeKey = key
        })
    end
    
    local chooser = hs.chooser.new(function(choice)
        if choice then
            self:activateModeAndRecord(choice.modeKey)
        end
    end)
    
    chooser:choices(choices)
    chooser:show()
    return self
end

return obj