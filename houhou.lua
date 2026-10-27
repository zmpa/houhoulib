local Talis = {}
Talis.Version = "0.1.0"
Talis.Animations = true
Talis.Root = "talis"

Talis.Flags = {}
Talis.FlagListeners = {}
Talis.Options = {}
Talis.Themed = {}
Talis.Instances = {}
Talis.Connections = {}
Talis.Notifications = {}
Talis.Builders = {}
Talis.Themes = {}

local cloneref = cloneref or clonereference or function(Object) return Object end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
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
	if class == "TextLabel" or class == "TextBox" then return "TextColor3" end
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
	Talis.Instances[#Talis.Instances + 1] = inst
	return inst
end

local function Theme(object, key, prop)
	Talis.Themed[object] = { key, prop or defaultProp(object) }
	local value = Talis.Theme[key]
	if value ~= nil then object[Talis.Themed[object][2]] = value end
	return object
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
		Text = tostring(value),
		TextSize = size or 13,
		FontFace = font or Talis.Fonts.Regular,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
	Theme(label, key or "Text", "TextColor3")
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

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function Talis:ApplyTheme(name)
	local theme = type(name) == "table" and name or self.Themes[name]
	if not theme then return end
	self.Theme = theme
	if self.ActiveWindow then self.ActiveWindow.Theme = theme end
	for object, info in next, self.Themed do
		if object.Parent == nil and object.ClassName ~= "ScreenGui" then
			self.Themed[object] = nil
		else
			local value = theme[info[1]]
			if value then object[info[2]] = value end
		end
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
		if self.Row then self.Row.Active = not self.Locked end
		return self.Locked
	end

	function option:Unlock()
		return self:Lock(false)
	end

	function option:Destroy()
		if info.row then info.row:Destroy() end
		Talis.Options[self.Flag] = nil
	end

	return option
end

function Talis:Notify(config)
	config = type(config) == "table" and config or { Content = tostring(config) }
	local duration = math.max(tonumber(config.Duration) or 4, 1.2)
	local layer = self.NotifLayer
	if not layer then return end

	local card = New("Frame", {
		Size = UDim2.fromOffset(268, 62),
		BackgroundColor3 = self.Theme.Raised,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = layer,
	})
	Corner(card, 6)
	Theme(card, "Raised", "BackgroundColor3")
	local stroke = Stroke(card, "Stroke", 1, 1)

	local bar = New("Frame", {
		Size = UDim2.new(0, 2, 1, -20),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme(bar, config.Color or "Accent", "BackgroundColor3")

	local title = Text(card, config.Title or "Notice", 13, self.Fonts.Semibold, "Text")
	title.Position = UDim2.new(0, 14, 0, 11)
	title.Size = UDim2.new(1, -24, 0, 15)

	local body = Text(card, config.Content or "", 12, self.Fonts.Regular, "Muted")
	body.Position = UDim2.new(0, 14, 0, 27)
	body.Size = UDim2.new(1, -24, 0, 26)
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top

	local timer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0, 6, 1, -5),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme(timer, config.Color or "Accent", "BackgroundColor3")

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
			if card.Parent then card:Destroy() end
		end)
	end)

	return card
end

