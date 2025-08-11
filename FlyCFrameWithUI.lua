-- FlyCFrameWithUI.lua
-- One-file loader that pulls SimpleUI from this repo and exposes a slider to control fly speed

-- Load SimpleUI from this repo
local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Trancezzzz/Senco/main/SimpleUI.lua"))()
local ui = SimpleUI:CreateWindow({ title = "Fly Controls", id = "FlyCFrameUI" })
local flyTab = ui:AddTab("Fly")
ui:BindToggleKey(Enum.KeyCode.RightShift)

----------------------------------------------------------------
-- CFrame Fly (anchored hover) with speed controlled by slider
----------------------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 60
local minSpeed, maxSpeed = 10, 300

local movement = {Forward=false, Backward=false, Left=false, Right=false, Up=false, Down=false}
local humanoid, root

local saved = { anchored = false, platformStand = false, autoRotate = true }
local savedCanCollide = {}
local pos
local conn

local function setRefs(char)
    humanoid = char:FindFirstChildOfClass("Humanoid")
    root = char:FindFirstChild("HumanoidRootPart")
end

local function dirFromInput()
    local cf = camera.CFrame
    local forward = cf.LookVector
    local right = cf.RightVector
    local up = Vector3.new(0,1,0)

    local d = Vector3.zero
    if movement.Forward  then d += forward end
    if movement.Backward then d -= forward end
    if movement.Right    then d += right   end
    if movement.Left     then d -= right   end
    if movement.Up       then d += up      end
    if movement.Down     then d -= up      end

    if d.Magnitude > 0 then d = d.Unit end
    return d
end

local function setCharCollideDisabled(disabled)
    if not player.Character then return end
    for _, inst in ipairs(player.Character:GetDescendants()) do
        if inst:IsA("BasePart") then
            if disabled then
                if savedCanCollide[inst] == nil then
                    savedCanCollide[inst] = inst.CanCollide
                end
                inst.CanCollide = false
            else
                local original = savedCanCollide[inst]
                if original ~= nil then
                    inst.CanCollide = original
                    savedCanCollide[inst] = nil
                end
            end
        end
    end
end

local function startFly()
    if flying or not root or not humanoid then return end
    flying = true

    saved.anchored = root.Anchored
    saved.platformStand = humanoid.PlatformStand
    saved.autoRotate = humanoid.AutoRotate

    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    setCharCollideDisabled(true)

    pos = root.Position
    root.Anchored = true

    conn = RunService.RenderStepped:Connect(function(dt)
        local d = dirFromInput()
        pos += d * speed * dt

        local look = camera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 1e-4 then
            flat = Vector3.new(0, 0, -1)
        else
            flat = flat.Unit
        end

        root.CFrame = CFrame.lookAt(pos, pos + flat)
    end)

    print("[+] Fly ON | Speed = " .. speed)
end

local function stopFly()
    if not flying then return end
    flying = false

    if conn then conn:Disconnect() conn = nil end

    if root then
        root.Anchored = saved.anchored
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if humanoid then
        humanoid.PlatformStand = saved.platformStand
        humanoid.AutoRotate = saved.autoRotate
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end

    setCharCollideDisabled(false)

    print("[-] Fly OFF")
end

local function toggle()
    if flying then stopFly() else startFly() end
end

-- Input for movement + toggle
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.E then
        toggle()
    elseif k == Enum.KeyCode.W then movement.Forward = true
    elseif k == Enum.KeyCode.S then movement.Backward = true
    elseif k == Enum.KeyCode.A then movement.Left = true
    elseif k == Enum.KeyCode.D then movement.Right = true
    elseif k == Enum.KeyCode.Space then movement.Up = true
    elseif k == Enum.KeyCode.LeftControl then movement.Down = true
    end
end)

UIS.InputEnded:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then movement.Forward = false
    elseif k == Enum.KeyCode.S then movement.Backward = false
    elseif k == Enum.KeyCode.A then movement.Left = false
    elseif k == Enum.KeyCode.D then movement.Right = false
    elseif k == Enum.KeyCode.Space then movement.Up = false
    elseif k == Enum.KeyCode.LeftControl then movement.Down = false
    end
end)

if player.Character then setRefs(player.Character) end
player.CharacterAdded:Connect(function(char)
    setRefs(char)
    if flying then stopFly() startFly() end
end)

----------------------------------------------------------------
-- UI wiring: slider controls 'speed' live
----------------------------------------------------------------
flyTab:AddSection("CFrame Fly")
flyTab:AddButton("Toggle Fly (E)", function() toggle() end)

local speedSlider = flyTab:AddSlider("Speed", minSpeed, maxSpeed, speed, function(v)
    speed = v
    if flying then print("[+] Speed = " .. speed) end
end, "fly_speed")

-- Settings tab with Unload + Config
local settings = ui:AddTab("Settings")
settings:AddSection("Config")
settings:AddButton("Save Config", function() ui:SaveConfig("fly") end)
settings:AddButton("Load Config", function() ui:LoadConfig("fly") end)
settings:AddSection("Session")
settings:AddButton("Unload UI", function() ui:Destroy() end)

flyTab:AddLabel("Use E to toggle. Space/LeftCtrl for vertical.")


