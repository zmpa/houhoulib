--[[
	Talis UI Library
	Version: 0.3.0

	Changes in this build (on top of 0.2.1):

	BUG FIXES
	  * UI scale no longer shifts the window/notifications/watermark off-screen
	    (Root is now counter-sized when UIScale changes).
	  * Popups (dropdown / colorpicker) respect UI scale and align to their anchor.
	  * Popups no longer leak connections (each popup owns and cleans its own).
	  * Mouse position now uses screen coordinates (colorpicker / tooltip were
	    offset vertically by the GUI inset).
	  * Resizing from the grip no longer drifts (window is centre-anchored).
	  * Re-opening a minimized window no longer breaks the layout.
	  * Escape / toggle key no longer closes the menu while binding a key or with a popup open.
	  * Settings page is no longer the default tab; it sits last in the rail.
	  * "Darken" slider was inverted. Fixed.
	  * Settings options no longer steal flag names such as "Theme" / "Accent" from your script.
	  * Config / settings loading applies callbacks, validates types, sanitizes names.
	  * Keybind callbacks in Settings no longer re-save on every key press.
	  * Watermark text box no longer shows the watermark while the toggle is off.
	  * Button clicks no longer overwrite flags that share the button's name.
	  * Search no longer hides sections that only contain buttons / labels.
	  * Slider value box no longer fights for focus.
	  * Colorpicker rainbow state is restored correctly from configs.
	  * Config status label had the wrong default size.
	  * Window config Theme / Accent / Scale / ToggleKey are no longer overridden by ui.json
	    unless you changed that setting in the Settings page.
	  * Background image links given in the window config are now downloaded.
	  * Re-executing the script replaces the old window instead of stacking a new one.
	  * Many colours (toggle, slider, progress, divider...) now follow theme changes.
	  * Memory leaks: instance / connection lists no longer grow forever.

	NEW
	  * Auto-sizing everywhere: rows grow to fit wrapped names/descriptions,
	    notifications size to their text, the window fits small screens,
	    keybind / value boxes / watermark / tooltips size to their text.
	  * Predefined elements: Paragraph, Label, Header, Divider, Space, Button,
	    Toggle, Slider, Dropdown, MultiDropdown, Input (Textbox), Keybind (Bind),
	    Colorpicker, Progress.
	  * Shorthand calls: section:Toggle("ESP", false, function(v) end) etc.
	  * tab:Toggle(...) / tab:Paragraph(...) work directly on a tab (auto section).
	  * window:Show / Hide / ToggleVisible / IsOpen, Talis:Unload().
	  * Window config: Search = true, RailWidth, MinSize.
]]

local Talis = {}
Talis.Version = "0.3.0"
Talis.Animations = true
Talis.Root = "talis"
Talis.Spacing = 6

Talis.Flags = {}
Talis.FlagListeners = {}
Talis.Options = {}
Talis.Themed = setmetatable({}, { __mode = "k" })
Talis.ThemeHooks = {}
Talis.Instances = setmetatable({}, { __mode = "k" })
Talis.Connections = {}
Talis.Notifications = {}
Talis.Builders = {}
Talis.Shorthand = {}
Talis.Themes = {}
Talis.ImageCache = {}
Talis.Rainbows = {}
Talis.RainbowHue = 0
Talis.UISet = {}
Talis.UIFromFile = false

Talis.UISettings = {
	Theme = "Huohuo",
	Accent = false,
	Background = "",
	BackgroundOpacity = 0.85,
	Scrim = 0.55, -- how dark the overlay on top of the background is (0 - 0.9)
	Scale = 1,
	Spacing = 6,
	Animations = true,
	ToggleKey = "RightShift",
	Watermark = false,
	WatermarkText = "talis",
}

local cloneref = cloneref or clonereference or function(Object) return Object end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local GuiService = cloneref(game:GetService("GuiService"))
local LP = Players.LocalPlayer

local FS = {
	read = type(readfile) == "function",
	write = type(writefile) == "function",
	exists = type(isfile) == "function",
	folder = type(isfolder) == "function" and type(makefolder) == "function",
	list = type(listfiles) == "function",
	delete = type(delfile) == "function",
}
FS.ok = FS.read and FS.write and FS.exists and FS.folder and FS.list
FS.img = FS.write and FS.exists and FS.folder

local getasset
if type(getcustomasset) == "function" then
	getasset = getcustomasset
elseif type(getsynasset) == "function" then
	getasset = getsynasset
end

local SEP = "/"
if FS.folder then
	local ok = pcall(function()
		if not isfolder(Talis.Root) then makefolder(Talis.Root) end
	end)
	if not ok then SEP = "\\" end
end

local function path(...)
	return table.concat({ ... }, SEP)
end

local FAMILY = "rbxasset://fonts/families/GothamSSm.json"
Talis.Fonts = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Medium),
	Semibold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium),
}

Talis.Glyphs = {
	close = "\u{2715}",
	min = "\u{2014}",
	chevron = "\u{25BE}",
	check = "\u{2713}",
	dot = "\u{2022}",
	arrow = "\u{203A}",
}

Talis.Themes.Huohuo = {
	Window = Color3.fromHex("0B1512"),
	Surface = Color3.fromHex("101E1A"),
	Raised = Color3.fromHex("16261F"),
	Hover = Color3.fromHex("1C3129"),
	Stroke = Color3.fromHex("244137"),
	Hairline = Color3.fromHex("1B3129"),
	Text = Color3.fromHex("E6F1EA"),
	Muted = Color3.fromHex("7E9A8E"),
	Faint = Color3.fromHex("4E655C"),
	Accent = Color3.fromHex("4FD6A8"),
	AccentSoft = Color3.fromHex("9BE8CB"),
	AccentText = Color3.fromHex("04120C"),
	Jade = Color3.fromHex("2FB8A8"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("E0574F"),
	Scrim = Color3.fromHex("05100C"),
	Shadow = Color3.fromHex("000000"),
}

Talis.Themes.Jade = {
	Window = Color3.fromHex("071614"),
	Surface = Color3.fromHex("0C1F1C"),
	Raised = Color3.fromHex("122A26"),
	Hover = Color3.fromHex("183832"),
	Stroke = Color3.fromHex("1F4A42"),
	Hairline = Color3.fromHex("15342F"),
	Text = Color3.fromHex("E2F4F0"),
	Muted = Color3.fromHex("74A199"),
	Faint = Color3.fromHex("47706A"),
	Accent = Color3.fromHex("3FD9C4"),
	AccentSoft = Color3.fromHex("93EDE1"),
	AccentText = Color3.fromHex("031210"),
	Jade = Color3.fromHex("2FB8A8"),
	Gold = Color3.fromHex("D8C179"),
	Ember = Color3.fromHex("EF9048"),
	Danger = Color3.fromHex("E0574F"),
	Scrim = Color3.fromHex("03100E"),
	Shadow = Color3.fromHex("000000"),
}

Talis.Themes.Talisman = {
	Window = Color3.fromHex("12110D"),
	Surface = Color3.fromHex("1A1812"),
	Raised = Color3.fromHex("221F17"),
	Hover = Color3.fromHex("2C281D"),
	Stroke = Color3.fromHex("3A3425"),
	Hairline = Color3.fromHex("2A2519"),
	Text = Color3.fromHex("F1EBDC"),
	Muted = Color3.fromHex("9C907A"),
	Faint = Color3.fromHex("6B614D"),
	Accent = Color3.fromHex("E3B96B"),
	AccentSoft = Color3.fromHex("F0D9A6"),
	AccentText = Color3.fromHex("14110A"),
	Jade = Color3.fromHex("5FBFA0"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("DE6A55"),
	Scrim = Color3.fromHex("0C0B07"),
	Shadow = Color3.fromHex("000000"),
}

Talis.Themes.Light = {
	Window = Color3.fromHex("F4F7F5"),
	Surface = Color3.fromHex("FFFFFF"),
	Raised = Color3.fromHex("EDF2EF"),
	Hover = Color3.fromHex("E3EAE6"),
	Stroke = Color3.fromHex("D3DCD7"),
	Hairline = Color3.fromHex("E2E9E5"),
	Text = Color3.fromHex("14211C"),
	Muted = Color3.fromHex("6C7F77"),
	Faint = Color3.fromHex("A3B3AC"),
	Accent = Color3.fromHex("2FA37C"),
	AccentSoft = Color3.fromHex("8FD9BF"),
	AccentText = Color3.fromHex("FFFFFF"),
	Jade = Color3.fromHex("2FA37C"),
	Gold = Color3.fromHex("B98F3C"),
	Ember = Color3.fromHex("D97B29"),
	Danger = Color3.fromHex("C9524A"),
	Scrim = Color3.fromHex("0B1512"),
	Shadow = Color3.fromHex("8FA69C"),
}

Talis.Theme = Talis.Themes.Huohuo

local function defaultProp(Object)
	local class = Object.ClassName
	if class == "TextLabel" or class == "TextBox" or class == "TextButton" then return "TextColor3" end
	if class == "ImageLabel" or class == "ImageButton" then return "ImageColor3" end
	if class == "UIStroke" then return "Color" end
	return "BackgroundColor3"
end

local function New(class, props, parent)
	local inst = Instance.new(class)
	local par = parent
	if props then
		for key, value in next, props do
			if key == "Parent" then
				par = value
			elseif value ~= nil then
				inst[key] = value
			end
		end
	end
	inst.Parent = par
	Talis.Instances[inst] = true
	return inst
end

local function Theme(object, key, prop)
	prop = prop or defaultProp(object)
	local entries = Talis.Themed[object]
	if not entries then
		entries = {}
		Talis.Themed[object] = entries
	end
	local found
	for index = 1, #entries do
		if entries[index][2] == prop then
			found = entries[index]
			break
		end
	end
	if found then
		found[1] = key
	else
		entries[#entries + 1] = { key, prop }
	end
	local value = Talis.Theme[key]
	if value ~= nil then object[prop] = value end
	return object
end

-- Register a function that re-paints something that is not a plain themed property.
local function OnTheme(fn)
	Talis.ThemeHooks[#Talis.ThemeHooks + 1] = fn
	return fn
end

local function Corner(object, radius)
	if not radius or radius <= 0 then return end
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = object })
end

local function Stroke(object, key, thickness, transparency)
	local stroke = New("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = object,
	})
	Theme(stroke, key or "Stroke", "Color")
	return stroke
end

local function Hairline(parent, key, transparency)
	local line = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = transparency or 0.35,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Theme(line, key or "Hairline", "BackgroundColor3")
	return line
end

local function Pad(object, all, right, bottom, left)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, all or 0),
		PaddingRight = UDim.new(0, right or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
		PaddingLeft = UDim.new(0, left or right or all or 0),
		Parent = object,
	})
end

local function Tween(object, time, props, style)
	if not Talis.Animations then
		for key, value in next, props do object[key] = value end
		return
	end
	local tween = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function Connect(signal, fn)
	local connection = signal:Connect(fn)
	Talis.Connections[#Talis.Connections + 1] = connection
	return connection
end

local function Text(parent, value, size, font, key, align)
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = tostring(value),
		TextSize = size or 13,
		FontFace = font or Talis.Fonts.Regular,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
	if typeof(key) == "Color3" then
		label.TextColor3 = key
	else
		Theme(label, key or "Text", "TextColor3")
	end
	return label
end

-- Makes a label grow vertically to fit its (wrapped) text.
local function Wrap(label)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, 0)
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
end

