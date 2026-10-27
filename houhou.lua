--[[
    HuohuoLib  |  Honkai: Star Rail (Huohuo) themed Roblox UI library
    MacLib-style layout: traffic-light window controls, sidebar tabs, two-column sections.

    Palette: deep violet base, mint/teal accent, lavender secondary, soft gold talisman highlights.

    ---------------------------------------------------------------
    QUICK START
    ---------------------------------------------------------------
    local Huohuo = loadstring(readfile("HuohuoLib.lua"))()   -- or paste / loadstring(game:HttpGet(...))()

    local Window = Huohuo:Window({
        Title = "Huohuo Hub",
        Subtitle = "Ghostly Abundance",
        Size = UDim2.fromOffset(720, 480),
        Keybind = Enum.KeyCode.RightShift,

        -- YOUR IMAGE (any one of these):
        --   "rbxassetid://123456789" or just 123456789    (uploaded to Roblox as a Decal/Image)
        --   "https://example.com/huohuo.png"              (needs executor request + writefile + getcustomasset)
        --   "huohuo.png"                                  (file in your executor workspace folder)
        Background = "rbxassetid://0",
        BackgroundTransparency = 0.7,   -- 0 = fully visible, 1 = hidden
    })

    local Main  = Window:TabGroup({ Name = "Main" })
    local Combat = Main:Tab({ Name = "Combat" })
    local Sec = Combat:Section({ Name = "Abilities", Side = "Left" })

    Sec:Toggle({ Name = "Auto Heal", Default = false, Flag = "AutoHeal", Callback = function(v) print(v) end })
    Sec:Slider({ Name = "Heal Threshold", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "Threshold", Callback = print })
    Sec:Dropdown({ Name = "Target", Options = {"Lowest HP", "Closest", "Self"}, Default = "Lowest HP", Callback = print })
    Sec:Button({ Name = "Ghostly Ward", Callback = function() Window:Notify({ Title = "Huohuo", Description = "Ward activated!", Duration = 4 }) end })
    Sec:Input({ Name = "Name", Placeholder = "Type here...", Callback = print })
    Sec:Keybind({ Name = "Toggle Key", Default = Enum.KeyCode.E, Callback = function() print("pressed") end })
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(23, 17, 38),   -- deep violet
    Panel      = Color3.fromRGB(33, 25, 54),   -- sidebar / panels
    Element    = Color3.fromRGB(46, 36, 72),   -- rows
    Accent     = Color3.fromRGB(110, 231, 205),-- Huohuo mint/teal
    Accent2    = Color3.fromRGB(179, 150, 242),-- lavender
    Gold       = Color3.fromRGB(255, 214, 120),-- talisman gold
    Text       = Color3.fromRGB(242, 238, 252),
    SubText    = Color3.fromRGB(164, 154, 192),
    Red        = Color3.fromRGB(255, 95, 109),
    Yellow     = Color3.fromRGB(255, 202, 94),
    Green      = Color3.fromRGB(94, 226, 160),
}

local Library = { Flags = {}, Options = {}, Theme = Theme }

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function Create(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function Stroke(color, trans, thick)
    return Create("UIStroke", {
        Color = color or Theme.Accent, Transparency = trans or 0.7,
        Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function Pad(l, t, r, b)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
        PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0),
    })
end
local function Tween(obj, props, t, style)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Label(props)
    local p = {
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, RichText = true,
    }
    for k, v in pairs(props) do p[k] = v end
    return Create("TextLabel", p)
end

local function ResolveImage(src)
    if src == nil or src == "" then return nil end
    if type(src) == "number" or tonumber(src) then
        if tonumber(src) == 0 then return nil end
        return "rbxassetid://" .. tostring(src)
    end
    if src:find("^rbxasset") then return src end
    local gca = getcustomasset or getsynasset
    if src:find("^https?://") then
        local req = request or http_request or (syn and syn.request)
        if req and writefile and gca then
            local ok, res = pcall(function()
                local r = req({ Url = src, Method = "GET" })
                local name = "HuohuoLib_bg_" .. tostring(#src) .. ".png"
                writefile(name, r.Body)
                return gca(name)
            end)
            if ok then return res end
        end
        warn("[HuohuoLib] Could not load image URL (executor lacks request/writefile/getcustomasset).")
        return nil
    end
    if isfile and gca and isfile(src) then
        local ok, res = pcall(gca, src)
        if ok then return res end
    end
    return nil
end

local function Keyname(k)
    return (typeof(k) == "EnumItem") and k.Name or "None"
end

----------------------------------------------------------------------
-- Section elements
----------------------------------------------------------------------
local Section = {}
Section.__index = Section

function Section:_order()
    self._n = (self._n or 0) + 1
    return self._n
end

function Section:_row(height)
    return Create("Frame", {
        Size = UDim2.new(1, 0, 0, height or 34),
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15,
        LayoutOrder = self:_order(), Parent = self.Content,
    }, { Corner(8) })
end

local function Register(self, opts, obj)
    if opts.Flag then
        Library.Options[opts.Flag] = obj
    end
    return obj
end

function Section:Header(o)
    o = type(o) == "string" and { Name = o } or o
    local l = Label({
        Text = o.Name, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent2,
        Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self:_order(), Parent = self.Content,
    })
    return { SetText = function(_, t) l.Text = t end }
end

function Section:Label(o)
    o = type(o) == "string" and { Name = o } or o
    local l = Label({
        Text = o.Name, TextColor3 = Theme.SubText, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = self:_order(), Parent = self.Content,
    })
    return { SetText = function(_, t) l.Text = t end }
end

function Section:Divider()
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Accent2, BackgroundTransparency = 0.8,
        BorderSizePixel = 0, LayoutOrder = self:_order(), Parent = self.Content,
    })
