--[[
	Talis UI Library
	Version: 1.0.0

	Full feature pass. New since 0.2.3:
	  * Groups, SubTabs, side-by-side Sections, Section Pages
	  * Tab icons, descriptions, order, locked
	  * Elements: Segmented, Paragraph, Info, Image, Console, PlayerList, Custom
	  * RegisterElement for your own element types
	  * Common element API: Reset/IsDefault/OnChanged/Highlight/Reveal/Move*/AddButton
	  * ShowWhen conditional rows, tabs and sections
	  * Notification handles, buttons, persist, bell menu, Dialog, Prompt
	  * Widgets, watermark parts, keystrokes, keybind list, particles, blur, dim, sounds
	  * Theme Export/Import/Bind, live colour edits, per-colour reset
	  * Config Export/Import, Config:Set/Get, ResetAll
	  * Patch/Restore, Track, Loop, OnEject, OnReset, Eject
	  * LockAll/UnlockAll, GetElement, Errors panel, KeySystem, Templates
	  * Rounder outer corners, adjustable live

	1.0.0 fixes:
	  * Server template had a stray ")" that killed the whole chunk
	  * SetFont called a RequestRebuild that did not exist
	  * Button:OnClick referenced rawCallbackSetter before it was declared
	  * Dialog passed an InputObject to IsAncestorOf
	  * KeySystem prompted when the key was already saved (inverted)
	  * sub:Section() parented into the tab page instead of the subtab page
	  * Theme_API.OnChanged listeners were never fired
]]

local Talis = {}
Talis.Version = "1.0.0"
Talis.Animations = true
Talis.Root = "talis"
Talis.Spacing = 6

Talis.Flags = {}
Talis.FlagListeners = {}
Talis.Options = {}
Talis.Elements = {}
Talis.Themed = {}
Talis.Instances = {}
Talis.Connections = {}
Talis.Notifications = {}
Talis.Builders = {}
Talis.Themes = {}
Talis.ImageCache = {}
Talis.Rainbows = {}
Talis.RainbowHue = 0
Talis.Errors = {}
Talis.Patches = {}
Talis.EjectHooks = {}
Talis.ResetHooks = {}
Talis.Loops = {}
Talis.Tracked = {}
Talis.Watchers = {}
Talis.Visibility = {}
Talis.NotificationLog = {}
Talis.ShowErrors = false
Talis.OnError = nil

Talis.UISettings = {
	Theme = "Huohuo",
	Accent = nil,
	Background = "",
	BackgroundOpacity = 0.85,
	Scrim = 0.45,
	Scale = 1,
	Spacing = 6,
	Radius = 10,
	Animations = true,
	ToggleKey = "RightShift",
	ToggleMode = "Toggle",
	Watermark = false,
	WatermarkText = "talis",
	Sounds = true,
	SoundVolume = 0.5,
	Notifications = true,
	NotifySide = "Bottom Right",
	Blur = false,
	Dim = false,
	Particles = "Off",
	Keystrokes = false,
	KeybindList = false,
	OpenOnLoad = true,
	Remember = true,
}

local cloneref = cloneref or clonereference or function(Object) return Object end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
local Lighting = cloneref(game:GetService("Lighting"))
local StarterGui = cloneref(game:GetService("StarterGui"))
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
Talis.FontFamilies = {
	Default = FAMILY,
	Mono = "rbxasset://fonts/families/RobotoMono.json",
	Gotham = FAMILY,
	BuilderSans = "rbxasset://fonts/families/BuilderSans.json",
	Montserrat = "rbxasset://fonts/families/Montserrat.json",
	Roboto = "rbxasset://fonts/families/Roboto.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
	Nunito = "rbxasset://fonts/families/Nunito.json",
	Oswald = "rbxasset://fonts/families/Oswald.json",
	SourceSansPro = "rbxasset://fonts/families/SourceSansPro.json",
	Michroma = "rbxasset://fonts/families/Michroma.json",
}

Talis.Fonts = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Medium),
	Semibold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
	Mono = Font.new(Talis.FontFamilies.Mono, Enum.FontWeight.Medium),
}

function Talis:SetFont(name)
	local family = self.FontFamilies[name]
	if not family then return end
	self.FontFamilyName = name
	self.Fonts = {
		Regular = Font.new(family, Enum.FontWeight.Medium),
		Semibold = Font.new(family, Enum.FontWeight.SemiBold),
		Bold = Font.new(family, Enum.FontWeight.Bold),
		Mono = Font.new(self.FontFamilies.Mono, Enum.FontWeight.Medium),
	}
	if self.ActiveWindow then
		self.ActiveWindow.Fonts = self.Fonts
		self:RequestRebuild()
	end
end

function Talis:RequestRebuild()
	local family = self.FontFamilies[self.FontFamilyName] or self.FontFamilies.Default
	for index = 1, #self.Instances do
		local instance = self.Instances[index]
		if instance.Parent and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
			local weight = Enum.FontWeight.Medium
			pcall(function() weight = instance.FontFace.Weight end)
			instance.FontFace = Font.new(family, weight)
		end
	end
end

Talis.Sounds = {
	click = "rbxasset://sounds/button.wav",
	toggle = "rbxasset://sounds/switch.wav",
	hover = "rbxasset://sounds/button.wav",
	slider = "rbxasset://sounds/button.wav",
	open = "rbxasset://sounds/switch3.wav",
	notify = "rbxasset://sounds/electronicpingshort.wav",
	bind = "rbxasset://sounds/switch.wav",
	error = "rbxasset://sounds/uuhhh.wav",
}

Talis.Glyphs = {
	close = "\u{2715}",
	min = "\u{2014}",
	chevron = "\u{25BE}",
	check = "\u{2713}",
	dot = "\u{2022}",
	arrow = "\u{203A}",
}

Talis.Icons = {
	close = "rbxassetid://116396312853810",
	min = "rbxassetid://95070996149109",
	chevron = "rbxassetid://71457658246709",
	check = "rbxassetid://86817768619372",
	arrow = "rbxassetid://72764732196403",
	home = "rbxassetid://107097922774777",
	user = "rbxassetid://107097944016053",
	settings = "rbxassetid://107349503080004",
	search = "rbxassetid://107097948594557",
	bell = "rbxassetid://107097900588334",
	star = "rbxassetid://107097949027096",
	trash = "rbxassetid://107097904322499",
	play = "rbxassetid://107097900588334",
	refresh = "rbxassetid://107097909140344",
	warning = "rbxassetid://107097908195158",
	info = "rbxassetid://107097908827508",
}

