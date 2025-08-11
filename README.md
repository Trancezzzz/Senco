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
```

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

### Demo hub included
`ScriptHubDemo.lua` demonstrates tabs, controls, and config buttons. Open it with the raw URL above.

### Notes
- Library logs use prefixes `[+]` and `[-]`.
- RightShift toggles UI by default. Override with `ui:BindToggleKey(Enum.KeyCode.X)`.
- The library is executor-friendly and does not touch the server.

### Publishing (PowerShell)
```powershell
cd "C:\Users\dexte\New folder"
git init
git add -A
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/Trancezzzz/Senco.git
git push -u origin main
```

