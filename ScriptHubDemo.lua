-- ScriptHubDemo.lua
-- Example loader showing how to build a small script hub UI using SimpleUI
-- Replace USERNAME/REPO with your GitHub details, then run this in your executor.

local RAW = "https://raw.githubusercontent.com/Trancezzzz/Senco/main/SimpleUI.lua"
local SimpleUI = loadstring(game:HttpGet(RAW))()

local ui = SimpleUI:CreateWindow({ title = "My Script Hub" })
ui:BindToggleKey(Enum.KeyCode.RightShift) -- toggle UI

-- Tabs
local main = ui:AddTab("Main")
local player = ui:AddTab("Player")
local settings = ui:AddTab("Settings")

-- Main tab
main:AddSection("General")
main:AddButton("Greet", function()
    ui:Notify("Welcome to the hub!", 2)
end)

local god = main:AddToggle("God Mode", false, function(on)
    print("[+] God Mode:", on)
end, "god_mode")

local team = main:AddDropdown("Team", {"Red", "Blue", "Green"}, "Red", function(v)
    print("[+] Team:", v)
end, "team")

-- Player tab
player:AddSection("Movement")
local ws = player:AddSlider("WalkSpeed", 8, 32, 16, function(v)
    local lp = game.Players.LocalPlayer
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, "walkspeed")

local jp = player:AddSlider("JumpPower", 20, 100, 50, function(v)
    local lp = game.Players.LocalPlayer
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end, "jumppower")

-- Settings tab
settings:AddSection("Config")
settings:AddButton("Save Config", function()
    ui:SaveConfig("default")
end)
settings:AddButton("Load Config", function()
    ui:LoadConfig("default")
end)

settings:AddSection("Info")
settings:AddLabel("Press RightShift to toggle UI")

ui:Notify("[+] Script Hub loaded", 2)


