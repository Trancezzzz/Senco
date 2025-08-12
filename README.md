### SimpleUI (Executor-friendly Roblox GUI Library)

Single-file, local-only UI library for Roblox executors. Renders in CoreGui/hidden UI, safely sharable across multiple scripts via `getgenv()` caching. Designed for script hubs.

Raw URLs for this repo
- Library: `https://raw.githubusercontent.com/Trancezzzz/Senco/main/SimpleUI.lua`
- Demo hub: `https://raw.githubusercontent.com/Trancezzzz/Senco/main/ScriptHubDemo.lua`

### Highlights
- Tabs and sections for organizing script hubs
- Controls: Button, Toggle, Slider, Dropdown, Keybind, Textbox, Label
- Toast notifications: `Notify(text, seconds)`
- Theme customization + draggable window
- Config save/load (uses executor filesystem if available; otherwise in-memory)
- Duplicate-execution protection: windows are cached by `id` and re-used until unloaded
- Unload support: `ui:Destroy()` fully removes the window so you can re-run your loader
- Global cache so multiple scripts can share the same library safely
 - Animated window show/hide + `ui:Toggle()`
 - Button ripple and micro-interaction animations
 - Dropdowns with smooth open/close and outside-click to close
 - New multi-select dropdown: `AddMultiDropdown`

### Quick start (library only)
```lua
local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Trancezzzz/Senco/main/SimpleUI.lua"))()
local ui = SimpleUI:CreateWindow({ title = "My Tools", id = "MyTools" })
ui:AddButton("Hello", function() ui:Notify("Hi!", 2) end)
```

### Quick start (full demo hub)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Trancezzzz/Senco/main/ScriptHubDemo.lua"))()
```

### Anti-duplicate behavior
If the same script runs again with the same `id`, the existing window is re-used instead of creating a duplicate. To unload and allow a fresh instance:
```lua
ui:Destroy() -- removes cached window
```

### API overview
Create a window
```lua
local ui = SimpleUI:CreateWindow({
  title = "Script Hub",
  id = "MyHub",            -- used to prevent duplicates; recommended
  size = Vector2.new(420, 300),
  theme = { Accent = Color3.fromRGB(255, 128, 0) }
})
ui:BindToggleKey(Enum.KeyCode.RightShift) -- show/hide UI
-- Visibility controls (animated)
ui:Show()
ui:Hide()
ui:Toggle() -- new
```

Tabs and sections
```lua
local main = ui:AddTab("Main")
main:AddSection("General")
```

Controls (tab API)
```lua
main:AddButton("Notify", function() ui:Notify("Hello!", 2) end)

local t = main:AddToggle("God Mode", false, function(on) end, "god") -- id enables config
local s = main:AddSlider("WalkSpeed", 8, 32, 16, function(v) end, "ws")
local d = main:AddDropdown("Team", {"Red","Blue"}, "Red", function(v) end, "team")

main:AddLabel("Status: Ready")
main:AddTextbox("Tag", "Enter...", function(text) end)
ui:AddKeybind("Open Menu", Enum.KeyCode.RightShift, function() end)

-- New: multi-select dropdown
local roles = main:AddMultiDropdown(
  "Roles",
  {"Sniper","Medic","Engineer","Scout"},
  {"Scout"},
  function(selectedList) print(table.concat(selectedList, ", ")) end,
  "roles"
)
```

Dropdown UX
- Smooth open/close animation
- Menu positions below the control
- Clicking outside closes the menu

Notifications
```lua
ui:Notify("Saved!", 2)
```

Config save/load
```lua
-- Save to SimpleUI/<windowTitle>_<name>.json if executor FS is available, else in-memory
ui:SaveConfig("default")
ui:LoadConfig("default")

-- Advanced
local blob = ui:ExportConfig()      -- returns a Lua table
ui:ImportConfig(blob)               -- apply values (only for controls created with ids)
```

Unload
```lua
ui:Destroy() -- removes window and clears cache entry so you can run again
```

### Components

#### Window and Tabs
```lua
local ui = SimpleUI:CreateWindow({
  title = "Script Hub",
  id = "MyHub",
  size = Vector2.new(420, 300),
  themePreset = "Midnight", -- presets: Dark (default), Light, Midnight
  theme = { Accent = Color3.fromRGB(255, 128, 0) } -- optional overrides
})
ui:BindToggleKey(Enum.KeyCode.RightShift)
ui:Show(); ui:Hide(); ui:Toggle()

local main = ui:AddTab("Main")
local settings = ui:AddTab("Settings")
```

#### Sections
- Title-only section:
```lua
main:AddSection("General")
```
- Collapsible group (add controls inside, then call `End()`):
```lua
local grp = main:BeginSection("Appearance", false) -- false = start open
-- controls here are placed inside the group body
grp.End()
-- grp.Toggle() to open/close
```

#### Controls
- Button
```lua
main:AddButton("Notify", function() ui:Notify("Hello!", 2) end)
```

- Toggle (returns Set/Get)
```lua
local god = main:AddToggle("God Mode", false, function(on) end, "god_mode")
god.Set(true)
print(god.Get())
```

- Slider (min, max, default, cb, id) — tooltip shows current value; returns Set/Get
```lua
local speed = main:AddSlider("Speed", 10, 300, 60, function(v) end, "speed")
speed.Set(120)
```

- Dropdown (single-select) — animated, outside-click closes; returns Set/Get/SetOptions
```lua
local team = main:AddDropdown("Team", {"Red","Blue","Green"}, "Red", function(v) end, "team")
team.Set("Blue")
team.SetOptions({"Alpha","Beta","Gamma"})
```

- MultiDropdown (multi-select) — returns Get/Set list
```lua
local roles = main:AddMultiDropdown("Roles", {"Sniper","Medic","Engineer","Scout"}, {"Scout"}, function(list) end, "roles")
print(table.concat(roles.Get(), ", "))
roles.Set({"Medic","Engineer"})
```

- Keybind — click to listen, then press key; callback fires on key press
```lua
local kb = ui:AddKeybind("Open Menu", Enum.KeyCode.RightShift, function() ui:Toggle() end)
kb.SetKey(Enum.KeyCode.F4)
```

- Textbox — callback on focus lost
```lua
main:AddTextbox("Tag", "Enter...", function(text) end)
```

- Label — returns SetText/GetText
```lua
local lbl = main:AddLabel("Status: Ready")
lbl.SetText("Status: Running")
```

#### Dropdown UX details
- Smooth open/close animation
- Menu positioned below control
- Clicking outside closes the menu

#### Theming
```lua
ui:SetThemePreset("Dark")            -- or "Light", "Midnight"
ui:SetTheme({ Accent = Color3.fromRGB(0,170,255) }) -- override specific colors
```

#### Config I/O
```lua
ui:SaveConfig("default")
ui:LoadConfig("default")
local data = ui:ExportConfig()  -- table of control ids -> values
ui:ImportConfig(data)           -- applies values back
```

### Demo hub included
`ScriptHubDemo.lua` demonstrates tabs, controls, config buttons, and the new multi-select dropdown. Open it with the raw URL above.

### Notes
- Library logs use prefixes `[+]` and `[-]`.
- RightShift toggles UI by default (animated). Override with `ui:BindToggleKey(Enum.KeyCode.X)`.
- If multiple windows exist (from different scripts), RightShift will toggle all via each window's `Toggle()`.
- The library is executor-friendly and does not touch the server.