Talis.Themes.Huohuo = {
	Window = Color3.fromHex("0B1512"),
	Surface = Color3.fromHex("101E1A"),
	Raised = Color3.fromHex("16261F"),
	Hover = Color3.fromHex("1C3129"),
	Stroke = Color3.fromHex("244137"),
	Hairline = Color3.fromHex("1B3129"),
	Text = Color3.fromHex("E6F1EA"),
	Label = Color3.fromHex("D3E4DA"),
	Muted = Color3.fromHex("7E9A8E"),
	Faint = Color3.fromHex("4E655C"),
	Accent = Color3.fromHex("4FD6A8"),
	AccentSoft = Color3.fromHex("9BE8CB"),
	AccentText = Color3.fromHex("04120C"),
	Jade = Color3.fromHex("2FB8A8"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("E0574F"),
	Success = Color3.fromHex("4FD6A8"),
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
	Label = Color3.fromHex("CDE8E3"),
	Muted = Color3.fromHex("74A199"),
	Faint = Color3.fromHex("47706A"),
	Accent = Color3.fromHex("3FD9C4"),
	AccentSoft = Color3.fromHex("93EDE1"),
	AccentText = Color3.fromHex("031210"),
	Jade = Color3.fromHex("2FB8A8"),
	Gold = Color3.fromHex("D8C179"),
	Ember = Color3.fromHex("EF9048"),
	Danger = Color3.fromHex("E0574F"),
	Success = Color3.fromHex("3FD9C4"),
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
	Label = Color3.fromHex("E2DAC6"),
	Muted = Color3.fromHex("9C907A"),
	Faint = Color3.fromHex("6B614D"),
	Accent = Color3.fromHex("E3B96B"),
	AccentSoft = Color3.fromHex("F0D9A6"),
	AccentText = Color3.fromHex("14110A"),
	Jade = Color3.fromHex("5FBFA0"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("DE6A55"),
	Success = Color3.fromHex("5FBFA0"),
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
	Label = Color3.fromHex("22322B"),
	Muted = Color3.fromHex("6C7F77"),
	Faint = Color3.fromHex("A3B3AC"),
	Accent = Color3.fromHex("2FA37C"),
	AccentSoft = Color3.fromHex("8FD9BF"),
	AccentText = Color3.fromHex("FFFFFF"),
	Jade = Color3.fromHex("2FA37C"),
	Gold = Color3.fromHex("B98F3C"),
	Ember = Color3.fromHex("D97B29"),
	Danger = Color3.fromHex("C9524A"),
	Success = Color3.fromHex("2FA37C"),
	Scrim = Color3.fromHex("0B1512"),
	Shadow = Color3.fromHex("8FA69C"),
}

Talis.Themes.Dark = {
	Window = Color3.fromHex("0C0C0E"),
	Surface = Color3.fromHex("141416"),
	Raised = Color3.fromHex("1C1C20"),
	Hover = Color3.fromHex("26262B"),
	Stroke = Color3.fromHex("32323A"),
	Hairline = Color3.fromHex("24242A"),
	Text = Color3.fromHex("F0F0F3"),
	Label = Color3.fromHex("D8D8DE"),
	Muted = Color3.fromHex("8C8C96"),
	Faint = Color3.fromHex("5A5A64"),
	Accent = Color3.fromHex("7C8CFF"),
	AccentSoft = Color3.fromHex("AAB4FF"),
	AccentText = Color3.fromHex("0A0A14"),
	Jade = Color3.fromHex("4FD6A8"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("E0574F"),
	Success = Color3.fromHex("4FD6A8"),
	Scrim = Color3.fromHex("050507"),
	Shadow = Color3.fromHex("000000"),
}

Talis.Themes.Purple = {
	Window = Color3.fromHex("100B18"),
	Surface = Color3.fromHex("181022"),
	Raised = Color3.fromHex("21162E"),
	Hover = Color3.fromHex("2C1E3E"),
	Stroke = Color3.fromHex("3B2A52"),
	Hairline = Color3.fromHex("2A1D3A"),
	Text = Color3.fromHex("F1E9FA"),
	Label = Color3.fromHex("DCCFEE"),
	Muted = Color3.fromHex("9B87B5"),
	Faint = Color3.fromHex("6A5A80"),
	Accent = Color3.fromHex("AA6EFF"),
	AccentSoft = Color3.fromHex("C9A4FF"),
	AccentText = Color3.fromHex("0D0716"),
	Jade = Color3.fromHex("5FBFA0"),
	Gold = Color3.fromHex("E3B96B"),
	Ember = Color3.fromHex("F0923C"),
	Danger = Color3.fromHex("E0574F"),
	Success = Color3.fromHex("5FBFA0"),
	Scrim = Color3.fromHex("08050F"),
	Shadow = Color3.fromHex("000000"),
}

Talis.Theme = Talis.Themes.Huohuo
Talis.ThemeName = "Huohuo"

local DEFAULT_COLORS = {}
for key in next, Talis.Themes.Huohuo do DEFAULT_COLORS[key] = true end

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
	Theme(label, key or "Label", "TextColor3")
	return label
end

local function Icon(parent, name, size, key)
	local icon = New("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Talis.Icons[name] or "",
		Size = UDim2.fromOffset(size or 12, size or 12),
		ImageColor3 = Talis.Theme[key or "Muted"],
		Parent = parent,
	})
	Theme(icon, key or "Muted", "ImageColor3")
	return icon
end

local function isPress(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

local function isMove(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch
end

local function isMouseButton(input)
	return tostring(input.UserInputType.Name):match("^MouseButton") ~= nil
end

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function measure(text, size, font)
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = font
		params.Size = size
		params.Width = 1e6
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and bounds then return bounds end
	return Vector2.new(#text * size * 0.55, size)
end

local function clamp01(v)
	return math.clamp(tonumber(v) or 0, 0, 1)
end

function Talis:Hex(color, alpha)
	if typeof(color) == "string" then return color end
	local hex = color:ToHex()
	if alpha then
		return string.format("%s%02X", hex, math.floor(clamp01(alpha) * 255))
	end
	return hex
end

local function playSound(name)
	if not Talis.UISettings.Sounds then return end
	local id = Talis.Sounds[name]
	local host = Talis.SoundHost
	if not id or not host then return end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Talis.UISettings.SoundVolume or 0.5
	sound.Parent = host
	sound:Play()
	task.delay(3, function()
		if sound then sound:Destroy() end
	end)
end

Talis.PlaySound = playSound

--[[ ERRORS ]]

function Talis:RecordError(err)
	local entry = { t = os.clock(), msg = tostring(err) }
	self.Errors[#self.Errors + 1] = entry
	if #self.Errors > 60 then table.remove(self.Errors, 1) end
	if self.ShowErrors then
		self:Notify({ Title = "Error", Content = entry.msg, Kind = "Error", Duration = 6 })
	end
	if self.OnError then pcall(self.OnError, entry.msg) end
	return entry
end

--[[ IMAGE LOADING ]]

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
	if not (FS.ok and type(getasset) == "function") then return source end

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

--[[ THEME API ]]

function Talis:ApplyTheme(name)
	local theme = type(name) == "table" and name or self.Themes[name]
	if not theme then return end
	if type(name) == "string" then self.ThemeName = name end
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
	local active = self.ActiveWindow
	if active and active.Current then
		local meta = active.TabMeta[active.Current]
		if meta and meta.Label then meta.Label.TextColor3 = theme.Text end
	end
	for index = 1, #self.Rainbows do
		local picker = self.Rainbows[index]
		if picker.Panel then picker.Panel() end
	end
	for index = 1, #self.ThemeListeners do
		pcall(self.ThemeListeners[index], self.Theme)
	end
end

function Talis:RegisterTheme(name, colors)
	local base = {}
	for key, value in next, self.Themes.Huohuo do base[key] = value end
	for key, value in next, colors do
		base[key] = typeof(value) == "string" and Color3.fromHex(value) or value
	end
	self.Themes[name] = base
	return base
end

Talis.Theme_API = {}

function Talis.Theme_API.Set(name)
	Talis:ApplyTheme(name)
end

function Talis.Theme_API.Get()
	return Talis.Theme
end

function Talis.Theme_API.List()
	local out = {}
	for name in next, Talis.Themes do out[#out + 1] = name end
	table.sort(out)
	return out
end

function Talis.Theme_API.SetColor(name, color)
	if not Talis.Theme[name] then return end
	local copy = {}
	for key, value in next, Talis.Theme do copy[key] = value end
	copy[name] = typeof(color) == "string" and Color3.fromHex(color) or color
	Talis.ThemeName = "Custom"
	Talis:ApplyTheme(copy)
	if Talis.ActiveWindow then Talis.ActiveWindow.Theme = Talis.Theme end
end

function Talis.Theme_API.SetColors(list)
	for key, value in next, list do
		Talis.Theme_API.SetColor(key, value)
	end
end

function Talis.Theme_API.GetColor(name)
	return Talis.Theme[name]
end

function Talis.Theme_API.ResetColor(name)
	local base = Talis.Themes[Talis.ThemeName] or Talis.Themes.Huohuo
	if name then
		Talis.Theme_API.SetColor(name, base[name])
	else
		Talis:ApplyTheme(base)
	end
end

function Talis.Theme_API.OnChanged(fn)
	Talis.ThemeListeners[#Talis.ThemeListeners + 1] = fn
	return fn
end

function Talis.Theme_API.Export()
	local out = { Name = Talis.ThemeName }
	for key, value in next, Talis.Theme do out[key] = Talis:Hex(value) end
	return HttpService:JSONEncode(out)
end

function Talis.Theme_API.Import(code, name)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, code)
	if not ok or type(data) ~= "table" then return false end
	local theme = {}
	for key, value in next, data do
		if key ~= "Name" then theme[key] = Color3.fromHex(value) end
	end
	local label = name or data.Name or "Imported"
	Talis.Themes[label] = theme
	Talis:ApplyTheme(label)
	return true
end

function Talis.Theme_API.Bind(instance, map)
	local entry = Talis.ThemeBinds[instance]
	if not entry then
		entry = { map = map, originals = {} }
		Talis.ThemeBinds[instance] = entry
	end
	for prop, key in next, map do
		if entry.originals[prop] == nil then
			entry.originals[prop] = instance[prop]
		end
		instance[prop] = Talis.Theme[key] or instance[prop]
	end
	return instance
end

function Talis.Theme_API.Unbind(instance)
	local entry = Talis.ThemeBinds[instance]
	if not entry then return end
	for prop, original in next, entry.originals do
		pcall(function() instance[prop] = original end)
	end
	Talis.ThemeBinds[instance] = nil
end

Talis.ThemeListeners = {}
Talis.ThemeBinds = {}
Talis.Theme2 = Talis.Theme_API
Talis.ThemeAPI = Talis.Theme_API

--[[ FLAGS ]]

local function evalCondition(cond)
	if cond == nil then return true end
	if type(cond) == "function" then
		local ok, result = pcall(cond)
		return ok and result ~= false and result ~= nil
	end
	return Talis.Flags[cond] ~= nil and Talis.Flags[cond] ~= false
end

function Talis:RefreshVisibility()
	for index = 1, #self.Visibility do
		local entry = self.Visibility[index]
		if entry.Row and entry.Row.Parent then
			entry.Row.Visible = evalCondition(entry.Cond)
		end
	end
end

function Talis:SetFlag(flag, value)
	self.Flags[flag] = value
	local listeners = self.FlagListeners[flag]
	if listeners then
		for index = 1, #listeners do
			local ok, err = pcall(listeners[index], value, flag)
			if not ok then self:RecordError(err) end
		end
	end
	if #self.Visibility > 0 then self:RefreshVisibility() end
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
	return {
		Disconnect = function()
			local index = table.find(listeners, fn)
			if index then table.remove(listeners, index) end
		end,
	}
end

function Talis:GetElement(flag)
	return self.Elements[flag] or self.Options[flag]
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
	Talis.Elements[flag] = option
	return flag
end

--[[ ELEMENT COMMON API ]]

local function safeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then Talis:RecordError(err) end
end

local function Decorate(option, info, window)
	option.Window = window
	option.Row = info.row
	option.Locked = false
	option.Visible = true
	option.Listeners = {}
	option.Index = info.index or 0
	option.Section = info.section

	local rawCallback = option.Callback or function() end
	option.Callback = function(...)
		local value = ...
		for index = 1, #option.Listeners do
			safeCall(option.Listeners[index], value, option)
		end
		safeCall(rawCallback, ...)
	end

	function option:OnChanged(fn)
		table.insert(self.Listeners, fn)
		if self.Value ~= nil then safeCall(fn, self.Value, self) end
		return fn
	end

	function option:SetCallback(fn)
		rawCallback = fn
	end

	function option:SetName(value)
		self.Name = tostring(value)
		if info.label then info.label.Text = self.Name end
	end
	option.SetTitle = option.SetName

	function option:SetDescription(value)
		self.Desc = tostring(value)
		if info.desc then info.desc.Text = self.Desc end
	end
	option.SetDesc = option.SetDescription

	function option:SetIcon(name)
		if not info.icon then
			info.icon = Icon(info.row, name, 14, "Muted")
			info.icon.Position = UDim2.new(0, 0, 0.5, 0)
			info.icon.AnchorPoint = Vector2.new(0, 0.5)
			if info.label then
				info.label.Position = UDim2.new(0, 20, 0, info.label.Position.Y.Offset)
				info.label.Size = UDim2.new(1, -140, info.label.Size.Y.Scale, info.label.Size.Y.Offset)
			end
		end
		info.icon.Image = Talis.Icons[name] or name
		return info.icon
	end

	function option:Lock(reason)
		self.Locked = reason ~= false
		self.LockReason = type(reason) == "string" and reason or nil
		local alpha = self.Locked and 0.42 or 0
		if info.label then info.label.TextTransparency = alpha end
		if info.desc then info.desc.TextTransparency = alpha end
		if info.icon then info.icon.ImageTransparency = alpha end
		if self.Row then self.Row.Active = not self.Locked end
		return self.Locked
	end

	function option:Unlock()
		return self:Lock(false)
	end

	function option:IsLocked()
		return self.Locked
	end

	function option:SetVisible(state)
		self.Visible = state ~= false
		if self.Row then self.Row.Visible = self.Visible end
		return self.Visible
	end

	function option:SetShowWhen(cond)
		self.ShowWhen = cond
		local existing
		for index = 1, #Talis.Visibility do
			if Talis.Visibility[index].Row == self.Row then existing = Talis.Visibility[index] break end
		end
		if existing then
			existing.Cond = cond
		else
			Talis.Visibility[#Talis.Visibility + 1] = { Row = self.Row, Cond = cond }
		end
		Talis:RefreshVisibility()
		return self
	end

	function option:Reset()
		if self.Default == nil then return end
		if self.Set then self:Set(self.Default, true) end
		self.Callback(self.Value)
		return self.Value
	end

	function option:IsDefault()
		if self.Default == nil then return true end
		if type(self.Default) == "table" then
			for index = 1, #self.Default do
				if self.Value[index] ~= self.Default[index] then return false end
			end
			return true
		end
		return self.Value == self.Default
	end

	function option:Highlight()
		if not self.Row then return end
		local flash = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Talis.Theme.Accent,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = self.Row,
		})
		Corner(flash, 5)
		Tween(flash, 0.5, { BackgroundTransparency = 1 })
		task.delay(0.6, function()
			if flash.Parent then flash:Destroy() end
		end)
	end

	function option:Reveal()
		if not self.Row or not window.Current or not self.Section then return end
		window:SelectTab(self.Section.Tab)
		task.wait(0.05)
		self:Highlight()
	end

	function option:MoveUp()
		self:MoveTo(self.Index - 1)
	end

	function option:MoveDown()
		self:MoveTo(self.Index + 1)
	end

	function option:MoveTo(index)
		if not self.Section then return end
		index = math.max(1, math.floor(index))
		local list = self.Section.Ordered
		local current = table.find(list, self)
		if not current then return end
		table.remove(list, current)
		table.insert(list, math.min(index, #list + 1), self)
		for position = 1, #list do
			list[position].Index = position
			if list[position].Row then list[position].Row.LayoutOrder = position end
		end
	end

	function option:AddButton(spec)
		spec = type(spec) == "table" and spec or { Icon = spec }
		local button = New("TextButton", {
			Size = UDim2.fromOffset(spec.Width or 22, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -(spec.Offset or 0), 0.5, 0),
			BackgroundColor3 = Talis.Theme.Raised,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = self.Row,
		})
		Corner(button, 5)
		Theme(button, "Raised", "BackgroundColor3")
		if spec.Icon then
			local icon = Icon(button, spec.Icon, 12, "Muted")
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		end
		Connect(button.MouseEnter, function() Tween(button, 0.1, { BackgroundTransparency = 0.15 }) end)
		Connect(button.MouseLeave, function() Tween(button, 0.1, { BackgroundTransparency = 0.4 }) end)
		Connect(button.MouseButton1Click, function()
			playSound("click")
			if spec.Callback then safeCall(spec.Callback, self) end
		end)
		if spec.Tooltip then window:AddTooltip(button, spec.Tooltip) end
		return button
	end

	function option:Destroy()
		if info.row then info.row:Destroy() end
		Talis.Options[self.Flag] = nil
		Talis.Elements[self.Flag] = nil
		if self.Section then
			local list = self.Section.Ordered
			local index = table.find(list, self)
			if index then table.remove(list, index) end
		end
	end

	if option.ShowWhen ~= nil then option:SetShowWhen(option.ShowWhen) end
	return option
end

--[[ NOTIFICATIONS ]]

function Talis:Notify(config)
	config = type(config) == "table" and config or { Content = tostring(config) }
	if not self.UISettings.Notifications and not config.Force then return end
	local duration = math.max(tonumber(config.Duration) or 4, 1.2)
	local layer = self.NotifLayer
	if not layer then return end

	local kind = config.Kind or "Info"
	local colorKey = config.Color or (kind == "Error" and "Danger" or kind == "Success" and "Success" or kind == "Warning" and "Ember" or "Accent")
	local iconName = config.Icon or (kind == "Error" and "warning" or kind == "Success" and "check" or kind == "Warning" and "warning" or "info")

	local card = New("Frame", {
		Size = UDim2.fromOffset(config.Compact and 250 or 268, config.Compact and 40 or 62),
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
		BackgroundColor3 = self.Theme[colorKey],
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme(bar, colorKey, "BackgroundColor3")

	local title = Text(card, config.Title or "Notice", 13, self.Fonts.Semibold, "Text")
	title.Position = UDim2.new(0, 30, 0, config.Compact and 12 or 11)
	title.Size = UDim2.new(1, -40, 0, 15)

	local body
	if not config.Compact then
		body = Text(card, config.Content or "", 12, self.Fonts.Regular, "Muted")
		body.Position = UDim2.new(0, 30, 0, 27)
		body.Size = UDim2.new(1, -40, 0, 26)
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top
	end

	local icon = Icon(card, iconName, 14, colorKey)
	icon.Position = UDim2.new(0, 12, 0, config.Compact and 13 or 12)
	icon.AnchorPoint = Vector2.new(0, 0)
	Theme(icon, colorKey, "ImageColor3")

	local timer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0, 6, 1, -5),
		BackgroundColor3 = self.Theme[colorKey],
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme(timer, colorKey, "BackgroundColor3")

	local progress
	if config.Progress then
		progress = New("Frame", {
			Size = UDim2.new(0, 0, 0, 3),
			Position = UDim2.new(0, 6, 1, -10),
			BackgroundColor3 = self.Theme[colorKey],
			BorderSizePixel = 0,
			Parent = card,
		})
		Corner(progress, 2)
	end

	Tween(card, 0.2, { BackgroundTransparency = 0.08 })
	Tween(stroke, 0.2, { Transparency = 0.45 })

	self.Notifications[card] = true
	playSound("notify")

	local handle = { Card = card, Dismissed = false }

	function handle:SetTitle(text)
		title.Text = tostring(text)
	end

	function handle:SetBody(text)
		if body then body.Text = tostring(text) end
	end

	function handle:SetProgress(alpha)
		if progress then
			progress.Size = UDim2.new(clamp01(alpha), 0, 0, 3)
		end
	end

	function handle:Dismiss()
		if self.Dismissed then return end
		self.Dismissed = true
		if self.Timer then self.Timer:Cancel() end
		self:Close()
	end

	function handle:Close()
		if not Talis.Notifications[card] then return end
		Talis.Notifications[card] = nil
		Tween(card, 0.18, { BackgroundTransparency = 1 })
		Tween(stroke, 0.18, { Transparency = 1 })
		task.delay(0.2, function()
			if card.Parent then card:Destroy() end
		end)
	end

	if config.Buttons then
		local strip = New("Frame", {
			Size = UDim2.new(1, -20, 0, 20),
			Position = UDim2.new(0, 10, 1, -24),
			BackgroundTransparency = 1,
			Parent = card,
		})
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = strip })
		for index = 1, #config.Buttons do
			local spec = config.Buttons[index]
			local button = New("TextButton", {
				Size = UDim2.fromOffset(60, 18),
				BackgroundColor3 = self.Theme.Hover,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Text = spec.Name or "OK",
				TextSize = 11,
				FontFace = self.Fonts.Regular,
				TextColor3 = self.Theme.Text,
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = strip,
			})
			Corner(button, 4)
			Connect(button.MouseButton1Click, function()
				if spec.Callback then safeCall(spec.Callback) end
				if not spec.Keep then handle:Dismiss() end
			end)
		end
	end

	if config.Callback then
		local click = New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = -1,
			Parent = card,
		})
		Connect(click.MouseButton1Click, function()
			safeCall(config.Callback)
			if not config.Persist then handle:Dismiss() end
		end)
	end

	if not config.Persist then
		Tween(timer, duration, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)
		handle.Timer = task.delay(duration, function() handle:Close() end)
	else
		timer.Visible = false
	end

	self.NotificationLog[#self.NotificationLog + 1] = { Title = config.Title or "Notice", Content = config.Content or "", Time = os.clock() }
	return handle
end

function Talis:Dialog(config)
	config = config or {}
	local root = self.ActiveWindow and self.ActiveWindow.Root
	if not root then return end

	local overlay = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Scrim,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 120,
		Parent = root,
	})

	local box = New("Frame", {
		Size = UDim2.fromOffset(config.Width or 320, 150),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 121,
		Parent = overlay,
	})
	Corner(box, 10)
	Stroke(box, "Stroke", 1, 0.3)

	local title = Text(box, config.Title or "Confirm", 15, self.Fonts.Bold, "Text")
	title.Position = UDim2.new(0, 18, 0, 16)
	title.Size = UDim2.new(1, -36, 0, 20)

	local body = Text(box, config.Content or "", 12, self.Fonts.Regular, "Muted")
	body.Position = UDim2.new(0, 18, 0, 42)
	body.Size = UDim2.new(1, -36, 0, 50)
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top

	local function close()
		overlay:Destroy()
	end

	local strip = New("Frame", {
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.new(0, 18, 1, -44),
		BackgroundTransparency = 1,
		ZIndex = 122,
		Parent = box,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		Parent = strip,
	})

	local buttons = config.Buttons or { { Name = "OK" } }
	for index = 1, #buttons do
		local spec = buttons[index]
		local style = spec.Style or (index == #buttons and "Primary" or "Default")
		local button = New("TextButton", {
			Size = UDim2.fromOffset(spec.Width or 88, 28),
			BackgroundColor3 = style == "Primary" and self.Theme.Accent or style == "Danger" and self.Theme.Danger or self.Theme.Raised,
			BackgroundTransparency = style == "Default" and 0.35 or 0,
			BorderSizePixel = 0,
			Text = spec.Name or "OK",
			TextSize = 12,
			FontFace = self.Fonts.Semibold,
			TextColor3 = style == "Default" and self.Theme.Text or self.Theme.AccentText,
			AutoButtonColor = false,
			LayoutOrder = index,
			ZIndex = 123,
			Parent = strip,
		})
		Corner(button, 6)
		Connect(button.MouseButton1Click, function()
			if spec.Callback then safeCall(spec.Callback) end
			if not spec.Keep then close() end
		end)
	end

	if config.Dismissable ~= false then
		local dismiss = New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 120,
			Parent = overlay,
		})
		Connect(dismiss.MouseButton1Click, close)
	end

	playSound("open")
	return { Close = close, Box = box }
end

function Talis:Prompt(config)
	config = config or {}
	local root = self.ActiveWindow and self.ActiveWindow.Root
	if not root then return end

	local overlay = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Scrim,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 120,
		Parent = root,
	})

	local box = New("Frame", {
		Size = UDim2.fromOffset(config.Width or 320, 150),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 121,
		Parent = overlay,
	})
	Corner(box, 10)
	Stroke(box, "Stroke", 1, 0.3)

	local title = Text(box, config.Title or "Enter", 15, self.Fonts.Bold, "Text")
	title.Position = UDim2.new(0, 18, 0, 16)
	title.Size = UDim2.new(1, -36, 0, 20)

	local body = Text(box, config.Content or "", 12, self.Fonts.Regular, "Muted")
	body.Position = UDim2.new(0, 18, 0, 40)
	body.Size = UDim2.new(1, -36, 0, 18)
	body.TextWrapped = true

	local field = New("Frame", {
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.new(0, 18, 0, 62),
		BackgroundColor3 = self.Theme.Raised,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 122,
		Parent = box,
	})
	Corner(field, 6)
	local stroke = Stroke(field, "Stroke", 1, 0.5)

	local input = New("TextBox", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.new(0, 9, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		PlaceholderColor3 = self.Theme.Faint,
		TextSize = 12,
		FontFace = self.Fonts.Regular,
		TextColor3 = self.Theme.Text,
		ClearTextOnFocus = false,
		ZIndex = 123,
		Parent = field,
	})

	local function close()
		overlay:Destroy()
	end

	local strip = New("Frame", {
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.new(0, 18, 1, -44),
		BackgroundTransparency = 1,
		ZIndex = 122,
		Parent = box,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		Parent = strip,
	})

	local error = Text(box, "", 11, self.Fonts.Regular, "Danger")
	error.Position = UDim2.new(0, 18, 0, 96)
	error.Size = UDim2.new(1, -36, 0, 14)

	local function submit()
		local text = input.Text
		if config.Validate then
			local ok, message = config.Validate(text)
			if ok == false then
				error.Text = message or "Invalid"
				return
			end
		end
		if config.Callback then safeCall(config.Callback, text) end
		close()
	end

	local cancel = New("TextButton", {
		Size = UDim2.fromOffset(88, 28),
		BackgroundColor3 = self.Theme.Raised,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Text = "Cancel",
		TextSize = 12,
		FontFace = self.Fonts.Semibold,
		TextColor3 = self.Theme.Text,
		AutoButtonColor = false,
		LayoutOrder = 1,
		ZIndex = 123,
		Parent = strip,
	})
	Corner(cancel, 6)
	Connect(cancel.MouseButton1Click, close)

	local confirm = New("TextButton", {
		Size = UDim2.fromOffset(88, 28),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Text = config.ConfirmText or "Confirm",
		TextSize = 12,
		FontFace = self.Fonts.Semibold,
		TextColor3 = self.Theme.AccentText,
		AutoButtonColor = false,
		LayoutOrder = 2,
		ZIndex = 123,
		Parent = strip,
	})
	Corner(confirm, 6)
	Connect(confirm.MouseButton1Click, submit)
	Connect(input.FocusLost, function(enter)
		if enter then submit() end
	end)

	task.defer(function()
		input:CaptureFocus()
	end)
	playSound("open")
	return { Close = close }
end

--[[ TOOLTIP ]]

function Talis:Tooltip(text, input)
	local root = self.ActiveWindow and self.ActiveWindow.Root
	if not root then return end
	if not self.TooltipLabel then
		self.TooltipLabel = New("TextLabel", {
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
		Corner(self.TooltipLabel, 4)
		Stroke(self.TooltipLabel, "Stroke", 1, 0.5)
		Theme(self.TooltipLabel, "Text", "TextColor3")
		Theme(self.TooltipLabel, "Raised", "BackgroundColor3")
	end
	self.TooltipLabel.Text = tostring(text)
	self.TooltipLabel.Size = UDim2.fromOffset(measure(tostring(text), 12, self.Fonts.Regular).X + 16, 22)
	self.TooltipLabel.Visible = true
	self:MoveTooltip(input)
end

function Talis:MoveTooltip(input)
	if not self.TooltipLabel or not self.TooltipLabel.Visible then return end
	local size = viewport()
	local wth = self.TooltipLabel.AbsoluteSize.X
	local x = input.Position.X + 16
	local y = input.Position.Y + 20
	if x + wth + 8 > size.X then x = input.Position.X - wth - 12 end
	if y + 26 > size.Y then y = input.Position.Y - 28 end
	self.TooltipLabel.Position = UDim2.fromOffset(x, y)
end

function Talis:HideTooltip()
	if self.TooltipLabel then self.TooltipLabel.Visible = false end
end

function Talis:AddTooltip(object, text)
	Connect(object.MouseEnter, function(input)
		self:Tooltip(text, input)
	end)
	Connect(object.MouseMoved, function(input)
		self:MoveTooltip(input)
	end)
	Connect(object.MouseLeave, function()
		self:HideTooltip()
	end)
	return object
end

--[[ LIFECYCLE ]]

function Talis:Track(instance)
	self.Tracked[#self.Tracked + 1] = instance
	return instance
end

function Talis:OnEject(fn)
	self.EjectHooks[#self.EjectHooks + 1] = fn
	return fn
end

function Talis:OnReset(fn)
	self.ResetHooks[#self.ResetHooks + 1] = fn
	return fn
end

function Talis:Loop(fn, seconds)
	if seconds then
		local running = true
		task.spawn(function()
			while running do
				task.wait(seconds)
				if not running then break end
				safeCall(fn)
			end
		end)
		local entry = { stop = function() running = false end }
		self.Loops[#self.Loops + 1] = entry
		return entry
	end
	local connection = RunService.RenderStepped:Connect(function(dt) safeCall(fn, dt) end)
	self.Connections[#self.Connections + 1] = connection
	return connection
end

function Talis:Patch(instance, prop, value)
	local list = self.Patches[instance]
	if not list then
		list = {}
		self.Patches[instance] = list
	end
	if list[prop] == nil then
		list[prop] = instance[prop]
	end
	instance[prop] = value
	return instance
end

function Talis:Restore(instance, prop)
	local list = self.Patches[instance]
	if not list then return end
	if prop then
		if list[prop] ~= nil then
			pcall(function() instance[prop] = list[prop] end)
			list[prop] = nil
		end
	else
		for key, original in next, list do
			pcall(function() instance[key] = original end)
		end
		self.Patches[instance] = nil
	end
end

function Talis:ResetAll()
	for flag, option in next, self.Options do
		if option.Reset and not option.IgnoreFlag and flag:sub(1, 3) ~= "ui/" and flag:sub(1, 7) ~= "config/" then
			pcall(option.Reset, option)
		end
	end
	for index = 1, #self.ResetHooks do
		safeCall(self.ResetHooks[index])
	end
	self:Notify({ Title = "Reset", Content = "Everything set back to defaults.", Kind = "Success" })
end

function Talis:Eject()
	self:SaveUISettings()
	for flag, option in next, self.Options do
		if option.Value == true and not option.IgnoreFlag and option.Type == "Toggle" then
			pcall(option.Set, option, false)
		end
	end
	for index = 1, #self.EjectHooks do
		safeCall(self.EjectHooks[index])
	end
	for instance, list in next, self.Patches do
		for key, original in next, list do
			pcall(function() instance[key] = original end)
		end
	end
	table.clear(self.Patches)
	for index = 1, #self.Connections do
		pcall(function() self.Connections[index]:Disconnect() end)
	end
	table.clear(self.Connections)
	for index = 1, #self.Tracked do
		pcall(function() self.Tracked[index]:Destroy() end)
	end
	table.clear(self.Tracked)
	if self.ActiveWindow then
		pcall(function() self.ActiveWindow:Destroy() end)
	end
	self.NotifLayer = nil
	self.ActiveWindow = nil
	self.TooltipLabel = nil
end

--[[ WINDOW ]]

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

local NOTIFY_SIDES = {
	["Top Right"] = { Vector2.new(1, 0), Vector2.new(1, 0), Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top },
	["Top Center"] = { Vector2.new(0.5, 0), Vector2.new(0.5, 0), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top },
	["Top Left"] = { Vector2.new(0, 0), Vector2.new(0, 0), Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top },
	["Bottom Right"] = { Vector2.new(1, 1), Vector2.new(1, 1), Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom },
	["Bottom Center"] = { Vector2.new(0.5, 1), Vector2.new(0.5, 1), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom },
	["Bottom Left"] = { Vector2.new(0, 1), Vector2.new(0, 1), Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom },
}

function Talis:SetNotifySide(side)
	local spec = NOTIFY_SIDES[side]
	if not spec or not self.NotifLayer then return end
	local layout = self.NotifLayer:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.HorizontalAlignment = spec[3]
		layout.VerticalAlignment = spec[4]
	end
	self.UISettings.NotifySide = side
end

function Talis:Window(config)
	config = type(config) == "table" and config or {}

	local theme = config.Theme
	if theme ~= nil then self:ApplyTheme(theme) end
	if config.Colors then self.Theme_API.SetColors(config.Colors) end
	if config.Accent then self.Theme_API.SetColor("Accent", config.Accent) end

	local radius = config.Radius or self.UISettings.Radius or 10
	local background = config.Background or {}
	local window = {
		Tabs = {},
		TabButtons = {},
		TabMeta = {},
		Groups = {},
		GroupTabs = {},
		SpacingTargets = {},
		Spacing = config.Spacing or Talis.Spacing,
		ScaleValue = config.Scale or 1,
		BackgroundSource = background.Image,
		Open = false,
		Minimized = false,
		RailOrder = 0,
		Title = config.Title or "Talis",
		Subtitle = config.Subtitle or ("v" .. self.Version),
		Author = config.Author,
		ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
		ToggleMode = config.ToggleMode or "Toggle",
		Size = config.Size or UDim2.fromOffset(680, 440),
		SidebarWidth = config.SidebarWidth or 152,
		Resizable = config.Resizable ~= false,
		CloseBehavior = config.CloseBehavior or "hide",
		Fonts = self.Fonts,
		Theme = self.Theme,
		Locked = false,
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
	Talis.SoundHost = New("Frame", { Size = UDim2.new(), BackgroundTransparency = 1, Parent = gui })

	window.Root = New("Frame", {
		Name = "Root",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local dim = New("Frame", {
		Name = "Dim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Shadow,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = window.Root,
	})
	window.Dim = dim

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
	local shellCorner = Corner(shell, radius)
	window.ShellCorner = shellCorner
	local shellStroke = Stroke(shell, "Stroke", 1, 0.55)
	Theme(shell, "Surface", "BackgroundColor3")
	window.Shell = shell

	local scale = New("UIScale", { Scale = config.Scale or 1, Parent = shell })
	window.Scale = scale

	local backdrop = New("Frame", {
		Name = "Backdrop",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})
	window.Backdrop = backdrop

	local initialImage = background.Image
	if initialImage ~= nil and initialImage ~= "" then
		initialImage = self:LoadImage(initialImage, "background")
	end
	local image = New("ImageLabel", {
		Name = "Image",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = initialImage or "",
		ImageTransparency = background.Transparency or 0.15,
		ScaleType = background.ScaleType or Enum.ScaleType.Crop,
		Visible = initialImage ~= nil and initialImage ~= "",
		Parent = backdrop,
	})
	window.Image = image

	local scrim = New("Frame", {
		Name = "Scrim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = self.Theme.Scrim,
		BackgroundTransparency = background.Scrim or 0.45,
		BorderSizePixel = 0,
		Visible = initialImage ~= nil and initialImage ~= "",
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
		Visible = initialImage ~= nil and initialImage ~= "",
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

	local particles = New("Frame", {
		Name = "Particles",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
		ClipsDescendants = true,
		Parent = shell,
	})
	window.Particles = particles

	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = shell,
	})

	local title = Text(header, window.Title, 13, self.Fonts.Semibold, "Text")
	title.Position = UDim2.new(0, 16, 0, 0)
	title.Size = UDim2.new(1, -180, 1, 0)

	local subtitle = Text(header, window.Subtitle, 11, self.Fonts.Regular, "Faint", Enum.TextXAlignment.Right)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.Size = UDim2.new(1, -74, 1, 0)
	window.SubtitleLabel = subtitle

	local function headerButton(iconName, offset)
		local button = New("TextButton", {
			Size = UDim2.fromOffset(22, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = header,
		})
		Corner(button, 4)
		Theme(button, "Raised", "BackgroundColor3")
		local icon = Icon(button, iconName, 12, "Muted")
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		Connect(button.MouseEnter, function()
			Tween(button, 0.12, { BackgroundTransparency = 0.6 })
			icon.ImageColor3 = self.Theme.Text
		end)
		Connect(button.MouseLeave, function()
			Tween(button, 0.12, { BackgroundTransparency = 1 })
			icon.ImageColor3 = self.Theme.Muted
		end)
		return button, icon
	end

	local minButton = headerButton("min", -40)
	local closeButton = headerButton("close", -14)

	-- bell menu
	local bellButton, bellIcon = headerButton("bell", -66)
	local bellBadge = New("Frame", {
		Size = UDim2.fromOffset(6, 6),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -1, 0, 1),
		BackgroundColor3 = self.Theme.Danger,
		BorderSizePixel = 0,
		Visible = false,
		Parent = bellButton,
	})
	Corner(bellBadge, 3)

	local rail = New("Frame", {
		Name = "Rail",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, window.SidebarWidth, 1, -40),
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
		Position = UDim2.new(0, window.SidebarWidth, 0, 40),
		Size = UDim2.new(1, -window.SidebarWidth, 1, -40),
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
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = shell,
	})
	local gripMark = Icon(grip, "arrow", 13, "Faint")
	gripMark.AnchorPoint = Vector2.new(1, 1)
	gripMark.Position = UDim2.new(1, -3, 1, -3)
	Connect(grip.MouseEnter, function() gripMark.ImageColor3 = self.Theme.Muted end)
	Connect(grip.MouseLeave, function() gripMark.ImageColor3 = self.Theme.Faint end)

	local opened = false

	local function applyDim()
		local on = Talis.UISettings.Dim and opened
		dim.Visible = on
		if on then
			dim.BackgroundTransparency = 1
			Tween(dim, 0.2, { BackgroundTransparency = 0.5 })
		end
	end

	local function applyBlur()
		if not Talis.BlurEffect then
			Talis.BlurEffect = Instance.new("BlurEffect")
			Talis.BlurEffect.Size = 0
			Talis.BlurEffect.Parent = Lighting
			Talis:Track(Talis.BlurEffect)
		end
		Talis.BlurEffect.Size = (Talis.UISettings.Blur and opened) and 18 or 0
	end

	local function setOpen(state)
		if window.Destroyed then return end
		state = state == true
		if opened == state then return end
		opened = state
		window.Open = state
		playSound("open")
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
		applyDim()
		applyBlur()
		for index = 1, #window.OpenHooks do safeCall(window.OpenHooks[index], state) end
	end
	window.SetOpen = setOpen
	window.OpenHooks = {}

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
		local screen = viewport()
		local width = shell.AbsoluteSize.X
		local height = shell.AbsoluteSize.Y
		local x = dragOrigin.X.Scale * screen.X + dragOrigin.X.Offset + delta.X
		local y = dragOrigin.Y.Scale * screen.Y + dragOrigin.Y.Offset + delta.Y
		x = math.clamp(x, 80 - width / 2, screen.X - 80 + width / 2)
		y = math.clamp(y, height / 2, screen.Y - 44 + height / 2)
		shell.Position = UDim2.fromOffset(x, y)
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	local resizing, resizeStart, resizeOrigin
	Connect(grip.InputBegan, function(input)
		if not isPress(input) or window.Minimized or not window.Resizable then return end
		resizing = true
		resizeStart = input.Position
		resizeOrigin = shell.AbsoluteSize
	end)
	Connect(UIS.InputChanged, function(input)
		if not resizing or not isMove(input) then return end
		local factor = scale.Scale
		local delta = input.Position - resizeStart
		local absWidth = math.max(420 * factor, resizeOrigin.X + delta.X)
		local absHeight = math.max(280 * factor, resizeOrigin.Y + delta.Y)
		shell.Size = UDim2.fromOffset(absWidth / factor, absHeight / factor)
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
		local source = spec.Image
		self.BackgroundSource = source
		if source ~= nil and source ~= "" then
			source = Talis:LoadImage(source, "background")
		end
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
		value = tonumber(value) or 1
		self.ScaleValue = value
		scale.Scale = value
	end

	function window:GetScale()
		return self.ScaleValue or scale.Scale
	end

	function window:SetRadius(value)
		value = math.clamp(tonumber(value) or 10, 0, 30)
		self.Radius = value
		if shellCorner then shellCorner.CornerRadius = UDim.new(0, value) end
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
		self.ToggleKey = key
	end

	function window:SetMenuKey(key)
		self:SetToggleKey(typeof(key) == "string" and Enum.KeyCode[key] or key)
	end

	function window:SetAccent(color)
		Talis.Theme_API.SetColor("Accent", color)
		self.Theme = Talis.Theme
	end

	function window:SetTitle(value)
		self.Title = tostring(value)
		title.Text = self.Title
	end

	function window:SetSubtitle(value)
		self.Subtitle = tostring(value)
		subtitle.Text = self.Subtitle
	end

	function window:SetAuthor(value)
		self.Author = tostring(value)
	end

	function window:SetSize(w, h)
		self.Size = UDim2.fromOffset(w, h)
		shell.Size = self.Size
	end

	function window:Center()
		shell.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	function window:Minimize(state)
		if state == nil then state = true end
		if self.Minimized ~= state then
			minButton.MouseButton1Click:Fire()
		end
	end

	function window:IsMinimized()
		return self.Minimized
	end

	function window:Toggle(state)
		setOpen(state)
	end

	function window:IsOpen()
		return opened
	end

	function window:OpenSearch()
		setOpen(true)
		local box = self:Search()
		task.defer(function()
			local input = box:FindFirstChildOfClass("TextBox")
			if input then input:CaptureFocus() end
		end)
	end

	function window:OnOpen(fn)
		table.insert(self.OpenHooks, fn)
	end

	function window:OnClose(fn)
		table.insert(self.OpenHooks, function(state)
			if not state then safeCall(fn) end
		end)
	end

	function window:LockAll(reason)
		self.Locked = true
		for flag, option in next, Talis.Options do
			if option.Window == self and not flag:match("^ui/") then
				pcall(option.Lock, option, reason)
			end
		end
	end

	function window:UnlockAll()
		self.Locked = false
		for flag, option in next, Talis.Options do
			if option.Window == self and not flag:match("^ui/") then
				pcall(option.Unlock, option)
			end
		end
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

	function window:AddTooltip(object, text)
		return Talis:AddTooltip(object, text)
	end

	function window:SelectTab(tab)
		if self.Current == tab then return end
		if self.Current then
			self.Current.Page.Visible = false
			local previous = self.TabMeta[self.Current]
			if previous then
				if previous.Pill then Tween(previous.Pill, 0.14, { BackgroundTransparency = 1 }) end
				if previous.Mark then Tween(previous.Mark, 0.14, { BackgroundTransparency = 1 }) end
				if previous.Label then previous.Label.TextColor3 = self.Theme.Muted end
				if previous.Icon then previous.Icon.ImageColor3 = self.Theme.Muted end
			end
		end
		self.Current = tab
		local meta = self.TabMeta[tab]
		if meta then
			if meta.Pill then Tween(meta.Pill, 0.14, { BackgroundTransparency = 0.2 }) end
			if meta.Mark then Tween(meta.Mark, 0.14, { BackgroundTransparency = 0 }) end
			if meta.Label then meta.Label.TextColor3 = self.Theme.Text end
			if meta.Icon then meta.Icon.ImageColor3 = self.Theme.Text end
		end
		tab.Page.Visible = true
		if tab.OnSelected then safeCall(tab.OnSelected) end
	end

	local function makeTabButton(parent, tab)
		local button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = tab.Order,
			Parent = parent,
		})
		local pill = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = self.Theme.Window,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = button,
		})
		Corner(pill, 5)
		Theme(pill, "Window", "BackgroundColor3")
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
		local meta = { Pill = pill, Mark = mark, Label = label, Icon = nil }

		if tab.Icon then
			local icon = Icon(button, tab.Icon, 14, "Muted")
			icon.Position = UDim2.new(0, 12, 0.5, 0)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			label.Position = UDim2.new(0, 34, 0, 0)
			label.Size = UDim2.new(1, -42, 1, 0)
			meta.Icon = icon
		else
			label.Position = UDim2.new(0, 14, 0, 0)
			label.Size = UDim2.new(1, -22, 1, 0)
		end

		self.TabMeta[tab] = meta
		tab.Button = button

		Connect(button.MouseEnter, function()
			if self.Current ~= tab then
				Tween(pill, 0.12, { BackgroundTransparency = 0.55 })
			end
			if tab.Description then self:Tooltip(tab.Description, { Position = Vector2.new(button.AbsolutePosition.X + 40, button.AbsolutePosition.Y) }) end
		end)
		Connect(button.MouseLeave, function()
			if self.Current ~= tab then
				Tween(pill, 0.12, { BackgroundTransparency = 1 })
			end
			if tab.Description then self:HideTooltip() end
		end)
		Connect(button.MouseButton1Click, function()
			if tab.Locked then
				self:Notify({ Title = "Locked", Content = tab.LockReason or "This tab is locked.", Kind = "Warning" })
				return
			end
			self:SelectTab(tab)
		end)
		return button
	end

	local function newTab(spec, parentRail, group)
		spec = type(spec) == "table" and spec or { Name = tostring(spec) }
		self.RailOrder = self.RailOrder + 1
		local tab = {
			Name = spec.Name or "Tab",
			Icon = spec.Icon,
			Description = spec.Description,
			Window = self,
			Sections = {},
			SubTabs = {},
			Order = spec.Order or self.RailOrder,
			Group = group,
			Locked = spec.Locked ~= nil and spec.Locked ~= false,
			LockReason = type(spec.Locked) == "string" and spec.Locked or nil,
			Visible = spec.Visible ~= false,
			ShowWhen = spec.ShowWhen,
		}

		local button = makeTabButton(parentRail, tab)

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
		local pageLayout = New("UIListLayout", {
			Padding = UDim.new(0, (self.Spacing or Talis.Spacing) + 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
		self.SpacingTargets[#self.SpacingTargets + 1] = { Layout = pageLayout, Factor = 1.34 }
		Pad(page, 16, 18, 18, 18)
		tab.Page = page
		tab.ButtonVisible = true

		if tab.ShowWhen then
			Talis.Visibility[#Talis.Visibility + 1] = { Row = button, Cond = tab.ShowWhen }
		end

		function tab:SetName(value)
			self.Name = tostring(value)
			local meta = self.Window.TabMeta[self]
			if meta and meta.Label then meta.Label.Text = self.Name end
		end

		function tab:SetIcon(name)
			self.Icon = name
			local meta = self.Window.TabMeta[self]
			if meta then
				if not meta.Icon then
					meta.Icon = Icon(self.Button, name, 14, "Muted")
					meta.Icon.Position = UDim2.new(0, 12, 0.5, 0)
					meta.Icon.AnchorPoint = Vector2.new(0, 0.5)
					meta.Label.Position = UDim2.new(0, 34, 0, 0)
					meta.Label.Size = UDim2.new(1, -42, 1, 0)
				else
					meta.Icon.Image = Talis.Icons[name] or name
				end
			end
		end

		function tab:SetDescription(value)
			self.Description = tostring(value)
		end

		function tab:SetVisible(state)
			self.Visible = state ~= false
			self.Button.Visible = self.Visible
		end

		function tab:IsVisible()
			return self.Visible
		end

		function tab:SetOrder(value)
			self.Order = value
			self.Button.LayoutOrder = value
		end

		function tab:MoveTo(index)
			self:SetOrder(index)
		end

		function tab:Lock(reason)
			self.Locked = true
			self.LockReason = reason
		end

		function tab:Unlock()
			self.Locked = false
		end

		function tab:Select()
			self.Window:SelectTab(self)
		end

		function tab:GetName()
			return self.Name
		end

		function tab:Destroy()
			if self.Button then self.Button:Destroy() end
			if self.Page then self.Page:Destroy() end
		end

		local function attachSectionMethods(section)
			for name, builder in next, Talis.Builders do
				section[name] = function(sectionSelf, spec2, ...)
					return builder(sectionSelf, spec2, ...)
				end
			end
		end

		function tab:Section(sectionSpec, parentPage)
			sectionSpec = type(sectionSpec) == "table" and sectionSpec or { Name = tostring(sectionSpec) }
			local owner = tab.Window

			local parent = parentPage or page
			if sectionSpec.Side then
				if not tab.Columns then
					tab.Columns = New("Frame", {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = #page:GetChildren(),
						Parent = parent,
					})
					New("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = tab.Columns,
					})
					tab.LeftColumn = New("Frame", {
						Size = UDim2.new(0.5, -4, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = tab.Columns,
					})
					New("UIListLayout", { Padding = UDim.new(0, owner.Spacing or Talis.Spacing), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tab.LeftColumn })
					tab.RightColumn = New("Frame", {
						Size = UDim2.new(0.5, -4, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						Parent = tab.Columns,
					})
					New("UIListLayout", { Padding = UDim.new(0, owner.Spacing or Talis.Spacing), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tab.RightColumn })
				end
				parent = sectionSpec.Side == "Right" and tab.RightColumn or tab.LeftColumn
			end

			local section = {
				Name = sectionSpec.Name or "",
				Tab = tab,
				Window = owner,
				Options = {},
				Ordered = {},
				Order = 0,
				Visible = sectionSpec.Visible ~= false,
				ShowWhen = sectionSpec.ShowWhen,
				ResetButton = sectionSpec.ResetButton,
			}

			local group = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = #parent:GetChildren(),
				Parent = parent,
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
				headText.Size = UDim2.new(1, -50, 1, 0)
				headText.Position = UDim2.new(0, 0, 0, 6)
				local headLine = Hairline(head, "Hairline", 0.5)
				headLine.Position = UDim2.new(0, 0, 1, -1)
				section.Head = head

				if section.ResetButton then
					local reset = Text(head, "Reset", 10, owner.Fonts.Semibold, "Faint", Enum.TextXAlignment.Right)
					reset.Size = UDim2.new(0, 44, 1, 0)
					reset.AnchorPoint = Vector2.new(1, 0)
					reset.Position = UDim2.new(1, 0, 0, 6)
					Connect(reset.InputBegan, function(input)
						if not isPress(input) then return end
						for index = 1, #section.Ordered do
							local element = section.Ordered[index]
							if element.Reset then pcall(element.Reset, element) end
						end
					end)
				end
			end

			if section.ShowWhen then
				Talis.Visibility[#Talis.Visibility + 1] = { Row = group, Cond = section.ShowWhen }
			end

			function section:Next()
				self.Order = self.Order + 1
				return self.Order
			end

			function section:SetName(value)
				self.Name = tostring(value)
				if self.Head then
					local label = self.Head:FindFirstChildOfClass("TextLabel")
					if label then label.Text = string.upper(self.Name) end
				end
			end

			function section:GetName()
				return self.Name
			end

			function section:SetSide(side)
				self.Side = side
			end

			function section:SetOrder(value)
				self.Order = value
				self.Group.LayoutOrder = value
			end

			function section:SetVisible(state)
				self.Visible = state ~= false
				self.Group.Visible = self.Visible
			end

			function section:SetShowWhen(cond)
				self.ShowWhen = cond
				Talis.Visibility[#Talis.Visibility + 1] = { Row = self.Group, Cond = cond }
				Talis:RefreshVisibility()
			end

			function section:Destroy()
				self.Group:Destroy()
			end

			function section:Row(height, name, desc, margin)
				local base = height or 30
				local extra = margin or 0
				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, base + extra),
					BackgroundTransparency = 1,
					LayoutOrder = self:Next(),
					Parent = group,
				})
				local info = { row = row, section = self, index = #self.Ordered + 1 }
				if name then
					local label = Text(row, name, 13, self.Window.Fonts.Regular, "Label")
					label.Position = UDim2.new(0, 0, 0, 0)
					if desc then
						label.Size = UDim2.new(1, -120, 0, 15)
						label.TextYAlignment = Enum.TextYAlignment.Top
					else
						label.Size = UDim2.new(1, -120, 1, 0)
						label.TextYAlignment = Enum.TextYAlignment.Center
					end
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

			function section:Page(name)
				local holder = New("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = self:Next(),
					Parent = group,
				})
				local strip = New("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = holder,
				})
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = strip })
				local pageGroup = New("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = holder,
				})
				New("UIListLayout", { Padding = UDim.new(0, owner.Spacing or Talis.Spacing), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pageGroup })

				local page = { Name = tostring(name), Group = pageGroup, Section = self, Window = owner, Options = {}, Ordered = {}, Order = 0 }
				page.Next = function(self2)
					self2.Order = self2.Order + 1
					return self2.Order
				end
				page.Row = function(self2, height, label, desc, margin)
					local base = height or 30
					local row = New("Frame", {
						Size = UDim2.new(1, 0, 0, base + (margin or 0)),
						BackgroundTransparency = 1,
						LayoutOrder = self2:Next(),
						Parent = pageGroup,
					})
					local info = { row = row, section = self, index = #self2.Ordered + 1 }
					if label then
						local text = Text(row, label, 13, owner.Fonts.Regular, "Label")
						text.Size = UDim2.new(1, -120, desc and 0 or 1, desc and 15 or 0)
						text.TextYAlignment = desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
						info.label = text
					end
					return row, info
				end
				page.Tooltip = section.Tooltip
				attachSectionMethods(page)

				local buttons = {}
				local function select(target)
					for index = 1, #buttons do
						local entry = buttons[index]
						entry.Group.Visible = entry.Page == target
						entry.Label.TextColor3 = entry.Page == target and owner.Theme.Text or owner.Theme.Muted
						entry.Pill.BackgroundTransparency = entry.Page == target and 0.4 or 1
					end
				end

				page.Select = select

				local function addButton()
					local button = New("TextButton", {
						Size = UDim2.fromOffset(measure(page.Name, 11, owner.Fonts.Semibold).X + 20, 22),
						BackgroundTransparency = 1,
						Text = "",
						AutoButtonColor = false,
						LayoutOrder = #buttons + 1,
						Parent = strip,
					})
					local pill = New("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = owner.Theme.Raised,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Parent = button,
					})
					Corner(pill, 5)
					Theme(pill, "Raised", "BackgroundColor3")
					local label = Text(button, page.Name, 11, owner.Fonts.Semibold, "Muted", Enum.TextXAlignment.Center)
					label.Size = UDim2.new(1, 0, 1, 0)
					buttons[#buttons + 1] = { Group = pageGroup, Page = page, Label = label, Pill = pill }
					Connect(button.MouseButton1Click, function() select(page) end)
				end

				addButton()
				pageGroup.Visible = #buttons == 1
				if #buttons == 1 then select(page) end

				section.Pages = section.Pages or {}
				section.Pages[#section.Pages + 1] = page
				return page
			end

			attachSectionMethods(section)

			tab.Sections[#tab.Sections + 1] = section
			return section
		end

		function tab:GetSection(name)
			for index = 1, #self.Sections do
				if self.Sections[index].Name == name then return self.Sections[index] end
			end
		end

		function tab:LeftSection(spec)
			spec = type(spec) == "table" and spec or { Name = tostring(spec) }
			spec.Side = "Left"
			return self:Section(spec)
		end

		function tab:RightSection(spec)
			spec = type(spec) == "table" and spec or { Name = tostring(spec) }
			spec.Side = "Right"
			return self:Section(spec)
		end

		function tab:SubTab(spec)
			spec = type(spec) == "table" and spec or { Name = tostring(spec) }
			if not tab.SubStrip then
				tab.SubStrip = New("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					LayoutOrder = -1,
					Parent = page,
				})
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = tab.SubStrip })
			end
			local sub = { Name = spec.Name or "Sub", Window = self, Sections = {}, Order = #tab.SubTabs + 1, ParentTab = tab }
			local button = New("TextButton", {
				Size = UDim2.fromOffset(measure(sub.Name, 11, self.Fonts.Semibold).X + 20, 22),
				BackgroundColor3 = self.Theme.Raised,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Text = sub.Name,
				TextSize = 11,
				FontFace = self.Fonts.Semibold,
				TextColor3 = self.Theme.Muted,
				AutoButtonColor = false,
				LayoutOrder = sub.Order,
				Parent = tab.SubStrip,
			})
			Corner(button, 5)
			sub.Button = button

			local subPage = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				Parent = page,
			})
			New("UIListLayout", { Padding = UDim.new(0, (self.Spacing or Talis.Spacing) + 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = subPage })
			sub.Page = subPage

			function sub:Select()
				for index = 1, #tab.SubTabs do
					local other = tab.SubTabs[index]
					other.Page.Visible = other == sub
					other.Button.TextColor3 = other == sub and self.Window.Theme.Text or self.Window.Theme.Muted
					other.Button.BackgroundTransparency = other == sub and 0.15 or 0.4
				end
			end

			function sub:Section(sectionSpec)
				local section = tab.Section(sectionSpec, subPage)
				sub.Sections[#sub.Sections + 1] = section
				return section
			end

			tab.SubTabs[#tab.SubTabs + 1] = sub
			if #tab.SubTabs == 1 then sub:Select() end
			Connect(button.MouseButton1Click, function() sub:Select() end)
			return sub
		end

		function tab:Template(name)
			return Talis:ApplyTemplate(tab, name)
		end

		function tab:CustomPage(fn)
			local frame = New("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Parent = page,
			})
			Pad(frame, 4, 4, 4, 4)
			safeCall(fn, frame, Talis:UIKit(self))
			return frame
		end

		self.Tabs[#self.Tabs + 1] = tab
		self.TabButtons[tab] = button
		if #self.Tabs == 1 then self:SelectTab(tab) end
		return tab
	end

	function window:Group(spec)
		spec = type(spec) == "table" and spec or { Name = tostring(spec) }
		self.RailOrder = self.RailOrder + 1
		local group = { Name = spec.Name or "Group", Window = self, Tabs = {}, Order = spec.Order or self.RailOrder, Visible = spec.Visible ~= false }

		local heading = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = string.upper(group.Name),
			TextSize = 10,
			FontFace = self.Fonts.Semibold,
			TextColor3 = self.Theme.Faint,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = group.Order,
			Parent = rail,
		})
		Pad(heading, 4, 0, 0, 4)
		group.Heading = heading

		local container = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = group.Order,
			Parent = rail,
		})
		New("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = container })
		group.Container = container

		function group:Tab(tabSpec)
			local tab = newTab(tabSpec, container, group)
			group.Tabs[#group.Tabs + 1] = tab
			return tab
		end

		function group:GetTab(name)
			for index = 1, #self.Tabs do
				if self.Tabs[index].Name == name then return self.Tabs[index] end
			end
		end

		function group:SetName(value)
			self.Name = tostring(value)
			self.Heading.Text = string.upper(self.Name)
		end

		function group:GetName()
			return self.Name
		end

		function group:SetVisible(state)
			self.Visible = state ~= false
			self.Heading.Visible = self.Visible
			self.Container.Visible = self.Visible
		end

		function group:SetOrder(value)
			self.Order = value
			self.Heading.LayoutOrder = value
			self.Container.LayoutOrder = value
		end

		function group:Destroy()
			self.Heading:Destroy()
			self.Container:Destroy()
		end

		self.Groups[#self.Groups + 1] = group
		return group
	end

	function window:Tab(spec)
		return newTab(spec, rail, nil)
	end

	function window:GetTab(name)
		for index = 1, #self.Tabs do
			if self.Tabs[index].Name == name then return self.Tabs[index] end
		end
	end

	function window:GetGroup(name)
		for index = 1, #self.Groups do
			if self.Groups[index].Name == name then return self.Groups[index] end
		end
	end

	function window:Notify(config)
		return Talis:Notify(config)
	end

	function window:Dialog(config)
		return Talis:Dialog(config)
	end

	function window:Prompt(config)
		return Talis:Prompt(config)
	end

	function window:SetTheme(name)
		Talis:ApplyTheme(name)
	end

	function window:Watermark(text)
		return Talis:SetWatermark({ Text = text, Visible = true })
	end

	function window:Search()
		if self.SearchBox then return self.SearchBox end
		local box = New("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Talis.Theme.Raised,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = -10,
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
						info.row.Visible = match
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
		table.clear(Talis.Elements)
		table.clear(Talis.Rainbows)
		table.clear(Talis.Visibility)
		Talis.TooltipLabel = nil
		self.ActivePopup = nil
		if Talis.BlurEffect then Talis.BlurEffect.Size = 0 end
		if Talis.ActiveWindow == self then
			Talis.ActiveWindow = nil
			Talis.NotifLayer = nil
		end
		if gui then pcall(function() gui:Destroy() end) end
	end

	function window:Eject()
		Talis:Eject()
	end

	if config.ToggleButton then
		local toggle = New("TextButton", {
			Position = UDim2.new(0, 14, 1, -46),
			Size = UDim2.fromOffset(96, 30),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Text = config.ToggleButton == true and "talis" or tostring(config.ToggleButton),
			TextSize = 12,
			FontFace = self.Fonts.Semibold,
			TextColor3 = self.Theme.Text,
			AutoButtonColor = false,
			ZIndex = 70,
			Parent = window.Root,
		})
		Corner(toggle, 6)
		Stroke(toggle, "Accent", 1, 0.6)
		Connect(toggle.MouseButton1Click, function() setOpen(not opened) end)
	end

	local held = false
	Connect(UIS.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == window.ToggleKey then
			if window.ToggleMode == "Hold" then
				held = true
				setOpen(true)
			else
				setOpen(not opened)
			end
		elseif input.KeyCode == Enum.KeyCode.Escape and opened then
			setOpen(false)
		end
	end)
	Connect(UIS.InputEnded, function(input)
		if window.ToggleMode == "Hold" and input.KeyCode == window.ToggleKey and held then
			held = false
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

--[[ POPUP ]]

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
		local bodyFrame = window.Body
		local bodyPosition = bodyFrame.AbsolutePosition
		local anchorPosition = anchor.AbsolutePosition
		local visible = anchorPosition.Y + anchor.AbsoluteSize.Y > bodyPosition.Y
			and anchorPosition.Y < bodyPosition.Y + bodyFrame.AbsoluteSize.Y
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

	return window
end

Talis.Window = baseWindow

--[[ HELPERS ]]

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

Talis.Rainbows = {}
Talis.RainbowHue = 0

RunService.RenderStepped:Connect(function()
	if #Talis.Rainbows == 0 then return end
	Talis.RainbowHue = (os.clock() * 0.06) % 1
	for index = 1, #Talis.Rainbows do
		local picker = Talis.Rainbows[index]
		if picker.Apply then picker.Apply() end
	end
end)

--[[ BUILDERS ]]

Talis.Builders.Toggle = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin)

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
		ShowWhen = spec.ShowWhen,
		section = section,
		Callback = spec.Callback or function() end,
		Value = spec.Value == true,
		Default = spec.Value == true,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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

	function option:Toggle(silent)
		return self:Set(not self.Value, silent)
	end

	function option:SetKey(key, mode)
		option.Key = key
		option.KeyMode = mode or "Toggle"
		Connect(UIS.InputBegan, function(input, processed)
			if processed or not option.Key then return end
			if input.KeyCode == (typeof(option.Key) == "string" and Enum.KeyCode[option.Key] or option.Key) then
				if option.KeyMode == "Toggle" then option:Toggle() end
			end
		end)
		return option
	end

	function option:GetKey()
		return option.Key
	end

	Connect(row.InputBegan, function(input)
		if not isPress(input) or option.Locked then return end
		playSound("toggle")
		option:Set(not option.Value)
	end)

	option:Set(option.Value, true)
	if spec.Keybind or spec.Key then option:SetKey(spec.Keybind or spec.Key, spec.KeyMode) end
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Button = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 28 + margin),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local button = New("TextButton", {
		Size = UDim2.new(1, 0, 1, -margin),
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

	local option = {
		Type = "Button", Name = spec.Name, section = section,
		Callback = spec.Callback or function() end, Row = row, Window = section.Window,
		ShowWhen = spec.ShowWhen, Default = 0,
	}
	Decorate(option, { row = row, section = section }, section.Window)
	section.Ordered[#section.Ordered + 1] = option

	Connect(button.MouseEnter, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0.12 or 0.15 })
	end)
	Connect(button.MouseLeave, function()
		Tween(button, 0.12, { BackgroundTransparency = spec.Primary and 0 or 0.35 })
	end)
	Connect(button.MouseButton1Click, function()
		if option.Locked then
			if option.LockReason then section.Window:Notify({ Title = "Locked", Content = option.LockReason, Kind = "Warning" }) end
			return
		end
		playSound("click")
		option:Press()
	end)

	function option:Press()
		Talis:SetFlag(option.Name, os.clock())
		option.Callback()
	end

	function option:OnClick(fn)
		option.SetCallback(fn)
	end

	option.Destroy = function(self)
		row:Destroy()
	end

	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Label = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec) }
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, margin),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	local label = Text(row, spec.Text or "", spec.Size or 12, Talis.Fonts.Regular, spec.Color or "Muted")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextWrapped = true
	label.RichText = spec.Rich ~= false
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.LayoutOrder = 1
	if margin > 0 then
		New("Frame", { Size = UDim2.new(1, 0, 0, margin), BackgroundTransparency = 1, LayoutOrder = 2, Parent = row })
	end

	local element = { Type = "Label", Name = spec.Name or spec.Text, Row = row, section = section, Window = section.Window, ShowWhen = spec.ShowWhen }
	Decorate(element, { row = row, section = section }, section.Window)
	section.Ordered[#section.Ordered + 1] = element

	function element:SetText(value)
		label.Text = tostring(value)
	end

	if spec.ShowWhen then element:SetShowWhen(spec.ShowWhen) end
	return element
end

Talis.Builders.Paragraph = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec) }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	local title = Text(row, spec.Title or "", 13, Talis.Fonts.Semibold, "Text")
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.LayoutOrder = 1
	local body = Text(row, spec.Text or "", 12, Talis.Fonts.Regular, "Muted")
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.LayoutOrder = 2
	if spec.Margin and spec.Margin > 0 then
		New("Frame", { Size = UDim2.new(1, 0, 0, spec.Margin), BackgroundTransparency = 1, LayoutOrder = 3, Parent = row })
	end

	local element = { Type = "Paragraph", Name = spec.Name or spec.Title, Row = row, section = section, Window = section.Window }
	Decorate(element, { row = row, section = section }, section.Window)
	section.Ordered[#section.Ordered + 1] = element

	function element:SetBody(value)
		body.Text = tostring(value)
	end

	return element
end

Talis.Builders.Info = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local row, info = section:Row(28, spec.Name, spec.Desc, spec.Margin)
	local value = Text(row, tostring(spec.Value or ""), 12, Talis.Fonts.Mono, "Text", Enum.TextXAlignment.Right)
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, 0, 0.5, 0)
	value.Size = UDim2.new(0.6, 0, 1, 0)

	local option = { Type = "Info", Name = spec.Name, Row = row, Value = spec.Value, section = section, Window = section.Window, Callback = function() end }
	Register(option)
	Decorate(option, info, section.Window)
	section.Ordered[#section.Ordered + 1] = option

	function option:Set(text, silent)
		self.Value = text
		value.Text = tostring(text)
		if not silent then self.Callback(text) end
		return text
	end

	function option:Get()
		return self.Value
	end

	return option
end

Talis.Builders.Header = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec) }
	local margin = spec.Margin or 0
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, margin),
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
	if margin > 0 then
		New("Frame", { Size = UDim2.new(1, 0, 0, margin), BackgroundTransparency = 1, LayoutOrder = 3, Parent = row })
	end
	return row
end

Talis.Builders.Divider = function(section, spec)
	spec = type(spec) == "table" and spec or { Text = tostring(spec or "") }
	local hasText = spec.Text ~= nil and spec.Text ~= ""
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, (hasText and 22 or 10) + (spec.Margin or 0)),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local line = Hairline(row, "Hairline", 0.5)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	if hasText then
		local upper = string.upper(tostring(spec.Text))
		local pill = New("Frame", {
			Size = UDim2.fromOffset(measure(upper, 10, Talis.Fonts.Semibold).X + 22, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Talis.Theme.Raised,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = row,
		})
		Corner(pill, 9)
		Stroke(pill, "Stroke", 1, 0.35)
		Theme(pill, "Raised", "BackgroundColor3")
		local label = Text(pill, upper, 10, Talis.Fonts.Semibold, "Faint", Enum.TextXAlignment.Center)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.ZIndex = 3
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

Talis.Builders.Spacer = Talis.Builders.Space

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
	local value = math.clamp(tonumber(spec.Value) or spec.Default or min, min, max)

	local row, info = section:Row(spec.Desc and 46 or 36, spec.Name, spec.Desc, spec.Margin)
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
		Type = "Slider", Name = spec.Name, Desc = spec.Desc, Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Value = value, Min = min, Max = max, Step = step, Default = value,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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

	function option:SetMin(v)
		self.Min = tonumber(v) or self.Min
		self:Set(self.Value, true)
	end

	function option:SetMax(v)
		self.Max = tonumber(v) or self.Max
		self:Set(self.Value, true)
	end

	function option:SetRange(a, b)
		self.Min = tonumber(a) or self.Min
		self.Max = tonumber(b) or self.Max
		self:Set(self.Value, true)
	end

	function option:SetStep(v)
		self.Step = tonumber(v) or self.Step
		places = decimals(self.Step)
		self:Set(self.Value, true)
	end

	function option:SetSuffix(text)
		unit = tostring(text or "")
		self:Set(self.Value, true)
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

	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin)
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

	local chevron = Icon(pill, "chevron", 12, "Faint")
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -8, 0.5, 0)

	local option = {
		Type = multi and "MultiDropdown" or "Dropdown", Name = spec.Name, Desc = spec.Desc,
		Flag = spec.Flag, IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Default = spec.Value,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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

	function option:SetValues(list, keep)
		values = normalizeValues(list)
		if not keep then selected = {} end
		pillText.Text = summary()
	end

	function option:AddValues(list)
		local extra = normalizeValues(list)
		for index = 1, #extra do values[#values + 1] = extra[index] end
		pillText.Text = summary()
	end

	function option:RemoveValues(list)
		for index = 1, #list do
			local name = tostring(list[index])
			for position = #values, 1, -1 do
				if values[position].Name == name then table.remove(values, position) end
			end
			selected[name] = nil
		end
		pillText.Text = summary()
	end

	option.Refresh = option.SetValues

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
				tick = Icon(item, "check", 12, "Accent")
				tick.AnchorPoint = Vector2.new(1, 0.5)
				tick.Position = UDim2.new(1, -8, 0.5, 0)
			end
			Connect(item.MouseEnter, function() Tween(item, 0.1, { BackgroundTransparency = 0.7 }) end)
			Connect(item.MouseLeave, function() Tween(item, 0.1, { BackgroundTransparency = 1 }) end)
			Connect(item.MouseButton1Click, function()
				if multi then
					selected[entry.Name] = not selected[entry.Name]
					if selected[entry.Name] then
						if not tick then
							tick = Icon(item, "check", 12, "Accent")
							tick.AnchorPoint = Vector2.new(1, 0.5)
							tick.Position = UDim2.new(1, -8, 0.5, 0)
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
	option.Default = option.Value
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

Talis.Builders.Segmented = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local values = normalizeValues(spec.Values)
	local row, info = section:Row(30, spec.Name, spec.Desc, spec.Margin)
	if info.label then info.label.Size = UDim2.new(0.4, -8, 0, 15) end

	local holder = New("Frame", {
		Size = UDim2.new(0.6, -8, 0, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(holder, 5)
	Stroke(holder, "Stroke", 1, 0.6)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), Parent = holder })
	Pad(holder, 2, 2, 2, 2)

	local option = {
		Type = "Segmented", Name = spec.Name, Desc = spec.Desc, Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Value = tostring(spec.Value or (values[1] and values[1].Name) or ""),
		Default = spec.Value,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

	local buttons = {}
	local function paint()
		for index = 1, #buttons do
			local entry = buttons[index]
			local on = entry.Name == option.Value
			entry.Button.BackgroundTransparency = on and 0 or 1
			entry.Label.TextColor3 = on and Talis.Theme.AccentText or Talis.Theme.Muted
		end
	end

	for index = 1, #values do
		local entry = values[index]
		local button = New("TextButton", {
			Size = UDim2.new(1 / math.max(#values, 1), -2, 1, 0),
			BackgroundColor3 = Talis.Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = holder,
		})
		Corner(button, 4)
		local label = Text(button, entry.Name, 11, Talis.Fonts.Semibold, "Muted", Enum.TextXAlignment.Center)
		label.Size = UDim2.new(1, 0, 1, 0)
		buttons[#buttons + 1] = { Name = entry.Name, Button = button, Label = label }
		Connect(button.MouseButton1Click, function()
			if option.Locked then return end
			option:Set(entry.Name)
		end)
	end

	function option:Set(value, silent)
		self.Value = tostring(value or "")
		Talis:SetFlag(self.Flag, self.Value)
		paint()
		if not silent then self.Callback(self.Value) end
		return self.Value
	end

	function option:Get()
		return self.Value
	end

	option:Set(option.Value, true)
	option.Default = option.Value
	return option
end

Talis.Builders.Input = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin)
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
		Type = "Input", Name = spec.Name, Desc = spec.Desc, Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Value = tostring(spec.Value or ""), Default = tostring(spec.Value or ""),
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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
		option:Set(box.Text, true)
		option.Callback(option.Value, enterPressed or nil)
	end)

	Talis:SetFlag(option.Flag, option.Value)
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

local DEFAULT_BLACKLIST = { "W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote" }

Talis.Builders.Keybind = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Desc and 40 or 30, spec.Name, spec.Desc, spec.Margin)
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
		Type = "Keybind", Name = spec.Name, Desc = spec.Desc, Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Value = value, Mode = mode, Mouse = spec.Mouse ~= false,
		Blacklist = spec.Blacklist or DEFAULT_BLACKLIST,
		Listening = false, Pressed = false, Toggled = false, Default = value,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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

	function option:GetKey()
		return self.Value
	end

	function option:SetKey(key, mode)
		if mode then self.Mode = mode end
		return self:Set(key)
	end

	function option:OnClick(fn)
		self.ClickCallback = fn
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
					option.Listening = false
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
			playSound("bind")
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
			if option.ClickCallback then safeCall(option.ClickCallback, true) end
		else
			option.Toggled = not option.Toggled
			Talis:SetFlag(option.Flag .. "/Toggled", option.Toggled)
			paint()
			option.Callback(option.Value, true, option.Toggled)
			if option.ClickCallback then safeCall(option.ClickCallback, option.Toggled) end
		end
	end)

	Connect(UIS.InputEnded, function(input, processed)
		if processed or option.Mode ~= "Hold" or not option.Pressed then return end
		if not matches(input) then return end
		option.Pressed = false
		paint()
		option.Callback(option.Value, false, option.Toggled)
		if option.ClickCallback then safeCall(option.ClickCallback, false) end
	end)

	paint()
	if spec.Tip then section:Tooltip(row, spec.Tip) end
	return option
end

Talis.Builders.Colorpicker = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(30, spec.Name, spec.Desc, spec.Margin)
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
		Type = "Colorpicker", Name = spec.Name, Desc = spec.Desc, Flag = spec.Flag,
		IgnoreFlag = spec.IgnoreFlag, ShowWhen = spec.ShowWhen,
		section = section, Callback = spec.Callback or function() end,
		Value = { 0.15, 0.7, 0.85, 1, false },
		Default = { 0.15, 0.7, 0.85, 1, false },
	}
	if typeof(spec.Value) == "Color3" then
		local h, s, v = spec.Value:ToHSV()
		option.Value[1], option.Value[2], option.Value[3] = h, s, v
	elseif type(spec.Value) == "table" then
		for index = 1, 5 do
			if spec.Value[index] ~= nil then option.Value[index] = spec.Value[index] end
		end
	end
	option.Default = { option.Value[1], option.Value[2], option.Value[3], option.Value[4], false }
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option

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

	function option:GetColor()
		return toColor()
	end

	option.Color = option.GetColor

	function option:AddColor(color)
		option:Set(color)
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
	local row, info = section:Row(38, spec.Name, spec.Desc, spec.Margin)
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

	local option = {
		Type = "Progress", Name = spec.Name, section = section, Value = 0,
		Row = row, Window = section.Window, Callback = function() end,
		ShowWhen = spec.ShowWhen, Default = 0,
	}
	Decorate(option, info, section.Window)
	section.Ordered[#section.Ordered + 1] = option

	function option:Set(value, silent)
		local alpha = clamp01(value)
		self.Value = alpha
		Tween(fill, 0.16, { Size = UDim2.new(alpha, 0, 1, 0) })
		percent.Text = string.format("%d%%", math.floor(alpha * 100 + 0.5))
		if not silent then self.Callback(alpha) end
		return alpha
	end

	function option:Get()
		return self.Value
	end

	return option
end

Talis.Builders.Image = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local row, info = section:Row(spec.Height or 120, spec.Name, spec.Desc, spec.Margin)
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, (spec.Height or 120) - 20),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = row,
	})
	Corner(holder, 6)
	Stroke(holder, "Stroke", 1, 0.6)
	local image = New("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = spec.Source and Talis:LoadImage(spec.Source, "element") or "",
		ScaleType = Enum.ScaleType.Crop,
		Parent = holder,
	})

	local option = { Type = "Image", Name = spec.Name, section = section, Row = row, Window = section.Window, Callback = function() end, ShowWhen = spec.ShowWhen }
	Decorate(option, info, section.Window)
	section.Ordered[#section.Ordered + 1] = option

	function option:SetSource(source)
		image.Image = Talis:LoadImage(source, "element")
	end

	return option
end

Talis.Builders.Console = function(section, spec)
	spec = type(spec) == "table" and spec or {}
	local window = section.Window
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, spec.Height or 150),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Talis.Theme.Window,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = row,
	})
	Corner(holder, 6)
	Stroke(holder, "Stroke", 1, 0.5)
	local scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, -12, 1, -12),
		Position = UDim2.new(0, 6, 0, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Talis.Theme.Faint,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = holder,
	})
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

	local option = { Type = "Console", Name = spec.Name, section = section, Row = row, Window = window, Callback = function() end, Lines = {}, ShowWhen = spec.ShowWhen }
	Decorate(option, { row = row, section = section }, window)
	section.Ordered[#section.Ordered + 1] = option

	local COLORS = { Info = "Muted", Success = "Success", Warn = "Ember", Error = "Danger" }

	function option:Append(text, level)
		level = level or "Info"
		local line = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = tostring(text),
			TextSize = 11,
			FontFace = Talis.Fonts.Mono,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = #self.Lines + 1,
			Parent = scroll,
		})
		Theme(line, COLORS[level] or "Muted", "TextColor3")
		self.Lines[#self.Lines + 1] = line
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
		end)
		return line
	end

	function option:Log(text) return self:Append(text, "Info") end
	function option:Success(text) return self:Append(text, "Success") end
	function option:Warn(text) return self:Append(text, "Warn") end
	function option:Error(text) return self:Append(text, "Error") end

	function option:Clear()
		for index = 1, #self.Lines do
			self.Lines[index]:Destroy()
		end
		self.Lines = {}
	end

	function option:Copy()
		local out = {}
		for index = 1, #self.Lines do
			out[#out + 1] = self.Lines[index].Text
		end
		local text = table.concat(out, "\n")
		if setclipboard then setclipboard(text) end
		window:Notify({ Title = "Console", Content = "Copied " .. #out .. " lines.", Kind = "Success" })
		return text
	end

	return option
end

Talis.Builders.PlayerList = function(section, spec)
	spec = type(spec) == "table" and spec or {}
	local window = section.Window
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, spec.Height or 160),
		BackgroundTransparency = 1,
		LayoutOrder = section:Next(),
		Parent = section.Group,
	})
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = row,
	})
	Corner(holder, 6)
	Stroke(holder, "Stroke", 1, 0.5)
	local scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, -12, 1, -12),
		Position = UDim2.new(0, 6, 0, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Talis.Theme.Faint,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = holder,
	})
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

	local option = { Type = "PlayerList", Name = spec.Name, section = section, Row = row, Window = window, Callback = function() end, Rows = {}, ShowWhen = spec.ShowWhen }
	Decorate(option, { row = row, section = section }, window)
	section.Ordered[#section.Ordered + 1] = option

	function option:Refresh()
		for index = 1, #self.Rows do
			self.Rows[index]:Destroy()
		end
		self.Rows = {}
		local list = Players:GetPlayers()
		table.sort(list, function(a, b) return a.Name < b.Name end)
		for index = 1, #list do
			local player = list[index]
			local line = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = Talis.Theme.Hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = scroll,
			})
			Corner(line, 4)
			local name = Text(line, player.Name, 12, Talis.Fonts.Regular, "Text")
			name.Position = UDim2.new(0, 8, 0, 0)
			name.Size = UDim2.new(1, -60, 1, 0)
			local tag = Text(line, player == LP and "you" or (index == 1 and "host" or ""), 10, Talis.Fonts.Regular, "Faint", Enum.TextXAlignment.Right)
			tag.AnchorPoint = Vector2.new(1, 0.5)
			tag.Position = UDim2.new(1, -8, 0.5, 0)
			tag.Size = UDim2.new(0, 50, 1, 0)
			Connect(line.MouseEnter, function() Tween(line, 0.1, { BackgroundTransparency = 0.7 }) end)
			Connect(line.MouseLeave, function() Tween(line, 0.1, { BackgroundTransparency = 1 }) end)
			if spec.OnSelect then
				Connect(line.MouseButton1Click, function() safeCall(spec.OnSelect, player) end)
			end
			self.Rows[#self.Rows + 1] = line
		end
	end

	option:Refresh()
	Connect(Players.PlayerAdded, function() option:Refresh() end)
	Connect(Players.PlayerRemoving, function() option:Refresh() end)

	return option
end

--[[ CUSTOM + UI KIT ]]

function Talis:UIKit(window)
	local ui = {}
	ui.Window = window
	ui.Theme = Talis.Theme
	ui.Accent = function() return Talis.Theme.Accent end
	ui.Frame = function(props)
		props = props or {}
		return New("Frame", props)
	end
	ui.Text = function(props)
		props = props or {}
		local label = New("TextLabel", props)
		label.BackgroundTransparency = props.BackgroundTransparency or 1
		label.FontFace = props.FontFace or Talis.Fonts.Regular
		return label
	end
	ui.Button = function(props)
		props = props or {}
		local button = New("TextButton", props)
		button.AutoButtonColor = false
		button.FontFace = props.FontFace or Talis.Fonts.Semibold
		return button
	end
	ui.Icon = function(name, size, color, props)
		props = props or {}
		props.Image = Talis.Icons[name] or name
		props.Size = props.Size or UDim2.fromOffset(size or 14, size or 14)
		local icon = New("ImageLabel", props)
		icon.BackgroundTransparency = 1
		icon.ImageColor3 = color or Talis.Theme.Text
		return icon
	end
	ui.Corner = Corner
	ui.Stroke = function(object, transparency) return Stroke(object, "Stroke", 1, transparency or 0.5) end
	ui.Tween = Tween
	ui.Font = function(weight)
		return weight == "bold" and Talis.Fonts.Bold or weight == "semi" and Talis.Fonts.Semibold or weight == "med" and Talis.Fonts.Semibold or Talis.Fonts.Regular
	end
	ui.Tip = function(object, text) return window:AddTooltip(object, text) end
	ui.Play = function(name) playSound(name) end
	ui.Connect = function(signal, fn) return Connect(signal, fn) end
	ui.Cleanup = function(fn) table.insert(window.Cleanups, fn) end
	ui.OnAccent = function(fn) table.insert(Talis.ThemeListeners, function() fn(Talis.Theme.Accent) end) end
	ui.Get = function() return nil end
	ui.Set = function() end
	ui.OnChanged = function() end
	return ui
end

Talis.Builders.Custom = function(section, spec)
	spec = type(spec) == "table" and spec or { Name = tostring(spec) }
	local window = section.Window
	local row, info = section:Row(spec.Height or 30, spec.Name, spec.Desc, spec.Margin)
	local frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, (spec.Height or 30) - (spec.Name and 18 or 0)),
		Position = UDim2.new(0, 0, 0, spec.Name and 18 or 0),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local ui = Talis:UIKit(window)
	local option = {
		Type = "Custom", Name = spec.Name, section = section, Row = row, Window = window,
		Callback = function() end, ShowWhen = spec.ShowWhen, Frame = frame,
	}
	Register(option)
	Decorate(option, info, window)
	section.Ordered[#section.Ordered + 1] = option
	if spec.Build then safeCall(spec.Build, frame, ui, option) end
	return option
end

function Talis:RegisterElement(name, spec)
	spec = spec or {}
	Talis.Builders[name] = function(section, elementSpec)
		elementSpec = type(elementSpec) == "table" and elementSpec or { Name = tostring(elementSpec) }
		local window = section.Window
		local row, info = section:Row(spec.Height or 30, elementSpec.Name, elementSpec.Desc, elementSpec.Margin)
		local frame = New("Frame", {
			Size = UDim2.new(1, 0, 0, (spec.Height or 30) - (elementSpec.Name and 18 or 0)),
			Position = UDim2.new(0, 0, 0, elementSpec.Name and 18 or 0),
			BackgroundTransparency = 1,
			Parent = row,
		})
		local option = {
			Type = name, Name = elementSpec.Name, section = section, Row = row, Window = window,
			Callback = elementSpec.Callback or function() end, Value = elementSpec.Default, Default = elementSpec.Default,
			ShowWhen = elementSpec.ShowWhen, Flag = elementSpec.Flag, IgnoreFlag = elementSpec.IgnoreFlag,
		}
		Register(option)
		Decorate(option, info, window)
		section.Ordered[#section.Ordered + 1] = option

		local ui = Talis:UIKit(window)
		ui.Get = function() return option.Value end
		ui.Set = function(value, silent)
			option.Value = value
			Talis:SetFlag(option.Flag, value)
			if not silent then option.Callback(value) end
		end
		ui.OnChanged = function(fn) option:OnChanged(fn) end
		if spec.Build then safeCall(spec.Build, frame, ui, elementSpec) end
		return option
	end
	return Talis.Builders[name]
end

--[[ CONFIG ]]

local function configFolder() return path(Talis.Root, "configs") end
local function configPath(name) return path(configFolder(), name .. ".json") end
local function autoloadPath() return path(Talis.Root, "autoload.json") end

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
			if name and name:sub(-5) == ".json" then out[#out + 1] = name:sub(1, -6) end
		end
	end)
	if not ok then return {} end
	table.sort(out)
	return out
end

function Talis:BuildConfigData()
	local window = self.ActiveWindow
	local data = { Version = self.Version, Flags = {}, Extra = self.ConfigExtra or {} }
	for flag, option in next, self.Options do
		if option.Flag == flag and option.Window == window and not option.IgnoreFlag and flag:sub(1, 7) ~= "config/" then
			local value = self.Flags[flag]
			if value ~= nil then data.Flags[flag] = value end
		end
	end
	return data
end

function Talis:ApplyConfigData(data)
	if type(data) ~= "table" then return false end
	local window = self.ActiveWindow
	for flag, value in next, data.Flags or {} do
		local option = self.Options[flag]
		if option and option.Window == window then
			if option.Set then pcall(option.Set, option, value, true) else self:SetFlag(flag, value) end
		end
	end
	if type(data.Extra) == "table" then
		self.ConfigExtra = data.Extra
	end
	return true
end

function Talis:SaveConfig(name)
	if not ensureFolders() or not name or name == "" then return false end
	local ok = pcall(function()
		writefile(configPath(name), HttpService:JSONEncode(self:BuildConfigData()))
	end)
	return ok
end

function Talis:LoadConfig(name)
	if not ensureFolders() or not name or name == "" then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(configPath(name))) end)
	if not ok or type(data) ~= "table" then return false end
	return self:ApplyConfigData(data)