function Talis:Tooltip(text, input)
	local root = self.ActiveWindow and self.ActiveWindow.Root
	if not root then return end
	if not self.Tooltip then
		self.Tooltip = New("TextLabel", {
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
		Corner(self.Tooltip, 4)
		Stroke(self.Tooltip, "Stroke", 1, 0.5)
		Theme(self.Tooltip, "Text", "TextColor3")
		Theme(self.Tooltip, "Raised", "BackgroundColor3")
	end
	self.Tooltip.Text = tostring(text)
	self.Tooltip.Size = UDim2.fromOffset(TextService:GetTextSize(tostring(text), 12, self.Fonts.Regular, Vector2.new(1e6, 1e6)).X + 16, 22)
	self.Tooltip.Visible = true
	self:MoveTooltip(input)
end

function Talis:MoveTooltip(input)
	if not self.Tooltip or not self.Tooltip.Visible then return end
	local size = viewport()
	local wth = self.Tooltip.AbsoluteSize.X
	local x = input.Position.X + 16
	local y = input.Position.Y + 20
	if x + wth + 8 > size.X then x = input.Position.X - wth - 12 end
	if y + 26 > size.Y then y = input.Position.Y - 28 end
	self.Tooltip.Position = UDim2.fromOffset(x, y)
end

function Talis:HeTooltip()
	if self.Tooltip then self.Tooltip.Visible = false end
end

local function parentGui(gui)
	if RunService:IsStudio() then
		gui.Parent = LP:WaitForChild("PlayerGui")
		return
	end
	if type(gethui) == "function" then
		if pcall(function() gui.Parent = gethui() end) and gui.Parent then return end
	end
	if type(get_hden_gui) == "function" then
		if pcall(function() gui.Parent = get_hden_gui() end) and gui.Parent then return end
	end
	local ok = pcall(function() gui.Parent = cloneref(game:GetService("CoreGui")) end)
	if not ok or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end
end

function Talis:Window(config)
	config = type(config) == "table" and config or {}

	local theme = config.Theme
	if type(theme) == "string" then self:ApplyTheme(theme) end
	if config.Accent then
		local base = {}
		for key, value in next, self.Theme do base[key] = value end
		base.Accent = config.Accent
		self:ApplyTheme(base)
	end

	local radius = config.Radius == nil and 8 or config.Radius
	local background = config.Background or {}
	local window = {
		Tabs = {},
		TabButtons = {},
		Open = false,
		Minimized = false,
		Title = config.Title or "Talis",
		Subtitle = config.Subtitle or ("v" .. self.Version),
		ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
		Size = config.Size or UDim2.fromOffset(680, 440),
		CloseBehavior = config.CloseBehavior or "he",
		Fonts = self.Fonts,
		Theme = self.Theme,
	}

	local gui = New("ScreenGui", {
		Name = "Talis",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	parentGui(gui)
	window.Gui = gui

	window.Root = New("Frame", {
		Name = "Root",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local scale = New("UIScale", { Scale = config.Scale or 1, Parent = window.Root })
	window.Scale = scale

	local shell = New("Frame", {
		Name = "Shell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.new(0.5, 0, 0.5, 0),
		Size = window.Size,
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = background.Image and 0.42 or 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = window.Root,
	})
	Corner(shell, radius)
	local shellStroke = Stroke(shell, "Stroke", 1, 0.55)
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
		Image = background.Image or "",
		ImageTransparency = background.Transparency or 0.15,
		ScaleType = background.ScaleType or Enum.ScaleType.Crop,
		Visible = background.Image ~= nil,
		Parent = backdrop,
	})
	window.Image = image

	local scrim = New("Frame", {
		Name = "Scrim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Scrim,
		BackgroundTransparency = background.Scrim or 0.45,
		BorderSizePixel = 0,
		Visible = background.Image ~= nil,
		Parent = backdrop,
	})
	Theme(scrim, "Scrim", "BackgroundColor3")
	window.Scrim = scrim

	local fade = New("Frame", {
		Name = "Fade",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = background.Image ~= nil,
		Parent = backdrop,
	})
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.55, 0.5),
			NumberSequenceKeypoint.new(1, 0.85),
		}),
		Color = ColorSequence.new(self.Theme.Scrim),
		Parent = fade,
	})

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

	local subtitle = Text(header, window.Subtitle, 11, self.Fonts.Regular, "Faint", Enum.TextXAlignment.Right)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.Size = UDim2.new(1, -74, 1, 0)

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
			button.TextColor3 = self.Theme.Text
		end)
		Connect(button.MouseLeave, function()
			Tween(button, 0.12, { BackgroundTransparency = 1 })
			button.TextColor3 = self.Theme.Muted
		end)
		return button
	end

	local minButton = headerButton(self.Glyphs.min, -40)
	local closeButton = headerButton(self.Glyphs.close, -14)

	local rail = New("Frame", {
		Name = "Rail",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 152, 1, -40),
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
		Position = UDim2.new(0, 152, 0, 40),
		Size = UDim2.new(1, -152, 1, -40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})
	window.Body = body

	local edge = Hairline(shell, "Hairline", 0.5)
	edge.Position = UDim2.new(0, 0, 0, 40)

	window.PopupLayer = New("Frame", {
		Name = "Popups",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = shell,
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

	local function setOpen(state)
		if window.Destroyed then return end
		state = state == true
		if opened == state then return end
		opened = state
		window.Open = state
		if state then
			shell.Visible = true
			shell.Size = UDim2.fromOffset(0, 0)
			Tween(shell, 0.22, { Size = window.Size }, Enum.EasingStyle.Quint)
		else
			Tween(shell, 0.16, { Size = UDim2.fromOffset(0, 0) })
			task.delay(0.18, function()
				if not opened then shell.Visible = false end
			end)
		end
	end
	window.SetOpen = setOpen

	local dragging, dragStart, dragOrigin
	Connect(header.InputBegan, function(input)
		if not isPress(input) then return end
		dragging = true
		dragStart = input.Position
		dragOrigin = shell.Position
	end)
	Connect(UIS.InputChanged, function(input)
		if not dragging or not isMove(input) then return end
		local delta = input.Position - dragStart
		local size = viewport()
		local x = math.clamp(dragOrigin.X.Offset + delta.X, -(shell.AbsoluteSize.X - 80), size.X - 80)
		local y = math.clamp(dragOrigin.Y.Offset + delta.Y, 0, size.Y - 44)
		shell.Position = UDim2.new(0.5, x, 0.5, y)
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	local resizing, resizeStart, resizeOrigin
	Connect(grip.InputBegan, function(input)
		if not isPress(input) then return end
		resizing = true
		resizeStart = input.Position
		resizeOrigin = shell.AbsoluteSize
	end)
	Connect(UIS.InputChanged, function(input)
		if not resizing or not isMove(input) then return end
		local delta = input.Position - resizeStart
		local width = math.max(420, resizeOrigin.X + delta.X)
		local height = math.max(280, resizeOrigin.Y + delta.Y)
		shell.Size = UDim2.fromOffset(width, height)
		window.Size = shell.Size
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
	end)

	function window:SetBackground(spec)
		spec = type(spec) == "table" and spec or { Image = spec }
		image.Image = spec.Image or ""
		image.ImageTransparency = spec.Transparency or 0.15
		image.ScaleType = spec.ScaleType or Enum.ScaleType.Crop
		scrim.BackgroundTransparency = spec.Scrim or 0.45
		local has = spec.Image ~= nil and spec.Image ~= ""
		image.Visible = has
		scrim.Visible = has
		fade.Visible = has
		shell.BackgroundTransparency = has and 0.42 or 0.05
	end

	function window:SetScale(value)
		scale.Scale = value
	end

	function window:SetToggleKey(key)
		self.ToggleKey = key
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
		if self.Current then
			self.Current.Page.Visible = false
			local previous = self.TabButtons[self.Current]
			if previous then
				Tween(previous.Pill, 0.14, { BackgroundTransparency = 1 })
				Tween(previous.Mark, 0.14, { BackgroundTransparency = 1 })
				previous.Label.TextColor3 = self.Theme.Muted
			end
		end
		self.Current = tab
		local button = self.TabButtons[tab]
		if button then
			Tween(button.Pill, 0.14, { BackgroundTransparency = 0.72 })
			Tween(button.Mark, 0.14, { BackgroundTransparency = 0 })
			button.Label.TextColor3 = self.Theme.Text
		end
		tab.Page.Visible = true
	end

	function window:Tab(spec)
		spec = type(spec) == "table" and spec or { Name = tostring(spec) }
		local tab = { Name = spec.Name or "Tab", Window = self, Sections = {} }

		local button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = #self.Tabs + 1,
			Parent = rail,
		})
		local pill = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = self.Theme.Raised,
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
			BackgroundColor3 = self.Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		})
		Corner(mark, 1)
		Theme(mark, "Accent", "BackgroundColor3")
		local label = Text(button, tab.Name, 13, self.Fonts.Regular, "Muted")
		label.Position = UDim2.new(0, 14, 0, 0)
		label.Size = UDim2.new(1, -22, 1, 0)

		button.Pill = pill
		button.Mark = mark
		button.Label = label
		tab.Button = button

		local page = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = self.Theme.Faint,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = body,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
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
			sectionSpec = type(sectionSpec) == "table" and sectionSpec or { Name = tostring(sectionSpec) }
			local section = { Name = sectionSpec.Name or "", Tab = tab, Window = self, Options = {}, Order = 0 }

			local group = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = #page:GetChildren(),
				Parent = page,
			})
			New("UIListLayout", {
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = group,
			})
			section.Group = group

			if section.Name ~= "" then
				local head = New("Frame", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Parent = group,
				})
				local headText = Text(head, string.upper(section.Name), 10, self.Fonts.Semibold, "Faint")
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
					local label = self.Head:FindFirstChildOfClass("TextLabel")
					if label then label.Text = string.upper(self.Name) end
				end
			end

			function section:Row(height, name, desc)
				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, height or 30),
					BackgroundTransparency = 1,
					LayoutOrder = self:Next(),
					Parent = group,
				})
				local info = { row = row, section = self }
				if name then
					local label = Text(row, name, 13, self.Window.Fonts.Regular, "Text")
					label.Size = UDim2.new(1, -120, 0, desc and 15 or 30)
					label.Position = UDim2.new(0, 0, 0, 0)
					label.TextYAlignment = desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
					info.label = label
					if desc then
						local sub = Text(row, desc, 11, self.Window.Fonts.Regular, "Faint")
						sub.Size = UDim2.new(1, -120, 0, 14)
						sub.Position = UDim2.new(0, 0, 0, 16)
						sub.TextYAlignment = Enum.TextYAlignment.Top
						info.desc = sub
					end
				end
				section.Options[#section.Options + 1] = info
				return row, info
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

			for name, builder in next, Talis.Builders do
				section[name] = function(self, spec, ...)
					return builder(self, spec, ...)
				end
			end

			tab.Sections[#tab.Sections + 1] = section
			return section
		end

		self.Tabs[#self.Tabs + 1] = tab
		self.TabButtons[tab] = button
		if #self.Tabs == 1 then self:SelectTab(tab) end
		return tab
	end

	function window:Notify(config)
		return Talis:Notify(config)
	end

	function window:SetTheme(name)
		Talis:ApplyTheme(name)
	end

	function window:Watermark(text)
		if self.Mark then
			self.Mark.Text = tostring(text)
			return self.Mark
		end
		local mark = New("TextLabel", {
			Position = UDim2.new(0, 14, 0, 14),
			Size = UDim2.fromOffset(TextService:GetTextSize(tostring(text), 12, self.Fonts.Semibold, Vector2.new(1e6, 1e6)).X + 22, 22),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Text = "  " .. tostring(text),
			TextSize = 12,
			FontFace = self.Fonts.Semibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 70,
			Parent = self.Root,
		})
		Corner(mark, 4)
		Stroke(mark, "Accent", 1, 0.7)
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
		for index = 1, #Talis.Instances do
			pcall(function() Talis.Instances[index]:Destroy() end)
		end
		table.clear(Talis.Instances)
		table.clear(Talis.Themed)
		table.clear(Talis.Options)
		table.clear(Talis.Rainbows)
		Talis.Tooltip = nil
		self.ActivePopup = nil
		if Talis.ActiveWindow == self then
			Talis.ActiveWindow = nil
			Talis.NotifLayer = nil
		end
		if gui then pcall(function() gui:Destroy() end) end
	end

	if config.ToggleButton then
		local toggle = New("TextButton", {
			Position = UDim2.new(0, 14, 1, -46),
			Size = UDim2.fromOffset(96, 30),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Text = "talis",
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
		if processed then return end
		if input.KeyCode == window.ToggleKey then
			setOpen(not opened)
		elseif input.KeyCode == Enum.KeyCode.Escape and opened then
			setOpen(false)
		end
	end)

	shell.Visible = false
	Talis.ActiveWindow = window
	if config.Open ~= false then
		opened = true
		window.Open = true
		shell.Visible = true
		shell.Size = UDim2.fromOffset(0, 0)
		Tween(shell, 0.22, { Size = window.Size }, Enum.EasingStyle.Quint)
	end

	return window
end

Talis.Builders.Toggle = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc)

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
		BackgroundColor3 = Talis.Theme.Text,
		BorderSizePixel = 0,
		Parent = track,
	})
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

	Connect(row.InputBegan, function(input)
		if not isPress(input) or option.Locked then return end
		option:Set(not option.Value)
	end)

	option:Set(option.Value, true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Button = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local button = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = spec.Primary and 0 or 0.35,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(button, 5)
	local stroke = Stroke(button, spec.Primary and "Accent" or "Stroke", 1, spec.Primary and 0.1 or 0.6)
	Theme(button, spec.Primary and "Accent" or "Raised", "BackgroundColor3")
	local label = Text(button, spec.Name, 12, Talis.Fonts.Semibold, spec.Primary and "AccentText" or "Text", Enum.TextXAlignment.Center)
	label.Size = UDim2.new(1, 0, 1, 0)

	local option = { Type = "Button", Name = spec.Name, section = section, Callback = spec.Callback or function() end, Row = row, Window = section.Window }

	Connect(button.MouseEnter, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0.12 or 0.15 })
	end)
	Connect(button.MouseLeave, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0 or 0.35 })
	end)
	Connect(button.MouseButton1Click, function()
		if option.Locked then return end
		Talis:SetFlag(option.Name, os.clock())
		option.Callback()
	end)

	function option:SetTitle(value)
		label.Text = tostring(value)
		self.Name = tostring(value)
	end

	function option:Lock(state)
		self.Locked = state ~= false
		label.TextTransparency = self.Locked and 0.42 or 0
		button.Active = not self.Locked
		return self.Locked
	end

	function option:Unlock()
		return self:Lock(false)
	end

	function option:Destroy()
		row:Destroy()
	end

	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Label = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec) }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local label = Text(row, spec.Text or "", spec.Size or 12, Talis.Fonts.Regular, spec.Color or "Muted")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextWrapped = true
	label.RichText = spec.Rich ~= false
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
end

