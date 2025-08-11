-- SimpleUI.lua  (single-file library for executors)
-- Load with: local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/SimpleUI.lua"))()
-- Reuses a single shared instance via getgenv() so multiple scripts can call it.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

getgenv().__SIMPLE_UI__ = getgenv().__SIMPLE_UI__ or {}
local CACHE = getgenv().__SIMPLE_UI__
if CACHE.__LIB then
    return CACHE.__LIB
end

local function protect(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

local function getUiParent()
    local ok, hidden = pcall(function()
        return (gethui and gethui()) or (get_hidden_ui and get_hidden_ui()) or (gethiddenui and gethiddenui())
    end)
    if ok and typeof(hidden) == "Instance" then
        return hidden
    end
    return game:GetService("CoreGui")
end

local function new(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = inst
        end
    end
    return inst
end

local function round(obj, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 6) }).Parent = obj
end

local function pad(obj, p)
    new("UIPadding", {
        PaddingTop = UDim.new(0, p),
        PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p),
        PaddingRight = UDim.new(0, p),
    }).Parent = obj
end

local DEFAULT_THEME = {
    WindowBg = Color3.fromRGB(18,18,20),
    TitleBg = Color3.fromRGB(28,28,32),
    Accent = Color3.fromRGB(0,170,255),
    Text = Color3.fromRGB(235,235,235),
    SubText = Color3.fromRGB(170,170,170),
    RowBg = Color3.fromRGB(26,26,30),
    Button = Color3.fromRGB(40,40,46),
    ButtonHover = Color3.fromRGB(52,52,60),
    Warn = Color3.fromRGB(255,170,0),
}

local LIB = {}
LIB._theme = DEFAULT_THEME
LIB._screen = nil