end

function Talis:DeleteConfig(name)
	if not ensureFolders() or not name then return end
	pcall(function() delfile(configPath(name)) end)
	if self:GetAutoload() == name then self:ClearAutoload() end
end

function Talis:GetAutoload()
	if not ensureFolders() then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(autoloadPath())) end)
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
	return pcall(function() writefile(autoloadPath(), HttpService:JSONEncode(data)) end)
end

function Talis:ClearAutoload()
	if not ensureFolders() then return end
	local data = {}
	pcall(function()
		local parsed = HttpService:JSONDecode(readfile(autoloadPath()))
		if type(parsed) == "table" then data = parsed end
	end)
	data[tostring(game.GameId)] = nil
	pcall(function() writefile(autoloadPath(), HttpService:JSONEncode(data)) end)
end

function Talis:ApplyAutoload()
	local name = self:GetAutoload()
	if name and table.find(self:GetConfigs(), name) then return self:LoadConfig(name) end
	return false
end

Talis.Config = {}

function Talis.Config.Save(name) return Talis:SaveConfig(name) end
function Talis.Config.Load(name) return Talis:LoadConfig(name) end
function Talis.Config.Delete(name) return Talis:DeleteConfig(name) end
function Talis.Config.List() return Talis:GetConfigs() end
function Talis.Config.SetAutoload(name) return Talis:SetAutoload(name) end
function Talis.Config.GetAutoload() return Talis:GetAutoload() end
function Talis.Config.ResetAll() return Talis:ResetAll() end