Talis.Builders.Header = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec) }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	local title = Text(row, spec.Text or "", 15, Talis.Fonts.Bold, "Text")
	title.Size = UDim2.new(1, 0, 0, 20)
	title.LayoutOrder = 1
	if spec.Desc then
		local desc = Text(row, spec.Desc, 11, Talis.Fonts.Regular, "Faint")
		desc.Size = UDim2.new(1, 0, 0, 14)
		desc.LayoutOrder = 2
	end
	return row
end

Talis.Builders.Divider = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec or "") }
	local hasText = spec.Text ~= nil and spec.Text ~= ""
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, hasText and 20 or 10),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local line = Hairline(row, "Hairline", 0.5)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	if hasText then
		local upper = string.upper(tostring(spec.Text))
		local label = Text(row, " " .. upper .. " ", 10, Talis.Fonts.Semibold, "Faint")
		label.Size = UDim2.fromOffset(TextService:GetTextSize(upper, 10, Talis.Fonts.Semibold, Vector2.new(1e6, 1e6)).X + 12, 20)
		label.Position = UDim2.new(0.5, 0, 0, 0)
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.BackgroundColor3 = Talis.Theme.Surface
		label.BackgroundTransparency = 0
		label.TextXAlignment = Enum.TextXAlignment.Center
	end
	return row