end

function Section:Button(o)
    local row = self:_row(34)
    local btn = Create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = row,
    })
    Label({ Text = o.Name, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(12, 0), Parent = row })
    local arrow = Label({
        Text = "✦", TextColor3 = Theme.Accent, Size = UDim2.fromOffset(24, 34), Position = UDim2.new(1, -30, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, Parent = row,
    })
    btn.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.Accent2:Lerp(Theme.Element, 0.75) }) end)
    btn.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.Element }) end)
    btn.MouseButton1Click:Connect(function()
        Tween(arrow, { TextColor3 = Theme.Gold }, 0.08)
        task.delay(0.15, function() Tween(arrow, { TextColor3 = Theme.Accent }, 0.2) end)
        if o.Callback then task.spawn(o.Callback) end
    end)
    return { SetText = function(_, t) end }
end

function Section:Toggle(o)
    local state = o.Default or false
    local row = self:_row(34)
    local btn = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
    Label({ Text = o.Name, Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(12, 0), Parent = row })
    local track = Create("Frame", {
        Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = Theme.Background, Parent = row,
    }, { Corner(10), Stroke(Theme.Accent2, 0.6) })
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Theme.SubText, Parent = track,
    }, { Corner(7) })

    local obj = {}
    local function render(anim)
        local t = anim and 0.18 or 0
        Tween(track, { BackgroundColor3 = state and Theme.Accent or Theme.Background }, t)
        Tween(knob, {
            Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and Theme.Background or Theme.SubText,
        }, t)
    end
    function obj:Set(v, silent)
        state = not not v
        render(true)
        if o.Flag then Library.Flags[o.Flag] = state end
        if not silent and o.Callback then task.spawn(o.Callback, state) end
    end
    function obj:Get() return state end
    btn.MouseButton1Click:Connect(function() obj:Set(not state) end)
    render(false)
    if o.Flag then Library.Flags[o.Flag] = state end
    if o.Default and o.Callback then task.spawn(o.Callback, state) end
    return Register(self, o, obj)
end