function Talis.Config.Set(key, value)
	Talis.ConfigExtra = Talis.ConfigExtra or {}
	Talis.ConfigExtra[key] = value
end

function Talis.Config.Get(key, default)
	Talis.ConfigExtra = Talis.ConfigExtra or {}
	local value = Talis.ConfigExtra[key]
	if value == nil then return default end
	return value
end

function Talis.Config.Export()
	local ok, code = pcall(function()
		return HttpService:JSONEncode(Talis:BuildConfigData())
	end)
	if not ok then return "" end
	return code
end

function Talis.Config.Import(code)
	local ok, data = pcall(function() return HttpService:JSONDecode(code) end)
	if not ok or type(data) ~= "table" then return false end
	return Talis:ApplyConfigData(data)
end

--[[ UI SETTINGS ]]

function Talis:SaveUISettings()
	if not FS.ok then return end
	pcall(function()
		if not isfolder(self.Root) then makefolder(self.Root) end
		writefile(path(self.Root, "ui.json"), HttpService:JSONEncode(self.UISettings))
	end)
end

function Talis:LoadUISettings()
	if not FS.ok then return end
	pcall(function()
		local file = path(self.Root, "ui.json")
		if not isfile(file) then return end
		local data = HttpService:JSONDecode(readfile(file))
		if type(data) ~= "table" then return end
		for key, value in next, data do
			if self.UISettings[key] ~= nil or key == "Accent" then self.UISettings[key] = value end
		end
	end)