local function isPress(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

local function isMove(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch
end

-- Any "MouseButton1".."MouseButton5" works, even where the enum member is missing.
local function isMouseButton(input)
	return tostring(input.UserInputType.Name):match("^MouseButton") ~= nil
end

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- Pointer position in real screen pixels (same space as AbsolutePosition when IgnoreGuiInset is on).
local function pointer(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
	end
	return UIS:GetMouseLocation()
end

--[[ IMAGE LOADING ]]
-- Roblox can only show rbxasset* images. For an http(s) link we download the
-- bytes, save them to disk and hand back a getcustomasset() path. Cached per URL.

local function httpBody(url)
	local callers = {}
	if type(request) == "function" then callers[#callers + 1] = request end
	if type(http_request) == "function" then callers[#callers + 1] = http_request end
	if type(syn) == "table" and type(syn.request) == "function" then callers[#callers + 1] = syn.request end
	for index = 1, #callers do
		local ok, res = pcall(callers[index], { Url = url, Method = "GET" })
		if ok and type(res) == "table" and res.Body and #res.Body > 0 then return res.Body end
	end
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 0 then return body end
	return nil
end

function Talis:LoadImage(source, name)
	if source == nil or source == "" then return "" end
	if type(source) == "number" then return "rbxassetid://" .. tostring(source) end
	source = tostring(source)
	if source:match("^rbxasset") or source:match("^rbxthumb") then return source end
	if source:match("^%d+$") then return "rbxassetid://" .. source end
	if self.ImageCache[source] then return self.ImageCache[source] end
	if not (FS.img and type(getasset) == "function") then return source end

	local dir = path(self.Root, "images")
	pcall(function()
		if not isfolder(self.Root) then makefolder(self.Root) end
		if not isfolder(dir) then makefolder(dir) end
	end)

	local body = httpBody(source)
	if not body then return source end

	local ext
	if body:sub(1, 4) == "\137PNG" then
		ext = "png"
	elseif body:sub(1, 3) == "\255\216\255" then
		ext = "jpg"
	else
		return source
	end

	local tag = string.gsub(body:sub(1, 64), "[^%w]", "")
	local file = path(dir, (name or "image") .. "_" .. #body .. "_" .. tag .. "." .. ext)
	if not isfile(file) then
		local ok = pcall(writefile, file, body)
		if not ok then return source end
	end

	local ok, asset = pcall(getasset, file)
	if ok and asset then
		self.ImageCache[source] = asset
		return asset
	end
	return source
end

--[[ THEME + FLAGS ]]

function Talis:ApplyTheme(name)
	local theme = type(name) == "table" and name or self.Themes[name]
	if not theme then return end
	self.Theme = theme
	if self.ActiveWindow then self.ActiveWindow.Theme = theme end
	for object, entries in next, self.Themed do
		if object.Parent == nil and object.ClassName ~= "ScreenGui" then
			self.Themed[object] = nil
		else
			for index = 1, #entries do
				local value = theme[entries[index][1]]
				if value then object[entries[index][2]] = value end
			end
		end
	end
	for index = 1, #self.ThemeHooks do
		pcall(self.ThemeHooks[index])
	end
	local active = self.ActiveWindow
	if active and active.Current then
		local meta = active.TabMeta[active.Current]
		if meta and meta.Label then meta.Label.TextColor3 = theme.Text end
	end
end

function Talis:SetFlag(flag, value)
	self.Flags[flag] = value
	local listeners = self.FlagListeners[flag]
	if listeners then
		for index = 1, #listeners do
			local ok, err = pcall(listeners[index], value, flag)
			if not ok then warn("[Talis] flag listener: " .. tostring(err)) end
		end
	end
	return value
end

function Talis:GetFlag(flag)
	return self.Flags[flag]
end

function Talis:OnFlagChanged(flag, fn)
	local listeners = self.FlagListeners[flag]
	if not listeners then
		listeners = {}
		self.FlagListeners[flag] = listeners
	end
	listeners[#listeners + 1] = fn
	if self.Flags[flag] ~= nil then pcall(fn, self.Flags[flag], flag) end
	return fn
end

local function Register(option)
	local base = tostring(option.Flag or option.Name or option.Type or "flag")
	local flag, index = base, 0
	while Talis.Options[flag] do
		index = index + 1
		flag = base .. "-" .. index
	end
	option.Flag = flag
	Talis.Options[flag] = option
	return flag
end

local function Decorate(option, info, window)
	option.Window = window
	option.Row = info.row
	option.Locked = false

	function option:SetTitle(value)
		if info.label then info.label.Text = tostring(value) end
		self.Name = tostring(value)
	end

	function option:SetDesc(value)
		if info.desc then info.desc.Text = tostring(value) end
		self.Desc = tostring(value)
	end

	function option:Lock(state)
		self.Locked = state ~= false
		local alpha = self.Locked and 0.42 or 0
		if info.label then info.label.TextTransparency = alpha end
		if info.desc then info.desc.TextTransparency = alpha end
		return self.Locked
	end

	function option:Unlock()
		return self:Lock(false)
	end

	function option:SetVisible(state)
		if info.row then info.row.Visible = state ~= false end
	end

	function option:Destroy()
		if info.row then info.row:Destroy() end
		if self.Flag then Talis.Options[self.Flag] = nil end
	end

	return option
end

--[[ NOTIFICATIONS + TOOLTIP ]]

function Talis:Notify(config)
	config = type(config) == "table" and config or { Content = tostring(config) }
	local window = self.ActiveWindow
	local layer = self.NotifLayer
	if not layer or not window then return end
	local duration = math.max(tonumber(config.Duration) or 4, 1.2)
	local colorKey = config.Color

	local function paint(object)
		if typeof(colorKey) == "Color3" then
			object.BackgroundColor3 = colorKey
		else
			Theme(object, colorKey or "Accent", "BackgroundColor3")
		end
	end

	local card = New("Frame", {
		Size = UDim2.fromOffset(268, 52),
		BackgroundColor3 = self.Theme.Raised,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = layer,
	})
	Corner(card, 6)
	Theme(card, "Raised", "BackgroundColor3")
	local stroke = Stroke(card, "Stroke", 1, 1)

	local content = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = card,
	})
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	Pad(content, 10, 12, 14, 14)

	local title = Wrap(Text(content, config.Title or "Notice", 13, self.Fonts.Semibold, "Text"))
	title.LayoutOrder = 1
	if config.Content and tostring(config.Content) ~= "" then
		local body = Wrap(Text(content, config.Content, 12, self.Fonts.Regular, "Muted"))
		body.LayoutOrder = 2
	end

	local bar = New("Frame", {
		Size = UDim2.new(0, 2, 1, -20),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		Parent = card,
	})
	paint(bar)

	local timer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0, 6, 1, -5),
		BorderSizePixel = 0,
		Parent = card,
	})
	paint(timer)

	local function fit()
		if not card.Parent then return end
		local factor = math.max(window.Scale.Scale, 0.01)
		card.Size = UDim2.fromOffset(268, math.max(46, content.AbsoluteSize.Y / factor))
	end
	local sizeConnection = content:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	Tween(card, 0.2, { BackgroundTransparency = 0.08 })
	Tween(stroke, 0.2, { Transparency = 0.45 })
	Tween(timer, duration, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)

	self.Notifications[card] = true

	task.delay(duration, function()
		if not self.Notifications[card] then return end
		self.Notifications[card] = nil
		Tween(card, 0.18, { BackgroundTransparency = 1 })
		Tween(stroke, 0.18, { Transparency = 1 })
		task.delay(0.2, function()
			sizeConnection:Disconnect()
			if card.Parent then card:Destroy() end
		end)
	end)

	return card
end

function Talis:Tooltip(text, input)
	local window = self.ActiveWindow
	local root = window and window.Root
	if not root then return end
	if not self.TooltipLabel or not self.TooltipLabel.Parent then
		local tip = New("TextLabel", {
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			TextSize = 12,
			FontFace = self.Fonts.Regular,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 90,
			Visible = false,
			Parent = root,
		})
		Corner(tip, 4)
		Stroke(tip, "Stroke", 1, 0.5)
		Pad(tip, 0, 8, 0, 8)
		Theme(tip, "Text", "TextColor3")
		Theme(tip, "Raised", "BackgroundColor3")
		self.TooltipLabel = tip
	end
	self.TooltipLabel.Text = tostring(text)
	self.TooltipLabel.Visible = true
	self:MoveTooltip(input)
end

function Talis:MoveTooltip(input)
	local tip = self.TooltipLabel
	local window = self.ActiveWindow
	if not tip or not tip.Visible or not window then return end
	local factor = math.max(window.Scale.Scale, 0.01)
	local view = viewport() / factor
	local point = pointer(input) / factor
	local width = tip.AbsoluteSize.X / factor
	local x = point.X + 14
	local y = point.Y + 18
	if x + width + 8 > view.X then x = point.X - width - 12 end
	if y + 28 > view.Y then y = point.Y - 28 end
	tip.Position = UDim2.fromOffset(math.max(4, x), math.max(4, y))
end

function Talis:HideTooltip()
	if self.TooltipLabel then self.TooltipLabel.Visible = false end
end

local function parentGui(gui)
	if RunService:IsStudio() then
		gui.Parent = LP:WaitForChild("PlayerGui")
		return
	end
	if type(gethui) == "function" then
		if pcall(function() gui.Parent = gethui() end) and gui.Parent then return end
	end
	if type(get_hidden_gui) == "function" then
		if pcall(function() gui.Parent = get_hidden_gui() end) and gui.Parent then return end
	end
	local ok = pcall(function() gui.Parent = cloneref(game:GetService("CoreGui")) end)
	if not ok or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end
end

--[[ WINDOW ]]

function Talis:Window(config)
	config = type(config) == "table" and config or {}

	-- Re-executing a script replaces the previous window instead of stacking another one.
	local env = type(getgenv) == "function" and getgenv() or _G
	local previous = env.__TalisWindow
	if type(previous) == "table" and type(previous.Destroy) == "function" then
		pcall(previous.Destroy, previous)
	end

	local theme = config.Theme
	if theme ~= nil then self:ApplyTheme(theme) end
	if config.Accent then
		local base = {}
		for key, value in next, self.Theme do base[key] = value end
		base.Accent = config.Accent
		self:ApplyTheme(base)
	end

	local radius = config.Radius == nil and 8 or config.Radius
	local background = config.Background or {}
	local railWidth = config.RailWidth or 152
	local startScale = config.Scale or 1
	local window = {
		Tabs = {},
		TabButtons = {},
		TabMeta = {},
		SpacingTargets = {},
		Spacing = config.Spacing or Talis.Spacing,
		Open = false,
		Minimized = false,
		Listening = 0,
		Title = config.Title or "Talis",
		Subtitle = config.Subtitle or ("v" .. self.Version),
		ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
		BaseSize = config.Size or UDim2.fromOffset(680, 440),
		MinSize = config.MinSize or Vector2.new(420, 280),
		CloseBehavior = config.CloseBehavior or "hide",
		Fonts = self.Fonts,
		Theme = self.Theme,
	}
	window.Size = window.BaseSize

	local gui = New("ScreenGui", {
		Name = "Talis",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	parentGui(gui)
	window.Gui = gui

	-- Root is counter-sized by 1/scale so a UIScale never moves the window off-centre.
	window.Root = New("Frame", {
		Name = "Root",
		Size = UDim2.fromScale(1 / startScale, 1 / startScale),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local scale = New("UIScale", { Scale = startScale, Parent = window.Root })
	window.Scale = scale

	local shell = New("Frame", {
		Name = "Shell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.new(0.5, 0, 0.5, 0),
		Size = window.Size,
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = window.Root,
	})
	Corner(shell, radius)
	Stroke(shell, "Stroke", 1, 0.55)
	Theme(shell, "Surface", "BackgroundColor3")
	window.Shell = shell

	local backdrop = New("Frame", {
		Name = "Backdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})
	window.Backdrop = backdrop

	local image = New("ImageLabel", {
		Name = "Image",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = background.Transparency or 0.15,
		ScaleType = background.ScaleType or Enum.ScaleType.Crop,
		Visible = false,
		Parent = backdrop,
	})
	window.Image = image

	local scrim = New("Frame", {
		Name = "Scrim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Scrim,
		BackgroundTransparency = background.Scrim or 0.45,
		BorderSizePixel = 0,
		Visible = false,
		Parent = backdrop,
	})
	Theme(scrim, "Scrim", "BackgroundColor3")
	window.Scrim = scrim

	local fade = New("Frame", {
		Name = "Fade",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Visible = false,
		Parent = backdrop,
	})
	local fadeGradient = New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.55, 0.5),
			NumberSequenceKeypoint.new(1, 0.85),
		}),
		Color = ColorSequence.new(self.Theme.Scrim),
		Parent = fade,
	})
	OnTheme(function()
		fadeGradient.Color = ColorSequence.new(Talis.Theme.Scrim)
	end)

	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})

	local title = Text(header, window.Title, 13, self.Fonts.Semibold, "Text")
	title.Position = UDim2.new(0, 16, 0, 0)
	title.Size = UDim2.new(1, -150, 1, 0)
	title.TextTruncate = Enum.TextTruncate.AtEnd
	window.TitleLabel = title

	local subtitle = Text(header, window.Subtitle, 11, self.Fonts.Regular, "Faint", Enum.TextXAlignment.Right)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.Size = UDim2.new(1, -74, 1, 0)
	window.SubtitleLabel = subtitle

	local function headerButton(glyph, offset)
		local button = New("TextButton", {
			Size = UDim2.fromOffset(22, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = glyph,
			TextSize = 12,
			FontFace = self.Fonts.Regular,
			AutoButtonColor = false,
			Parent = header,
		})
		Corner(button, 4)
		Theme(button, "Muted", "TextColor3")
		Theme(button, "Raised", "BackgroundColor3")
		Connect(button.MouseEnter, function()
			Tween(button, 0.12, { BackgroundTransparency = 0.6 })
			button.TextColor3 = Talis.Theme.Text
		end)
		Connect(button.MouseLeave, function()
			Tween(button, 0.12, { BackgroundTransparency = 1 })
			button.TextColor3 = Talis.Theme.Muted
		end)
		return button
	end

	local minButton = headerButton(self.Glyphs.min, -40)
	local closeButton = headerButton(self.Glyphs.close, -14)

	local rail = New("Frame", {
		Name = "Rail",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, railWidth, 1, -40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rail,
	})
	Pad(rail, 8, 8, 10, 8)
	window.Rail = rail

	local body = New("Frame", {
		Name = "Body",
		Position = UDim2.new(0, railWidth, 0, 40),
		Size = UDim2.new(1, -railWidth, 1, -40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})
	window.Body = body

	local edge = Hairline(shell, "Hairline", 0.5)
	edge.Position = UDim2.new(0, 0, 0, 40)

	-- Popups live inside Root so they share the UI scale.
	window.PopupHost = New("Frame", {
		Name = "Popups",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = window.Root,
	})

	window.NotifLayer = New("Frame", {
		Name = "Notifs",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 80,
		Parent = window.Root,
	})
	New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = window.NotifLayer,
	})
	Pad(window.NotifLayer, 0, 14, 14, 0)

	Talis.ActiveWindow = window
	Talis.NotifLayer = window.NotifLayer

	local grip = New("TextButton", {
		Name = "Grip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5,
		Parent = shell,
	})
	local gripMark = New("Frame", {
		Size = UDim2.fromOffset(6, 6),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -5, 1, -5),
		BackgroundColor3 = self.Theme.Faint,
		BorderSizePixel = 0,
		Parent = grip,
	})
	Theme(gripMark, "Faint", "BackgroundColor3")

	local opened = false

	-- Keeps the window inside the screen (small screens / phones / big UI scale).
	local function fit()
		if window.Destroyed then return end
		local view = viewport() / math.max(scale.Scale, 0.01)
		local base = window.BaseSize
		local width = math.min(base.X.Offset, math.max(240, view.X - 24))
		local height = math.min(base.Y.Offset, math.max(200, view.Y - 24))
		window.Size = UDim2.fromOffset(width, height)
		if opened and not window.Minimized then
			shell.Size = window.Size
		end
	end
	window.Fit = fit

	local function setOpen(state)
		if window.Destroyed then return end
		state = state == true
		if opened == state then return end
		opened = state
		window.Open = state
		if window.ActivePopup then window.ActivePopup:Close() end
		if state then
			shell.Visible = true
			shell.Size = UDim2.fromOffset(0, 0)
			local target = window.Minimized and UDim2.fromOffset(240, 40) or window.Size
			Tween(shell, 0.22, { Size = target }, Enum.EasingStyle.Quint)
		else
			Talis:HideTooltip()
			Tween(shell, 0.16, { Size = UDim2.fromOffset(0, 0) })
			task.delay(0.18, function()
				if not opened then shell.Visible = false end
			end)
		end
	end
	window.SetOpen = setOpen

	function window:Show() setOpen(true) end
	function window:Hide() setOpen(false) end
	function window:ToggleVisible() setOpen(not opened) end
	function window:IsOpen() return opened end

	local dragging, dragStart, dragOrigin
	Connect(header.InputBegan, function(input)
		if not isPress(input) then return end
		dragging = true
		dragStart = input.Position
		dragOrigin = shell.Position
	end)
	Connect(UIS.InputChanged, function(input)
		if not dragging or not isMove(input) then return end
		local factor = scale.Scale
		local delta = (input.Position - dragStart) / factor
		local screen = viewport() / factor
		local width = shell.AbsoluteSize.X / factor
		local height = shell.AbsoluteSize.Y / factor
		local x = dragOrigin.X.Scale * screen.X + dragOrigin.X.Offset + delta.X
		local y = dragOrigin.Y.Scale * screen.Y + dragOrigin.Y.Offset + delta.Y
		x = math.clamp(x, 80 - width / 2, screen.X - 80 + width / 2)
		y = math.clamp(y, height / 2, screen.Y - 44 + height / 2)
		shell.Position = UDim2.fromOffset(x, y)
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	local resizing, resizeStart, resizeOrigin, resizePosition
	Connect(grip.InputBegan, function(input)
		if not isPress(input) or window.Minimized then return end
		resizing = true
		resizeStart = input.Position
		resizeOrigin = shell.AbsoluteSize / scale.Scale
		resizePosition = shell.Position
	end)
	Connect(UIS.InputChanged, function(input)
		if not resizing or not isMove(input) then return end
		local factor = scale.Scale
		local delta = (input.Position - resizeStart) / factor
		local view = viewport() / factor
		local width = math.clamp(resizeOrigin.X + delta.X, window.MinSize.X, math.max(window.MinSize.X, view.X))
		local height = math.clamp(resizeOrigin.Y + delta.Y, window.MinSize.Y, math.max(window.MinSize.Y, view.Y))
		-- The shell is centre-anchored, so shift the centre by half the growth to keep the top-left fixed.
		shell.Size = UDim2.fromOffset(width, height)
		shell.Position = UDim2.new(
			resizePosition.X.Scale, resizePosition.X.Offset + (width - resizeOrigin.X) / 2,
			resizePosition.Y.Scale, resizePosition.Y.Offset + (height - resizeOrigin.Y) / 2
		)
		window.Size = shell.Size
		window.BaseSize = shell.Size
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then resizing = false end
	end)

	Connect(closeButton.MouseButton1Click, function()
		if window.CloseBehavior == "destroy" then
			window:Destroy()
		else
			setOpen(false)
		end
	end)

	Connect(minButton.MouseButton1Click, function()
		window.Minimized = not window.Minimized
		local target = window.Minimized and UDim2.fromOffset(240, 40) or window.Size
		Tween(shell, 0.2, { Size = target })
		body.Visible = not window.Minimized
		rail.Visible = not window.Minimized
		grip.Visible = not window.Minimized
		if window.ActivePopup then window.ActivePopup:Close() end
	end)

	function window:SetBackground(spec)
		spec = type(spec) == "table" and spec or { Image = spec }
		local source = spec.Image
		if source ~= nil and source ~= "" then
			source = Talis:LoadImage(source, "background")
			if type(source) == "string" and source:match("^https?://") then
				Talis:Notify({
					Title = "Background",
					Content = "Couldn't load that image. Use a direct PNG/JPG link.",
					Color = "Ember",
				})
				source = ""
			end
		end
		if self.Destroyed then return end
		image.Image = source or ""
		image.ImageTransparency = spec.Transparency or 0.15
		image.ScaleType = spec.ScaleType or Enum.ScaleType.Crop
		scrim.BackgroundTransparency = spec.Scrim or 0.45
		local has = source ~= nil and source ~= ""
		image.Visible = has
		scrim.Visible = has
		fade.Visible = has
		shell.BackgroundTransparency = has and 0.42 or 0.05
	end

	function window:SetBackgroundImage(source, opts)
		opts = opts or {}
		self:SetBackground({
			Image = source,
			Transparency = opts.Transparency or 0.15,
			Scrim = opts.Scrim or 0.45,
			ScaleType = opts.ScaleType or Enum.ScaleType.Crop,
		})
	end

	function window:SetScale(value)
		value = math.clamp(tonumber(value) or 1, 0.3, 3)
		scale.Scale = value
		self.Root.Size = UDim2.fromScale(1 / value, 1 / value)
		fit()
	end

	function window:GetScale()
		return scale.Scale
	end

	function window:SetTitle(value)
		self.Title = tostring(value)
		title.Text = self.Title
	end

	function window:SetSubtitle(value)
		self.Subtitle = tostring(value)
		subtitle.Text = self.Subtitle
	end

	function window:SetSpacing(value)
		value = tonumber(value) or 0
		self.Spacing = value
		for index = 1, #self.SpacingTargets do
			local entry = self.SpacingTargets[index]
			if entry.Layout.Parent then
				entry.Layout.Padding = UDim.new(0, value * (entry.Factor or 1))
			end
		end
	end

	function window:GetSpacing()
		return self.Spacing
	end

	function window:SetToggleKey(key)
		if type(key) == "string" then
			local ok, resolved = pcall(function() return Enum.KeyCode[key] end)
			if not ok or not resolved then return end
			key = resolved
		end
		self.ToggleKey = key
	end

	function window:SetAccent(color)
		if typeof(color) == "string" then color = Color3.fromHex(color) end
		local base = {}
		for key, value in next, Talis.Theme do base[key] = value end
		base.Accent = color
		Talis:ApplyTheme(base)
		self.Theme = Talis.Theme
	end

	function window:Tooltip(text, input)
		return Talis:Tooltip(text, input)
	end

	function window:MoveTooltip(input)
		return Talis:MoveTooltip(input)
	end

	function window:HideTooltip()
		return Talis:HideTooltip()
	end

	function window:SelectTab(tab)
		if self.Current == tab then return end
		if self.ActivePopup then self.ActivePopup:Close() end
		if self.Current then
			self.Current.Page.Visible = false
			local previous = self.TabMeta[self.Current]
			if previous then
				if previous.Pill then Tween(previous.Pill, 0.14, { BackgroundTransparency = 1 }) end
				if previous.Mark then Tween(previous.Mark, 0.14, { BackgroundTransparency = 1 }) end
				if previous.Label then previous.Label.TextColor3 = Talis.Theme.Muted end
			end
		end
		self.Current = tab
		local meta = self.TabMeta[tab]
		if meta then
			if meta.Pill then Tween(meta.Pill, 0.14, { BackgroundTransparency = 0.72 }) end
			if meta.Mark then Tween(meta.Mark, 0.14, { BackgroundTransparency = 0 }) end
			if meta.Label then meta.Label.TextColor3 = Talis.Theme.Text end
		end
		tab.Page.Visible = true
	end

	function window:Tab(spec)
		if spec == nil then spec = { Name = "Tab" } end
		spec = type(spec) == "table" and spec or { Name = tostring(spec) }
		local tab = { Name = spec.Name or "Tab", Window = self, Sections = {}, SectionCount = 0 }

		local button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = spec.Order or (#self.Tabs + 1),
			Parent = rail,
		})
		local pill = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Talis.Theme.Raised,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		})
		Corner(pill, 5)
		Theme(pill, "Raised", "BackgroundColor3")
		local mark = New("Frame", {
			Size = UDim2.new(0, 2, 0, 14),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Talis.Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		})
		Corner(mark, 1)
		Theme(mark, "Accent", "BackgroundColor3")
		local label = Text(button, tab.Name, 13, self.Fonts.Regular, "Muted")
		label.Position = UDim2.new(0, 14, 0, 0)
		label.Size = UDim2.new(1, -22, 1, 0)
		label.TextTruncate = Enum.TextTruncate.AtEnd

		self.TabMeta[tab] = { Pill = pill, Mark = mark, Label = label }
		tab.Button = button

		local page = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = body,
		})
		Theme(page, "Faint", "ScrollBarImageColor3")
		local pageLayout = New("UIListLayout", {
			Padding = UDim.new(0, (self.Spacing or Talis.Spacing) * 1.34),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
		self.SpacingTargets[#self.SpacingTargets + 1] = { Layout = pageLayout, Factor = 1.34 }
		Pad(page, 16, 18, 18, 18)
		tab.Page = page

		Connect(button.MouseEnter, function()
			if self.Current ~= tab then
				Tween(pill, 0.12, { BackgroundTransparency = 0.86 })
			end
		end)
		Connect(button.MouseLeave, function()
			if self.Current ~= tab then
				Tween(pill, 0.12, { BackgroundTransparency = 1 })
			end
		end)
		Connect(button.MouseButton1Click, function() self:SelectTab(tab) end)

		function tab:Section(sectionSpec)
			if sectionSpec == nil then sectionSpec = { Name = "" } end
			sectionSpec = type(sectionSpec) == "table" and sectionSpec or { Name = tostring(sectionSpec) }
			local owner = tab.Window
			local section = { Name = sectionSpec.Name or "", Tab = tab, Window = owner, Options = {}, Order = 0 }
			tab.SectionCount = tab.SectionCount + 1

			local group = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = tab.SectionCount,
				Parent = page,
			})
			local groupLayout = New("UIListLayout", {
				Padding = UDim.new(0, owner.Spacing or Talis.Spacing),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = group,
			})
			owner.SpacingTargets[#owner.SpacingTargets + 1] = { Layout = groupLayout, Factor = 1 }
			section.Group = group
			section.Layout = groupLayout

			if section.Name ~= "" then
				local head = New("Frame", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Parent = group,
				})
				local headText = Text(head, string.upper(section.Name), 10, owner.Fonts.Semibold, "Faint")
				headText.Size = UDim2.new(1, 0, 1, 0)
				headText.Position = UDim2.new(0, 0, 0, 6)
				local headLine = Hairline(head, "Hairline", 0.5)
				headLine.Position = UDim2.new(0, 0, 1, -1)
				section.Head = head
			end

			function section:Next()
				self.Order = self.Order + 1
				return self.Order
			end

			function section:SetTitle(value)
				self.Name = tostring(value)
				if self.Head then
					local headLabel = self.Head:FindFirstChildOfClass("TextLabel")
					if headLabel then headLabel.Text = string.upper(self.Name) end
				end
			end

			-- Creates an auto-sizing row. Returns (controlsFrame, info).
			-- opts: reserve = pixels kept free on the right for the control,
			--       split = fraction of the width the text may use (overrides reserve),
			--       top = align the text to the top, bottom = extra space kept under the text.
			function section:Row(height, name, desc, margin, opts)
				opts = opts or {}
				local base = height or 30
				local extra = margin or 0
				local bottom = opts.bottom or 0
				local fonts = self.Window.Fonts

				local outer = New("Frame", {
					Size = UDim2.new(1, 0, 0, base + extra),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = self:Next(),
					Parent = group,
				})
				local info = { row = outer, section = self }
				local block

				if name then
					block = New("Frame", {
						Size = opts.split and UDim2.new(opts.split, -8, 0, base + extra)
							or UDim2.new(1, -(opts.reserve or 120), 0, base + extra),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Parent = outer,
					})
					New("UIListLayout", {
						Padding = UDim.new(0, 1),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = opts.top and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Center,
						Parent = block,
					})
					New("UIPadding", { PaddingBottom = UDim.new(0, extra + bottom), Parent = block })

					local label = Wrap(Text(block, name, 13, fonts.Regular, "Text"))
					label.LayoutOrder = 1
					info.label = label
					if desc then
						local sub = Wrap(Text(block, desc, 11, fonts.Regular, "Faint"))
						sub.LayoutOrder = 2
						info.desc = sub
					end
				end

				-- Overlay for the controls; its height follows the text block (offset based, no scale feedback).
				local ctrl = New("Frame", {
					Size = UDim2.new(1, 0, 0, base),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = outer,
				})
				info.ctrl = ctrl

				if block then
					local function sync()
						local factor = math.max(owner.Scale.Scale, 0.01)
						local current = block.AbsoluteSize.Y / factor
						ctrl.Size = UDim2.new(1, 0, 0, math.max(base, current - extra))
					end
					Connect(block:GetPropertyChangedSignal("AbsoluteSize"), sync)
				end

				section.Options[#section.Options + 1] = info
				return ctrl, info
			end

			function section:Tooltip(object, tip)
				if not tip then return end
				Connect(object.InputBegan, function(input)
					if isMove(input) then self.Window:Tooltip(tip, input) end
				end)
				Connect(object.InputChanged, function(input)
					if isMove(input) then self.Window:MoveTooltip(input) end
				end)
				Connect(object.InputEnded, function(input)
					if isMove(input) then self.Window:HideTooltip() end
				end)
			end

			-- Every builder becomes a section method. Accepts a spec table or the shorthand form.
			for name, builder in next, Talis.Builders do
				section[name] = function(self, spec, ...)
					if type(spec) ~= "table" then
						local short = Talis.Shorthand[name]
						if short then spec = short(spec, ...) end
					end
					if type(spec) == "table" then
						if spec.Name == nil and spec.Title ~= nil and name ~= "Paragraph" then spec.Name = spec.Title end
						if spec.Desc == nil and spec.Description ~= nil then spec.Desc = spec.Description end
						if spec.Value == nil and spec.Default ~= nil then spec.Value = spec.Default end
						if spec.Callback == nil and spec.Changed ~= nil then spec.Callback = spec.Changed end
					end
					return builder(self, spec, ...)
				end
			end

			tab.Sections[#tab.Sections + 1] = section
			return section
		end

		-- tab:Toggle(...), tab:Paragraph(...) etc. drop into an automatic, header-less section.
		setmetatable(tab, {
			__index = function(t, key)
				if Talis.Builders[key] then
					return function(_, ...)
						local section = rawget(t, "DefaultSection")
						if not section then
							section = t:Section({ Name = "" })
							rawset(t, "DefaultSection", section)
						end
						return section[key](section, ...)
					end
				end
				return nil
			end,
		})

		self.Tabs[#self.Tabs + 1] = tab
		self.TabButtons[tab] = button
		if not self.Current or (self.Current == self.SettingsTab and tab ~= self.SettingsTab) then
			self:SelectTab(tab)
		end
		return tab
	end

	function window:Notify(config)
		return Talis:Notify(config)
	end

	function window:SetTheme(name)
		Talis:ApplyTheme(name)
	end

	function window:Watermark(text)
		text = tostring(text or "")
		if self.Mark and self.Mark.Parent then
			self.Mark.Text = text
			self.Mark.Visible = true
			return self.Mark
		end
		local mark = New("TextLabel", {
			Position = UDim2.new(0, 14, 0, 14),
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Talis.Theme.Raised,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Text = text,
			TextSize = 12,
			FontFace = self.Fonts.Semibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 70,
			Parent = self.Root,
		})
		Corner(mark, 4)
		Stroke(mark, "Accent", 1, 0.7)
		Pad(mark, 0, 10, 0, 10)
		Theme(mark, "Text", "TextColor3")
		Theme(mark, "Raised", "BackgroundColor3")
		self.Mark = mark
		return mark
	end

	function window:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		for index = 1, #Talis.Connections do
			pcall(function() Talis.Connections[index]:Disconnect() end)
		end
		table.clear(Talis.Connections)
		if self.ActivePopup then pcall(function() self.ActivePopup:Close() end) end
		for instance in next, Talis.Instances do
			pcall(function() instance:Destroy() end)
		end
		table.clear(Talis.Instances)
		table.clear(Talis.Themed)
		table.clear(Talis.ThemeHooks)
		table.clear(Talis.Options)
		table.clear(Talis.Rainbows)
		table.clear(Talis.Notifications)
		Talis.TooltipLabel = nil
		self.ActivePopup = nil
		if Talis.Overlay then pcall(function() Talis.Overlay:Clear() end) end
		if Talis.ActiveWindow == self then
			Talis.ActiveWindow = nil
			Talis.NotifLayer = nil
		end
		if env.__TalisWindow == self then env.__TalisWindow = nil end
		if gui then pcall(function() gui:Destroy() end) end
	end

	if config.ToggleButton then
		local toggle = New("TextButton", {
			Position = UDim2.new(0, 14, 1, -46),
			Size = UDim2.fromOffset(96, 30),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Text = config.ToggleButtonText or "talis",
			TextSize = 12,
			FontFace = self.Fonts.Semibold,
			AutoButtonColor = false,
			ZIndex = 70,
			Parent = window.Root,
		})
		Corner(toggle, 5)
		Stroke(toggle, "Accent", 1, 0.6)
		Theme(toggle, "Text", "TextColor3")
		Theme(toggle, "Raised", "BackgroundColor3")
		Connect(toggle.MouseButton1Click, function() setOpen(not opened) end)
	end

	Connect(UIS.InputBegan, function(input, processed)
		if processed or window.Listening > 0 then return end
		if input.KeyCode == window.ToggleKey then
			setOpen(not opened)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if window.ActivePopup then
				window.ActivePopup:Close()
			elseif opened then
				setOpen(false)
			end
		end
	end)

	local camera = workspace.CurrentCamera
	if camera then
		Connect(camera:GetPropertyChangedSignal("ViewportSize"), fit)
	end
	fit()

	shell.Visible = false
	Talis.ActiveWindow = window
	env.__TalisWindow = window
	if config.Open ~= false then
		opened = true
		window.Open = true
		shell.Visible = true
		shell.Size = UDim2.fromOffset(0, 0)
		Tween(shell, 0.22, { Size = window.Size }, Enum.EasingStyle.Quint)
	end

	return window
end

--[[ SHORTHAND (section:Toggle("Name", false, callback) etc.) ]]

local function split(value, callback)
	if type(value) == "function" then return nil, value end
	return value, callback
end

Talis.Shorthand.Toggle = function(name, value, callback)
	value, callback = split(value, callback)
	return { Name = name, Value = value, Callback = callback }
end
Talis.Shorthand.Button = function(name, callback)
	return { Name = name, Callback = callback }
end
Talis.Shorthand.Slider = function(name, min, max, value, callback)
	value, callback = split(value, callback)
	return { Name = name, Min = min, Max = max, Value = value, Callback = callback }
end
Talis.Shorthand.Dropdown = function(name, values, value, callback)
	value, callback = split(value, callback)
	return { Name = name, Values = values, Value = value, Callback = callback }
end
Talis.Shorthand.MultiDropdown = Talis.Shorthand.Dropdown
Talis.Shorthand.Input = function(name, value, callback)
	value, callback = split(value, callback)
	return { Name = name, Value = value, Callback = callback }
end
Talis.Shorthand.Keybind = Talis.Shorthand.Input
Talis.Shorthand.Colorpicker = Talis.Shorthand.Input
Talis.Shorthand.Label = function(text)
	return { Text = text }
end
Talis.Shorthand.Paragraph = function(title, content)
	return { Title = title, Content = content }
end
Talis.Shorthand.Header = function(text, desc)
	return { Text = text, Desc = desc }
end
Talis.Shorthand.Divider = function(text)
	return { Text = text }
end
Talis.Shorthand.Progress = function(name, value)
	return { Name = name, Value = value }
end

--[[ BUILDERS ]]

Talis.Builders.Toggle = function(section, spec)
	local window = section.Window
	local row, info = section:Row(spec.Desc and 36 or 30, spec.Name, spec.Desc, spec.Margin, { reserve = 52 })

	local track = New("Frame", {
		Size = UDim2.fromOffset(34, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Faint,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(track, 9)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		BorderSizePixel = 0,
		Parent = track,
	})
	Theme(knob, "Text", "BackgroundColor3")
	Corner(knob, 7)

	local option = {
		Type = "Toggle",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		Tip = spec.Tip,
		section = section,
		Callback = spec.Callback or function() end,
		Value = spec.Value == true,
	}
	Register(option)
	Decorate(option, info, window)

	function option:Set(value, silent)
		value = value == true
		self.Value = value
		Talis:SetFlag(self.Flag, value)
		Tween(knob, 0.14, { Position = UDim2.new(0, value and 18 or 2, 0.5, 0) })
		Tween(track, 0.14, { BackgroundColor3 = value and Talis.Theme.Accent or Talis.Theme.Faint })
		if not silent then self.Callback(value) end
		return value
	end

	function option:Get()
		return self.Value
	end

	function option:Toggle()
		return self:Set(not self.Value)
	end

	OnTheme(function()
		track.BackgroundColor3 = option.Value and Talis.Theme.Accent or Talis.Theme.Faint
	end)

	Connect(row.InputBegan, function(input)
		if not isPress(input) or option.Locked then return end
		option:Set(not option.Value)
	end)

	option:Set(option.Value, true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Button = function(section, spec)
	local window = section.Window
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 28 + margin),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIPadding", { PaddingBottom = UDim.new(0, margin), Parent = row })

	local button = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = spec.Primary and 0 or 0.35,
		BorderSizePixel = 0,
		Text = tostring(spec.Name or "Button"),
		TextSize = 12,
		FontFace = Talis.Fonts.Semibold,
		TextWrapped = true,
		AutoButtonColor = false,
		Parent = row,
	})
	Pad(button, 7, 10, 7, 10)
	Corner(button, 5)
	Stroke(button, spec.Primary and "Accent" or "Stroke", 1, spec.Primary and 0.1 or 0.6)
	Theme(button, spec.Primary and "Accent" or "Raised", "BackgroundColor3")
	Theme(button, spec.Primary and "AccentText" or "Text", "TextColor3")

	local option = {
		Type = "Button",
		Name = spec.Name,
		Flag = spec.Flag,
		section = section,
		Callback = spec.Callback or function() end,
		Row = row,
		Window = window,
	}

	Connect(button.MouseEnter, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0.12 or 0.15 })
	end)
	Connect(button.MouseLeave, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0 or 0.35 })
	end)
	Connect(button.MouseButton1Click, function()
		if option.Locked then return end
		Talis:SetFlag((option.Flag or option.Name or "button") .. "/Clicked", os.clock())
		option.Callback()
	end)

	function option:SetTitle(value)
		button.Text = tostring(value)
		self.Name = tostring(value)
	end

	function option:Lock(state)
		self.Locked = state ~= false
		button.TextTransparency = self.Locked and 0.42 or 0
		return self.Locked
	end

	function option:Unlock()
		return self:Lock(false)
	end

	function option:SetVisible(state)
		row.Visible = state ~= false
	end

	function option:Destroy()
		row:Destroy()
	end

	section.Options[#section.Options + 1] = { row = row, label = button }
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

-- Returns a proxy that behaves like the TextLabel but also has :Set / :SetText / :Destroy.
local function proxyLabel(label, row, extra)
	local object = { Instance = label, Row = row }
	function object:Set(value) label.Text = tostring(value) end
	function object:SetText(value) label.Text = tostring(value) end
	function object:Get() return label.Text end
	function object:SetVisible(state) row.Visible = state ~= false end
	function object:Destroy() row:Destroy() end
	if extra then
		for key, value in next, extra do object[key] = value end
	end
	return setmetatable(object, {
		__index = function(_, key)
			local ok, value = pcall(function() return label[key] end)
			if ok then return value end
			return nil
		end,
		__newindex = function(t, key, value)
			local ok = pcall(function() return label[key] end)
			if ok then
				label[key] = value
			else
				rawset(t, key, value)
			end
		end,
	})
end

Talis.Builders.Label = function(section, spec)
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIPadding", { PaddingBottom = UDim.new(0, margin), Parent = row })
	local label = Wrap(Text(row, spec.Text or "", spec.Size or 12, Talis.Fonts.Regular, spec.Color or "Muted"))
	label.RichText = spec.Rich ~= false
	section.Options[#section.Options + 1] = { row = row, label = label }
	return proxyLabel(label, row)
end

Talis.Builders.Paragraph = function(section, spec)
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = spec.Card == false and 1 or 0.55,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	Theme(row, "Raised", "BackgroundColor3")
	if spec.Card ~= false then
		Corner(row, 6)
		Stroke(row, "Stroke", 1, 0.7)
		Pad(row, 10, 12, 10, 12)
	end
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

	local titleLabel
	if spec.Title and tostring(spec.Title) ~= "" then
		titleLabel = Wrap(Text(row, spec.Title, 13, Talis.Fonts.Semibold, "Text"))
		titleLabel.LayoutOrder = 1
	end
	local contentLabel = Wrap(Text(row, spec.Content or spec.Text or "", spec.Size or 12, Talis.Fonts.Regular, spec.Color or "Muted"))
	contentLabel.RichText = spec.Rich ~= false
	contentLabel.LayoutOrder = 2

	local object
	object = proxyLabel(contentLabel, row, {
		TitleLabel = titleLabel,
		SetTitle = function(_, value)
			if titleLabel then
				titleLabel.Text = tostring(value)
			end
		end,
		SetContent = function(_, value)
			contentLabel.Text = tostring(value)
		end,
	})
	function object:Set(title, content)
		if content == nil then
			contentLabel.Text = tostring(title)
		else
			if titleLabel then titleLabel.Text = tostring(title) end
			contentLabel.Text = tostring(content)
		end
	end

	section.Options[#section.Options + 1] = { row = row, label = titleLabel or contentLabel }
	return object
end

Talis.Builders.Header = function(section, spec)
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	New("UIPadding", { PaddingBottom = UDim.new(0, margin), Parent = row })
	local title = Wrap(Text(row, spec.Text or "", 15, Talis.Fonts.Bold, "Text"))
	title.LayoutOrder = 1
	if spec.Desc then
		local desc = Wrap(Text(row, spec.Desc, 11, Talis.Fonts.Regular, "Faint"))
		desc.LayoutOrder = 2
	end
	section.Options[#section.Options + 1] = { row = row, label = title }
	return proxyLabel(title, row)
end

Talis.Builders.Divider = function(section, spec)
	local hasText = spec.Text ~= nil and spec.Text ~= ""
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, (hasText and 20 or 10) + (spec.Margin or 0)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local line = Hairline(row, "Hairline", 0.5)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	if hasText then
		local label = Text(row, string.upper(tostring(spec.Text)), 10, Talis.Fonts.Semibold, "Faint", Enum.TextXAlignment.Center)
		label.Size = UDim2.fromOffset(0, 20)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Position = UDim2.new(0.5, 0, 0, 0)
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.BackgroundTransparency = 0
		Theme(label, "Surface", "BackgroundColor3")
		Pad(label, 0, 6, 0, 6)
	end
	return row
end

Talis.Builders.Space = function(section, size)
	return New("Frame", {
		Size = UDim2.new(1, 0, 0, tonumber(size) or 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
end

RunService.RenderStepped:Connect(function()
	if #Talis.Rainbows == 0 then return end
	Talis.RainbowHue = (os.clock() * 0.06) % 1
	for index = 1, #Talis.Rainbows do
		local picker = Talis.Rainbows[index]
		if picker and picker.Apply then picker.Apply() end
	end
end)

local function decimals(step)
	local places = 0
	while places < 6 and math.abs(step * 10 ^ places - math.floor(step * 10 ^ places + 0.5)) > 1e-6 do
		places = places + 1
	end
	return places
end

local function format(value, places)
	return string.format("%." .. places .. "f", value)
end

local function normalizeValues(list)
	local out = {}
	for index = 1, #(list or {}) do
		local entry = list[index]
		if type(entry) == "table" then
			out[index] = { Name = tostring(entry.Name or entry[1] or index), Value = entry.Value }
		else
			out[index] = { Name = tostring(entry) }
		end
	end
	return out
end

-- Popups own their connections, so nothing leaks when they close.
local function Popup(window, anchor, width, height)
	if window.ActivePopup then window.ActivePopup:Close() end
	local host = window.PopupHost

	local popup = { Anchor = anchor, Window = window, Conns = {} }

	function popup:Connect(signal, fn)
		local connection = signal:Connect(fn)
		self.Conns[#self.Conns + 1] = connection
		return connection
	end

	local dismiss = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 40,
		Parent = host,
	})

	local holder = New("Frame", {
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 41,
		Parent = host,
	})
	Corner(holder, 6)
	Stroke(holder, "Stroke", 1, 0.3)
	Theme(holder, "Raised", "BackgroundColor3")
	popup.Holder = holder

	-- Right edge aligned to the anchor, flipped above when there's no room below.
	local function place()
		local factor = math.max(window.Scale.Scale, 0.01)
		local anchorPosition = anchor.AbsolutePosition
		local anchorSize = anchor.AbsoluteSize
		local view = viewport()
		local w, h = width * factor, height * factor
		local x = anchorPosition.X + anchorSize.X - w
		local y = anchorPosition.Y + anchorSize.Y + 6 * factor
		if y + h + 10 > view.Y then y = anchorPosition.Y - h - 6 * factor end
		x = math.clamp(x, 8, math.max(8, view.X - w - 8))
		y = math.clamp(y, 8, math.max(8, view.Y - h - 8))
		holder.Position = UDim2.fromOffset(x / factor, y / factor)
	end

	popup:Connect(RunService.RenderStepped, function()
		if not holder.Parent then return end
		local body = window.Body
		local bodyPosition = body.AbsolutePosition
		local anchorPosition = anchor.AbsolutePosition
		local visible = anchorPosition.Y + anchor.AbsoluteSize.Y > bodyPosition.Y
			and anchorPosition.Y < bodyPosition.Y + body.AbsoluteSize.Y
		holder.Visible = visible
		if visible then place() end
	end)

	place()

	function popup:Close()
		if self.Closed then return end
		self.Closed = true
		if window.ActivePopup == self then window.ActivePopup = nil end
		for index = 1, #self.Conns do
			pcall(function() self.Conns[index]:Disconnect() end)
		end
		table.clear(self.Conns)
		if dismiss.Parent then dismiss:Destroy() end
		if holder.Parent then holder:Destroy() end
	end

	popup:Connect(dismiss.MouseButton1Click, function() popup:Close() end)

	window.ActivePopup = popup
	return popup
end

Talis.Builders.Slider = function(section, spec)
	local window = section.Window
	local min = tonumber(spec.Min) or 0
	local max = tonumber(spec.Max) or 100
	if max <= min then max = min + 1 end
	local step = tonumber(spec.Step) or (spec.Precise and 10 ^ -spec.Precise) or 1
	if step <= 0 then step = 1 end
	local places = decimals(step)
	local unit = spec.Unit or ""
	local value = math.clamp(tonumber(spec.Value) or min, min, max)

	local row, info = section:Row(spec.Desc and 50 or 38, spec.Name, spec.Desc, spec.Margin, {
		reserve = 76,
		top = true,
		bottom = 18,
	})

	local valueBox = New("TextBox", {
		Size = UDim2.new(0, 52, 0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 12,
		FontFace = Talis.Fonts.Mono,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		Parent = row,
	})
	Theme(valueBox, "Muted", "TextColor3")

	local hit = New("Frame", {
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = row,
	})
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		Parent = hit,
	})
	Theme(bar, "Hairline", "BackgroundColor3")
	Corner(bar, 2)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme(fill, "Accent", "BackgroundColor3")
	Corner(fill, 2)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(11, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BorderSizePixel = 0,
		Parent = hit,
	})
	Theme(knob, "Text", "BackgroundColor3")
	Corner(knob, 6)

	local option = {
		Type = "Slider",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		section = section,
		Callback = spec.Callback or function() end,
		Value = value,
		Min = min,
		Max = max,
		Step = step,
	}
	Register(option)
	Decorate(option, info, window)

	local function ratio(v)
		return (v - min) / (max - min)
	end

	function option:Set(input, silent)
		local v = tonumber(input)
		if not v then v = self.Min end
		v = self.Min + math.floor((v - self.Min) / self.Step + 0.5) * self.Step
		v = math.clamp(v, self.Min, self.Max)
		v = tonumber(format(v, places)) or v
		self.Value = v
		local alpha = ratio(v)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueBox.Text = spec.Format and spec.Format(v) or (format(v, places) .. unit)
		Talis:SetFlag(self.Flag, v)
		if not silent then self.Callback(v) end
		return v
	end

	function option:Get()
		return self.Value
	end

	local dragging = false

	local function fromPointer(input)
		local alpha = math.clamp((pointer(input).X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		option:Set(min + alpha * (max - min))
	end

	Connect(hit.InputBegan, function(input)
		if option.Locked or not isPress(input) then return end
		dragging = true
		fromPointer(input)
	end)
	Connect(UIS.InputChanged, function(input)
		if not dragging or not isMove(input) then return end
		fromPointer(input)
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	Connect(valueBox.Focused, function()
		valueBox.Text = format(option.Value, places)
	end)
	Connect(valueBox.FocusLost, function()
		local parsed = tonumber(tostring(valueBox.Text):match("-?%d*%.?%d+"))
		option:Set(parsed or option.Value)
	end)

	Connect(row.MouseEnter, function() Tween(knob, 0.12, { BackgroundColor3 = Talis.Theme.Accent }) end)
	Connect(row.MouseLeave, function() Tween(knob, 0.12, { BackgroundColor3 = Talis.Theme.Text }) end)

	option:Set(option.Value, true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

local function buildDropdown(section, spec, multi)
	local window = section.Window
	local values = normalizeValues(spec.Values)
	local selected = {}
	local width = spec.Width or 150

	if multi then
		local initial = spec.Value
		if type(initial) == "table" then
			for index = 1, #initial do selected[tostring(initial[index])] = true end
		elseif initial ~= nil then
			selected[tostring(initial)] = true
		end
	else
		selected[tostring(spec.Value or (values[1] and values[1].Name) or "")] = true
	end

	local row, info = section:Row(spec.Desc and 36 or 30, spec.Name, spec.Desc, spec.Margin, { reserve = width + 12 })

	local pill = New("TextButton", {
		Size = UDim2.fromOffset(width, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(pill, 5)
	local pillStroke = Stroke(pill, "Stroke", 1, 0.6)
	Theme(pill, "Raised", "BackgroundColor3")

	local pillText = Text(pill, "", 12, Talis.Fonts.Regular, "Text")
	pillText.Position = UDim2.new(0, 10, 0, 0)
	pillText.Size = UDim2.new(1, -30, 1, 0)
	pillText.TextTruncate = Enum.TextTruncate.AtEnd

	local chevron = Text(pill, Talis.Glyphs.chevron, 10, Talis.Fonts.Regular, "Faint", Enum.TextXAlignment.Right)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -8, 0.5, 0)
	chevron.Size = UDim2.new(0, 12, 1, 0)

	local option = {
		Type = multi and "MultiDropdown" or "Dropdown",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		section = section,
		Callback = spec.Callback or function() end,
	}
	Register(option)
	Decorate(option, info, window)

	local function collect()
		local out = {}
		for index = 1, #values do
			local entry = values[index]
			if selected[entry.Name] then out[#out + 1] = entry.Name end
		end
		return out
	end

	local function refreshText()
		local out = collect()
		option.Value = multi and out or out[1]
		if #out == 0 then
			pillText.Text = "None"
		elseif #out <= 2 then
			pillText.Text = table.concat(out, ", ")
		else
			pillText.Text = out[1] .. " +" .. (#out - 1)
		end
	end

	function option:Set(value, silent)
		selected = {}
		if multi then
			if type(value) == "table" then
				for index = 1, #value do selected[tostring(value[index])] = true end
			elseif value ~= nil then
				selected[tostring(value)] = true
			end
		elseif value ~= nil then
			selected[tostring(value)] = true
		end
		refreshText()
		Talis:SetFlag(option.Flag, option.Value)
		if not silent then option.Callback(option.Value) end
		return option.Value
	end

	function option:Get()
		return self.Value
	end

	function option:Refresh(list)
		values = normalizeValues(list)
		refreshText()
	end

	function option:Open()
		if option.Locked then return end
		if window.ActivePopup and window.ActivePopup.Anchor == pill then
			window.ActivePopup:Close()
			return
		end
		local height = #values == 0 and 34 or math.min(#values * 24 + 10, 168)
		local popup = Popup(window, pill, math.max(width, 120), height)

		if #values == 0 then
			local empty = Text(popup.Holder, "No options", 12, Talis.Fonts.Regular, "Faint", Enum.TextXAlignment.Center)
			empty.Size = UDim2.new(1, 0, 1, 0)
			return
		end

		local scroll = New("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = popup.Holder,
		})
		Theme(scroll, "Faint", "ScrollBarImageColor3")
		New("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

		for index = 1, #values do
			local entry = values[index]
			local on = selected[entry.Name] == true
			local item = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = scroll,
			})
			Theme(item, "Hover", "BackgroundColor3")
			Corner(item, 4)
			local label = Text(item, entry.Name, 12, Talis.Fonts.Regular, on and "Text" or "Muted")
			label.Position = UDim2.new(0, 8, 0, 0)
			label.Size = UDim2.new(1, -28, 1, 0)
			label.TextTruncate = Enum.TextTruncate.AtEnd
			local tick = Text(item, Talis.Glyphs.check, 11, Talis.Fonts.Semibold, "Accent", Enum.TextXAlignment.Right)
			tick.AnchorPoint = Vector2.new(1, 0.5)
			tick.Position = UDim2.new(1, -8, 0.5, 0)
			tick.Size = UDim2.new(0, 12, 1, 0)
			tick.Visible = on

			popup:Connect(item.MouseEnter, function() Tween(item, 0.1, { BackgroundTransparency = 0.7 }) end)
			popup:Connect(item.MouseLeave, function() Tween(item, 0.1, { BackgroundTransparency = 1 }) end)
			popup:Connect(item.MouseButton1Click, function()
				if multi then
					selected[entry.Name] = not selected[entry.Name] or nil
					local now = selected[entry.Name] == true
					tick.Visible = now
					Theme(label, now and "Text" or "Muted", "TextColor3")
					refreshText()
					Talis:SetFlag(option.Flag, option.Value)
					option.Callback(option.Value)
				else
					option:Set(entry.Name)
					popup:Close()
				end
			end)
		end
	end

	Connect(pill.MouseButton1Click, function() option:Open() end)
	Connect(pill.MouseEnter, function() Tween(pillStroke, 0.12, { Transparency = 0.3 }) end)
	Connect(pill.MouseLeave, function() Tween(pillStroke, 0.12, { Transparency = 0.6 }) end)

	if spec.Value ~= nil then
		option:Set(spec.Value, true)
	elseif not multi and values[1] then
		option:Set(values[1].Name, true)
	else
		option:Set(nil, true)
	end
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Dropdown = function(section, spec)
	return buildDropdown(section, spec, false)
end

Talis.Builders.MultiDropdown = function(section, spec)
	return buildDropdown(section, spec, true)
end

Talis.Builders.Input = function(section, spec)
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin, { split = 0.4 })

	local field = New("Frame", {
		Size = UDim2.new(0.6, -8, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(field, 5)
	local fieldStroke = Stroke(field, "Stroke", 1, 0.6)
	Theme(field, "Raised", "BackgroundColor3")

	local box = New("TextBox", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.new(0, 9, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(spec.Value or ""),
		PlaceholderText = spec.Placeholder or "",
		TextSize = 12,
		FontFace = Talis.Fonts.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = field,
	})
	Theme(box, "Text", "TextColor3")
	Theme(box, "Faint", "PlaceholderColor3")

	local option = {
		Type = "Input",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		section = section,
		Callback = spec.Callback or function() end,
		Value = tostring(spec.Value or ""),
	}
	Register(option)
	Decorate(option, info, window)

	function option:Set(value, silent)
		self.Value = tostring(value or "")
		box.Text = self.Value
		Talis:SetFlag(self.Flag, self.Value)
		if not silent then self.Callback(self.Value) end
		return self.Value
	end

	function option:Get()
		return self.Value
	end

	Connect(box.Focused, function()
		Tween(fieldStroke, 0.12, { Color = Talis.Theme.Accent, Transparency = 0.2 })
	end)
	Connect(box.FocusLost, function(enterPressed)
		Tween(fieldStroke, 0.12, { Color = Talis.Theme.Stroke, Transparency = 0.6 })
		if spec.NumbersOnly then
			box.Text = tostring(tonumber(box.Text) or 0)
		end
		option.Value = box.Text
		Talis:SetFlag(option.Flag, option.Value)
		option.Callback(option.Value, enterPressed or nil)
	end)

	Talis:SetFlag(option.Flag, option.Value)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

local DEFAULT_BLACKLIST = { "W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote" }

Talis.Builders.Keybind = function(section, spec)
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin, { reserve = 130 })

	local mode = spec.Mode == "Hold" and "Hold" or "Toggle"
	local value = spec.Value or "NONE"
	if typeof(value) == "EnumItem" then value = value.Name end
	value = tostring(value)

	-- The key cap is a single auto-sizing button, so long key names never overflow.
	local cap = New("TextButton", {
		Size = UDim2.fromOffset(74, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Text = "",
		TextSize = 11,
		FontFace = Talis.Fonts.Mono,
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(cap, 5)
	Pad(cap, 0, 8, 0, 8)
	local capStroke = Stroke(cap, "Stroke", 1, 0.6)
	Theme(cap, "Raised", "BackgroundColor3")

	local option = {
		Type = "Keybind",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		section = section,
		Callback = spec.Callback or function() end,
		Value = value,
		Mode = mode,
		Mouse = spec.Mouse ~= false,
		Blacklist = spec.Blacklist or DEFAULT_BLACKLIST,
		Listening = false,
		Pressed = false,
		Toggled = false,
	}
	Register(option)
	Decorate(option, info, window)

	local function paint()
		if option.Listening then
			cap.Text = "..."
			cap.TextColor3 = Talis.Theme.Accent
		elseif option.Value == "NONE" then
			cap.Text = "[ NONE ]"
			cap.TextColor3 = Talis.Theme.Faint
		else
			cap.Text = "[ " .. option.Value .. " ]"
			cap.TextColor3 = option.Pressed and Talis.Theme.Accent or Talis.Theme.Text
		end
	end

	local function setListening(state)
		if option.Listening == state then return end
		option.Listening = state
		window.Listening = math.max(0, (window.Listening or 0) + (state and 1 or -1))
		if state then
			Tween(capStroke, 0.12, { Color = Talis.Theme.Accent, Transparency = 0.2 })
		else
			Tween(capStroke, 0.12, { Color = Talis.Theme.Stroke, Transparency = 0.6 })
		end
		paint()
	end

	function option:Set(newValue, silent)
		if typeof(newValue) == "EnumItem" then newValue = newValue.Name end
		if newValue == nil or newValue == "" then newValue = "NONE" end
		self.Value = tostring(newValue)
		Talis:SetFlag(self.Flag, self.Value)
		paint()
		if not silent then self.Callback(self.Value, false, self.Toggled) end
		return self.Value
	end

	function option:Get()
		return self.Value
	end

	-- Hold mode: true while the key is down. Toggle mode: the toggled state.
	function option:State()
		if self.Mode == "Hold" then return self.Pressed end
		return self.Toggled
	end

	OnTheme(paint)

	Connect(cap.MouseButton1Click, function()
		if option.Locked then return end
		setListening(not option.Listening)
	end)

	local function matches(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name == option.Value
		end
		return input.UserInputType.Name == option.Value
	end

	Connect(UIS.InputBegan, function(input, processed)
		if processed then return end
		if option.Listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Backspace then
					option:Set("NONE")
				elseif input.KeyCode == Enum.KeyCode.Escape then
					-- cancel
				elseif not table.find(option.Blacklist, input.KeyCode.Name) then
					option:Set(input.KeyCode.Name)
				else
					return
				end
			elseif option.Mouse and isMouseButton(input) then
				option:Set(input.UserInputType.Name)
			else
				return
			end
			setListening(false)
			return
		end

		if option.Locked or option.Value == "NONE" or not matches(input) then return end
		option.Pressed = true
		if option.Mode == "Hold" then
			paint()
			option.Callback(option.Value, true, option.Toggled)
		else
			option.Toggled = not option.Toggled
			Talis:SetFlag(option.Flag .. "/Toggled", option.Toggled)
			paint()
			option.Callback(option.Value, true, option.Toggled)
		end
	end)

	Connect(UIS.InputEnded, function(input)
		if not option.Pressed then return end
		if not matches(input) then return end
		option.Pressed = false
		paint()
		if option.Mode == "Hold" then
			option.Callback(option.Value, false, option.Toggled)
		end
	end)

	paint()
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Colorpicker = function(section, spec)
	local window = section.Window
	local row, info = section:Row(30, spec.Name, spec.Desc, spec.Margin, { reserve = 62 })

	local swatch = New("TextButton", {
		Size = UDim2.fromOffset(46, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(swatch, 4)
	Stroke(swatch, "Stroke", 1, 0.4)

	local option = {
		Type = "Colorpicker",
		Name = spec.Name,
		Desc = spec.Desc,
		Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag,
		section = section,
		Callback = spec.Callback or function() end,
		Value = { 0.15, 0.7, 0.85, 1, false },
	}
	if typeof(spec.Value) == "Color3" then
		local h, s, v = spec.Value:ToHSV()
		option.Value[1], option.Value[2], option.Value[3] = h, s, v
	elseif type(spec.Value) == "table" then
		for index = 1, 5 do
			if spec.Value[index] ~= nil then option.Value[index] = spec.Value[index] end
		end
	end
	Register(option)
	Decorate(option, info, window)

	local function toColor()
		local v = option.Value
		return Color3.fromHSV(v[1], v[2], v[3])
	end

	local function push(silent)
		local color = toColor()
		swatch.BackgroundColor3 = color
		local registered = table.find(Talis.Rainbows, option)
		if option.Value[5] and not registered then
			table.insert(Talis.Rainbows, option)
		elseif not option.Value[5] and registered then
			table.remove(Talis.Rainbows, registered)
		end
		Talis:SetFlag(option.Flag, { option.Value[1], option.Value[2], option.Value[3], option.Value[4], option.Value[5] })
		if option.Panel then option.Panel() end
		if not silent then option.Callback(option.Value, color) end
	end

	function option:Set(value, silent)
		if typeof(value) == "Color3" then
			local h, s, v = value:ToHSV()
			self.Value[1], self.Value[2], self.Value[3] = h, s, v
		elseif type(value) == "table" then
			for index = 1, 5 do
				if value[index] ~= nil then self.Value[index] = value[index] end
			end
		end
		push(silent)
		return self.Value
	end

	function option:Get()
		return self.Value
	end

	function option:Color()
		return toColor()
	end

	option.Apply = function()
		option.Value[1] = Talis.RainbowHue
		push(true)
	end

	Connect(swatch.MouseButton1Click, function()
		if option.Locked then return end
		if window.ActivePopup and window.ActivePopup.Anchor == swatch then
			window.ActivePopup:Close()
			return
		end
		local popup = Popup(window, swatch, 214, 258)
		local holder = popup.Holder

		local square = New("Frame", {
			Size = UDim2.new(1, -20, 0, 128),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundColor3 = Color3.fromHSV(option.Value[1], 1, 1),
			BorderSizePixel = 0,
			Parent = holder,
		})
		Corner(square, 4)
		local white = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = square,
		})
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = white,
		})
		local black = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Parent = square,
		})
		New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = black,
		})
		local cursor = New("Frame", {
			Size = UDim2.fromOffset(9, 9),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = square,
		})
		Corner(cursor, 5)
		New("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Parent = cursor })

		local hueBar = New("Frame", {
			Size = UDim2.new(1, -20, 0, 10),
			Position = UDim2.new(0, 10, 0, 146),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = holder,
		})
		Corner(hueBar, 5)
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Parent = hueBar,
		})
		local huePin = New("Frame", {
			Size = UDim2.new(0, 2, 1, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = hueBar,
		})
		Corner(huePin, 1)

		local alphaBar = New("Frame", {
			Size = UDim2.new(1, -20, 0, 10),
			Position = UDim2.new(0, 10, 0, 164),
			BackgroundColor3 = Color3.fromRGB(120, 120, 120),
			BorderSizePixel = 0,
			Parent = holder,
		})
		Corner(alphaBar, 5)
		local alphaGrad = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = alphaBar,
		})
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = alphaGrad,
		})
		local alphaPin = New("Frame", {
			Size = UDim2.new(0, 2, 1, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = alphaBar,
		})
		Corner(alphaPin, 1)

		local hexField = New("Frame", {
			Size = UDim2.new(1, -20, 0, 22),
			Position = UDim2.new(0, 10, 0, 182),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = holder,
		})
		Theme(hexField, "Hover", "BackgroundColor3")
		Corner(hexField, 4)
		local hexBox = New("TextBox", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "HEX",
			TextSize = 11,
			FontFace = Talis.Fonts.Mono,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = hexField,
		})
		Theme(hexBox, "Text", "TextColor3")
		Theme(hexBox, "Faint", "PlaceholderColor3")

		local strip = New("Frame", {
			Size = UDim2.new(1, -20, 0, 16),
			Position = UDim2.new(0, 10, 0, 210),
			BackgroundTransparency = 1,
			Parent = holder,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = strip,
		})
		local presets = spec.Presets or {
			"4FD6A8", "2FB8A8", "9BE8CB", "E3B96B",
			"F0923C", "E0574F", "7A8CFF", "E6F1EA",
		}
		for index = 1, #presets do
			local chip = New("TextButton", {
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.fromHex(presets[index]),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = strip,
			})
			Corner(chip, 3)
			popup:Connect(chip.MouseButton1Click, function()
				option:Set(Color3.fromHex(presets[index]))
			end)
		end

		local rainbowButton = New("TextButton", {
			Size = UDim2.new(1, -20, 0, 20),
			Position = UDim2.new(0, 10, 0, 230),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Text = "Rainbow",
			TextSize = 11,
			FontFace = Talis.Fonts.Regular,
			AutoButtonColor = false,
			Parent = holder,
		})
		Theme(rainbowButton, "Hover", "BackgroundColor3")
		Corner(rainbowButton, 4)

		local function refresh()
			local v = option.Value
			square.BackgroundColor3 = Color3.fromHSV(v[1], 1, 1)
			cursor.Position = UDim2.new(v[2], 0, 1 - v[3], 0)
			huePin.Position = UDim2.new(1 - v[1], 0, 0.5, 0)
			alphaPin.Position = UDim2.new(v[4], 0, 0.5, 0)
			alphaGrad.BackgroundColor3 = toColor()
			if not hexBox:IsFocused() then
				hexBox.Text = "#" .. toColor():ToHex()
			end
			rainbowButton.TextColor3 = v[5] and Talis.Theme.Accent or Talis.Theme.Muted
		end

		option.Panel = refresh

		local editing

		local function ratioOf(frame, input, axis)
			local point = pointer(input)
			if axis == "x" then
				return math.clamp((point.X - frame.AbsolutePosition.X) / math.max(frame.AbsoluteSize.X, 1), 0, 1)
			end
			return math.clamp((point.Y - frame.AbsolutePosition.Y) / math.max(frame.AbsoluteSize.Y, 1), 0, 1)
		end

		local function update(input)
			if editing == "sv" then
				option.Value[2] = ratioOf(square, input, "x")
				option.Value[3] = 1 - ratioOf(square, input, "y")
			elseif editing == "hue" then
				option.Value[1] = 1 - math.min(ratioOf(hueBar, input, "x"), 0.999)
			elseif editing == "alpha" then
				option.Value[4] = ratioOf(alphaBar, input, "x")
			else
				return
			end
			option.Value[5] = false
			push()
			refresh()
		end

		popup:Connect(square.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "sv"
			update(input)
		end)
		popup:Connect(hueBar.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "hue"
			update(input)
		end)
		popup:Connect(alphaBar.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "alpha"
			update(input)
		end)
		popup:Connect(UIS.InputChanged, function(input)
			if not editing or not isMove(input) then return end
			update(input)
		end)
		popup:Connect(UIS.InputEnded, function(input)
			if isPress(input) then editing = nil end
		end)

		popup:Connect(hexBox.FocusLost, function()
			local hex = hexBox.Text:gsub("#", ""):gsub("%s", "")
			if #hex == 6 and tonumber(hex, 16) then
				option:Set(Color3.fromHex(hex))
			end
			refresh()
		end)

		popup:Connect(rainbowButton.MouseButton1Click, function()
			option.Value[5] = not option.Value[5]
			push(true)
			refresh()
		end)

		refresh()

		local baseClose = popup.Close
		function popup:Close()
			option.Panel = nil
			baseClose(self)
		end
	end)

	push(true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Progress = function(section, spec)
	local row, info = section:Row(spec.Desc and 44 or 38, spec.Name, spec.Desc, spec.Margin, {
		reserve = 56,
		top = true,
		bottom = 14,
	})

	local percent = Text(row, "0%", 11, Talis.Fonts.Mono, "Muted", Enum.TextXAlignment.Right)
	percent.AnchorPoint = Vector2.new(1, 0)
	percent.Position = UDim2.new(1, 0, 0, 0)
	percent.Size = UDim2.new(0, 40, 0, 15)

	local bar = New("Frame", {
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 3),
		BorderSizePixel = 0,
		Parent = row,
	})
	Theme(bar, "Hairline", "BackgroundColor3")
	Corner(bar, 2)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme(fill, "Accent", "BackgroundColor3")
	Corner(fill, 2)

	local option = { Type = "Progress", Name = spec.Name, section = section, Value = 0, Row = info.row, Window = section.Window }

	function option:Set(value)
		local alpha = math.clamp(tonumber(value) or 0, 0, 1)
		self.Value = alpha
		Tween(fill, 0.16, { Size = UDim2.new(alpha, 0, 1, 0) })
		percent.Text = string.format("%d%%", math.floor(alpha * 100 + 0.5))
		return alpha
	end

	function option:Get()
		return self.Value
	end

	function option:SetTitle(value)
		if info.label then info.label.Text = tostring(value) end
		self.Name = tostring(value)
	end

	function option:Destroy()
		info.row:Destroy()
	end

	if spec.Value ~= nil then option:Set(spec.Value) end
	return option
end

-- Friendly aliases.
Talis.Builders.Textbox = Talis.Builders.Input
Talis.Builders.Bind = Talis.Builders.Keybind
Talis.Builders.ColorPicker = Talis.Builders.Colorpicker
Talis.Builders.Switch = Talis.Builders.Toggle
Talis.Builders.Separator = Talis.Builders.Divider
Talis.Shorthand.Textbox = Talis.Shorthand.Input
Talis.Shorthand.Bind = Talis.Shorthand.Keybind
Talis.Shorthand.ColorPicker = Talis.Shorthand.Colorpicker
Talis.Shorthand.Switch = Talis.Shorthand.Toggle
Talis.Shorthand.Separator = Talis.Shorthand.Divider

--[[ SEARCH ]]

local function addSearch(window)
	function window:Search()
		if self.SearchBox then return self.SearchBox end
		local box = New("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = -1,
			Parent = self.Rail,
		})
		Theme(box, "Raised", "BackgroundColor3")
		Corner(box, 5)
		Stroke(box, "Stroke", 1, 0.7)
		local input = New("TextBox", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search",
			TextSize = 12,
			FontFace = Talis.Fonts.Regular,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = box,
		})
		Theme(input, "Text", "TextColor3")
		Theme(input, "Faint", "PlaceholderColor3")

		Connect(input:GetPropertyChangedSignal("Text"), function()
			local query = input.Text:lower()
			for index = 1, #self.Tabs do
				local tab = self.Tabs[index]
				local anyVisible = false
				for sectionIndex = 1, #tab.Sections do
					local section = tab.Sections[sectionIndex]
					local sectionVisible = false
					for optionIndex = 1, #section.Options do
						local info = section.Options[optionIndex]
						local match = query == ""
							or (info.label ~= nil and info.label.Text:lower():find(query, 1, true) ~= nil)
						info.row.Visible = match
						if match then sectionVisible = true end
					end
					section.Group.Visible = query == "" or sectionVisible
					if query == "" or sectionVisible then anyVisible = true end
				end
				local button = self.TabButtons[tab]
				if button then button.Visible = anyVisible or query == "" end
			end
		end)

		self.SearchBox = box
		return box
	end
end

--[[ CONFIGS ]]

local function cleanName(name)
	local cleaned = tostring(name or ""):gsub("[^%w _%-]", "")
	cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")
	if cleaned == "" then return nil end
	return cleaned
end

local function configFolder()
	return path(Talis.Root, "configs")
end

local function configPath(name)
	return path(configFolder(), name .. ".json")
end

local function autoloadPath()
	return path(Talis.Root, "autoload.json")
end

local function ensureFolders()
	if not FS.ok then return false end
	pcall(function()
		if not isfolder(Talis.Root) then makefolder(Talis.Root) end
		if not isfolder(configFolder()) then makefolder(configFolder()) end
	end)
	return true
end

function Talis:GetConfigs()
	if not ensureFolders() then return {} end
	local out = {}
	local ok = pcall(function()
		for _, file in next, listfiles(configFolder()) do
			local name = tostring(file):match("[^/\\]+$")
			if name and name:sub(-5) == ".json" then
				out[#out + 1] = name:sub(1, -6)
			end
		end
	end)
	if not ok then return {} end
	table.sort(out)
	return out
end

function Talis:SaveConfig(name)
	name = cleanName(name)
	if not ensureFolders() or not name then return false end
	local window = self.ActiveWindow
	local data = { Version = self.Version, Flags = {} }
	for flag, option in next, self.Options do
		if option.Flag == flag and option.Window == window and not option.IgnoreFlag
			and flag:sub(1, 7) ~= "config/" and flag:sub(1, 3) ~= "ui/" then
			local value = self.Flags[flag]
			if value ~= nil then data.Flags[flag] = value end
		end
	end
	local ok = pcall(function()
		writefile(configPath(name), HttpService:JSONEncode(data))
	end)
	return ok
end

function Talis:LoadConfig(name)
	name = cleanName(name)
	if not ensureFolders() or not name then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(configPath(name)))
	end)
	if not ok or type(data) ~= "table" or type(data.Flags) ~= "table" then return false end
	local window = self.ActiveWindow
	for flag, value in next, data.Flags do
		local option = self.Options[flag]
		if option and option.Window == window and not option.IgnoreFlag then
			if option.Set then
				-- Not silent: loading a config must also run the callbacks so the script reacts.
				pcall(option.Set, option, value)
			else
				self:SetFlag(flag, value)
			end
		end
	end
	return true
end

function Talis:DeleteConfig(name)
	name = cleanName(name)
	if not ensureFolders() or not name then return end
	pcall(function() delfile(configPath(name)) end)
	if self:GetAutoload() == name then self:ClearAutoload() end
end

function Talis:GetAutoload()
	if not ensureFolders() then return nil end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(autoloadPath()))
	end)
	if not ok or type(data) ~= "table" then return nil end
	return data[tostring(game.GameId)]
end

function Talis:SetAutoload(name)
	name = cleanName(name)
	if not ensureFolders() or not name then return false end
	local data = {}
	pcall(function()
		local parsed = HttpService:JSONDecode(readfile(autoloadPath()))
		if type(parsed) == "table" then data = parsed end
	end)
	data[tostring(game.GameId)] = name
	local ok = pcall(function()
		writefile(autoloadPath(), HttpService:JSONEncode(data))
	end)
	return ok
end

function Talis:ClearAutoload()
	if not ensureFolders() then return end
	local data = {}
	pcall(function()
		local parsed = HttpService:JSONDecode(readfile(autoloadPath()))
		if type(parsed) == "table" then data = parsed end
	end)
	data[tostring(game.GameId)] = nil
	pcall(function()
		writefile(autoloadPath(), HttpService:JSONEncode(data))
	end)
end

function Talis:ApplyAutoload()
	local name = self:GetAutoload()
	if name and table.find(self:GetConfigs(), name) then
		return self:LoadConfig(name)
	end
	return false
end

--[[ UI SETTINGS PERSISTENCE (separate from script configs) ]]
-- Only settings the user changed on the Settings page are written to ui.json,
-- so values from your window config still apply for everything else.

function Talis:SaveUISettings()
	if not FS.ok then return end
	local data = {}
	for key in next, self.UISet do
		data[key] = self.UISettings[key]
	end
	pcall(function()
		if not isfolder(self.Root) then makefolder(self.Root) end
		writefile(path(self.Root, "ui.json"), HttpService:JSONEncode(data))
	end)
end

function Talis:QueueSave()
	if self.SavePending then return end
	self.SavePending = true
	task.delay(0.6, function()
		self.SavePending = false
		self:SaveUISettings()
	end)
end

function Talis:SetUI(key, value)
	self.UISettings[key] = value
	self.UISet[key] = true
	self:QueueSave()
end

function Talis:LoadUISettings()
	if not FS.ok then return end
	pcall(function()
		local file = path(self.Root, "ui.json")
		if not isfile(file) then return end
		local data = HttpService:JSONDecode(readfile(file))
		if type(data) ~= "table" then return end
		for key, value in next, data do
			local default = self.UISettings[key]
			if default ~= nil then
				local kind = type(default)
				if type(value) == kind then
					self.UISettings[key] = value
					self.UISet[key] = true
					self.UIFromFile = true
				elseif key == "Accent" and (type(value) == "string" or value == false) then
					self.UISettings[key] = value
					self.UISet[key] = true
					self.UIFromFile = true
				end
			end
		end
	end)
end

function Talis:ApplyLook()
	local ui = self.UISettings
	local theme = self.Themes[ui.Theme] or self.Themes.Huohuo
	local base = {}
	for key, value in next, theme do base[key] = value end
	if type(ui.Accent) == "string" and ui.Accent ~= "" then
		local ok, color = pcall(Color3.fromHex, ui.Accent)
		if ok and color then base.Accent = color end
	end
	self:ApplyTheme(base)
end

local function configSection(window, tab)
	local section = tab:Section({ Name = "Configs" })
	local status = Text(section.Group, "no configs", 11, Talis.Fonts.Regular, "Faint")
	status.Size = UDim2.new(1, 0, 0, 14)
	status.LayoutOrder = section:Next()
	local picker

	local function refresh(select)
		local list = Talis:GetConfigs()
		if picker then
			local current = select or picker:Get()
			picker:Refresh(list)
			if current and table.find(list, current) then
				picker:Set(current, true)
			else
				picker:Set(nil, true)
			end
		end
		status.Text = #list == 0 and "no configs saved" or (#list .. " saved")
		local active = Talis:GetAutoload()
		status.TextColor3 = active and Talis.Theme.Accent or Talis.Theme.Faint
	end

	local nameInput = section:Input({ Name = "Name", Value = "default", Flag = "config/name", IgnoreFlag = true })

	section:Button({
		Name = "Save",
		Primary = true,
		Callback = function()
			local name = cleanName(nameInput:Get())
			if not name then
				window:Notify({ Title = "Configs", Content = "Enter a name first.", Color = "Ember" })
				return
			end
			if Talis:SaveConfig(name) then
				window:Notify({ Title = "Configs", Content = "Saved " .. name })
			else
				window:Notify({ Title = "Configs", Content = "Save failed.", Color = "Danger" })
			end
			refresh(name)
		end,
	})

	picker = section:Dropdown({ Name = "Saved", Values = Talis:GetConfigs(), Flag = "config/picker", IgnoreFlag = true })

	section:Button({
		Name = "Load",
		Callback = function()
			local name = picker:Get()
			if not name then return end
			if Talis:LoadConfig(name) then
				window:Notify({ Title = "Configs", Content = "Loaded " .. name })
			else
				window:Notify({ Title = "Configs", Content = "Load failed.", Color = "Danger" })
			end
		end,
	})

	section:Button({
		Name = "Delete",
		Callback = function()
			local name = picker:Get()
			if not name then return end
			Talis:DeleteConfig(name)
			refresh()
		end,
	})

	section:Divider({ Text = "Autoload" })

	section:Button({
		Name = "Autoload selected",
		Callback = function()
			local name = picker:Get()
			if not name then
				window:Notify({ Title = "Configs", Content = "Select a config first.", Color = "Ember" })
				return
			end
			Talis:SetAutoload(name)
			refresh()
		end,
	})

	section:Button({
		Name = "Clear autoload",
		Callback = function()
			Talis:ClearAutoload()
			refresh()
		end,
	})

	section:Button({ Name = "Refresh", Callback = function() refresh() end })
	refresh()

	if not FS.ok then
		section:Label({ Text = "No filesystem on this executor, configs are unavailable.", Color = "Ember" })
	end

	return section
end

--[[ BUILT-IN SETTINGS PAGE ]]

function Talis:BuildSettings(window)
	if window.SettingsTab then return window.SettingsTab end
	local ui = self.UISettings
	-- Order = 9999 keeps Settings at the bottom of the rail and never the default tab.
	local tab = window:Tab({ Name = "Settings", Order = 9999 })
	window.SettingsTab = tab

	-- Appearance
	local look = tab:Section({ Name = "Appearance" })

	local themeNames = {}
	for name in next, Talis.Themes do themeNames[#themeNames + 1] = name end
	table.sort(themeNames)

	local accentPicker

	look:Dropdown({
		Name = "Theme",
		Flag = "ui/theme",
		Values = themeNames,
		Value = ui.Theme,
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("Theme", value)
			-- A theme change resets the accent to that theme's own accent.
			Talis:SetUI("Accent", false)
			window:ApplyLook()
			if accentPicker then accentPicker:Set(Talis.Theme.Accent, true) end
		end,
	})

	accentPicker = look:Colorpicker({
		Name = "Accent",
		Flag = "ui/accent",
		Value = Talis.Theme.Accent,
		IgnoreFlag = true,
		Callback = function(_, color)
			Talis:SetUI("Accent", color:ToHex())
			window:ApplyLook()
		end,
	})

	look:Slider({
		Name = "UI Scale",
		Flag = "ui/scale",
		Min = 50, Max = 150, Step = 5, Unit = "%",
		Value = math.floor((ui.Scale or 1) * 100 + 0.5),
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("Scale", value / 100)
			window:SetScale(value / 100)
		end,
	})

	look:Slider({
		Name = "Row Spacing",
		Flag = "ui/spacing",
		Desc = "Gap between every row",
		Min = 0, Max = 20, Step = 1, Unit = "px",
		Value = ui.Spacing,
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("Spacing", value)
			window:SetSpacing(value)
		end,
	})

	look:Toggle({
		Name = "Animations",
		Flag = "ui/animations",
		Value = ui.Animations,
		IgnoreFlag = true,
		Callback = function(value)
			Talis.Animations = value
			Talis:SetUI("Animations", value)
		end,
	})

	-- Background
	local bg = tab:Section({ Name = "Background" })

	local urlInput = bg:Input({
		Name = "Image Link",
		Flag = "ui/background",
		Value = ui.Background,
		Placeholder = "https://files.catbox.moe/x.png",
		IgnoreFlag = true,
	})

	local function backgroundSpec()
		return {
			Image = ui.Background,
			Transparency = 1 - (ui.BackgroundOpacity or 0.85),
			Scrim = 1 - (ui.Scrim or 0.55),
		}
	end

	bg:Button({
		Name = "Apply Background",
		Primary = true,
		Callback = function()
			Talis:SetUI("Background", urlInput:Get())
			if ui.Background == "" then
				window:SetBackground({ Image = "" })
			else
				window:SetBackground(backgroundSpec())
			end
		end,
	})

	bg:Button({
		Name = "Clear Background",
		Callback = function()
			urlInput:Set("", true)
			Talis:SetUI("Background", "")
			window:SetBackground({ Image = "" })
		end,
	})

	bg:Slider({
		Name = "Background Opacity",
		Flag = "ui/bgopacity",
		Min = 0, Max = 100, Step = 5, Unit = "%",
		Value = math.floor((ui.BackgroundOpacity or 0.85) * 100 + 0.5),
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("BackgroundOpacity", value / 100)
			if window.Image then window.Image.ImageTransparency = 1 - ui.BackgroundOpacity end
		end,
	})

	bg:Slider({
		Name = "Darken",
		Flag = "ui/darken",
		Desc = "Keeps text readable over the image",
		Min = 0, Max = 90, Step = 5, Unit = "%",
		Value = math.floor((ui.Scrim or 0.55) * 100 + 0.5),
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("Scrim", value / 100)
			-- More darkening = less transparent overlay.
			if window.Scrim then window.Scrim.BackgroundTransparency = 1 - ui.Scrim end
		end,
	})

	-- Behavior
	local behavior = tab:Section({ Name = "Behavior" })

	behavior:Keybind({
		Name = "Toggle Menu",
		Flag = "ui/togglekey",
		Value = ui.ToggleKey,
		Mouse = false,
		IgnoreFlag = true,
		Callback = function(value, pressed)
			-- The callback also fires on every key press; only react to an actual rebind.
			if pressed then return end
			Talis:SetUI("ToggleKey", value)
			window:SetToggleKey(value)
		end,
	})

	behavior:Input({
		Name = "Watermark Text",
		Flag = "ui/watermarktext",
		Value = ui.WatermarkText,
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("WatermarkText", value)
			if ui.Watermark then window:Watermark(value) end
		end,
	})

	behavior:Toggle({
		Name = "Watermark",
		Flag = "ui/watermark",
		Value = ui.Watermark,
		IgnoreFlag = true,
		Callback = function(value)
			Talis:SetUI("Watermark", value)
			if value then
				window:Watermark(ui.WatermarkText)
			elseif window.Mark then
				window.Mark.Visible = false
			end
		end,
	})

	-- Configs (script settings) + About
	window:ConfigSection(tab)

	local about = tab:Section({ Name = "About" })
	about:Label({ Text = "Talis v" .. self.Version .. "\nUI settings save to talis/ui.json" })

	return tab
end

--[[ FINAL WINDOW WRAPPER ]]

Talis:LoadUISettings()
Talis.Animations = Talis.UISettings.Animations

local coreWindow = Talis.Window

Talis.Window = function(self, config)
	config = type(config) == "table" and config or {}
	local ui = self.UISettings

	-- Values from the window config apply unless the user changed that setting on the Settings page.
	local function pref(key, value)
		if value ~= nil and not self.UISet[key] then ui[key] = value end
	end

	if type(config.Theme) == "string" and self.Themes[config.Theme] then
		pref("Theme", config.Theme)
	elseif type(config.Theme) == "table" then
		local custom = {}
		for key, value in next, self.Themes.Huohuo do custom[key] = value end
		for key, value in next, config.Theme do custom[key] = value end
		self.Themes.Custom = custom
		pref("Theme", "Custom")
	end
	if typeof(config.Accent) == "Color3" then
		pref("Accent", config.Accent:ToHex())
	elseif type(config.Accent) == "string" then
		pref("Accent", (config.Accent:gsub("#", "")))
	end
	pref("Scale", config.Scale)
	pref("Spacing", config.Spacing)
	if typeof(config.ToggleKey) == "EnumItem" then
		pref("ToggleKey", config.ToggleKey.Name)
	elseif type(config.ToggleKey) == "string" then
		pref("ToggleKey", config.ToggleKey)
	end

	self.Animations = ui.Animations
	self:ApplyLook()

	local cfg = {}
	for key, value in next, config do cfg[key] = value end
	cfg.Theme = nil
	cfg.Accent = nil
	cfg.Scale = ui.Scale or 1
	cfg.Spacing = ui.Spacing or Talis.Spacing
	local okKey, key = pcall(function() return Enum.KeyCode[ui.ToggleKey] end)
	cfg.ToggleKey = okKey and key or Enum.KeyCode.RightShift
	cfg.Background = nil

	local window = coreWindow(self, cfg)

	function window:ApplyLook()
		Talis:ApplyLook()
		self.Theme = Talis.Theme
	end

	function window:SaveConfig(name) return Talis:SaveConfig(name) end
	function window:LoadConfig(name) return Talis:LoadConfig(name) end
	function window:DeleteConfig(name) return Talis:DeleteConfig(name) end
	function window:GetConfigs() return Talis:GetConfigs() end
	function window:SetAutoload(name) return Talis:SetAutoload(name) end
	function window:ClearAutoload() return Talis:ClearAutoload() end
	function window:ApplyAutoload() return Talis:ApplyAutoload() end
	function window:ConfigSection(tab) return configSection(self, tab) end

	addSearch(window)

	window:SetSpacing(ui.Spacing or Talis.Spacing)

	-- Background: saved setting wins, otherwise the window config. Downloaded off-thread.
	local bgConfig = type(config.Background) == "table" and config.Background or nil
	if ui.Background ~= "" then
		task.spawn(function()
			window:SetBackground({
				Image = ui.Background,
				Transparency = 1 - (ui.BackgroundOpacity or 0.85),
				Scrim = 1 - (ui.Scrim or 0.55),
			})
		end)
	elseif bgConfig and bgConfig.Image then
		task.spawn(function() window:SetBackground(bgConfig) end)
	end

	if ui.Watermark then
		window:Watermark(ui.WatermarkText)
	end

	if config.Search then
		window:Search()
	end

	if config.Settings ~= false then
		self:BuildSettings(window)
	end

	return window
end

Talis.CreateWindow = Talis.Window
Talis.new = Talis.Window

function Talis:Unload()
	local window = self.ActiveWindow
	if window and window.Destroy then window:Destroy() end
end

--[[ DRAWING OVERLAY ]]

Talis.Overlay = {
	Enabled = (type(Drawing) == "table" or type(Drawing) == "userdata") and pcall(function() return Drawing.new end),
	Objects = {},
	Connections = {},
}

function Talis.Overlay:New(class, props)
	if not self.Enabled then return nil end
	local ok, object = pcall(function() return Drawing.new(class) end)
	if not ok or not object then return nil end
	for key, value in next, props or {} do
		pcall(function() object[key] = value end)
	end
	self.Objects[#self.Objects + 1] = object
	return object
end

local function handle(object)
	if not object then return nil end
	return {
		Object = object,
		Set = function(_, props)
			for key, value in next, props or {} do
				pcall(function() object[key] = value end)
			end
		end,
		Remove = function()
			pcall(function() object:Remove() end)
		end,
	}
end

function Talis.Overlay:Circle(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 1
	props.Filled = props.Filled == true
	props.NumSides = props.NumSides or 48
	return handle(self:New("Circle", props))
end

function Talis.Overlay:Line(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 1
	return handle(self:New("Line", props))
end

function Talis.Overlay:Text(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Text
	props.Size = props.Size or 13
	props.Center = props.Center ~= false
	props.Outline = props.Outline ~= false
	props.Transparency = props.Transparency or 1
	return handle(self:New("Text", props))
end

function Talis.Overlay:Square(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 1
	props.Filled = props.Filled == true
	return handle(self:New("Square", props))
end

function Talis.Overlay:Quad(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 1
	props.Filled = props.Filled == true
	return handle(self:New("Quad", props))
end

function Talis.Overlay:Box(position, size, color, filled)
	return self:Square({
		Position = position,
		Size = size,
		Color = color or Talis.Theme.Accent,
		Filled = filled == true,
	})
end

function Talis.Overlay:Render(fn)
	local connection = RunService.RenderStepped:Connect(fn)
	self.Connections[#self.Connections + 1] = connection
	return connection
end

function Talis.Overlay:Remove(object)
	if not object then return end
	if type(object) == "table" and object.Object then object = object.Object end
	for index = #self.Objects, 1, -1 do
		if self.Objects[index] == object then
			table.remove(self.Objects, index)
		end
	end
	pcall(function() object:Remove() end)
end

function Talis.Overlay:Clear()
	for index = #self.Objects, 1, -1 do
		pcall(function() self.Objects[index]:Remove() end)
	end
	table.clear(self.Objects)
	for index = #self.Connections, 1, -1 do
		pcall(function() self.Connections[index]:Disconnect() end)
	end
	table.clear(self.Connections)
end

function Talis.Overlay:Screen()
	return viewport()
end

function Talis.Overlay:WorldToScreen(position)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local point, onScreen = camera:WorldToViewportPoint(position)
	if not onScreen then return nil end
	return Vector2.new(point.X, point.Y)
end

function Talis.Overlay:FOV(radius, color)
	local center = Vector2.new(viewport().X / 2, viewport().Y / 2)
	local circle = self:Circle({
		Position = center,
		Radius = radius,
		Color = color or Talis.Theme.Accent,
		Visible = true,
	})
	return circle, center
end

return Talis