local function ensureScreen()
    if LIB._screen and LIB._screen.Parent then return LIB._screen end
    local parent = getUiParent()
    local screen = new("ScreenGui", {
        Name = "SimpleUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    })
    protect(screen)
    screen.Parent = parent
    LIB._screen = screen
    return screen
end

local function makeDraggable(frame, handle)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input == startInput then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput.Position
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function LIB:SetTheme(partial)
    for k, v in pairs(partial or {}) do
        self._theme[k] = v
        DEFAULT_THEME[k] = v
    end
end

function LIB:CreateWindow(opts)
    opts = opts or {}
    local theme = {}
    for k, v in pairs(DEFAULT_THEME) do theme[k] = v end
    for k, v in pairs(opts.theme or {}) do theme[k] = v end

    local screen = ensureScreen()
    local size = opts.size or Vector2.new(420, 300)

    local window = new("Frame", {
        Name = opts.title or "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = theme.WindowBg,
        BorderSizePixel = 0
    })
    round(window, 8)
    window.Parent = screen

    local bar = new("Frame", {
        BackgroundColor3 = theme.TitleBg,
        Size = UDim2.new(1, 0, 0, 32),
        BorderSizePixel = 0,
        Parent = window
    })
    round(bar, 8)

    local title = new("TextLabel", {
        Text = tostring(opts.title or "Simple UI"),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        Parent = bar
    })

    local close = new("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.SubText,
        BackgroundColor3 = theme.Button,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(28, 20),
        Position = UDim2.new(1, -36, 0, 6),
        Parent = bar
    })
    round(close, 6)
    close.MouseEnter:Connect(function() close.BackgroundColor3 = theme.ButtonHover end)
    close.MouseLeave:Connect(function() close.BackgroundColor3 = theme.Button end)
    close.MouseButton1Click:Connect(function() screen.Enabled = false end)

    makeDraggable(window, bar)

    local content = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 1, -48),
        ScrollBarThickness = 6,
        BorderSizePixel = 0,
        Parent = window
    })
    pad(content, 8)
    local list = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    list.Parent = content
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
    end)

    local function row(text, height)
        local r = new("Frame", {
            BackgroundColor3 = theme.RowBg,
            Size = UDim2.new(1, 0, 0, height or 36),
            BorderSizePixel = 0,
            Parent = content
        })
        round(r, 6)
        local lbl = new("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -140, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            Parent = r
        })
        local right = new("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(130, r.Size.Y.Offset),
            Parent = r
        })
        return r, lbl, right
    end

    local api = {}
    api.Screen = screen
    api.Window = window
    api.Theme = theme

    function api:Show() screen.Enabled = true print("[+] UI shown") end
    function api:Hide() screen.Enabled = false print("[-] UI hidden") end
    function api:Destroy() window:Destroy() print("[-] UI destroyed") end
    function api:BindToggleKey(keyCode)
        UIS.InputBegan:Connect(function(input, gp)
            if not gp and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode then
                screen.Enabled = not screen.Enabled
            end
        end)
    end

    function api:AddButton(text, cb)
        local _, _, right = row(text, 36)
        local btn = new("TextButton", {
            Text = text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundColor3 = theme.Button,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 28),
            Parent = right
        })
        round(btn, 6)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.ButtonHover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.Button end)
        btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    function api:AddToggle(text, defaultValue, cb)
        local _, _, right = row(text, 36)
        local state = defaultValue and true or false

        local track = new("Frame", {
            BackgroundColor3 = state and theme.Accent or theme.Button,
            Size = UDim2.fromOffset(52, 24),
            Parent = right
        })
        round(track, 12)

        local knob = new("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            Size = UDim2.fromOffset(20, 20),
            Position = state and UDim2.fromOffset(28, 2) or UDim2.fromOffset(2, 2),
            Parent = track
        })
        round(knob, 10)

        local function set(v)
            state = v and true or false
            TS:Create(knob, TweenInfo.new(0.15), { Position = state and UDim2.fromOffset(28, 2) or UDim2.fromOffset(2, 2) }):Play()
            TS:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = state and theme.Accent or theme.Button }):Play()
            if cb then cb(state) end
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) end
        end)

        return { Set = set, Get = function() return state end }
    end

    function api:AddSlider(text, min, max, defaultValue, cb)
        min, max = min or 0, max or 100
        local value = defaultValue or min
        local _, _, right = row(text, 40)

        local bar = new("Frame", {
            BackgroundColor3 = theme.Button,
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 0.5, -4),
            Parent = right
        })
        round(bar, 4)

        local fill = new("Frame", {
            BackgroundColor3 = theme.Accent,
            Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0),
            Parent = bar
        })
        round(fill, 4)

        local dragging = false
        local function setFromX(px)
            local rel = math.clamp((px - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            value = math.floor((min + (max - min) * rel) + 0.5)
            fill.Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0)
            if cb then cb(value) end
        end

        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setFromX(i.Position.X)
            end
        end)
        bar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                setFromX(i.Position.X)
            end
        end)

        return {
            Set = function(v)
                setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * math.clamp((v - min) / math.max(1, (max - min)), 0, 1))
            end,
            Get = function() return value end,
        }
    end

    function api:AddKeybind(text, defaultKey, cb)
        local _, _, right = row(text, 36)
        local listening = false
        local current = defaultKey or Enum.KeyCode.E

        local btn = new("TextButton", {
            Text = current.Name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundColor3 = theme.Button,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 28),
            Parent = right
        })
        round(btn, 6)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.ButtonHover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.Button end)

        btn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            btn.Text = "Press a key..."
            local conn; conn = UIS.InputBegan:Connect(function(i, gp)
                if gp then return end
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    current = i.KeyCode
                    btn.Text = current.Name
                    listening = false
                    conn:Disconnect()
                end
            end)
        end)

        UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == current then
                if cb then cb() end
            end
        end)

        return { SetKey = function(k) current = k btn.Text = current.Name end, GetKey = function() return current end }
    end

    function api:AddTextbox(text, placeholder, cb)
        local _, _, right = row(text, 36)
        local box = new("TextBox", {
            Text = "",
            PlaceholderText = placeholder or "Type...",
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundColor3 = theme.Button,
            Size = UDim2.new(1, 0, 0, 28),
            Parent = right
        })
        round(box, 6)
        box.FocusLost:Connect(function()
            if cb then cb(box.Text) end
        end)
        return box
    end

    function api:Notify(text, seconds)
        seconds = seconds or 2
        local toast = new("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = Color3.new(1,1,1),
            BackgroundColor3 = theme.Warn,
            BackgroundTransparency = 0.15,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -10, 1, -10),
            Size = UDim2.fromOffset(240, 36),
            Parent = screen
        })
        round(toast, 6)
        pad(toast, 8)
        toast.TextWrapped = true
        toast.AutomaticSize = Enum.AutomaticSize.XY
        task.spawn(function()
            TS:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
            task.wait(seconds)
            TS:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
            task.wait(0.25)
            toast:Destroy()
        end)
    end

    print("[+] SimpleUI ready")
    return api
end

-- default visibility toggle (RightShift)
do
    local screen = ensureScreen()
    UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightShift then
            screen.Enabled = not screen.Enabled
        end
    end)
end

CACHE.__LIB = LIB
return LIB