end

--[[ WATERMARK / OVERLAYS ]]

Talis.WatermarkParts = {}

function Talis:SetWatermark(config)
	config = config or {}
	local window = self.ActiveWindow
	if not window then return end

	self.UISettings.WatermarkText = config.Text or self.UISettings.WatermarkText
	self.UISettings.Watermark = config.Visible ~= false

	if not window.Mark then
		window.Mark = New("Frame", {
			Position = UDim2.new(0, 14, 0, 14),
			Size = UDim2.fromOffset(10, 22),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 70,
			Parent = window.Root,
		})
		Corner(window.Mark, 6)
		Stroke(window.Mark, "Accent", 1, 0.7)
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = window.Mark })
		Pad(window.Mark, 0, 12, 0, 12)
		window.MarkTitle = Text(window.Mark, "", 12, self.Fonts.Semibold, "Text")
		window.MarkTitle.Size = UDim2.new(0, 0, 1, 0)
		window.MarkTitle.AutomaticSize = Enum.AutomaticSize.X
		window.MarkTitle.LayoutOrder = 1
	end

	window.Mark.Visible = self.UISettings.Watermark
	window.MarkTitle.Text = tostring(self.UISettings.WatermarkText)
	return window.Mark
end

function Talis:AddWatermarkPart(key, spec)
	spec = spec or {}
	local window = self.ActiveWindow
	if not window or not window.Mark then return end
	if window.MarkParts and window.MarkParts[key] then window.MarkParts[key]:Destroy() end
	window.MarkParts = window.MarkParts or {}
	local label = Text(window.Mark, spec.Text or "", 11, self.Fonts.Regular, spec.Color or "Muted")
	label.Size = UDim2.new(0, 0, 1, 0)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = #window.Mark:GetChildren() + 1
	window.MarkParts[key] = label
	if spec.Get then
		task.spawn(function()
			while label.Parent do
				label.Text = tostring(spec.Get())
				task.wait(1)
			end
		end)
	end
	return label