end

Talis.Builders.Space = function(section, size)
	return New("Frame", {
		Size = UDim2.new(1, 0, 0, size or 6),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
end

Talis.Rainbows = {}
Talis.RainbowHue = 0

Connect(RunService.RenderStepped, function()
	if #Talis.Rainbows == 0 then return end
	Talis.RainbowHue = (os.clock() * 0.06) % 1
	for index = 1, #Talis.Rainbows do
		local picker = Talis.Rainbows[index]
		if picker.Apply then picker.Apply() end
	end
end)

local function decimals(step)
	if step >= 1 then return 0 end
	return math.clamp(math.ceil(-math.log10(step)), 0, 6)
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

local function Popup(window, anchor, width, height)
	if window.ActivePopup then window.ActivePopup:Close() end
	local host = window.PopupHost

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
	local holderStroke = Stroke(holder, "Stroke", 1, 0.3)
	Theme(holder, "Raised", "BackgroundColor3")

	local popup = { Holder = holder, Anchor = anchor, Window = window }

	local function place()
		local anchorPosition = anchor.AbsolutePosition
		local anchorSize = anchor.AbsoluteSize
		local size = viewport()
		local x = anchorPosition.X
		local y = anchorPosition.Y + anchorSize.Y + 6
		if y + height + 10 > size.Y then y = anchorPosition.Y - height - 6 end
		x = math.clamp(x, 8, math.max(8, size.X - width - 8))
		y = math.clamp(y, 8, math.max(8, size.Y - height - 8))
		holder.Position = UDim2.fromOffset(x, y)
	end

	local render
	render = Connect(RunService.RenderStepped, function()
		if not holder.Parent then
			pcall(function() render:Disconnect() end)
			return
		end
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
		window.ActivePopup = nil
		if render then pcall(function() render:Disconnect() end) end
		if dismiss.Parent then dismiss:Destroy() end
		if holder.Parent then holder:Destroy() end
	end

	Connect(dismiss.MouseButton1Click, function() popup:Close() end)

	Tween(holder, 0.14, { BackgroundTransparency = 0.02 })
	Tween(holderStroke, 0.14, { Transparency = 0.3 })

	window.ActivePopup = popup
	return popup
end

local originalWindow = Talis.Window

local function baseWindow(self, config)
	local window = originalWindow(self, config)

	window.PopupHost = New("Frame", {
		Name = "PopupHost",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = window.Gui,
	})

	local baseSelect = window.SelectTab
	function window:SelectTab(tab)
		if self.ActivePopup then self.ActivePopup:Close() end
		baseSelect(self, tab)
	end

	function window:Search()
		if self.SearchBox then return self.SearchBox end
		local box = New("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Talis.Theme.Raised,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = -1,
			Parent = self.Rail,
		})
		Corner(box, 5)
		Stroke(box, "Stroke", 1, 0.7)
		local input = New("TextBox", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search",
			PlaceholderColor3 = Talis.Theme.Faint,
			TextSize = 12,
			FontFace = Talis.Fonts.Regular,
			ClearTextOnFocus = false,
			Parent = box,
		})
		Theme(input, "Text", "TextColor3")

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
						local match = query == "" or (info.label and info.label.Text:lower():find(query, 1, true) ~= nil)
						info.row.Visible = match and true or false
						if match then sectionVisible = true end
					end
					section.Group.Visible = sectionVisible
					if sectionVisible then anyVisible = true end
				end
				local button = self.TabButtons[tab]
				if button then button.Visible = anyVisible or query == "" end
			end
		end)

		self.SearchBox = box
		return box
	end

	return window
