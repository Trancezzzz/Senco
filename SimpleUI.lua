-- SimpleUI.lua  (single-file library for executors)
-- Load with: local SimpleUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/SimpleUI.lua"))()
-- Reuses a single shared instance via getgenv() so multiple scripts can call it.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

getgenv().__SIMPLE_UI__ = getgenv().__SIMPLE_UI__ or {}
local CACHE = getgenv().__SIMPLE_UI__
if CACHE.__LIB then
    return CACHE.__LIB
end
CACHE.__windows = CACHE.__windows or {}

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

-- Simple tween helper
local function tween(obj, info, props)
    local ti
    if typeof(info) == "number" then
        ti = TweenInfo.new(info, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        ti = info
    end
    return TS:Create(obj, ti, props)
end

-- Ripple effect on buttons
local function attachRipple(button)
    if not button or not button:IsA("TextButton") then return end
    button.ClipsDescendants = true
    button.AutoButtonColor = false
    button.MouseButton1Down:Connect(function(x, y)
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local radius = math.max(absSize.X, absSize.Y)
        local ripple = Instance.new("Frame")
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.8
        ripple.Size = UDim2.fromOffset(0, 0)
        ripple.Position = UDim2.fromOffset((x - absPos.X), (y - absPos.Y))
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.ZIndex = (button.ZIndex or 1) + 1
        ripple.Parent = button
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        tween(ripple, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(radius * 1.8, radius * 1.8),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.4, function() if ripple then ripple:Destroy() end end)
    end)
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

local THEME_PRESETS = {
    Dark = DEFAULT_THEME,
    Light = {
        WindowBg = Color3.fromRGB(240,240,244),
        TitleBg = Color3.fromRGB(225,225,230),
        Accent = Color3.fromRGB(0,120,255),
        Text = Color3.fromRGB(20,20,22),
        SubText = Color3.fromRGB(80,80,90),
        RowBg = Color3.fromRGB(235,235,240),
        Button = Color3.fromRGB(220,220,228),
        ButtonHover = Color3.fromRGB(205,205,215),
        Warn = Color3.fromRGB(255,170,0),
    },
    Midnight = {
        WindowBg = Color3.fromRGB(10,12,18),
        TitleBg = Color3.fromRGB(18,20,28),
        Accent = Color3.fromRGB(120,90,255),
        Text = Color3.fromRGB(235,235,255),
        SubText = Color3.fromRGB(150,150,180),
        RowBg = Color3.fromRGB(16,18,24),
        Button = Color3.fromRGB(22,24,30),
        ButtonHover = Color3.fromRGB(30,32,40),
        Warn = Color3.fromRGB(255,140,0),
    },
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
    if opts.themePreset and THEME_PRESETS[opts.themePreset] then
        for k, v in pairs(THEME_PRESETS[opts.themePreset]) do theme[k] = v end
    end
    for k, v in pairs(opts.theme or {}) do theme[k] = v end

    local id = tostring(opts.id or opts.title or "Window")
    if CACHE.__windows[id] and CACHE.__windows[id].Window and CACHE.__windows[id].Window.Parent then
        local existing = CACHE.__windows[id]
        if type(existing.SetThemePreset) ~= "function" then
            -- Old instance without new APIs: destroy and recreate
            pcall(function() existing:Destroy() end)
            CACHE.__windows[id] = nil
        else
            print("[+] SimpleUI window already running: " .. id .. " (reuse)")
            if existing.Screen then existing.Screen.Enabled = true end
            return existing
        end
    end

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
    local scale = Instance.new("UIScale")
    scale.Scale = 0.96
    scale.Parent = window
    TS:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

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

    -- Tabs bar on the left
    local tabsBar = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(0, 120, 1, -48),
        Parent = window
    })
    local tabsList = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top
    })
    tabsList.Parent = tabsBar

    -- Content area on the right where tab pages live
    local contentArea = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 136, 0, 40),
        Size = UDim2.new(1, -144, 1, -48),
        Parent = window
    })

    local function isLight()
        local c = theme.WindowBg
        local r, g, b = c.R, c.G, c.B
        local lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum > 0.7
    end

    local function outlineColor()
        if isLight() then
            return Color3.fromRGB(20, 20, 28) -- darker outline on light themes
        end
        return theme.Accent
    end

    local function addGlow(frame)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.2
        stroke.Color = outlineColor()
        stroke.Transparency = isLight() and 0.8 or 0.6
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = frame
        -- keep stroke in sync with theme
        table.insert(api._themeWatch, function()
            stroke.Color = outlineColor()
            stroke.Transparency = isLight() and 0.8 or 0.6
        end)
        return stroke
    end
    local windowStroke = addGlow(window)
    local barStroke = addGlow(bar)

    local function makeContainer()
        local scrolling = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ScrollBarThickness = 6,
            Visible = false,
            Parent = contentArea
        })
        pad(scrolling, 8)
        local list = new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        list.Parent = scrolling
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrolling.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
        end)
        return scrolling
    end

    local function row(parentContainer, text, height)
        local r = new("Frame", {
            BackgroundColor3 = theme.RowBg,
            Size = UDim2.new(1, 0, 0, height or 36),
            BorderSizePixel = 0,
            Parent = parentContainer
        })
        round(r, 6)
        local rStroke = addGlow(r)
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
        table.insert(api._themeWatch, function()
            r.BackgroundColor3 = theme.RowBg
            lbl.TextColor3 = theme.Text
        end)
        return r, lbl, right, rStroke
    end

    local api = {}
    api.Screen = screen
    api.Window = window
    api.Theme = theme
    api._tabs = {}
    api._tabByName = {}
    api._defaultTab = nil
    api._registry = {}
    api._themeWatch = {}
    api.Id = id

    local function addWatch(fn)
        table.insert(api._themeWatch, fn)
    end
    local function applyTheme()
        for _, fn in ipairs(api._themeWatch) do
            pcall(fn)
        end
    end

    -- base theme watchers for window chrome
    addWatch(function()
        window.BackgroundColor3 = theme.WindowBg
        bar.BackgroundColor3 = theme.TitleBg
        title.TextColor3 = theme.Text
        close.BackgroundColor3 = theme.Button
        close.TextColor3 = theme.SubText
        windowStroke.Color = theme.Accent
        barStroke.Color = theme.Accent
    end)

    api._visible = true
    api._scale = window:FindFirstChildOfClass("UIScale")
    function api:Show()
        screen.Enabled = true
        if self._scale then self._scale.Scale = 0.96 end
        window.BackgroundTransparency = 0
        bar.BackgroundTransparency = 0
        tween(self._scale or window, 0.2, { Scale = 1 }):Play()
        self._visible = true
        print("[+] UI shown")
    end
    function api:Hide()
        if self._visible then
            local tw = tween(self._scale or window, 0.15, { Scale = 0.97 })
            tw:Play()
            tw.Completed:Wait()
        end
        screen.Enabled = false
        self._visible = false
        print("[-] UI hidden")
    end
    function api:Toggle()
        if self._visible and screen.Enabled then self:Hide() else self:Show() end
    end
    function api:Destroy()
        if window and window.Parent then window:Destroy() end
        if CACHE.__windows and CACHE.__windows[api.Id] then
            CACHE.__windows[api.Id] = nil
        end
        print("[-] UI destroyed")
    end
    function api:SetTheme(overrides)
        for k, v in pairs(overrides or {}) do theme[k] = v end
        applyTheme()
    end
    function api:SetThemePreset(preset)
        local p = THEME_PRESETS[tostring(preset)]
        if p then
            for k, v in pairs(p) do theme[k] = v end
            applyTheme()
        end
    end
    function api:BindToggleKey(keyCode)
        UIS.InputBegan:Connect(function(input, gp)
            if not gp and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode then
                screen.Enabled = not screen.Enabled
            end
        end)
    end

    -- Internal helper to register controls for configs
    local function register(id, getter, setter)
        if not id then return end
        api._registry[id] = { get = getter, set = setter }
    end

    -- Tab creation
    function api:AddTab(tabName)
        tabName = tostring(tabName or ("Tab " .. tostring(#api._tabs + 1)))
        -- Deduplicate: return existing tab if it already exists
        if api._tabByName[tabName] then
            local existing = api._tabByName[tabName]
            -- Activate existing tab
            for _, t in ipairs(api._tabs) do
                t.Container.Visible = false
                if t.TabButton then t.TabButton.BackgroundColor3 = theme.Button end
            end
            existing.Container.Visible = true
            if existing.TabButton then existing.TabButton.BackgroundColor3 = theme.ButtonHover end
            return existing
        end

        local tabBtn = new("TextButton", {
            Text = tabName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundColor3 = theme.Button,
            AutoButtonColor = false,
            Size = UDim2.new(1, -8, 0, 28),
            Parent = tabsBar
        })
        round(tabBtn, 6)
        attachRipple(tabBtn)
        tabBtn.MouseEnter:Connect(function() tabBtn.BackgroundColor3 = theme.ButtonHover end)
        tabBtn.MouseLeave:Connect(function() tabBtn.BackgroundColor3 = theme.Button end)
        addWatch(function()
            tabBtn.BackgroundColor3 = theme.Button
            tabBtn.TextColor3 = theme.Text
        end)
        local tbScale = Instance.new("UIScale")
        tbScale.Parent = tabBtn
        tabBtn.MouseButton1Down:Connect(function()
            TS:Create(tbScale, TweenInfo.new(0.08), { Scale = 0.97 }):Play()
        end)
        tabBtn.MouseButton1Up:Connect(function()
            TS:Create(tbScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
        end)

        local container = makeContainer()

        local tabApi = {}
        tabApi.Container = container
        tabApi.TabButton = tabBtn
        tabApi.Name = tabName
        tabApi._current = nil

        local function activate()
            for _, t in ipairs(api._tabs) do
                t.Container.Visible = false
            end
            container.Visible = true
        end
        tabBtn.MouseButton1Click:Connect(activate)

        -- Components inside tab
        function tabApi:AddSection(text)
            local lbl = new("TextLabel", {
                Text = tostring(text or "Section"),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container
            })
            addWatch(function() lbl.TextColor3 = theme.SubText end)
            return lbl
        end

        -- Collapsible groups to organize many controls
        function tabApi:BeginSection(title, collapsed)
            local group = new("Frame", {
                BackgroundColor3 = theme.RowBg,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = container
            })
            round(group, 6)
            local header = new("TextButton", {
                Text = tostring(title or "Section"),
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = theme.Text,
                BackgroundColor3 = Color3.new(0,0,0),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Size = UDim2.new(1, -8, 0, 28),
                Position = UDim2.fromOffset(8, 2),
                Parent = group
            })
            local body = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 32),
                Size = UDim2.new(1, -16, 0, 0),
                Parent = group
            })
            local bl = new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
            bl.Parent = body
            local function resize()
                group.Size = UDim2.new(1, 0, 0, 32 + (body.Visible and (bl.AbsoluteContentSize.Y + 8) or 0))
            end
            bl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
            local open = not collapsed
            body.Visible = open
            header.Text = (open and "▼ " or "► ") .. header.Text
            local function toggle()
                open = not open
                body.Visible = open
                header.Text = (open and "▼ " or "► ") .. tostring(title or "Section")
                resize()
            end
            header.MouseButton1Click:Connect(toggle)
            task.defer(resize)
            tabApi._current = body
            return {
                End = function()
                    tabApi._current = nil
                    resize()
                end,
                Toggle = toggle,
                Body = body,
            }
        end

        function tabApi:AddLabel(text)
            local frame = new("Frame", {
                BackgroundColor3 = theme.RowBg,
                Size = UDim2.new(1, 0, 0, 30),
                BorderSizePixel = 0,
                Parent = container
            })
            round(frame, 6)
            local fStroke = addGlow(frame)
            local lbl = new("TextLabel", {
                Text = tostring(text or "Label"),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                Parent = frame
            })
            addWatch(function()
                frame.BackgroundColor3 = theme.RowBg
                lbl.TextColor3 = theme.Text
                fStroke.Color = theme.Accent
            end)
            return {
                SetText = function(t) lbl.Text = tostring(t) end,
                GetText = function() return lbl.Text end
            }
        end

        function tabApi:AddButton(text, cb)
            local _, _, right = row(container, text, 36)
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
            attachRipple(btn)
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.ButtonHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.Button end)
            btn.MouseButton1Click:Connect(function() if cb then cb() end end)
            addWatch(function()
                btn.BackgroundColor3 = theme.Button
                btn.TextColor3 = theme.Text
            end)
            local s = Instance.new("UIScale")
            s.Parent = btn
            btn.MouseButton1Down:Connect(function() TS:Create(s, TweenInfo.new(0.08), { Scale = 0.97 }):Play() end)
            btn.MouseButton1Up:Connect(function() TS:Create(s, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
        end

        function tabApi:AddToggle(text, defaultValue, cb, id)
            local _, _, right = row(container, text, 36)
            local state = defaultValue and true or false
            local track = new("Frame", { BackgroundColor3 = state and theme.Accent or theme.Button, Size = UDim2.fromOffset(52, 24), Parent = right })
            round(track, 12)
            local knob = new("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(20, 20), Position = state and UDim2.fromOffset(28, 2) or UDim2.fromOffset(2, 2), Parent = track })
            round(knob, 10)
            local function set(v)
                state = v and true or false
                TS:Create(knob, TweenInfo.new(0.15), { Position = state and UDim2.fromOffset(28, 2) or UDim2.fromOffset(2, 2) }):Play()
                TS:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = state and theme.Accent or theme.Button }):Play()
                if cb then cb(state) end
            end
            track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) end end)
            addWatch(function() set(state) end)
            register(id, function() return state end, set)
            return { Set = set, Get = function() return state end }
        end

        function tabApi:AddSlider(text, min, max, defaultValue, cb, id)
            min, max = min or 0, max or 100
            local value = defaultValue or min
            local rowFrame, labelLeft, right = row(container, text, 40)
            labelLeft.Text = string.format("%s: %s", tostring(text), tostring(value))
            local bar = new("Frame", { BackgroundColor3 = theme.Button, Size = UDim2.new(1, -50, 0, 8), Position = UDim2.new(0, 0, 0.5, -4), Parent = right })
            round(bar, 4)
            local fill = new("Frame", { BackgroundColor3 = theme.Accent, Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0), Parent = bar })
            round(fill, 4)
            local valueBox = new("TextBox", {
                Text = tostring(value),
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextColor3 = theme.Text,
                BackgroundColor3 = theme.Button,
                ClearTextOnFocus = false,
                Size = UDim2.fromOffset(46, 22),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Parent = right
            })
            round(valueBox, 4)
            local tooltip = new("TextLabel", {
                Text = tostring(value),
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                BackgroundColor3 = theme.RowBg,
                TextColor3 = theme.Text,
                BackgroundTransparency = 0.1,
                Visible = false,
                ZIndex = 50,
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.fromOffset(40, 16),
                Parent = rowFrame
            })
            round(tooltip, 4)
            local dragging = false
            local function setFromX(px)
                local rel = math.clamp((px - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                value = math.floor((min + (max - min) * rel) + 0.5)
                fill.Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0)
                if cb then cb(value) end
                labelLeft.Text = string.format("%s: %s", tostring(text), tostring(value))
                tooltip.Text = tostring(value)
                valueBox.Text = tostring(value)
                local localX = math.clamp(px - rowFrame.AbsolutePosition.X, 12, rowFrame.AbsoluteSize.X - 12)
                local localY = bar.AbsolutePosition.Y - rowFrame.AbsolutePosition.Y - 4
                tooltip.Position = UDim2.fromOffset(localX, localY)
            end
            addWatch(function()
                bar.BackgroundColor3 = theme.Button
                fill.BackgroundColor3 = theme.Accent
                valueBox.BackgroundColor3 = theme.Button
                valueBox.TextColor3 = theme.Text
                tooltip.BackgroundColor3 = theme.RowBg
                tooltip.TextColor3 = theme.Text
            end)
            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    tooltip.Visible = true
                    setFromX(i.Position.X)
                end
            end)
            bar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            UIS.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if dragging then setFromX(i.Position.X) end
                end
            end)
            bar.MouseEnter:Connect(function()
                tooltip.Visible = true
                -- position by current value when just hovering
                local px = bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((value - min) / math.max(1, (max - min)))
                setFromX(px)
            end)
            bar.MouseLeave:Connect(function()
                if not dragging then tooltip.Visible = false end
            end)
            valueBox.FocusLost:Connect(function()
                local n = tonumber(valueBox.Text)
                if n then
                    n = math.clamp(math.floor(n + 0.5), min, max)
                    setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((n - min) / math.max(1, (max - min))))
                else
                    valueBox.Text = tostring(value)
                end
            end)
            local function set(v) setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * math.clamp((v - min) / math.max(1, (max - min)), 0, 1)) end
            register(id, function() return value end, set)
            return { Set = set, Get = function() return value end }
        end

        function tabApi:AddDropdown(text, options, defaultValue, cb, id)
            options = options or {}
            local rowFrame, _, right = row(container, text, 36)
            local btn = new("TextButton", {
                Text = tostring(defaultValue or (options[1] or "Select")),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                BackgroundColor3 = theme.Button,
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = right
            })
            round(btn, 6)
            attachRipple(btn)
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.ButtonHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.Button end)

            local open = false
            local menu = new("Frame", {
                BackgroundColor3 = theme.RowBg,
                BorderSizePixel = 0,
                Visible = false,
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 1, 4),
                Parent = rowFrame
            })
            round(menu, 6)
            pad(menu, 6)
            local menuList = new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
            menuList.Parent = menu
            local menuStroke = Instance.new("UIStroke")
            menuStroke.Thickness = 1
            menuStroke.Color = outlineColor()
            menuStroke.Transparency = 0.6
            menuStroke.Parent = menu
            addWatch(function()
                btn.BackgroundColor3 = theme.Button
                btn.TextColor3 = theme.Text
                menu.BackgroundColor3 = theme.RowBg
                menuStroke.Color = outlineColor()
            end)

            local value = defaultValue or options[1]

            local function rebuild()
                menu:ClearAllChildren()
                menuList.Parent = menu
                for _, opt in ipairs(options) do
                    local optBtn = new("TextButton", {
                        Text = tostring(opt),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        BackgroundColor3 = theme.Button,
                        AutoButtonColor = false,
                        Size = UDim2.new(1, -8, 0, 24),
                        Parent = menu
                    })
                    round(optBtn, 4)
                    attachRipple(optBtn)
                    optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = theme.ButtonHover end)
                    optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = theme.Button end)
                    optBtn.MouseButton1Click:Connect(function()
                        value = opt
                        btn.Text = tostring(value)
                        open = false
                        tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, 0) }):Play()
                        task.delay(0.13, function() menu.Visible = false end)
                        if cb then cb(value) end
                    end)
                end
                menu.Size = UDim2.new(1, -16, 0, math.max(0, menuList.AbsoluteContentSize.Y + 8))
            end
            rebuild()

            btn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    menu.Visible = true
                    rebuild()
                    tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, menuList.AbsoluteContentSize.Y + 8) }):Play()
                else
                    tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, 0) }):Play()
                    task.delay(0.13, function() if not open then menu.Visible = false end end)
                end
            end)

            -- Close when clicking outside
            local outsideConn
            outsideConn = UIS.InputBegan:Connect(function(i, gp)
                if gp then return end
                if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = UIS:GetMouseLocation()
                    local abs = menu.AbsolutePosition
                    local size = menu.AbsoluteSize
                    local inside = (mp.X >= abs.X and mp.X <= abs.X + size.X and mp.Y >= abs.Y and mp.Y <= abs.Y + size.Y)
                    if not inside then
                        open = false
                        tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, 0) }):Play()
                        task.delay(0.13, function() if not open then menu.Visible = false end end)
                    end
                end
            end)

            local function set(v)
                value = v
                btn.Text = tostring(v)
                if cb then cb(value) end
            end
            local function setOptions(newOptions)
                options = newOptions or {}
                rebuild()
            end
            register(id, function() return value end, set)
            return { Set = set, Get = function() return value end, SetOptions = setOptions }
        end

        function tabApi:AddMultiDropdown(text, options, defaults, cb, id)
            options = options or {}
            local selected = {}
            if type(defaults) == "table" then for _, v in ipairs(defaults) do selected[tostring(v)] = true end end
            local rowFrame, _, right = row(container, text, 36)
            local btn = new("TextButton", {
                Text = "Select...",
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                BackgroundColor3 = theme.Button,
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = right
            })
            round(btn, 6)
            attachRipple(btn)
            local function refreshText()
                local list = {}
                for _, opt in ipairs(options) do if selected[tostring(opt)] then table.insert(list, tostring(opt)) end end
                if #list == 0 then btn.Text = "Select..." elseif #list <= 2 then btn.Text = table.concat(list, ", ") else btn.Text = list[1] .. " +" .. tostring(#list - 1) end
            end
            local open = false
            local menu = new("Frame", { BackgroundColor3 = theme.RowBg, BorderSizePixel = 0, Visible = false, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 1, 4), Parent = rowFrame })
            round(menu, 6)
            pad(menu, 6)
            local menuList = new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
            menuList.Parent = menu
            local function rebuild()
                menu:ClearAllChildren()
                menuList.Parent = menu
                for _, opt in ipairs(options) do
                    local chosen = selected[tostring(opt)]
                    local optBtn = new("TextButton", { Text = (chosen and "[x] " or "[ ] ") .. tostring(opt), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = theme.Text, BackgroundColor3 = theme.Button, AutoButtonColor = false, Size = UDim2.new(1, -8, 0, 24), Parent = menu })
                    round(optBtn, 4)
                    attachRipple(optBtn)
                    optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = theme.ButtonHover end)
                    optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = theme.Button end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected[tostring(opt)] = not selected[tostring(opt)] or nil
                        rebuild()
                        refreshText()
                        if cb then
                            local out = {}
                            for _, o in ipairs(options) do if selected[tostring(o)] then table.insert(out, o) end end
                            cb(out)
                        end
                    end)
                end
                menu.Size = UDim2.new(1, -16, 0, menuList.AbsoluteContentSize.Y + 8)
            end
            rebuild()
            refreshText()
            btn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    menu.Visible = true
                    rebuild()
                    tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, menuList.AbsoluteContentSize.Y + 8) }):Play()
                else
                    tween(menu, 0.12, { Size = UDim2.new(1, -16, 0, 0) }):Play()
                    task.delay(0.13, function() if not open then menu.Visible = false end end)
                end
            end)
            register(id, function()
                local out = {}
                for _, o in ipairs(options) do if selected[tostring(o)] then table.insert(out, o) end end
                return out
            end, function(vals)
                selected = {}
                if type(vals) == "table" then for _, v in ipairs(vals) do selected[tostring(v)] = true end end
                rebuild(); refreshText()
            end)
            return {
                Get = function()
                    local out = {}
                    for _, o in ipairs(options) do if selected[tostring(o)] then table.insert(out, o) end end
                    return out
                end,
                Set = function(vals)
                    selected = {}
                    if type(vals) == "table" then for _, v in ipairs(vals) do selected[tostring(v)] = true end end
                    rebuild(); refreshText()
                end
            }
        end

        -- expose base methods to tab
        tabApi.Row = function(text, height) return row(tabApi._current or container, text, height) end

        table.insert(api._tabs, tabApi)
        api._tabByName[tabName] = tabApi
        if #api._tabs == 1 then
            api._defaultTab = tabApi
            tabBtn.BackgroundColor3 = theme.ButtonHover
            tabApi.Container.Visible = true
        end
        return tabApi
    end

    -- Default tab for backwards compatibility
    local defaultTab = api:AddTab("Main")

    function api:AddButton(text, cb)
        local _, _, right = defaultTab.Row(text, 36)
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
        attachRipple(btn)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.ButtonHover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.Button end)
        btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    function api:AddToggle(text, defaultValue, cb, id)
        local _, _, right = defaultTab.Row(text, 36)
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

        register(id, function() return state end, set)
        return { Set = set, Get = function() return state end }
    end

    function api:AddSlider(text, min, max, defaultValue, cb, id)
        min, max = min or 0, max or 100
        local value = defaultValue or min
        local rowFrame, labelLeft, right = defaultTab.Row(text, 40)
        labelLeft.Text = string.format("%s: %s", tostring(text), tostring(value))

        local bar = new("Frame", {
            BackgroundColor3 = theme.Button,
            Size = UDim2.new(1, -50, 0, 8),
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
        local valueBox = new("TextBox", {
            Text = tostring(value),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = theme.Text,
            BackgroundColor3 = theme.Button,
            ClearTextOnFocus = false,
            Size = UDim2.fromOffset(46, 22),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Parent = right
        })
        round(valueBox, 4)

        local tooltip = new("TextLabel", {
            Text = tostring(value),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            BackgroundColor3 = theme.RowBg,
            TextColor3 = theme.Text,
            BackgroundTransparency = 0.1,
            Visible = false,
            ZIndex = 50,
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.fromOffset(40, 16),
            Parent = rowFrame
        })
        round(tooltip, 4)
        local dragging = false
        local function setFromX(px)
            local rel = math.clamp((px - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            value = math.floor((min + (max - min) * rel) + 0.5)
            fill.Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0)
            if cb then cb(value) end
            labelLeft.Text = string.format("%s: %s", tostring(text), tostring(value))
            tooltip.Text = tostring(value)
            valueBox.Text = tostring(value)
            local localX = math.clamp(px - rowFrame.AbsolutePosition.X, 12, rowFrame.AbsoluteSize.X - 12)
            local localY = bar.AbsolutePosition.Y - rowFrame.AbsolutePosition.Y - 4
            tooltip.Position = UDim2.fromOffset(localX, localY)
        end

        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                tooltip.Visible = true
                setFromX(i.Position.X)
            end
        end)
        bar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UIS.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                if dragging then setFromX(i.Position.X) end
            end
        end)
        bar.MouseEnter:Connect(function()
            tooltip.Visible = true
            local px = bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((value - min) / math.max(1, (max - min)))
            setFromX(px)
        end)
        bar.MouseLeave:Connect(function()
            if not dragging then tooltip.Visible = false end
        end)
        valueBox.FocusLost:Connect(function()
            local n = tonumber(valueBox.Text)
            if n then
                n = math.clamp(math.floor(n + 0.5), min, max)
                setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((n - min) / math.max(1, (max - min))))
            else
                valueBox.Text = tostring(value)
            end
        end)

        local function set(v)
            setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * math.clamp((v - min) / math.max(1, (max - min)), 0, 1))
        end
        register(id, function() return value end, set)
        return {
            Set = function(v)
                set(v)
            end,
            Get = function() return value end,
        }
    end

    function api:AddKeybind(text, defaultKey, cb)
        local _, _, right = defaultTab.Row(text, 36)
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
        attachRipple(btn)
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
        local _, _, right = defaultTab.Row(text, 36)
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
            addWatch(function()
                box.BackgroundColor3 = theme.Button
                box.TextColor3 = theme.Text
            end)
        box.FocusLost:Connect(function()
            if cb then cb(box.Text) end
        end)
        return box
    end

    -- Config I/O
    local function canFS()
        return (typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function" and typeof(makefolder) == "function")
    end
    local function configPath(name)
        name = tostring(name or "default")
        local root = "SimpleUI"
        if canFS() then
            if not isfolder(root) then pcall(makefolder, root) end
            return string.format("%s/%s_%s.json", root, tostring(window.Name), name)
        end
        return nil
    end
    function api:ExportConfig()
        local data = {}
        for id, rec in pairs(api._registry) do
            data[id] = rec.get()
        end
        return data
    end
    function api:ImportConfig(tbl)
        if type(tbl) ~= "table" then return end
        for id, val in pairs(tbl) do
            local rec = api._registry[id]
            if rec and rec.set then pcall(rec.set, val) end
        end
    end
    function api:SaveConfig(name)
        local path = configPath(name)
        local data = HttpService:JSONEncode(self:ExportConfig())
        if path then
            pcall(writefile, path, data)
            print("[+] Saved config to ", path)
        else
            -- fallback to global memory
            CACHE.__configs = CACHE.__configs or {}
            CACHE.__configs[window.Name .. ":" .. tostring(name or "default")] = data
            print("[+] Saved config to memory")
        end
    end
    function api:LoadConfig(name)
        local path = configPath(name)
        local raw
        if path and isfile(path) then
            raw = readfile(path)
        elseif CACHE.__configs then
            raw = CACHE.__configs[window.Name .. ":" .. tostring(name or "default")]
        end
        if raw then
            local ok, tbl = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok then self:ImportConfig(tbl) print("[+] Config loaded") else print("[-] Invalid config data") end
        else
            print("[-] No config found")
        end
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

    -- register this window instance
    CACHE.__windows[id] = api

    print("[+] SimpleUI ready")
    return api
end

-- default visibility toggle (RightShift)
do
    local screen = ensureScreen()
    UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightShift then
            local any = false
            if CACHE.__windows then
                for _, win in pairs(CACHE.__windows) do
                    if type(win.Toggle) == "function" then
                        win:Toggle()
                        any = true
                    end
                end
            end
            if not any then
                screen.Enabled = not screen.Enabled
            end
        end
    end)
end

CACHE.__LIB = LIB
return LIB