end

function Talis:RemoveWatermarkPart(key)
	local window = self.ActiveWindow
	if not window or not window.MarkParts then return end
	if window.MarkParts[key] then
		window.MarkParts[key]:Destroy()
		window.MarkParts[key] = nil
	end
end

function Talis:Keystrokes(enabled)
	local window = self.ActiveWindow
	if not window then return end

	self.UISettings.Keystrokes = enabled ~= false
	if enabled == false then
		if window.KeyDisplay then window.KeyDisplay.Visible = false end
		return
	end
	if not window.KeyDisplay then
		local holder = New("Frame", {
			Position = UDim2.new(0, 14, 1, -60),
			Size = UDim2.fromOffset(120, 46),
			BackgroundTransparency = 1,
			ZIndex = 70,
			Parent = window.Root,
		})
		window.KeyDisplay = holder
		local keys = { "W", "A", "S", "D", "Space" }
		local frames = {}
		for index = 1, #keys do
			local key = keys[index]
			local box = New("TextLabel", {
				Size = UDim2.fromOffset(key == "Space" and 62 or 24, 20),
				Position = UDim2.new(0, ((index - 1) % 3) * 26, 0, math.floor((index - 1) / 3) * 22),
				BackgroundColor3 = self.Theme.Raised,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Text = key,
				TextSize = 10,
				FontFace = self.Fonts.Semibold,
				TextColor3 = self.Theme.Muted,
				ZIndex = 71,
				Parent = holder,
			})
			Corner(box, 4)
			frames[key] = box
		end
		window.KeyFrames = frames
		Connect(UIS.InputBegan, function(input, processed)
			if processed then return end
			local frame = frames[input.KeyCode and input.KeyCode.Name]
			if frame then
				frame.BackgroundTransparency = 0
				frame.TextColor3 = self.Theme.Text
			end
		end)
		Connect(UIS.InputEnded, function(input)
			local frame = frames[input.KeyCode and input.KeyCode.Name]
			if frame then
				frame.BackgroundTransparency = 0.4
				frame.TextColor3 = self.Theme.Muted
			end
		end)
	end
	window.KeyDisplay.Visible = true