function Section:Slider(o)
    local min, max = o.Min or 0, o.Max or 100
    local inc = o.Increment or 1
    local dec = tostring(inc):match("%.(%d+)")
    dec = dec and #dec or 0
    local value = math.clamp(o.Default or min, min, max)
    local row = self:_row(50)
    Label({ Text = o.Name, Size = UDim2.new(1, -80, 0, 22), Position = UDim2.fromOffset(12, 4), Parent = row })
    local valLabel = Label({
        Size = UDim2.fromOffset(70, 22), Position = UDim2.new(1, -82, 0, 4),
        TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Theme.Accent, Parent = row,
    })
    local bar = Create("Frame", {
        Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 33),
        BackgroundColor3 = Theme.Background, Parent = row,
    }, { Corner(3) })
    local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, Parent = bar }, {
        Corner(3),
        Create("UIGradient", { Color = ColorSequence.new(Theme.Accent2, Theme.Accent) }),
    })
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.Gold, Parent = bar,
    }, { Corner(6) })

    local obj = {}
    local function render()
        local rel = (value - min) / math.max(max - min, 1e-9)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valLabel.Text = string.format("%." .. dec .. "f", value) .. (o.Suffix or "")
    end
    function obj:Set(v, silent)
        v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
        if v == value and not silent then return end
        value = v
        render()
        if o.Flag then Library.Flags[o.Flag] = value end
        if not silent and o.Callback then task.spawn(o.Callback, value) end
    end
    function obj:Get() return value end

    local dragging = false
    local function fromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        obj:Set(min + (max - min) * rel)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(i.Position.X)
        end
    end)
    table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end))
    table.insert(self._conns, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    render()
    if o.Flag then Library.Flags[o.Flag] = value end
    return Register(self, o, obj)
end

function Section:Input(o)
    local row = self:_row(34)
    Label({ Text = o.Name, Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(12, 0), Parent = row })
    local box = Create("TextBox", {
        Size = UDim2.fromOffset(130, 24), Position = UDim2.new(1, -140, 0.5, -12),
        BackgroundColor3 = Theme.Background, Text = o.Default or "", PlaceholderText = o.Placeholder or "",
        PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    }, { Corner(6), Pad(8, 0, 8, 0) })
    local stroke = Stroke(Theme.Accent2, 0.7)
    stroke.Parent = box
    box.Focused:Connect(function() Tween(stroke, { Color = Theme.Accent, Transparency = 0.1 }) end)
    local obj = {}
    function obj:Set(t, silent)
        box.Text = t
        if o.Flag then Library.Flags[o.Flag] = t end
        if not silent and o.Callback then task.spawn(o.Callback, t) end
    end
    function obj:Get() return box.Text end
    box.FocusLost:Connect(function()
        Tween(stroke, { Color = Theme.Accent2, Transparency = 0.7 })
        obj:Set(box.Text)
    end)
    if o.Flag then Library.Flags[o.Flag] = box.Text end
    return Register(self, o, obj)
end

function Section:Dropdown(o)
    local items = o.Options or {}
    local multi = o.Multi
    local value = multi and {} or nil
    local open = false

    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15,
        ClipsDescendants = true, LayoutOrder = self:_order(), Parent = self.Content,
    }, { Corner(8) })
    local head = Create("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", Parent = row })
    Label({ Text = o.Name, Size = UDim2.new(0.5, -12, 0, 34), Position = UDim2.fromOffset(12, 0), Parent = head })
    local valText = Label({
        Size = UDim2.new(0.5, -34, 0, 34), Position = UDim2.new(0.5, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Theme.Accent, Parent = head,
    })
    local arrow = Label({
        Text = "▾", Size = UDim2.fromOffset(20, 34), Position = UDim2.new(1, -26, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Accent2, Parent = head,
    })
    local list = Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 0, 0), Position = UDim2.fromOffset(6, 38), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = row,
    }, { Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local buttons = {}
    local function refresh()
        for name, b in pairs(buttons) do
            local sel = multi and value[name] or (value == name)
            Tween(b.btn, { BackgroundTransparency = sel and 0.75 or 1 }, 0.12)
            b.lbl.TextColor3 = sel and Theme.Accent or Theme.Text
        end
        if multi then
            local t = {}
            for _, n in ipairs(items) do if value[n] then table.insert(t, n) end end
            valText.Text = #t > 0 and table.concat(t, ", ") or "None"
        else
            valText.Text = value or "None"
        end
    end

    local obj = {}
    local function fire(silent)
        local out = value
        if multi then
            out = {}
            for _, n in ipairs(items) do if value[n] then table.insert(out, n) end end
        end
        if o.Flag then Library.Flags[o.Flag] = out end
        if not silent and o.Callback then task.spawn(o.Callback, out) end
    end
    function obj:Set(v, silent)
        if multi then
            value = {}
            for _, n in ipairs(v or {}) do value[n] = true end
        else
            value = v
        end
        refresh(); fire(silent)
    end
    function obj:Get()
        if multi then
            local out = {}
            for _, n in ipairs(items) do if value[n] then table.insert(out, n) end end
            return out
        end
        return value
    end

    local function toggle(state)
        open = state
        local h = math.min(#items * 28, 140)
        list.Size = UDim2.new(1, -12, 0, h)
        Tween(row, { Size = UDim2.new(1, 0, 0, open and (34 + h + 10) or 34) }, 0.2)
        Tween(arrow, { Rotation = open and 180 or 0 }, 0.2)
    end

    local function build()
        for _, b in pairs(buttons) do b.btn:Destroy() end
        buttons = {}
        for i, name in ipairs(items) do
            local btn = Create("TextButton", {
                Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                Text = "", LayoutOrder = i, AutoButtonColor = false, Parent = list,
            }, { Corner(6) })
            local lbl = Label({ Text = name, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Parent = btn })
            buttons[name] = { btn = btn, lbl = lbl }
            btn.MouseButton1Click:Connect(function()
                if multi then
                    value[name] = not value[name] or nil
                else
                    value = name
                    toggle(false)
                end
                refresh(); fire()
            end)
        end
        refresh()
    end
    function obj:Refresh(newItems)
        items = newItems
        build()
        if open then toggle(true) end
    end

    head.MouseButton1Click:Connect(function() toggle(not open) end)
    build()
    if o.Default ~= nil then
        if multi then obj:Set(type(o.Default) == "table" and o.Default or { o.Default }, true) else obj:Set(o.Default, true) end
        if o.Callback then task.spawn(o.Callback, obj:Get()) end
    end
    return Register(self, o, obj)
end

function Section:Keybind(o)
    local key = o.Default
    local listening = false
    local row = self:_row(34)
    Label({ Text = o.Name, Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(12, 0), Parent = row })
    local btn = Create("TextButton", {
        Size = UDim2.fromOffset(84, 24), Position = UDim2.new(1, -94, 0.5, -12),
        BackgroundColor3 = Theme.Background, Text = Keyname(key), TextColor3 = Theme.Gold,
        Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false, Parent = row,
    }, { Corner(6), Stroke(Theme.Accent2, 0.7) })
    local obj = {}
    function obj:Set(k)
        key = k
        btn.Text = Keyname(k)
        if o.Flag then Library.Flags[o.Flag] = k end
        if o.OnChange then task.spawn(o.OnChange, k) end
    end
    function obj:Get() return key end
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
    end)
    table.insert(self._conns, UserInputService.InputBegan:Connect(function(i, gp)
        if listening then
            if i.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                obj:Set(i.KeyCode == Enum.KeyCode.Escape and nil or i.KeyCode)
            end
        elseif not gp and key and i.KeyCode == key then
            if o.Callback then task.spawn(o.Callback, key) end
        end
    end))
    if o.Flag then Library.Flags[o.Flag] = key end
    return Register(self, o, obj)
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Library:Window(o)
    o = o or {}
    local window = { _conns = {}, Tabs = {}, Visible = true }

    local gui = Create("ScreenGui", {
        Name = "HuohuoLib", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true, DisplayOrder = 999,
    })
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
    if not ok or not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    window.Gui = gui

    local baseSize = o.Size or UDim2.fromOffset(720, 480)
    local main = Create("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = baseSize, BackgroundColor3 = Theme.Background, ClipsDescendants = true, Parent = gui,
    }, { Corner(14), Stroke(Theme.Accent, 0.55, 1.5) })
    window.Main = main

    -- Background image (your Huohuo art)
    local bg = Create("ImageLabel", {
        Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Image = ResolveImage(o.Background) or "", ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = o.BackgroundTransparency or 0.7, ZIndex = 0, Parent = main,
    })
    -- Violet legibility veil with soft teal glow
    Create("Frame", {
        Name = "Veil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 1, Parent = main,
    }, {
        Create("UIGradient", {
            Rotation = 25,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Background),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(38, 26, 66)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 52, 62)),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 0.5),
            }),
        }),
    })

    ---------------- Sidebar ----------------
    local sidebar = Create("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, 190, 1, 0), BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2, Parent = main,
    })
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Accent2,
        BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3, Parent = sidebar,
    })

    local lights = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 3, Parent = sidebar,
    })
    local function Light(x, color)
        return Create("TextButton", {
            Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(x, 14), BackgroundColor3 = color,
            Text = "", AutoButtonColor = false, ZIndex = 4, Parent = lights,
        }, { Corner(7) })
    end
    local closeBtn, minBtn, maxBtn = Light(14, Theme.Red), Light(34, Theme.Yellow), Light(54, Theme.Green)

    Label({
        Text = o.Title or "Huohuo", Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Theme.Text,
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(14, 46), ZIndex = 3, Parent = sidebar,
    })
    Label({
        Text = o.Subtitle or "Ghostly Abundance", TextSize = 11, TextColor3 = Theme.Accent,
        Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(14, 68), ZIndex = 3, Parent = sidebar,
    })

    local tabList = Create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -104), Position = UDim2.fromOffset(8, 94), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), ZIndex = 3, Parent = sidebar,
    }, { Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }) })

    ---------------- Content ----------------
    local content = Create("Frame", {
        Name = "Content", Size = UDim2.new(1, -190, 1, 0), Position = UDim2.fromOffset(190, 0),
        BackgroundTransparency = 1, ZIndex = 2, Parent = main,
    })
    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ZIndex = 3, Parent = content,
    })
    local pageTitle = Label({
        Text = "", Font = Enum.Font.GothamBold, TextSize = 16,
        Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(16, 0), ZIndex = 3, Parent = header,
    })
    Create("Frame", {
        Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -1), BackgroundColor3 = Theme.Accent2,
        BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3, Parent = header,
    })
    local pages = Create("Frame", {
        Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1,
        ZIndex = 3, Parent = content,
    })

    ---------------- Dragging ----------------
    local function MakeDraggable(handle)
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, i.Position, main.Position
            end
        end)
        table.insert(window._conns, UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        table.insert(window._conns, UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end
    MakeDraggable(header)
    MakeDraggable(lights)

    ---------------- Window controls ----------------
    function window:SetVisible(v)
        window.Visible = v
        main.Visible = v
    end
    function window:Toggle() window:SetVisible(not window.Visible) end
    function window:Destroy()
        for _, c in ipairs(window._conns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
        if o.OnUnload then task.spawn(o.OnUnload) end
    end
    function window:SetBackground(src)
        bg.Image = ResolveImage(src) or ""
    end
    function window:SetBackgroundTransparency(t)
        bg.ImageTransparency = t
    end

    closeBtn.MouseButton1Click:Connect(function() window:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() window:SetVisible(false) end)
    local big = false
    maxBtn.MouseButton1Click:Connect(function()
        big = not big
        Tween(main, {
            Size = big and UDim2.new(0, baseSize.X.Offset * 1.25, 0, baseSize.Y.Offset * 1.25) or baseSize,
        }, 0.25, Enum.EasingStyle.Quint)
    end)

    local toggleKey = o.Keybind or Enum.KeyCode.RightShift
    table.insert(window._conns, UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == toggleKey then window:Toggle() end
    end))

    ---------------- Tabs ----------------
    local currentTab
    local tabOrder = 0

    local function SelectTab(t)
        if currentTab == t then return end
        if currentTab then
            currentTab.Page.Visible = false
            Tween(currentTab.Button, { BackgroundTransparency = 1 })
            Tween(currentTab.Label, { TextColor3 = Theme.SubText })
            Tween(currentTab.Bar, { BackgroundTransparency = 1 })
            if currentTab.Icon then Tween(currentTab.Icon, { ImageColor3 = Theme.SubText }) end
        end
        currentTab = t
        t.Page.Visible = true
        pageTitle.Text = t.Name
        Tween(t.Button, { BackgroundTransparency = 0.82 })
        Tween(t.Label, { TextColor3 = Theme.Accent })
        Tween(t.Bar, { BackgroundTransparency = 0 })
        if t.Icon then Tween(t.Icon, { ImageColor3 = Theme.Accent }) end
    end

    local function NewTab(to)
        tabOrder += 1
        local tab = { Name = to.Name or "Tab" }
        local btn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, LayoutOrder = tabOrder, ZIndex = 4, Parent = tabList,
        }, { Corner(8) })
        tab.Button = btn
        tab.Bar = Create("Frame", {
            Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Theme.Gold,
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = btn,
        }, { Corner(2) })
        local textX = 14
        if to.Icon then
            tab.Icon = Create("ImageLabel", {
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 14, 0.5, -8), BackgroundTransparency = 1,
                Image = ResolveImage(to.Icon) or "", ImageColor3 = Theme.SubText, ZIndex = 5, Parent = btn,
            })
            textX = 38
        end
        tab.Label = Label({
            Text = tab.Name, TextColor3 = Theme.SubText, Size = UDim2.new(1, -textX - 6, 1, 0),
            Position = UDim2.fromOffset(textX, 0), ZIndex = 5, Parent = btn,
        })

        tab.Page = Create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = pages,
        })
        local function Column(side)
            local left = side == "Left"
            return Create("ScrollingFrame", {
                Size = UDim2.new(0.5, -14, 1, -12), Position = left and UDim2.fromOffset(10, 6) or UDim2.new(0.5, 4, 0, 6),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(), ZIndex = 3, Parent = tab.Page,
            }, {
                Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
                Pad(2, 2, 4, 8),
            })
        end
        local cols = { Left = Column("Left"), Right = Column("Right") }
        local secCount = 0

        function tab:Section(so)
            so = so or {}
            secCount += 1
            local side = so.Side == "Right" and "Right" or "Left"
            local frame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.3, LayoutOrder = secCount,
                Parent = cols[side],
            }, { Corner(10), Stroke(Theme.Accent2, 0.75), Pad(10, 8, 10, 10) })
            local inner = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                Parent = frame,
            }, { Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
            if so.Name then
                Label({
                    Text = so.Name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent,
                    Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = inner,
                })
            end
            local s = setmetatable({ Content = inner, _n = 0, _conns = window._conns }, Section)
            return s
        end

        btn.MouseButton1Click:Connect(function() SelectTab(tab) end)
        btn.MouseEnter:Connect(function()
            if currentTab ~= tab then Tween(btn, { BackgroundTransparency = 0.92 }) end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= tab then Tween(btn, { BackgroundTransparency = 1 }) end
        end)

        table.insert(window.Tabs, tab)
        if not currentTab then SelectTab(tab) end
        return tab
    end

    function window:TabGroup(go)
        go = go or {}
        if go.Name then
            tabOrder += 1
            Label({
                Text = string.upper(go.Name), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.Accent2,
                Size = UDim2.new(1, 0, 0, 22), LayoutOrder = tabOrder, ZIndex = 4, Parent = tabList,
            }, {}).TextTransparency = 0.2
        end
        return { Tab = function(_, to) return NewTab(to) end }
    end
    function window:Tab(to) return NewTab(to) end

    ---------------- Notifications ----------------
    local holder = Create("Frame", {
        Size = UDim2.new(0, 290, 1, -24), Position = UDim2.new(1, -302, 0, 12), BackgroundTransparency = 1,
        ZIndex = 50, Parent = gui,
    }, {
        Create("UIListLayout", {
            Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    function window:Notify(no)
        no = no or {}
        local dur = no.Duration or 4
        local n = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 50, Parent = holder,
        }, { Corner(10), Pad(12, 10, 12, 14) })
        local stroke = Stroke(Theme.Accent, 1, 1.2)
        stroke.Parent = n
        local list = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            ZIndex = 51, Parent = n,
        }, { Create("UIListLayout", { Padding = UDim.new(0, 3) }) })
        local t = Label({
            Text = no.Title or "Huohuo", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent,
            Size = UDim2.new(1, 0, 0, 18), ZIndex = 51, TextTransparency = 1, Parent = list,
        })
        local d = Label({
            Text = no.Description or "", TextSize = 12, TextColor3 = Theme.Text, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 14), ZIndex = 51, TextTransparency = 1, Parent = list,
        })
        local bar = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = Theme.Gold,
            BorderSizePixel = 0, ZIndex = 52, Parent = n,
        })
        Tween(n, { BackgroundTransparency = 0.08 }, 0.25)
        Tween(stroke, { Transparency = 0.3 }, 0.25)
        Tween(t, { TextTransparency = 0 }, 0.25)
        Tween(d, { TextTransparency = 0 }, 0.25)
        Tween(bar, { Size = UDim2.new(0, 0, 0, 3) }, dur, Enum.EasingStyle.Linear)
        task.delay(dur, function()
            if not n.Parent then return end
            Tween(n, { BackgroundTransparency = 1 }, 0.25)
            Tween(stroke, { Transparency = 1 }, 0.25)
            Tween(t, { TextTransparency = 1 }, 0.25)
            Tween(d, { TextTransparency = 1 }, 0.25)
            Tween(bar, { BackgroundTransparency = 1 }, 0.25)
            task.wait(0.3)
            n:Destroy()
        end)
    end

    -- open animation
    main.Size = UDim2.new(0, baseSize.X.Offset * 0.92, 0, baseSize.Y.Offset * 0.92)
    Tween(main, { Size = baseSize }, 0.35, Enum.EasingStyle.Back)

    return window
end

return Library