end

Talis.Window = baseWindow

Talis.Builders.Slider = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local min = tonumber(spec.Min) or 0
	local max = tonumber(spec.Max) or 100
	if max <= min then max = min + 1 end
	local step = tonumber(spec.Step) or (spec.Precise and 10 ^ -spec.Precise) or 1
	if step <= 0 then step = 1 end
	local places = decimals(step)
	local unit = spec.Unit or ""
	local value = math.clamp(tonumber(spec.Value) or min, min, max)

	local row, info = section:Row(spec.Desc and 46 or 36, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.6, -8, 0, 15) end

	local valueBox = New("TextBox", {
		Size = UDim2.new(0, 52, 0, 15),
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
		BackgroundColor3 = Talis.Theme.Hairline,
		BorderSizePixel = 0,
		Parent = hit,
	})
	Corner(bar, 2)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Talis.Theme.Accent,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Corner(fill, 2)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(11, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Text,
		BorderSizePixel = 0,
		Parent = hit,
	})
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
		v = math.floor(v / self.Step + 0.5) * self.Step
		v = math.clamp(v, self.Min, self.Max)
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

	Connect(hit.InputBegan, function(input)
		if option.Locked or not isPress(input) then return end
		dragging = true
		local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		option:Set(min + alpha * (max - min))
	end)
	Connect(UIS.InputChanged, function(input)
		if not dragging or not isMove(input) then return end
		local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		option:Set(min + alpha * (max - min))
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	Connect(valueBox.Focused, function()
		valueBox.Text = format(option.Value, places)
		valueBox:CaptureFocus()
	end)
	Connect(valueBox.FocusLost, function()
		local parsed = tonumber(tostring(valueBox.Text):match("-?%d+%.?%d*"))
		option:Set(parsed or option.Value)
	end)

	Connect(row.MouseEnter, function() Tween(knob, 0.12, { BackgroundColor3 = Talis.Theme.Accent }) end)
	Connect(row.MouseLeave, function() Tween(knob, 0.12, { BackgroundColor3 = Talis.Theme.Text }) end)

	option:Set(option.Value, true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

local function buildDropdown(section, spec, multi)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local values = normalizeValues(spec.Values)
	local selected = {}

	if multi then
		for index = 1, #(spec.Value or {}) do selected[tostring(spec.Value[index])] = true end
	else
		selected[tostring(spec.Value or (values[1] and values[1].Name) or "")] = true
	end

	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.45, -8, 0, 15) end

	local pill = New("TextButton", {
		Size = UDim2.new(0, 150, 0, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Raised,
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

	local function summary()
		local out = {}
		for index = 1, #values do
			local entry = values[index]
			if selected[entry.Name] then out[#out + 1] = entry.Name end
		end
		if #out == 0 then return "None" end
		if #out <= 2 then return table.concat(out, ", ") end
		return out[1] .. " +" .. (#out - 1)
	end

	local function sync()
		local out = {}
		for index = 1, #values do
			local entry = values[index]
			if selected[entry.Name] then out[#out + 1] = entry.Name end
		end
		option.Value = multi and out or out[1]
		pillText.Text = summary()
		Talis:SetFlag(option.Flag, option.Value)
		option.Callback(option.Value)
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
		local out = {}
		for index = 1, #values do
			local entry = values[index]
			if selected[entry.Name] then out[#out + 1] = entry.Name end
		end
		option.Value = multi and out or out[1]
		pillText.Text = summary()
		Talis:SetFlag(option.Flag, option.Value)
		if not silent then option.Callback(option.Value) end
		return option.Value
	end

	function option:Get()
		return self.Value
	end

	function option:Refresh(list)
		values = normalizeValues(list)
		pillText.Text = summary()
	end

	function option:Open()
		if option.Locked then return end
		if window.ActivePopup and window.ActivePopup.Anchor == pill then
			window.ActivePopup:Close()
			return
		end
		local height = math.min(#values * 24 + 10, 168)
		local popup = Popup(window, pill, 172, height)

		local scroll = New("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Talis.Theme.Faint,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = popup.Holder,
		})
		New("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

		for index = 1, #values do
			local entry = values[index]
			local on = selected[entry.Name] == true
			local item = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = Talis.Theme.Hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = scroll,
			})
			Corner(item, 4)
			local label = Text(item, entry.Name, 12, Talis.Fonts.Regular, on and "Text" or "Muted")
			label.Position = UDim2.new(0, 8, 0, 0)
			label.Size = UDim2.new(1, -28, 1, 0)
			label.TextTruncate = Enum.TextTruncate.AtEnd
			local tick
			if on then
				tick = Text(item, Talis.Glyphs.check, 11, Talis.Fonts.Semibold, "Accent", Enum.TextXAlignment.Right)
				tick.AnchorPoint = Vector2.new(1, 0.5)
				tick.Position = UDim2.new(1, -8, 0.5, 0)
				tick.Size = UDim2.new(0, 12, 1, 0)
			end
			Connect(item.MouseEnter, function() Tween(item, 0.1, { BackgroundTransparency = 0.7 }) end)
			Connect(item.MouseLeave, function() Tween(item, 0.1, { BackgroundTransparency = 1 }) end)
			Connect(item.MouseButton1Click, function()
				if multi then
					selected[entry.Name] = not selected[entry.Name]
					if selected[entry.Name] then
						if not tick then
							tick = Text(item, Talis.Glyphs.check, 11, Talis.Fonts.Semibold, "Accent", Enum.TextXAlignment.Right)
							tick.AnchorPoint = Vector2.new(1, 0.5)
							tick.Position = UDim2.new(1, -8, 0.5, 0)
							tick.Size = UDim2.new(0, 12, 1, 0)
						end
						tick.Visible = true
					elseif tick then
						tick.Visible = false
					end
					label.TextColor3 = selected[entry.Name] and Talis.Theme.Text or Talis.Theme.Muted
					sync()
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
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	spec.Multi = true
	return buildDropdown(section, spec, true)
end

Talis.Builders.Input = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.4, -8, 0, 15) end

	local field = New("Frame", {
		Size = UDim2.new(0.6, -8, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Raised,
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
		PlaceholderColor3 = Talis.Theme.Faint,
		TextSize = 12,
		FontFace = Talis.Fonts.Regular,
		ClearTextOnFocus = false,
		Parent = field,
	})
	Theme(box, "Text", "TextColor3")

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
		option:Set(box.Text)
		if enterPressed then option.Callback(option.Value, true) end
	end)

	Talis:SetFlag(option.Flag, option.Value)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

local DEFAULT_BLACKLIST = { "W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote" }

Talis.Builders.Keybind = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.5, -8, 0, 15) end

	local mode = spec.Mode == "Hold" and "Hold" or "Toggle"
	local value = spec.Value or "NONE"
	if typeof(value) == "EnumItem" then value = value.Name end
	value = tostring(value)

	local cap = New("TextButton", {
		Size = UDim2.new(0, 74, 0, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(cap, 5)
	local capStroke = Stroke(cap, "Stroke", 1, 0.6)
	Theme(cap, "Raised", "BackgroundColor3")

	local capText = Text(cap, "", 11, Talis.Fonts.Mono, "Text", Enum.TextXAlignment.Center)
	capText.Size = UDim2.new(1, 0, 1, 0)

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
		Mouse = spec.Mouse == true,
		Blacklist = spec.Blacklist or DEFAULT_BLACKLIST,
		Listening = false,
		Pressed = false,
		Toggled = false,
	}
	Register(option)
	Decorate(option, info, window)

	local function paint()
		if option.Listening then
			capText.Text = "..."
			capText.TextColor3 = Talis.Theme.Accent
		elseif option.Value == "NONE" then
			capText.Text = "[ NONE ]"
			capText.TextColor3 = Talis.Theme.Faint
		else
			capText.Text = "[ " .. option.Value .. " ]"
			capText.TextColor3 = option.Pressed and Talis.Theme.Accent or Talis.Theme.Text
		end
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

	Connect(cap.MouseButton1Click, function()
		if option.Locked then return end
		option.Listening = not option.Listening
		if option.Listening then
			Tween(capStroke, 0.12, { Color = Talis.Theme.Accent, Transparency = 0.2 })
		else
			Tween(capStroke, 0.12, { Color = Talis.Theme.Stroke, Transparency = 0.6 })
		end
		paint()
	end)

	local function matches(input)
		if option.Mouse then
			return input.UserInputType.Name == option.Value
		end
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == option.Value
	end

	Connect(UIS.InputBegan, function(input, processed)
		if processed then return end
		if option.Listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Backspace then
					option:Set("NONE")
				elseif input.KeyCode == Enum.KeyCode.Escape then
					option.Listening = false
				elseif not table.find(option.Blacklist, input.KeyCode.Name) then
					option:Set(input.KeyCode.Name)
				else
					return
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				option:Set(input.UserInputType.Name)
			else
				return
			end
			option.Listening = false
			Tween(capStroke, 0.12, { Color = Talis.Theme.Stroke, Transparency = 0.6 })
			paint()
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

	Connect(UIS.InputEnded, function(input, processed)
		if processed or option.Mode ~= "Hold" or not option.Pressed then return end
		if not matches(input) then return end
		option.Pressed = false
		paint()
		option.Callback(option.Value, false, option.Toggled)
	end)

	paint()
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Colorpicker = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(30, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.6, -8, 0, 15) end

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
	if type(spec.Value) == "table" then
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
		Talis:SetFlag(option.Flag, { option.Value[1], option.Value[2], option.Value[3], option.Value[4], option.Value[5] })
		if option.Panel then option.Panel() end
		if not silent then option.Callback(option.Value, color) end
	end

	function option:Set(value, silent)
		if typeof(value) == "Color3" then
			local h, s, v = Color3.toHSV(value)
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
		if option.Panel then option.Panel() end
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
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
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
			BackgroundColor3 = Talis.Theme.Hover,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = holder,
		})
		Corner(hexField, 4)
		local hexBox = New("TextBox", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "HEX",
			PlaceholderColor3 = Talis.Theme.Faint,
			TextSize = 11,
			FontFace = Talis.Fonts.Mono,
			ClearTextOnFocus = false,
			Parent = hexField,
		})
		Theme(hexBox, "Text", "TextColor3")

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
			Connect(chip.MouseButton1Click, function()
				option:Set(Color3.fromHex(presets[index]))
			end)
		end

		local rainbowButton = New("TextButton", {
			Size = UDim2.new(1, -20, 0, 20),
			Position = UDim2.new(0, 10, 0, 230),
			BackgroundColor3 = Talis.Theme.Hover,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Text = "Rainbow",
			TextSize = 11,
			FontFace = Talis.Fonts.Regular,
			AutoButtonColor = false,
			Parent = holder,
		})
		Corner(rainbowButton, 4)
		Theme(rainbowButton, "Muted", "TextColor3")

		local function refresh()
			local v = option.Value
			square.BackgroundColor3 = Color3.fromHSV(v[1], 1, 1)
			cursor.Position = UDim2.new(v[2], 0, 1 - v[3], 0)
			huePin.Position = UDim2.new(1 - v[1], 0, 0.5, 0)
			alphaPin.Position = UDim2.new(v[4], 0, 0.5, 0)
			alphaGrad.BackgroundColor3 = toColor()
			hexBox.Text = "#" .. toColor():ToHex()
			rainbowButton.TextColor3 = v[5] and Talis.Theme.Accent or Talis.Theme.Muted
		end

		option.Panel = refresh

		local editing

		Connect(square.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "sv"
		end)
		Connect(hueBar.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "hue"
		end)
		Connect(alphaBar.InputBegan, function(input)
			if not isPress(input) then return end
			editing = "alpha"
		end)
		Connect(UIS.InputChanged, function(input)
			if not editing or not isMove(input) then return end
			if editing == "sv" then
				option.Value[2] = math.clamp((input.Position.X - square.AbsolutePosition.X) / math.max(square.AbsoluteSize.X, 1), 0, 1)
				option.Value[3] = 1 - math.clamp((input.Position.Y - square.AbsolutePosition.Y) / math.max(square.AbsoluteSize.Y, 1), 0, 1)
			elseif editing == "hue" then
				option.Value[1] = 1 - math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
			else
				option.Value[4] = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / math.max(alphaBar.AbsoluteSize.X, 1), 0, 1)
			end
			push()
			refresh()
		end)
		Connect(UIS.InputEnded, function(input)
			if isPress(input) then editing = nil end
		end)

		Connect(hexBox.FocusLost, function()
			local hex = hexBox.Text:gsub("#", ""):gsub("%s", "")
			if #hex == 6 and tonumber(hex, 16) then
				option:Set(Color3.fromHex(hex))
			else
				refresh()
			end
		end)

		Connect(rainbowButton.MouseButton1Click, function()
			option.Value[5] = not option.Value[5]
			if option.Value[5] then
				if not table.find(Talis.Rainbows, option) then table.insert(Talis.Rainbows, option) end
			else
				local index = table.find(Talis.Rainbows, option)
				if index then table.remove(Talis.Rainbows, index) end
			end
			refresh()
		end)

		refresh()

		local baseClose = popup.Close
		function popup:Close()
			option.Panel = nil
			baseClose(self)
		end
	end)

	if option.Value[5] then table.insert(Talis.Rainbows, option) end
	push(true)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Progress = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local row, info = section:Row(38, spec.Name, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.75, -8, 0, 15) end

	local percent = Text(row, "0%", 11, Talis.Fonts.Mono, "Muted", Enum.TextXAlignment.Right)
	percent.AnchorPoint = Vector2.new(1, 0)
	percent.Position = UDim2.new(1, 0, 0, 0)
	percent.Size = UDim2.new(0, 40, 0, 15)

	local bar = New("Frame", {
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Talis.Theme.Hairline,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(bar, 2)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Talis.Theme.Accent,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Corner(fill, 2)

	local option = { Type = "Progress", Name = spec.Name, section = section, Value = 0, Row = row, Window = section.Window }

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

	return option
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
	if not ensureFolders() or not name or name == "" then return false end
	local window = self.ActiveWindow
	local data = { Version = self.Version, Flags = {} }
	for flag, option in next, self.Options do
		if option.Flag == flag and option.Window == window and not option.IgnoreFlag and flag:sub(1, 7) ~= "config/" then
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
	if not ensureFolders() or not name or name == "" then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(configPath(name)))
	end)
	if not ok or type(data) ~= "table" or type(data.Flags) ~= "table" then return false end
	local window = self.ActiveWindow
	for flag, value in next, data.Flags do
		local option = self.Options[flag]
		if option and option.Window == window then
			if option.Set then
				pcall(option.Set, option, value, true)
			else
				self:SetFlag(flag, value)
			end
		end
	end
	return true
end

function Talis:DeleteConfig(name)
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
	if not ensureFolders() then return false end
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

local function configSection(window, tab)
	local section = tab:Section({ Name = "Configs" })
	local status = Text(section.Group, "no configs", 11, Talis.Fonts.Regular, "Faint")
	status.LayoutOrder = section:Next()
	local picker

	local function refresh()
		local list = Talis:GetConfigs()
		if picker then
			picker:Refresh(list)
			picker:Set(nil, true)
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
			local name = nameInput:Get()
			if name == "" then
				window:Notify({ Title = "Configs", Content = "Enter a name first.", Color = "Ember" })
				return
			end
			if Talis:SaveConfig(name) then
				window:Notify({ Title = "Configs", Content = "Saved " .. name })
			else
				window:Notify({ Title = "Configs", Content = "Save failed.", Color = "Danger" })
			end
			refresh()
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

	section:Button({ Name = "Refresh", Callback = refresh })
	refresh()

	if not FS.ok then
		section:Label({ Text = "No filesystem on this executor, configs are unavailable.", Color = "Ember" })
	end

	return section
end

local baseWindow2 = Talis.Window

Talis.Window = function(self, config)
	local window = baseWindow2(self, config)
	Talis.ActiveWindow = window

	function window:SaveConfig(name)
		return Talis:SaveConfig(name)
	end

	function window:LoadConfig(name)
		return Talis:LoadConfig(name)
	end

	function window:DeleteConfig(name)
		return Talis:DeleteConfig(name)
	end

	function window:GetConfigs()
		return Talis:GetConfigs()
	end

	function window:SetAutoload(name)
		return Talis:SetAutoload(name)
	end

	function window:ClearAutoload()
		return Talis:ClearAutoload()
	end

	function window:ApplyAutoload()
		return Talis:ApplyAutoload()
	end

	function window:ConfigSection(tab)
		return configSection(self, tab)
	end

	return window
end

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
	props.Transparency = props.Transparency or 0.2
	props.Filled = props.Filled == true
	props.NumSides = props.NumSides or 48
	return handle(self:New("Circle", props))
end

function Talis.Overlay:Line(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 0.2
	return handle(self:New("Line", props))
end

function Talis.Overlay:Text(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Text
	props.Size = props.Size or 13
	props.Center = props.Center ~= false
	props.Outline = props.Outline ~= false
	props.Transparency = props.Transparency or 0.1
	return handle(self:New("Text", props))
end

function Talis.Overlay:Square(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 0.2
	props.Filled = props.Filled == true
	return handle(self:New("Square", props))
end

function Talis.Overlay:Quad(props)
	props = props or {}
	props.Color = props.Color or Talis.Theme.Accent
	props.Thickness = props.Thickness or 1
	props.Transparency = props.Transparency or 0.2
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
	if object.Object then object = object.Object end
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