end

function Talis:KeybindList(enabled)
	local window = self.ActiveWindow
	if not window then return end

	self.UISettings.KeybindList = enabled ~= false
	if not window.KeyList then
		local holder = New("Frame", {
			Position = UDim2.new(0, 14, 0, 46),
			Size = UDim2.fromOffset(160, 10),
			BackgroundColor3 = self.Theme.Raised,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 70,
			Parent = window.Root,
		})
		Corner(holder, 6)
		Stroke(holder, "Stroke", 1, 0.6)
		Pad(holder, 8, 10, 8, 10)
		New("UIListLayout", { Padding = UDim.new(0, 3), Parent = holder })
		window.KeyList = holder
		window.KeyListRows = {}
		local function rebuild()
			for index = 1, #window.KeyListRows do window.KeyListRows[index]:Destroy() end
			window.KeyListRows = {}
			for flag, option in next, Talis.Options do
				if option.Type == "Keybind" and option.Value and option.Value ~= "NONE" then
					local line = New("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = holder })
					local name = Text(line, option.Name, 11, Talis.Fonts.Regular, "Muted")
					name.Size = UDim2.new(1, -60, 1, 0)
					local key = Text(line, option.Value, 11, Talis.Fonts.Mono, "Text", Enum.TextXAlignment.Right)
					key.Size = UDim2.new(0, 56, 1, 0)
					key.AnchorPoint = Vector2.new(1, 0)
					key.Position = UDim2.new(1, 0, 0, 0)
					window.KeyListRows[#window.KeyListRows + 1] = line
				end
			end
		end
		window.KeyListRebuild = rebuild
		rebuild()
	end
	window.KeyList.Visible = enabled ~= false
end

--[[ PARTICLES ]]

function Talis:Particles(style)
	style = style or "Off"
	Talis.UISettings.Particles = style
	local window = self.ActiveWindow
	if not window then return end
	if window.ParticleObjects then
		for index = 1, #window.ParticleObjects do window.ParticleObjects[index]:Destroy() end
	end
	window.ParticleObjects = {}
	if style == "Off" then return end

	local count = style == "Sparkles" and 30 or 45
	for index = 1, count do
		local dot = New("Frame", {
			Size = UDim2.fromOffset(style == "Dust" and 2 or 3, style == "Dust" and 2 or 3),
			BackgroundColor3 = Talis.Theme.AccentSoft,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			Parent = window.Particles,
		})
		Corner(dot, 3)
		window.ParticleObjects[#window.ParticleObjects + 1] = dot
	end

	if not window.ParticleLoop then
		window.ParticleLoop = true
		Talis:Loop(function(dt)
			if not window.Particles or not window.Particles.Parent then return end
			for index = 1, #(window.ParticleObjects or {}) do
				local dot = window.ParticleObjects[index]
				if dot.Parent then
					local pos = dot.Position
					local speed = style == "Sparkles" and 0.1 or 0.06
					local y = pos.Y.Scale + speed * (dt or 0.016) * 8
					if y > 1 then y = -0.02 end
					dot.Position = UDim2.new(pos.X.Scale, 0, y, 0)
					if style == "Sparkles" then
						dot.BackgroundTransparency = 0.2 + math.abs(math.sin(os.clock() * 2 + index)) * 0.6
					end
				end
			end
		end)
	end
end

--[[ WIDGET ]]

function Talis:Widget(spec)
	spec = spec or {}
	local window = self.ActiveWindow
	local widget = { Rows = {}, Order = 0 }

	local frame = New("Frame", {
		Position = spec.Position or UDim2.new(0, 16, 0.5, -60),
		Size = UDim2.fromOffset(spec.Width or 170, 10),
		BackgroundColor3 = Talis.Theme.Raised,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 65,
		Visible = spec.Visible ~= false,
		Parent = window and window.Root or game:GetService("CoreGui"),
	})
	Corner(frame, 8)
	Stroke(frame, "Stroke", 1, 0.5)
	Pad(frame, 10, 12, 10, 12)
	New("UIListLayout", { Padding = UDim.new(0, 4), Parent = frame })

	local title = Text(frame, spec.Name or "Widget", 12, Talis.Fonts.Semibold, "Text")
	title.Size = UDim2.new(1, 0, 0, 16)
	title.LayoutOrder = 0

	local body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame })
	New("UIListLayout", { Padding = UDim.new(0, 3), Parent = body })

	widget.Frame = frame

	local dragging, dragStart, dragOrigin
	Connect(title.InputBegan, function(input)
		if not isPress(input) then return end
		dragging = true
		dragStart = input.Position
		dragOrigin = frame.Position
	end)
	Connect(UIS.InputChanged, function(input)
		if not dragging or not isMove(input) then return end
		local delta = input.Position - dragStart
		frame.Position = UDim2.fromOffset(dragOrigin.X.Offset + delta.X, dragOrigin.Y.Offset + delta.Y)
	end)
	Connect(UIS.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	function widget:SetRow(name, value, color)
		local row = self.Rows[name]
		if not row then
			local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = body })
			local label = Text(holder, name, 11, Talis.Fonts.Regular, "Muted")
			label.Size = UDim2.new(1, -50, 1, 0)
			local val = Text(holder, "", 11, Talis.Fonts.Mono, "Text", Enum.TextXAlignment.Right)
			val.Size = UDim2.new(0, 50, 1, 0)
			val.AnchorPoint = Vector2.new(1, 0)
			val.Position = UDim2.new(1, 0, 0, 0)
			row = { Holder = holder, Value = val }
			self.Rows[name] = row
		end
		row.Value.Text = tostring(value)
		if color then row.Value.TextColor3 = color end
	end

	function widget:RemoveRow(name)
		local row = self.Rows[name]
		if row then row.Holder:Destroy() self.Rows[name] = nil end
	end

	function widget:Clear()
		for name in next, self.Rows do self:RemoveRow(name) end
	end

	function widget:SetTitle(text) title.Text = tostring(text) end
	function widget:SetVisible(state) frame.Visible = state ~= false end
	function widget:Destroy() frame:Destroy() end

	return widget
end

--[[ KEY SYSTEM ]]

function Talis:KeySystem(config)
	config = config or {}
	local keys = config.Keys or {}
	if #keys == 0 then return true end
	local window = self.ActiveWindow
	if not window then return false end

	local passed = true
	for index = 1, #keys do
		local key = tostring(keys[index]):lower()
		local missing = pcall(function()
			if not isfile(path(self.Root, "keys.json")) then return end
			local data = HttpService:JSONDecode(readfile(path(self.Root, "keys.json")))
			if type(data) == "table" and data[key] then error("saved") end
		end)
		if missing then
			passed = false
			window:Prompt({
				Title = "Key System",
				Content = config.Content or "Enter the key to continue.",
				Placeholder = "Key",
				Validate = function(text)
					if text:lower() == key then return true end
					return false, "Wrong key."
				end,
				Callback = function()
					pcall(function()
						local data = {}
						if isfile(path(self.Root, "keys.json")) then
							local parsed = HttpService:JSONDecode(readfile(path(self.Root, "keys.json")))
							if type(parsed) == "table" then data = parsed end
						end
						data[key] = true
						writefile(path(self.Root, "keys.json"), HttpService:JSONEncode(data))
					end)
					window:Notify({ Title = "Key System", Content = "Key accepted.", Kind = "Success" })
				end,
			})
			break
		end
	end
	return passed
end

--[[ TEMPLATES ]]

