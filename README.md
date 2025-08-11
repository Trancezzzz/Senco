SimpleUI (Executor-friendly Roblox GUI Library)

Single-file UI library for executors. Works locally in CoreGui/hidden UI and supports multiple scripts via getgenv() caching.

Loading from GitHub (after you push):

```
https://raw.githubusercontent.com/USERNAME/REPO/main/SimpleUI.lua
```

Usage example:

```lua
local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/SimpleUI.lua"))()
local ui = SimpleUI:CreateWindow({ title = "My Tools" })
ui:AddButton("Hello", function() ui:Notify("Hi!", 2) end)
```

Publish this folder to GitHub (PowerShell):

```powershell
cd "C:\Users\dexte\New folder"

git init
git add SimpleUI.lua README.md
git commit -m "Add SimpleUI executor-friendly GUI library"
git branch -M main

# If you have GitHub CLI:
# gh repo create REPO --public --source . --remote origin --push

# Or create repo manually on github.com, then:
# Replace USERNAME and REPO below
git remote add origin https://github.com/USERNAME/REPO.git
git push -u origin main
```

API quick ref:

```lua
local ui = SimpleUI:CreateWindow({ title = "Title", size = Vector2.new(420,300) })
ui:AddButton(text, function() end)
local t = ui:AddToggle(text, false, function(on) end)
local s = ui:AddSlider(text, 0, 100, 50, function(v) end)
local k = ui:AddKeybind(text, Enum.KeyCode.E, function() end)
ui:AddTextbox(text, "placeholder", function(txt) end)
ui:Notify(text, 2)
```

Logs use prefixes [+] and [-].