function Talis:ApplyTemplate(tab, name)
	name = name or "Player"
	if name == "Player" then
		local section = tab:Section({ Name = "Movement" })
		local humanoid = function()
			local char = LP.Character
			return char and char:FindFirstChildOfClass("Humanoid")
		end
		section:Slider({
			Name = "Walk Speed", Min = 8, Max = 200, Value = 16, Step = 1, Flag = "tpl_speed",
			Callback = function(v) local h = humanoid() if h then h.WalkSpeed = v end end,
		})
		section:Slider({
			Name = "Jump Power", Min = 30, Max = 300, Value = 50, Step = 1, Flag = "tpl_jump",
			Callback = function(v) local h = humanoid() if h then h.JumpPower = v end end,
		})
		section:Toggle({
			Name = "Infinite Jump", Flag = "tpl_infjump",
			Callback = function(on) Talis.Flags.tpl_infjump = on end,
		})
		section:Toggle({
			Name = "Noclip", Flag = "tpl_noclip",
			Callback = function(on) Talis.Flags.tpl_noclip = on end,
		})
		section:Button({
			Name = "Reset Character", Callback = function()
				local char = LP.Character
				if char then char:BreakJoints() end
			end,
		})
		local camera = tab:Section({ Name = "Camera" })
		camera:Slider({
			Name = "Field of View", Min = 40, Max = 120, Value = 70, Step = 1, Flag = "tpl_fov",
			Callback = function(v) local cam = workspace.CurrentCamera if cam then cam.FieldOfView = v end end,
		})
		return tab
	end

	if name == "World" then
		local section = tab:Section({ Name = "Lighting" })
		section:Slider({
			Name = "Time of Day", Min = 0, Max = 24, Value = 12, Step = 0.5, Flag = "tpl_time",
			Callback = function(v) Lighting.ClockTime = v end,
		})
		section:Slider({
			Name = "Brightness", Min = 0, Max = 5, Value = 2, Step = 0.1, Flag = "tpl_bright",
			Callback = function(v) Talis:Patch(Lighting, "Brightness", v) end,
		})
		section:Slider({
			Name = "Fog End", Min = 100, Max = 5000, Value = 1000, Step = 50, Flag = "tpl_fog",
			Callback = function(v) Talis:Patch(Lighting, "FogEnd", v) end,
		})
		section:Toggle({
			Name = "Fullbright", Flag = "tpl_full",
			Callback = function(on)
				if on then
					Talis:Patch(Lighting, "Ambient", Color3.new(1, 1, 1))
					Talis:Patch(Lighting, "OutdoorAmbient", Color3.new(1, 1, 1))
				else
					Talis:Restore(Lighting, "Ambient")
					Talis:Restore(Lighting, "OutdoorAmbient")
				end
			end,
		})
		return tab
	end

	if name == "Extras" then
		local section = tab:Section({ Name = "Overlays" })
		local crosshair, crosshair2
		section:Toggle({
			Name = "Crosshair", Flag = "tpl_cross",
			Callback = function(on)
				if on then
					crosshair = Talis.Overlay:Line({ From = Vector2.new(viewport().X / 2 - 8, viewport().Y / 2), To = Vector2.new(viewport().X / 2 + 8, viewport().Y / 2) })
					crosshair2 = Talis.Overlay:Line({ From = Vector2.new(viewport().X / 2, viewport().Y / 2 - 8), To = Vector2.new(viewport().X / 2, viewport().Y / 2 + 8) })
				else
					if crosshair then Talis.Overlay:Remove(crosshair) end
					if crosshair2 then Talis.Overlay:Remove(crosshair2) end
				end
			end,
		})
		section:Toggle({
			Name = "FPS Counter", Flag = "tpl_fps",
			Callback = function(on)
				if on then
					local widget = Talis:Widget({ Name = "Performance" })
					Talis.FpsWidget = widget
					local frames = 0
					local last = os.clock()
					Talis:Loop(function()
						frames = frames + 1
						if os.clock() - last >= 1 then
							widget:SetRow("FPS", frames)
							frames = 0
							last = os.clock()
						end
					end)
				elseif Talis.FpsWidget then
					Talis.FpsWidget:Destroy()
					Talis.FpsWidget = nil
				end
			end,
		})
		return tab
	end

	if name == "Server" then
		local section = tab:Section({ Name = "Server" })
		local info = section:Info({ Name = "Players", Value = tostring(#Players:GetPlayers()) })
		section:Info({ Name = "Place Id", Value = tostring(game.PlaceId) })
		section:Info({ Name = "Job Id", Value = tostring(game.JobId):sub(1, 12) .. "..." })
		section:Button({
			Name = "Rejoin", Primary = true,
			Callback = function()
				game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
			end,
		})
		Talis:Loop(function()
			info:Set(tostring(#Players:GetPlayers()), true)
		end, 2)
		return tab
	end

	if name == "Tools" then
		local section = tab:Section({ Name = "Performance" })
		section:Toggle({
			Name = "FPS Unlock", Flag = "tpl_unlock",
			Callback = function(on)
				if setfpscap then setfpscap(on and 240 or 60) end
			end,
		})
		section:Button({
			Name = "Reset Camera",
			Callback = function()
				local cam = workspace.CurrentCamera
				if cam then cam.CameraType = Enum.CameraType.Custom end
			end,
		})
		return tab
	end

	return tab
end

--[[ SETTINGS PAGE ]]

local function configSection(window, tab)
	local section = tab:Section({ Name = "Configs" })
	local status = Text(section.Group, "no configs", 11, Talis.Fonts.Regular, "Faint")
	status.LayoutOrder = section:Next()
	local picker

	local function refresh()
		local list = Talis:GetConfigs()
		if picker then
			picker:SetValues(list)
			picker:Set(nil, true)
		end
		status.Text = #list == 0 and "no configs saved" or (#list .. " saved")
	end

	local nameInput = section:Input({ Name = "Name", Value = "default", Flag = "config/name", IgnoreFlag = true })

	section:Button({
		Name = "Save", Primary = true,
		Callback = function()
			local name = nameInput:Get()
			if name == "" then
				window:Notify({ Title = "Configs", Content = "Enter a name first.", Kind = "Warning" })
				return
			end
			if Talis:SaveConfig(name) then
				window:Notify({ Title = "Configs", Content = "Saved " .. name, Kind = "Success" })
			else
				window:Notify({ Title = "Configs", Content = "Save failed.", Kind = "Error" })
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
				window:Notify({ Title = "Configs", Content = "Loaded " .. name, Kind = "Success" })
			else
				window:Notify({ Title = "Configs", Content = "Load failed.", Kind = "Error" })
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

	section:Divider({ Text = "Share" })

	section:Button({
		Name = "Export to clipboard",
		Callback = function()
			local code = Talis.Config.Export()
			if setclipboard then setclipboard(code) end
			window:Notify({ Title = "Configs", Content = "Config code copied.", Kind = "Success" })
		end,
	})

	local importBox = section:Input({ Name = "Import code", Value = "", Placeholder = "paste code", IgnoreFlag = true })
	section:Button({
		Name = "Import",
		Callback = function()
			if Talis.Config.Import(importBox:Get()) then
				window:Notify({ Title = "Configs", Content = "Imported.", Kind = "Success" })
			else
				window:Notify({ Title = "Configs", Content = "Bad code.", Kind = "Error" })
			end
		end,
	})

	section:Divider({ Text = "Autoload" })

	section:Button({
		Name = "Autoload selected",
		Callback = function()
			local name = picker:Get()
			if not name then
				window:Notify({ Title = "Configs", Content = "Select a config first.", Kind = "Warning" })
				return
			end
			Talis:SetAutoload(name)
			window:Notify({ Title = "Configs", Content = "Autoload set.", Kind = "Success" })
		end,
	})

	section:Button({ Name = "Clear autoload", Callback = function() Talis:ClearAutoload() end })
	section:Button({ Name = "Refresh", Callback = refresh })
	refresh()

	return section
end

local baseWindow2 = Talis.Window

Talis.Window = function(self, config)
	local window = baseWindow2(self, config)
	Talis.ActiveWindow = window
	window.Cleanups = {}

	function window:SaveConfig(name) return Talis:SaveConfig(name) end
	function window:LoadConfig(name) return Talis:LoadConfig(name) end
	function window:DeleteConfig(name) return Talis:DeleteConfig(name) end
	function window:GetConfigs() return Talis:GetConfigs() end
	function window:SetAutoload(name) return Talis:SetAutoload(name) end
	function window:ClearAutoload() return Talis:ClearAutoload() end
	function window:ApplyAutoload() return Talis:ApplyAutoload() end
	function window:ConfigSection(tab) return configSection(self, tab) end
	function window:Eject() return Talis:Eject() end

	function window:ApplyLook()
		local theme = Talis.Themes[Talis.UISettings.Theme] or Talis.Themes.Huohuo
		local base = {}
		for key, value in next, theme do base[key] = value end
		if Talis.UISettings.Accent then
			local ok, color = pcall(Color3.fromHex, Talis.UISettings.Accent)
			if ok then base.Accent = color end
		end
		Talis:ApplyTheme(base)
		self.Theme = Talis.Theme
	end

	return window
end

function Talis:BuildSettings(window)
	if window.SettingsTab then return window.SettingsTab end
	local ui = self.UISettings
	local tab = window:Tab({ Name = "Settings", Icon = "settings" })
	window.SettingsTab = tab

	local look = tab:Section({ Name = "Appearance" })

	local themeNames = {}
	for name in next, Talis.Themes do themeNames[#themeNames + 1] = name end
	table.sort(themeNames)

	look:Dropdown({
		Name = "Theme", Values = themeNames, Value = ui.Theme, IgnoreFlag = true,
		Callback = function(value)
			ui.Theme = value
			window:ApplyLook()
			Talis:SaveUISettings()
		end,
	})

	look:Colorpicker({
		Name = "Accent",
		Value = ui.Accent and Color3.fromHex(ui.Accent) or Talis.Theme.Accent,
		IgnoreFlag = true,
		Callback = function(_, color)
			ui.Accent = color:ToHex()
			window:ApplyLook()
			Talis:SaveUISettings()
		end,
	})

	look:Slider({
		Name = "UI Scale", Min = 50, Max = 150, Step = 5, Unit = "%",
		Value = math.floor((ui.Scale or 1) * 100), IgnoreFlag = true,
		Callback = function(value)
			ui.Scale = value / 100
			window:SetScale(ui.Scale)
			Talis:SaveUISettings()
		end,
	})

	look:Slider({
		Name = "Corner Roundness", Min = 0, Max = 24, Step = 1, Unit = "px",
		Value = ui.Radius, IgnoreFlag = true,
		Callback = function(value)
			ui.Radius = value
			window:SetRadius(value)
			Talis:SaveUISettings()
		end,
	})

	look:Slider({
		Name = "Row Spacing", Desc = "Gap between every row",
		Min = 0, Max = 20, Step = 1, Unit = "px",
		Value = ui.Spacing, IgnoreFlag = true,
		Callback = function(value)
			ui.Spacing = value
			window:SetSpacing(value)
			Talis:SaveUISettings()
		end,
	})

	look:Toggle({
		Name = "Animations", Value = ui.Animations, IgnoreFlag = true,
		Callback = function(value)
			ui.Animations = value
			Talis.Animations = value
			Talis:SaveUISettings()
		end,
	})

	look:Segmented({
		Name = "Particles", Values = { "Off", "Snow", "Sparkles", "Dust" }, Value = ui.Particles, IgnoreFlag = true,
		Callback = function(value)
			ui.Particles = value
			Talis:Particles(value)
			Talis:SaveUISettings()
		end,
	})

	local bg = tab:Section({ Name = "Background" })

	local urlInput = bg:Input({
		Name = "Image Link", Value = ui.Background,
		Placeholder = "https://files.catbox.moe/x.png", IgnoreFlag = true,
	})

	local function applyBackground()
		ui.Background = urlInput:Get()
		if ui.Background == "" then
			window:SetBackground({ Image = "" })
		else
			window:SetBackground({
				Image = ui.Background,
				Transparency = 1 - (ui.BackgroundOpacity or 0.85),
				Scrim = ui.Scrim,
			})
		end
		Talis:SaveUISettings()
	end

	bg:Button({ Name = "Apply Background", Primary = true, Callback = applyBackground })
	bg:Button({
		Name = "Clear Background",
		Callback = function()
			urlInput:Set("")
			ui.Background = ""
			window:SetBackground({ Image = "" })
			Talis:SaveUISettings()
		end,
	})

	bg:Slider({
		Name = "Background Opacity", Min = 0, Max = 100, Step = 5, Unit = "%",
		Value = math.floor((ui.BackgroundOpacity or 0.85) * 100), IgnoreFlag = true,
		Callback = function(value)
			ui.BackgroundOpacity = value / 100
			if window.Image then window.Image.ImageTransparency = 1 - ui.BackgroundOpacity end
			Talis:SaveUISettings()
		end,
	})

	bg:Slider({
		Name = "Darken", Desc = "Keeps text readable over the image",
		Min = 0, Max = 90, Step = 5, Unit = "%",
		Value = math.floor((ui.Scrim or 0.45) * 100), IgnoreFlag = true,
		Callback = function(value)
			ui.Scrim = value / 100
			if window.Scrim then window.Scrim.BackgroundTransparency = ui.Scrim end
			Talis:SaveUISettings()
		end,
	})

	bg:Toggle({
		Name = "Dim Behind Menu", Value = ui.Dim, IgnoreFlag = true,
		Callback = function(value)
			ui.Dim = value
			Talis:SaveUISettings()
		end,
	})

	bg:Toggle({
		Name = "Blur Behind Menu", Value = ui.Blur, IgnoreFlag = true,
		Callback = function(value)
			ui.Blur = value
			Talis:SaveUISettings()
		end,
	})

	local behavior = tab:Section({ Name = "Behavior" })

	behavior:Keybind({
		Name = "Toggle Menu", Value = ui.ToggleKey, Mouse = false, IgnoreFlag = true,
		Callback = function(value)
			ui.ToggleKey = value
			local ok, key = pcall(function() return Enum.KeyCode[value] end)
			if ok and key then window:SetToggleKey(key) end
			Talis:SaveUISettings()
		end,
	})

	behavior:Segmented({
		Name = "Key Mode", Values = { "Toggle", "Hold" }, Value = ui.ToggleMode, IgnoreFlag = true,
		Callback = function(value)
			ui.ToggleMode = value
			window.ToggleMode = value
			Talis:SaveUISettings()
		end,
	})

	behavior:Toggle({
		Name = "Sounds", Value = ui.Sounds, IgnoreFlag = true,
		Callback = function(value)
			ui.Sounds = value
			Talis:SaveUISettings()
		end,
	})

	behavior:Toggle({
		Name = "Notifications", Value = ui.Notifications, IgnoreFlag = true,
		Callback = function(value)
			ui.Notifications = value
			Talis:SaveUISettings()
		end,
	})

	behavior:Dropdown({
		Name = "Notify Side",
		Values = { "Top Right", "Top Center", "Top Left", "Bottom Right", "Bottom Center", "Bottom Left" },
		Value = ui.NotifySide, IgnoreFlag = true,
		Callback = function(value)
			Talis:SetNotifySide(value)
			Talis:SaveUISettings()
		end,
	})

	behavior:Input({
		Name = "Watermark Text", Value = ui.WatermarkText, IgnoreFlag = true,
		Callback = function(value)
			ui.WatermarkText = value
			Talis:SetWatermark({ Text = value, Visible = ui.Watermark })
			Talis:SaveUISettings()
		end,
	})

	behavior:Toggle({
		Name = "Watermark", Value = ui.Watermark, IgnoreFlag = true,
		Callback = function(value)
			ui.Watermark = value
			Talis:SetWatermark({ Visible = value })
			Talis:SaveUISettings()
		end,
	})

	behavior:Toggle({
		Name = "Keystrokes", Value = ui.Keystrokes, IgnoreFlag = true,
		Callback = function(value)
			Talis:Keystrokes(value)
			Talis:SaveUISettings()
		end,
	})

	behavior:Toggle({
		Name = "Keybind List", Value = ui.KeybindList, IgnoreFlag = true,
		Callback = function(value)
			Talis:KeybindList(value)
			Talis:SaveUISettings()
		end,
	})

	local overlaySection = tab:Section({ Name = "Overlays" })
	overlaySection:Toggle({
		Name = "Show Errors", Value = Talis.ShowErrors, IgnoreFlag = true,
		Callback = function(value) Talis.ShowErrors = value end,
	})
	overlaySection:Button({
		Name = "Reset Everything",
		Callback = function() Talis:ResetAll() end,
	})
	overlaySection:Button({
		Name = "Eject",
		Callback = function() Talis:Eject() end,
	})

	window:ConfigSection(tab)

	local about = tab:Section({ Name = "About" })
	about:Label({
		Text = "Talis v" .. self.Version ..
			"\nTheme: " .. ui.Theme ..
			"\nAuthor: " .. (window.Author or "you") ..
			"\nUI settings save to talis/ui.json",
	})

	return tab
end

Talis:LoadUISettings()
Talis.Animations = Talis.UISettings.Animations

local finalWindow = Talis.Window

Talis.Window = function(self, config)
	config = type(config) == "table" and config or {}
	local window = finalWindow(self, config)

	window:ApplyLook()
	window:SetScale(config.Scale or Talis.UISettings.Scale or 1)
	window:SetSpacing(config.Spacing or Talis.UISettings.Spacing or Talis.Spacing)
	window:SetRadius(config.Radius or Talis.UISettings.Radius or 10)
	Talis.Animations = Talis.UISettings.Animations
	window.ToggleMode = config.ToggleMode or Talis.UISettings.ToggleMode

	local hasConfigBg = config.Background and config.Background.Image ~= nil and config.Background.Image ~= ""
	if not hasConfigBg and Talis.UISettings.Background ~= "" then
		window:SetBackground({
			Image = Talis.UISettings.Background,
			Transparency = 1 - (Talis.UISettings.BackgroundOpacity or 0.85),
			Scrim = Talis.UISettings.Scrim,
		})
	elseif hasConfigBg then
		window.BackgroundSource = config.Background.Image
	end

	if Talis.UISettings.Watermark then Talis:SetWatermark({ Visible = true }) end
	if Talis.UISettings.Keystrokes then Talis:Keystrokes(true) end
	if Talis.UISettings.KeybindList then Talis:KeybindList(true) end
	if Talis.UISettings.Particles ~= "Off" then Talis:Particles(Talis.UISettings.Particles) end
	Talis:SetNotifySide(Talis.UISettings.NotifySide)

	local ok, key = pcall(function() return Enum.KeyCode[Talis.UISettings.ToggleKey] end)
	if ok and key then window:SetToggleKey(key) end

	if config.Search ~= false then window:Search() end
	if config.Settings ~= false then self:BuildSettings(window) end

	-- built-in keybind list rebuild hook
	Talis:Loop(function()
		if window.KeyListRebuild and window.KeyList and window.KeyList.Visible then
			window.KeyListRebuild()
		end
	end, 1)

	return window
end

Talis.CreateWindow = Talis.Window

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
	return self:Square({ Position = position, Size = size, Color = color or Talis.Theme.Accent, Filled = filled == true })
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
		if self.Objects[index] == object then table.remove(self.Objects, index) end
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

function Talis.Overlay:Screen() return viewport() end

function Talis.Overlay:WorldToScreen(position)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local point, onScreen = camera:WorldToViewportPoint(position)
	if not onScreen then return nil end
	return Vector2.new(point.X, point.Y)
end

function Talis.Overlay:FOV(radius, color)
	local center = Vector2.new(viewport().X / 2, viewport().Y / 2)
	return self:Circle({ Position = center, Radius = radius, Color = color or Talis.Theme.Accent, Visible = true }), center
end

-- keep the "fire the flag" behaviour for built-in infinite jump / noclip
RunService.Heartbeat:Connect(function()
	if Talis.Flags.tpl_infjump then
		local char = LP.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall and UIS:IsKeyDown(Enum.KeyCode.Space) then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
	if Talis.Flags.tpl_noclip then
		local char = LP.Character
		if char then
			for _, part in next, char:GetDescendants() do
				if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
			end
		end
	end
end)

return Talis
