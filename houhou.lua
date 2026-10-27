local Huo = {}
Huo.Version = "1.0.0"
Huo.Instances = {}
Huo.Connections = {}
Huo.Flags = {}
Huo.FlagListeners = {}
Huo.Options = {}
Huo.Themed = {}
Huo.Notifications = {}
Huo.ConfigFolder = "huo_configs"
Huo.ConfigExt = ".huo"
Huo.Animations = true
Huo.KeyBlacklist = {Enum.KeyCode.Unknown, Enum.KeyCode.Escape}

local cloneref = cloneref or clonereference or function(i) return i end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
local LP = Players.LocalPlayer

local COMPAT = {
	hasFiles = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function" and typeof(listfiles) == "function",
	hasHook = typeof(hookmetamethod) == "function" and typeof(checkcaller) == "function",
	hasRawMeta = typeof(getrawmetatable) == "function" and typeof(setreadonly) == "function",
	isTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled,
	canSave = false,
}
COMPAT.canSave = COMPAT.hasFiles

Huo.Icons = {
	house = "rbxassetid://98755624629571",
	settings = "rbxassetid://80758916183665",
	search = "rbxassetid://121018724060431",
	x = "rbxassetid://110786993356448",
	check = "rbxassetid://93898873302694",
	chevronDown = "rbxassetid://134243273101015",
	chevronRight = "rbxassetid://92473583511724",
	chevronLeft = "rbxassetid://73780377692148",
	user = "rbxassetid://81589895647169",
	sword = "rbxassetid://124448418211665",
	swords = "rbxassetid://81872698913435",
	eye = "rbxassetid://100033680381365",
	eyeOff = "rbxassetid://135928786788378",
	palette = "rbxassetid://86350350950064",
	swatch = "rbxassetid://126786244872453",
	folder = "rbxassetid://80846616596607",
	save = "rbxassetid://126116963775616",
	trash = "rbxassetid://109843431391323",
	info = "rbxassetid://124560466474914",
	zap = "rbxassetid://130551565616516",
	crosshair = "rbxassetid://134242818164054",
	target = "rbxassetid://87563802520297",
	star = "rbxassetid://136141469398409",
	sparkle = "rbxassetid://111044800239623",
	sparkles = "rbxassetid://138635884129147",
	plus = "rbxassetid://111774323017047",
	minus = "rbxassetid://118026365011536",
	sun = "rbxassetid://110150589884127",
	moon = "rbxassetid://83380517901735",
	refresh = "rbxassetid://138133190015277",
	sliders = "rbxassetid://85538382643347",
	pointer = "rbxassetid://72322454962935",
	shield = "rbxassetid://110987169760162",
	box = "rbxassetid://101768155599700",
	file = "rbxassetid://90496405707281",
	maximize = "rbxassetid://73085922906397",
	minimize = "rbxassetid://116269596042539",
	bell = "rbxassetid://97392696311902",
	flame = "rbxassetid://98218034436456",
	ghost = "rbxassetid://113822048130017",
	gem = "rbxassetid://112904952151156",
	key = "rbxassetid://96510194465420",
	copy = "rbxassetid://78979572434545",
	link = "rbxassetid://131607023382430",
	ellipsis = "rbxassetid://140019550645825",
	grid = "rbxassetid://81344910161871",
	checkCircle = "rbxassetid://85262178816537",
	alert = "rbxassetid://125920361880643",
	power = "rbxassetid://96479131758775",
	paw = "rbxassetid://112218825427601",
	leaf = "rbxassetid://119951075637174",
	flower = "rbxassetid://86129438272762",
	book = "rbxassetid://125383279695672",
	code = "rbxassetid://107380207681249",
	terminal = "rbxassetid://106783148545356",
	wrench = "rbxassetid://112148279212860",
	lock = "rbxassetid://134724289526879",
	rocket = "rbxassetid://87412317685854",
	trending = "rbxassetid://81819858538839",
	activity = "rbxassetid://94212016861936",
	gauge = "rbxassetid://110273524101447",
	database = "rbxassetid://126791525623846",
	list = "rbxassetid://113179976918783",
	rows = "rbxassetid://112556185960101",
	columns = "rbxassetid://113004100221850",
	panel = "rbxassetid://97419752870313",
	play = "rbxassetid://135609604299893",
	pause = "rbxassetid://74873705394436",
	pencil = "rbxassetid://137986121120732",
	pipette = "rbxassetid://133167932934404",
	paint = "rbxassetid://124275586663284",
	dot = "rbxassetid://82947033619201",
	circlePlus = "rbxassetid://113157136350384",
	circleMinus = "rbxassetid://133556159576809",
	circleX = "rbxassetid://76821953846248",
	download = "rbxassetid://134814648082393",
	upload = "rbxassetid://138212042425501",
	corner = "rbxassetid://90473561177832",
	grip = "rbxassetid://137183678565296",
	wand = "rbxassetid://82546429942392",
	circle = "rbxassetid://130359823580534",
	square = "rbxassetid://86304921356806",
}

Huo.Themes = {
	Huohuo = {
		Window = Color3.fromHex("13100E"),
		Panel = Color3.fromHex("1A1512"),
		Card = Color3.fromHex("221B17"),
		Hover = Color3.fromHex("2C2320"),
		Stroke = Color3.fromHex("3B2C24"),
		Text = Color3.fromHex("F6EFE8"),
		SubText = Color3.fromHex("A8917F"),
		Accent = Color3.fromHex("FF4B2E"),
		AccentSoft = Color3.fromHex("FFB7A0"),
		AccentText = Color3.fromHex("FFFFFF"),
		Highlight = Color3.fromHex("FFD66A"),
		Shadow = Color3.fromHex("000000"),
	},
	Dark = {
		Window = Color3.fromHex("111113"),
		Panel = Color3.fromHex("17171A"),
		Card = Color3.fromHex("1E1E22"),
		Hover = Color3.fromHex("26262B"),
		Stroke = Color3.fromHex("2E2E34"),
		Text = Color3.fromHex("F2F2F5"),
		SubText = Color3.fromHex("8E8E96"),
		Accent = Color3.fromHex("4C8DFF"),
		AccentSoft = Color3.fromHex("A8C7FF"),
		AccentText = Color3.fromHex("FFFFFF"),
		Highlight = Color3.fromHex("FFD66A"),
		Shadow = Color3.fromHex("000000"),
	},
	Light = {
		Window = Color3.fromHex("F7F3EE"),
		Panel = Color3.fromHex("FFFFFF"),
		Card = Color3.fromHex("FFFFFF"),
		Hover = Color3.fromHex("F0EAE3"),
		Stroke = Color3.fromHex("E0D6CB"),
		Text = Color3.fromHex("241D19"),
		SubText = Color3.fromHex("8A7A6C"),
		Accent = Color3.fromHex("FF4B2E"),
		AccentSoft = Color3.fromHex("FFD9CE"),
		AccentText = Color3.fromHex("FFFFFF"),
		Highlight = Color3.fromHex("FFB300"),
		Shadow = Color3.fromHex("8A7A6C"),
	},
	Midnight = {
		Window = Color3.fromHex("0B0D14"),
		Panel = Color3.fromHex("11141D"),
		Card = Color3.fromHex("171B26"),
		Hover = Color3.fromHex("1F2433"),
		Stroke = Color3.fromHex("262C3D"),
		Text = Color3.fromHex("E8ECF5"),
		SubText = Color3.fromHex("7C869C"),
		Accent = Color3.fromHex("7A5CFF"),
		AccentSoft = Color3.fromHex("B9A6FF"),
		AccentText = Color3.fromHex("FFFFFF"),
		Highlight = Color3.fromHex("4ADEDE"),
		Shadow = Color3.fromHex("000000"),
	},
	Jade = {
		Window = Color3.fromHex("0C1412"),
		Panel = Color3.fromHex("111B18"),
		Card = Color3.fromHex("17241F"),
		Hover = Color3.fromHex("1E2E28"),
		Stroke = Color3.fromHex("26382F"),
		Text = Color3.fromHex("E7F2EC"),
		SubText = Color3.fromHex("7E988C"),
		Accent = Color3.fromHex("2FBF8F"),
		AccentSoft = Color3.fromHex("8FE6C6"),
		AccentText = Color3.fromHex("04120D"),
		Highlight = Color3.fromHex("FFD66A"),
		Shadow = Color3.fromHex("000000"),
	},
}

Huo.Theme = Huo.Themes.Huohuo

local FONT_FAMILY = "rbxasset://fonts/families/GothamSSm.json"
Huo.Fonts = {
	Regular = Font.new(FONT_FAMILY, Enum.FontWeight.Medium),
	Semibold = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FONT_FAMILY, Enum.FontWeight.Bold),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium),
}

local function isPress(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

local function isMove(input)
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch
end

local function measure(text, size, font)
	return TextService:GetTextSize(tostring(text), size or 14, font or Huo.Fonts.Regular, Vector2.new(9e9, 9e9)).X
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function New(class, props, parent)
	local inst = Instance.new(class)
	local par = parent
	if props then
		if props.Parent ~= nil then
			par = props.Parent
			props.Parent = nil
		end
		for k, v in next, props do inst[k] = v end
	end
	inst.Parent = par
	table.insert(Huo.Instances, inst)
	return inst
end

local function Corner(obj, radius)
	local c = New("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = obj})
	return c
end

local function Stroke(obj, color, thickness, transparency)
	local s = New("UIStroke", {
		Color = color or Huo.Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0.15,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = obj,
	})
	return s
end

local function Pad(obj, t, r, b, l)
	New("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
		PaddingLeft = UDim.new(0, l or r or t or 0),
		Parent = obj,
	})
end

local function Theme(obj, key, prop)
	Huo.Themed[obj] = {key = key, prop = prop or ((obj.ClassName == "TextLabel" or obj.ClassName == "TextBox") and "TextColor3") or (obj.ClassName == "ImageLabel" and "ImageColor3") or (obj.ClassName == "UIStroke" and "Color") or "BackgroundColor3"}
	return obj
end

local function Tween(obj, time, props, style, dir)
	local info = TweenInfo.new(Huo.Animations and time or 0, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function Connect(signal, name, fn)
	local c = signal:Connect(fn)
	table.insert(Huo.Connections, c)
	return c
end

local function Text(parent, text, size, font, colorKey, align, transparency)
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(text),
		TextSize = size or 14,
		FontFace = font or Huo.Fonts.Regular,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = transparency or 0,
		Parent = parent,
	})
	Theme(label, colorKey or "Text", "TextColor3")
	return label
end

local function Icon(parent, name, size, colorKey)
	local id = Huo.Icons[name] or (type(name) == "string" and name:match("^rbxassetid://") and name) or Huo.Icons.circle
	local img = New("ImageLabel", {
		BackgroundTransparency = 1,
		Image = id,
		Size = UDim2.fromOffset(size or 16, size or 16),
		ImageTransparency = 0,
		Parent = parent,
	})
	Theme(img, colorKey or "SubText", "ImageColor3")
	return img
end

local function Sparkle(parent, colorKey, alpha)
	local holder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = parent,
	})
	local dot = New("Frame", {
		Size = UDim2.fromOffset(3, 3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 6, 0, 6),
		BackgroundTransparency = alpha or 0.35,
		Parent = holder,
	})
	Corner(dot, 2)
	Theme(dot, colorKey or "Highlight", "BackgroundColor3")
	return holder
end

function Huo:SetFlag(flag, value)
	self.Flags[flag] = value
	local listeners = self.FlagListeners[flag]
	if listeners then
		for _, fn in next, listeners do
			local ok, err = pcall(fn, value, flag)
			if not ok then warn("[Huo] flag listener: " .. tostring(err)) end
		end
	end
	return value
end

function Huo:GetFlag(flag)
	return self.Flags[flag]
end

function Huo:OnFlagChanged(flag, fn)
	self.FlagListeners[flag] = self.FlagListeners[flag] or {}
	table.insert(self.FlagListeners[flag], fn)
	if self.Flags[flag] ~= nil then pcall(fn, self.Flags[flag], flag) end
	return fn
end

function Huo:ApplyTheme(name)
	local theme = type(name) == "table" and name or self.Themes[name]
	if not theme then return end
	self.Theme = theme
	for obj, info in next, self.Themed do
		if obj.Parent == nil and obj.ClassName ~= "ScreenGui" then
			self.Themed[obj] = nil
		else
			obj[info.prop] = theme[info.key] or theme.Text
		end
	end
end

function Huo:Notify(config)
	config = type(config) == "table" and config or {Content = tostring(config)}
	local duration = tonumber(config.Duration) or 4
	if duration < 1.5 then duration = 1.5 end

	local holder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.fromOffset(292, 66),
		BackgroundColor3 = self.Theme.Card,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self.NotifLayer,
	})
	Corner(holder, 12)
	Theme(holder, "Card", "BackgroundColor3")
	local stroke = Stroke(holder, self.Theme.Stroke, 1, 1)
	Theme(stroke, "Stroke", "Color")
	local accent = New("Frame", {
		Size = UDim2.new(0, 3, 1, -20),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Corner(accent, 2)
	Theme(accent, config.Color or "Accent", "BackgroundColor3")

	local iconName = config.Icon or "bell"
	local icon = Icon(holder, iconName, 18, "Text")
	icon.Position = UDim2.new(0, 14, 0, 14)
	Theme(icon, "Text", "ImageColor3")

	local title = Text(holder, config.Title or "Notice", 14, self.Fonts.Semibold, "Text")
	title.Position = UDim2.new(0, 42, 0, 10)
	title.Size = UDim2.new(1, -56, 0, 18)

	local content = Text(holder, config.Content or "", 13, self.Fonts.Regular, "SubText")
	content.Position = UDim2.new(0, 42, 0, 28)
	content.Size = UDim2.new(1, -56, 0, 30)
	content.TextWrapped = true
	content.TextYAlignment = Enum.TextYAlignment.Top

	local bar = New("Frame", {
		Size = UDim2.new(1, -20, 0, 2),
		Position = UDim2.new(0, 10, 1, -6),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Corner(bar, 1)
	Theme(bar, config.Color or "Accent", "BackgroundColor3")

	for _, other in next, self.Notifications do
		Tween(other, 0.22, {Position = UDim2.new(1, -14, 1, other.Position.Y.Offset - 74)})
	end
	self.Notifications[holder] = true

	Tween(holder, 0.28, {BackgroundTransparency = 0.06})
	Tween(stroke, 0.28, {Transparency = 0.25})
	Tween(bar, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not self.Notifications[holder] then return end
		self.Notifications[holder] = nil
		Tween(holder, 0.2, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 1, holder.Position.Y.Offset)})
		for _, other in next, self.Notifications do
			if other.Position.Y.Offset < holder.Position.Y.Offset then
				Tween(other, 0.22, {Position = UDim2.new(1, -14, 1, other.Position.Y.Offset + 74)})
			end
		end
		task.delay(0.25, function() holder:Destroy() end)
	end)
	return holder
end

function Huo:Dialog(config)
	config = type(config) == "table" and config or {}
	local result = nil

	local overlay = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Parent = self.Root,
	})

	local card = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = overlay,
	})
	Corner(card, 14)
	local cs = Stroke(card, self.Theme.Stroke, 1, 1)
	Theme(cs, "Stroke", "Color")
	Pad(card, 18)
	New("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})

	local head = Text(card, config.Title or "Confirm", 16, self.Fonts.Semibold, "Text")
	head.Size = UDim2.new(1, 0, 0, 20)
	head.LayoutOrder = 1

	local body = Text(card, config.Content or "", 13, self.Fonts.Regular, "SubText")
	body.Size = UDim2.new(1, 0, 0, 16)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.LayoutOrder = 2

	local input
	if config.Input then
		local field = New("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = self.Theme.Card,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = card,
		})
		Corner(field, 8)
		local fs = Stroke(field, self.Theme.Stroke, 1, 0.4)
		Theme(fs, "Stroke", "Color")
		input = New("TextBox", {
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1,
			Text = config.Default or "",
			PlaceholderText = config.Placeholder or "",
			PlaceholderColor3 = self.Theme.SubText,
			TextSize = 13,
			FontFace = self.Fonts.Regular,
			ClearTextOnFocus = false,
			Parent = field,
		})
		Theme(input, "Text", "TextColor3")
	end

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = card,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})

	local function button(label, order, primary)
		local btn = New("TextButton", {
			Size = UDim2.fromOffset(86, 32),
			BackgroundColor3 = primary and self.Theme.Accent or self.Theme.Card,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			Parent = row,
		})
		Corner(btn, 8)
		Theme(btn, primary and "Accent" or "Card", "BackgroundColor3")
		local t = Text(btn, label, 13, self.Fonts.Semibold, primary and "AccentText" or "Text")
		t.Size = UDim2.new(1, 0, 1, 0)
		t.TextXAlignment = Enum.TextXAlignment.Center
		Theme(t, primary and "AccentText" or "Text", "TextColor3")
		return btn
	end

	local buttons = config.Buttons or {{Title = "Cancel", Value = false}, {Title = "Confirm", Value = true, Primary = true}}
	for i, spec in ipairs(buttons) do
		local btn = button(spec.Title, i, spec.Primary)
		Connect(btn.MouseButton1Click, nil, function()
			result = input and input.Text or spec.Value
			Tween(card, 0.16, {BackgroundTransparency = 1})
			Tween(overlay, 0.16, {BackgroundTransparency = 1})
			task.delay(0.18, function() overlay:Destroy() end)
		end)
	end

	Tween(card, 0.28, {BackgroundTransparency = 0.02})
	Tween(overlay, 0.28, {BackgroundTransparency = 0.45})
	Tween(cs, 0.28, {Transparency = 0.2})

	if input then
		repeat task.wait() until input.Text ~= nil
	end

	return result, function()
		if overlay.Parent then
			result = nil
			overlay:Destroy()
		end
	end
end

function Huo:GetConfigs()
	if not COMPAT.canSave then return {} end
	local ok, files = pcall(function()
		if not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
		local out = {}
		for _, path in next, listfiles(self.ConfigFolder) do
			local name = tostring(path):match("[^/\\]+$") or tostring(path)
			if name:sub(-#self.ConfigExt) == self.ConfigExt then
				table.insert(out, name:sub(1, #name - #self.ConfigExt))
			end
		end
		return out
	end)
	return ok and files or {}
end

function Huo:SaveConfig(name)
	if not COMPAT.canSave or not name or name == "" then return false end
	local data = {__version = self.Version, flags = {}}
	for flag, value in next, self.Flags do
		if self.Options[flag] and not self.Options[flag].skipflag then
			local t = typeof(value)
			if t == "Color3" then
				data.flags[flag] = {__type = "Color3", r = value.R, g = value.G, b = value.B}
			elseif t == "number" or t == "string" or t == "boolean" then
				data.flags[flag] = value
			elseif t == "table" then
				data.flags[flag] = {__type = "table", value = value}
			end
		end
	end
	local ok = pcall(function()
		writefile(self.ConfigFolder .. "/" .. name .. self.ConfigExt, HttpService:JSONEncode(data))
	end)
	return ok
end

function Huo:LoadConfig(name)
	if not COMPAT.canSave or not name or name == "" then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(self.ConfigFolder .. "/" .. name .. self.ConfigExt))
	end)
	if not ok or typeof(data) ~= "table" or not data.flags then return false end
	for flag, value in next, data.flags do
		local option = self.Options[flag]
		if option then
			local decoded = value
			if typeof(value) == "table" and value.__type == "Color3" then
				decoded = Color3.new(value.r, value.g, value.b)
			elseif typeof(value) == "table" and value.__type == "table" then
				decoded = value.value
			end
			local setter = option.Set
			if setter then
				pcall(setter, option, decoded, true)
			else
				self:SetFlag(flag, decoded)
			end
		end
	end
	return true
end

function Huo:DeleteConfig(name)
	if not COMPAT.canSave or not name then return end
	pcall(function() delfile(self.ConfigFolder .. "/" .. name .. self.ConfigExt) end)
end

local function SetText(el, value)
	if el.option then
		el.option.text = tostring(value)
		if el.label then el.label.Text = tostring(value) end
		if el.desc then el.desc.Text = tostring(value) end
		return
	end
	el.Text = tostring(value)
end

function Huo:CreateWindow(config)
	config = type(config) == "table" and config or {}
	local self_ = self

	if config.Theme then self:ApplyTheme(config.Theme) end

	local window = {
		Tabs = {},
		TabButtons = {},
		CurrentTab = nil,
		Open = false,
		Minimized = false,
		Search = "",
		ToggleKey = config.ToggleKey or Enum.KeyCode.Insert,
		Title = config.Title or "Huo",
		Subtitle = config.Subtitle,
		Folder = config.Folder or "huo",
		Size = config.Size or UDim2.fromOffset(724, 468),
	}

	local gui = New("ScreenGui", {
		Name = "Huo",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	window.Gui = gui

	local function parentGui()
		if RunService:IsStudio() then
			gui.Parent = LP:WaitForChild("PlayerGui")
			return
		end
		if typeof(gethui) == "function" then
			if pcall(function() gui.Parent = gethui() end) and gui.Parent then return end
		end
		if typeof(get_hidden_gui) == "function" then
			if pcall(function() gui.Parent = get_hidden_gui() end) and gui.Parent then return end
		end
		if not pcall(function() gui.Parent = game:GetService("CoreGui") end) or not gui.Parent then
			gui.Parent = LP:WaitForChild("PlayerGui")
		end
	end
	parentGui()

	window.Root = New("Frame", {
		Name = "Root",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local scale = New("UIScale", {Parent = window.Root, Scale = 1})
	if COMPAT.isTouch then
		local vp = viewport()
		scale.Scale = math.clamp(math.min(vp.X / 780, vp.Y / 560), 0.42, 1)
	end

	local shadow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = window.Size,
		BackgroundColor3 = self.Theme.Shadow,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Parent = window.Root,
	})
	Corner(shadow, 18)
	Theme(shadow, "Shadow", "BackgroundColor3")

	local main = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = window.Size,
		BackgroundColor3 = self.Theme.Window,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = window.Root,
	})
	Corner(main, 14)
	local mainStroke = Stroke(main, self.Theme.Stroke, 1, 0.35)
	Theme(mainStroke, "Stroke", "Color")
	Theme(main, "Window", "BackgroundColor3")
	window.Main = main

	local blur = New("UIBlur", {Size = 22, Transparency = 0.12, Parent = main})
	window.Blur = blur

	local titlebar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = main,
	})
	Theme(titlebar, "Panel", "BackgroundColor3")
	New("UICorner", {CornerRadius = UDim.new(0, 14), Parent = titlebar})
	local tbMask = New("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = titlebar,
	})
	Theme(tbMask, "Panel", "BackgroundColor3")
	local hairline = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = self.Theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = titlebar,
	})
	Theme(hairline, "Stroke", "BackgroundColor3")

	local lightColors = {
		{key = "close", color = Color3.fromHex("FF5F57")},
		{key = "min", color = Color3.fromHex("FEBC2E")},
		{key = "max", color = Color3.fromHex("28C840")},
	}
	for i, spec in ipairs(lightColors) do
		local dot = New("TextButton", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 14 + ((i - 1) * 20), 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = spec.color,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = titlebar,
		})
		Corner(dot, 6)
		window["Light_" .. spec.key] = dot
	end

	local titleLabel = Text(titlebar, window.Title, 13, self.Fonts.Semibold, "Text")
	titleLabel.Size = UDim2.new(1, -200, 1, 0)
	titleLabel.Position = UDim2.new(0, 90, 0, 0)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local subtitleLabel = Text(titlebar, window.Subtitle or "", 12, self.Fonts.Regular, "SubText")
	subtitleLabel.Size = UDim2.new(1, -240, 1, 0)
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
	subtitleLabel.Position = UDim2.new(0, 120, 0, 0)

	local sidebar = New("Frame", {
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 178, 1, -42),
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Parent = main,
	})
	Theme(sidebar, "Panel", "BackgroundColor3")

	local searchBox = New("Frame", {
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(1, -24, 0, 28),
		BackgroundColor3 = self.Theme.Card,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Corner(searchBox, 8)
	Theme(searchBox, "Card", "BackgroundColor3")
	local searchIcon = Icon(searchBox, "search", 13, "SubText")
	searchIcon.Position = UDim2.new(0, 9, 0.5, 0)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	local searchInput = New("TextBox", {
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = self.Theme.SubText,
		TextSize = 13,
		FontFace = self.Fonts.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = searchBox,
	})
	Theme(searchInput, "Text", "TextColor3")
	window.SearchInput = searchInput

	local tabList = New("ScrollingFrame", {
		Position = UDim2.new(0, 8, 0, 46),
		Size = UDim2.new(1, -16, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self.Theme.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	New("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList})
	window.TabList = tabList

	local content = New("Frame", {
		Position = UDim2.new(0, 178, 0, 42),
		Size = UDim2.new(1, -178, 1, -42),
		BackgroundTransparency = 1,
		Parent = main,
	})
	window.Content = content

	window.PopupLayer = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 20,
		Parent = main,
	})

	window.NotifLayer = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = gui,
	})

	local watermark = nil
	local opened = false

	local function setOpen(state)
		if window.Destroyed then return end
		state = state == true
		if opened == state then return end
		opened = state
		window.Open = state
		if state then
			main.Visible = true
			shadow.Visible = true
			main.Size = UDim2.new(0, 0, 0, 0)
			Tween(main, 0.3, {Size = window.Size}, Enum.EasingStyle.Back)
			Tween(shadow, 0.3, {Size = window.Size}, Enum.EasingStyle.Back)
			if window.SearchInput then window.SearchInput.Text = window.SearchInput.Text end
		else
			Tween(main, 0.18, {Size = UDim2.new(0, 0, 0, 0)})
			Tween(shadow, 0.18, {Size = UDim2.new(0, 0, 0, 0)})
			task.delay(0.2, function()
				if not opened then
					main.Visible = false
					shadow.Visible = false
				end
			end)
		end
	end
	window.SetOpen = setOpen

	local function drag(startObj)
		local dragging, dragStart, startPos, dragInput
		Connect(startObj.InputBegan, nil, function(input)
			if not isPress(input) then return end
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end)
		Connect(startObj.InputChanged, nil, function(input)
			if dragging and isMove(input) then dragInput = input end
		end)
		Connect(startObj.InputEnded, nil, function(input)
			if isPress(input) then dragging = false end
		end)
		Connect(UIS.InputChanged, nil, function(input)
			if input ~= dragInput or not dragging then return end
			local delta = input.Position - dragStart
			local vp = viewport()
			local x = math.clamp(startPos.X.Offset + delta.X, -(main.AbsoluteSize.X - 80), vp.X - 80)
			local y = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - 46)
			main.Position = UDim2.new(0.5, x, 0.5, y)
			shadow.Position = UDim2.new(0.5, x, 0.5, y + 6)
		end)
	end
	drag(titlebar)

	Connect(window.Light_close.MouseButton1Click, nil, function()
		if config.CloseBehavior == "destroy" then
			window:Destroy()
		else
			setOpen(false)
		end
	end)

	Connect(window.Light_min.MouseButton1Click, nil, function()
		window.Minimized = not window.Minimized
		local target = window.Minimized and UDim2.fromOffset(320, 44) or window.Size
		Tween(main, 0.24, {Size = target}, Enum.EasingStyle.Quint)
		Tween(shadow, 0.24, {Size = target}, Enum.EasingStyle.Quint)
		content.Visible = not window.Minimized
		sidebar.Visible = not window.Minimized
	end)

	Connect(window.Light_max.MouseButton1Click, nil, function()
		local vp = viewport()
		local full = UDim2.fromOffset(vp.X - 60, vp.Y - 90)
		local current = main.Size == full and window.Size or full
		Tween(main, 0.26, {Size = current}, Enum.EasingStyle.Quint)
		Tween(shadow, 0.26, {Size = current}, Enum.EasingStyle.Quint)
	end)

	function window:SetToggleKey(key)
		self.ToggleKey = key
	end

	function window:SetScale(value)
		scale.Scale = value
	end

	function window:SelectTab(tab)
		if self.CurrentTab == tab then return end
		if self.CurrentTab then
			local btn = self.TabButtons[self.CurrentTab]
			if btn then
				Tween(btn.Pill, 0.2, {BackgroundTransparency = 1})
				Theme(btn.Pill, "Card", "BackgroundColor3")
				btn.Icon.ImageColor3 = self.Theme.SubText
				btn.Label.TextColor3 = self.Theme.SubText
			end
			self.CurrentTab.Page.Visible = false
		end
		self.CurrentTab = tab
		local btn = self.TabButtons[tab]
		if btn then
			btn.Pill.BackgroundColor3 = self.Theme.Card
			Tween(btn.Pill, 0.2, {BackgroundTransparency = 0.2})
			btn.Icon.ImageColor3 = self.Theme.Accent
			btn.Label.TextColor3 = self.Theme.Text
		end
		tab.Page.Visible = true
	end

	function window:Tab(spec)
		spec = type(spec) == "table" and spec or {Title = tostring(spec)}
		local tab = {Title = spec.Title or "Tab", Icon = spec.Icon or "circle", Window = self}

		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = #self.Tabs + 1,
			Parent = tabList,
		})
		tab.Button = btn
		local pill = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = self.Theme.Card,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = btn,
		})
		Corner(pill, 8)
		btn.Pill = pill
		local ico = Icon(btn, tab.Icon, 15, "SubText")
		ico.Position = UDim2.new(0, 9, 0.5, 0)
		ico.AnchorPoint = Vector2.new(0, 0.5)
		btn.Icon = ico
		local lbl = Text(btn, tab.Title, 13, self.Fonts.Regular, "SubText")
		lbl.Position = UDim2.new(0, 32, 0, 0)
		lbl.Size = UDim2.new(1, -40, 1, 0)
		btn.Label = lbl

		local page = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = self.Theme.Stroke,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = content,
		})
		New("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
		Pad(page, 14, 14, 18, 16)
		tab.Page = page

		Connect(btn.MouseButton1Click, nil, function() self:SelectTab(tab) end)

		table.insert(self.Tabs, tab)
		self.TabButtons[tab] = btn

		function tab:Section(sectionSpec)
			sectionSpec = type(sectionSpec) == "table" and sectionSpec or {Title = tostring(sectionSpec)}
			local section = {Title = sectionSpec.Title or "", Tab = tab, Window = self, Options = {}, Order = 0}

			local card = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = self.Theme.Card,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				LayoutOrder = #page:GetChildren(),
				Parent = page,
			})
			Corner(card, 12)
			local cs = Stroke(card, self.Theme.Stroke, 1, 0.6)
			Theme(cs, "Stroke", "Color")
			Theme(card, "Card", "BackgroundColor3")
			Pad(card, 12)
			local layout = New("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
			section.Card = card

			if section.Title ~= "" then
				local head = New("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Parent = card,
				})
				local hl = Text(head, section.Title, 12, self.Fonts.Semibold, "SubText")
				hl.Size = UDim2.new(1, 0, 1, 0)
				hl.TextXAlignment = Enum.TextXAlignment.Left
				section.Header = head
			end

			function section:NextOrder()
				self.Order = self.Order + 1
				return self.Order
			end

			function section:SetTitle(value)
				if section.Header then
					section.Header:FindFirstChildOfClass("TextLabel").Text = tostring(value)
				end
				section.Title = tostring(value)
			end

			function section:Row(height, titleText, descText)
				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, height or 34),
					BackgroundTransparency = 1,
					LayoutOrder = self:NextOrder(),
					Parent = card,
				})
				local info = {row = row, title = titleText, section = section}
				if titleText then
					local label = Text(row, titleText, 13, self.Fonts.Regular, "Text")
					label.Size = UDim2.new(1, -110, 0, descText and 17 or 34)
					label.Position = UDim2.new(0, 0, 0, 0)
					label.TextYAlignment = descText and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
					info.label = label
					if descText then
						local desc = Text(row, descText, 11, self.Fonts.Regular, "SubText")
						desc.Size = UDim2.new(1, -110, 0, 15)
						desc.Position = UDim2.new(0, 0, 0, 18)
						desc.TextYAlignment = Enum.TextYAlignment.Top
						info.desc = desc
					end
				end
				table.insert(section.Options, info)
				return row, info
			end

			function section:Tooltip(obj, tipText)
				if not tipText then return end
				Connect(obj.InputBegan, nil, function(input)
					if isMove(input) then
						self.Window:ShowTooltip(tipText, input)
					end
				end)
				Connect(obj.InputChanged, nil, function(input)
					if isMove(input) then self.Window:MoveTooltip(input) end
				end)
				Connect(obj.InputEnded, nil, function(input)
					if isMove(input) then self.Window:HideTooltip() end
				end)
			end

			table.insert(tab.Sections or {}, section)
			tab.Sections = tab.Sections or {}
			table.insert(tab.Sections, section)
			return section
		end

		return tab
	end

	function window:ShowTooltip(text, input)
		if not self.Tooltip then
			self.Tooltip = New("TextLabel", {
				BackgroundColor3 = self.Theme.Window,
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				TextSize = 12,
				FontFace = self.Fonts.Regular,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 80,
				Visible = false,
				Parent = self.Root,
			})
			Corner(self.Tooltip, 6)
			local ts = Stroke(self.Tooltip, self.Theme.Stroke, 1, 0.3)
			Theme(self.Tooltip, "Text", "TextColor3")
			Theme(self.Tooltip, "Window", "BackgroundColor3")
			Theme(ts, "Stroke", "Color")
		end
		self.Tooltip.Text = text
		self.Tooltip.Size = UDim2.fromOffset(measure(text, 12) + 18, 24)
		self.Tooltip.Visible = true
		self:MoveTooltip(input)
	end

	function window:MoveTooltip(input)
		if not self.Tooltip then return end
		local vp = viewport()
		local w = self.Tooltip.AbsoluteSize.X
		local x = input.Position.X + 18
		local y = input.Position.Y + 22
		if x + w > vp.X then x = input.Position.X - w - 12 end
		if y + 26 > vp.Y then y = input.Position.Y - 30 end
		self.Tooltip.Position = UDim2.fromOffset(x, y)
	end

	function window:HideTooltip()
		if self.Tooltip then self.Tooltip.Visible = false end
	end

	function window:Watermark(text, iconName)
		if self.Mark then
			self.Mark.Text = tostring(text)
			return self.Mark
		end
		local mark = New("TextLabel", {
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.fromOffset(measure(text, 13, self.Fonts.Semibold) + 44, 28),
			BackgroundColor3 = self.Theme.Window,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Text = "  " .. tostring(text),
			TextSize = 13,
			FontFace = self.Fonts.Semibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 70,
			Parent = self.Root,
		})
		Corner(mark, 8)
		local ms = Stroke(mark, self.Theme.Accent, 1, 0.4)
		Theme(mark, "Text", "TextColor3")
		Theme(mark, "Window", "BackgroundColor3")
		Theme(ms, "Accent", "Color")
		local ico = Icon(mark, iconName or "flame", 15, "Accent")
		ico.Position = UDim2.new(0, 12, 0.5, 0)
		ico.AnchorPoint = Vector2.new(0, 0.5)
		self.Mark = mark
		return mark
	end

	function window:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		for _, c in next, Huo.Connections do
			pcall(function() c:Disconnect() end)
		end
		table.clear(Huo.Connections)
		for _, inst in next, Huo.Instances do
			pcall(function() inst:Destroy() end)
		end
		table.clear(Huo.Instances)
		table.clear(Huo.Themed)
		if gui then pcall(function() gui:Destroy() end) end
	end

	Connect(UIS.InputBegan, nil, function(input, processed)
		if processed then return end
		if input.KeyCode == window.ToggleKey then
			setOpen(not opened)
		end
		if input.KeyCode == Enum.KeyCode.Escape and opened then
			setOpen(false)
		end
	end)

	Connect(searchInput:GetPropertyChangedSignal("Text"), nil, function()
		local query = searchInput.Text:lower()
		window.Search = query
		for _, tab in next, window.Tabs do
			local anyVisible = false
			for _, section in next, tab.Sections or {} do
				local sectionVisible = false
				for _, info in next, section.Options do
					local match = query == "" or (info.title and info.title:lower():find(query, 1, true))
					info.row.Visible = match and true or false
					if match then sectionVisible = true end
				end
				section.Card.Visible = sectionVisible
				if sectionVisible then anyVisible = true end
			end
			local btn = window.TabButtons[tab]
			if btn then btn.Visible = anyVisible or query == "" end
		end
	end)

	if config.OpenButton then
		local openBtn = New("TextButton", {
			Position = UDim2.new(0, 16, 1, -60),
			Size = UDim2.fromOffset(132, 34),
			BackgroundColor3 = self.Theme.Accent,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 70,
			Parent = window.Root,
		})
		Corner(openBtn, 17)
		Theme(openBtn, "Accent", "BackgroundColor3")
		local t = Text(openBtn, config.OpenButton.Title or "Open UI", 13, self.Fonts.Semibold, "AccentText")
		t.Size = UDim2.new(1, 0, 1, 0)
		t.TextXAlignment = Enum.TextXAlignment.Center
		Connect(openBtn.MouseButton1Click, nil, function() setOpen(true) end)
		window.OpenButton = openBtn
	end

	main.Visible = false
	shadow.Visible = false

	Huo.Window = window
	if config.Open ~= false then
		task.delay(0.2, function() setOpen(true) end)
	end

	return window
end

function Huo:Load()
	return Huo
end

return Huo
Huo.ThemeListeners = {}

local originalApplyTheme = Huo.ApplyTheme
function Huo:ApplyTheme(name)
	originalApplyTheme(self, name)
	for _, fn in next, self.ThemeListeners do pcall(fn, self.Theme) end
end

function Huo:OnTheme(fn)
	table.insert(self.ThemeListeners, fn)
	if self.Theme then pcall(fn, self.Theme) end
	return fn
end

local function Register(option)
	local base = tostring(option.flag or option.title or option.type)
	local flag = base
	local n = 0
	while Huo.Options[flag] do
		n = n + 1
		flag = base .. " " .. n
	end
	option.flag = flag
	if not option.skipflag then Huo.Options[flag] = option end
	return flag
end

local function Decorate(option, info, window)
	function option:SetTitle(value)
		if info.label then info.label.Text = tostring(value) end
		self.title = tostring(value)
	end
	function option:SetDesc(value)
		if info.desc then info.desc.Text = tostring(value) end
		self.desc = tostring(value)
	end
	function option:Lock(state)
		self.locked = state ~= false
		local alpha = self.locked and 0.45 or 0
		if info.label then info.label.TextTransparency = alpha end
		if info.desc then info.desc.TextTransparency = alpha end
		if self.Row then self.Row.Active = not self.locked end
		return self.locked
	end
	function option:Unlock() return self:Lock(false) end
	function option:Destroy()
		if info.row then info.row:Destroy() end
		Huo.Options[self.flag] = nil
	end
	option.Window = window
	option.Row = info.row
	option.locked = false
	if info.label and option.tip then
		local section = option.section
		if section and section.Tooltip then section:Tooltip(info.row, option.tip) end
	end
	return option
end

local function Popup(window, anchor, width, height)
	if window.OpenPopup then window.OpenPopup:Close() end
	local dismiss = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 19,
		Parent = window.Root,
	})
	local holder = New("Frame", {
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Huo.Theme.Panel,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = window.PopupLayer,
	})
	Corner(holder, 10)
	local hs = Stroke(holder, Huo.Theme.Stroke, 1, 0.25)
	Theme(holder, "Panel", "BackgroundColor3")
	Theme(hs, "Stroke", "Color")

	local mainPos = window.Main.AbsolutePosition
	local mainSize = window.Main.AbsoluteSize
	local aPos = anchor.AbsolutePosition
	local aSize = anchor.AbsoluteSize
	local x = aPos.X - mainPos.X
	local y = aPos.Y - mainPos.Y + aSize.Y + 6
	local vp = viewport()
	if aPos.Y + aSize.Y + height + 16 > vp.Y then
		y = aPos.Y - mainPos.Y - height - 6
	end
	if x + width + 8 > mainSize.X then x = mainSize.X - width - 8 end
	if x < 8 then x = 8 end
	holder.Position = UDim2.fromOffset(x, y)

	local popup = {Holder = holder, Window = window}
	function popup:Close()
		window.OpenPopup = nil
		pcall(function() dismiss:Destroy() end)
		pcall(function() holder:Destroy() end)
	end
	Connect(dismiss.MouseButton1Click, nil, function() popup:Close() end)
	window.OpenPopup = popup
	return popup
end

local function BuildToggle(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local row, info = section:Row(spec.Desc and 44 or 34, spec.Title, spec.Desc)

	local track = New("Frame", {
		Size = UDim2.fromOffset(38, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Huo.Theme.Stroke,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(track, 11)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		BackgroundColor3 = Color3.fromHex("FFFFFF"),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(knob, 9)

	local option = {
		type = "toggle",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = spec.Value == true,
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	function option:Set(value, nocallback)
		value = value == true
		self.value = value
		Huo:SetFlag(self.flag, value)
		Tween(knob, 0.16, {Position = UDim2.new(0, value and 18 or 2, 0.5, 0)})
		Tween(track, 0.16, {BackgroundColor3 = value and Huo.Theme.Accent or Huo.Theme.Stroke, BackgroundTransparency = value and 0 or 0.1})
		if info.label then Tween(info.label, 0.16, {TextColor3 = value and Huo.Theme.Text or Huo.Theme.SubText}) end
		if not nocallback then self.callback(value) end
		return value
	end

	function option:Get() return self.value end

	Connect(row.InputBegan, nil, function(input)
		if not isPress(input) or self.locked then return end
		self:Set(not self.value)
	end)

	Huo:OnTheme(function() option:Set(option.value, true) end)
	option:Set(option.value, true)
	return option
end

local function BuildSlider(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local min = tonumber(spec.Min) or 0
	local max = tonumber(spec.Max) or 100
	if max <= min then max = min + 1 end
	local step = tonumber(spec.Step) or 1
	local value = math.clamp(tonumber(spec.Value) or min, min, max)

	local row, info = section:Row(spec.Desc and 62 or 50, spec.Title, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.62, -8, 0, 17) end

	local valueBox = New("TextBox", {
		Size = UDim2.new(0.38, -8, 0, 18),
		Position = UDim2.new(0.62, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 12,
		FontFace = Huo.Fonts.Mono,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		Parent = row,
	})
	Theme(valueBox, "SubText", "TextColor3")

	local track = New("Frame", {
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Huo.Theme.Stroke,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(track, 3)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Huo.Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(fill, 3)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromHex("FFFFFF"),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(knob, 7)

	local option = {
		type = "slider",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = value,
		Min = min,
		Max = max,
		Step = step,
		Suffix = spec.Suffix or "",
		Format = spec.Format,
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	local function alpha(v)
		return (v - min) / (max - min)
	end

	local function paint(v)
		local a = alpha(v)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
	end

	function option:Set(v, nocallback)
		if typeof(v) ~= "number" then v = self.Min end
		if step >= 1 then
			v = math.floor((v / step) + 0.5) * step
		else
			v = math.floor(v / step + 0.5) * step
		end
		v = math.clamp(v, self.Min, self.Max)
		self.value = v
		paint(v)
		valueBox.Text = self.Format and self.Format(v) or (tostring(v) .. self.Suffix)
		Huo:SetFlag(self.flag, v)
		if not nocallback then self.callback(v) end
		return v
	end

	function option:Get() return self.value end

	local dragging = false

	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		return self.Min + a * (self.Max - self.Min)
	end

	Connect(track.InputBegan, nil, function(input)
		if self.locked or not isPress(input) then return end
		dragging = true
		option:Set(fromX(input.Position.X))
	end)
	Connect(UIS.InputChanged, nil, function(input)
		if dragging and isMove(input) then option:Set(fromX(input.Position.X)) end
	end)
	Connect(UIS.InputEnded, nil, function(input)
		if isPress(input) then dragging = false end
	end)

	Connect(valueBox.Focused, nil, function()
		valueBox.Text = tostring(option.value)
		valueBox:CaptureFocus()
	end)
	Connect(valueBox.FocusLost, nil, function()
		local parsed = tonumber(tostring(valueBox.Text):match("-?%d+%.?%d*"))
		option:Set(parsed or option.value)
	end)

	Huo:OnTheme(function()
		fill.BackgroundColor3 = Huo.Theme.Accent
		track.BackgroundColor3 = Huo.Theme.Stroke
	end)
	option:Set(option.value, true)
	return option
end

local function BuildDropdown(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local multi = spec.Multi == true
	local values = {}
	for _, v in ipairs(spec.Values or {}) do
		table.insert(values, typeof(v) == "table" and v.Title or tostring(v))
	end

	local row, info = section:Row(spec.Desc and 44 or 34, spec.Title, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.5, -8, 0, 17) end

	local pill = New("TextButton", {
		Size = UDim2.fromOffset(148, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Huo.Theme.Card,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(pill, 8)
	local ps = Stroke(pill, Huo.Theme.Stroke, 1, 0.5)
	Theme(ps, "Stroke", "Color")
	Theme(pill, "Card", "BackgroundColor3")
	local pillText = Text(pill, "", 12, Huo.Fonts.Regular, "Text")
	pillText.Size = UDim2.new(1, -26, 1, 0)
	pillText.Position = UDim2.new(0, 9, 0, 0)
	pillText.TextTruncate = Enum.TextTruncate.AtEnd
	local chev = Icon(pill, "chevronDown", 12, "SubText")
	chev.AnchorPoint = Vector2.new(1, 0.5)
	chev.Position = UDim2.new(1, -8, 0.5, 0)

	local selected
	if multi then
		selected = {}
		for _, v in ipairs(spec.Value or {}) do selected[v] = true end
	else
		selected = spec.Value and tostring(spec.Value) or (values[1] or "")
	end

	local option = {
		type = multi and "multidropdown" or "dropdown",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = selected,
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	local function label()
		if multi then
			local out = {}
			for _, v in ipairs(values) do
				if selected[v] then table.insert(out, v) end
			end
			return #out == 0 and "None" or table.concat(out, ", ")
		end
		return tostring(selected)
	end

	function option:Set(value, nocallback)
		if multi then
			if typeof(value) == "table" then
				selected = {}
				for _, v in ipairs(value) do selected[tostring(v)] = true end
			elseif value ~= nil then
				selected[tostring(value)] = true
			end
			self.value = selected
		else
			if value ~= nil then selected = tostring(value) end
			self.value = selected
		end
		pillText.Text = label()
		Huo:SetFlag(self.flag, self.value)
		if not nocallback then self.callback(self.value) end
		return self.value
	end

	function option:Get() return self.value end

	function option:Refresh(newValues)
		values = {}
		for _, v in ipairs(newValues or {}) do table.insert(values, typeof(v) == "table" and v.Title or tostring(v)) end
		pillText.Text = label()
	end

	Connect(pill.MouseButton1Click, nil, function()
		if option.locked then return end
		if window.OpenPopup and window.OpenPopup.Anchor == pill then window.OpenPopup:Close() return end
		local listHeight = math.min(#values * 26 + 12, 190)
		local popup = Popup(window, pill, 200, listHeight)
		popup.Anchor = pill
		local scroll = New("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Huo.Theme.Stroke,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = popup.Holder,
		})
		New("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})

		for i, v in ipairs(values) do
			local isOn = multi and selected[v] or (not multi and selected == v)
			local item = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = isOn and Huo.Theme.Hover or Huo.Theme.Panel,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				Parent = scroll,
			})
			Corner(item, 6)
			local t = Text(item, v, 12, Huo.Fonts.Regular, isOn and "Text" or "SubText")
			t.Size = UDim2.new(1, -30, 1, 0)
			t.Position = UDim2.new(0, 9, 0, 0)
			if isOn then
				local check = Icon(item, "check", 12, "Accent")
				check.AnchorPoint = Vector2.new(1, 0.5)
				check.Position = UDim2.new(1, -8, 0.5, 0)
			end
			Connect(item.MouseEnter, nil, function() Tween(item, 0.12, {BackgroundTransparency = 0.75}) end)
			Connect(item.MouseLeave, nil, function() Tween(item, 0.12, {BackgroundTransparency = 1}) end)
			Connect(item.MouseButton1Click, nil, function()
				if multi then
					selected[v] = not selected[v]
					option:Set(selected)
				else
					option:Set(v)
					popup:Close()
				end
			end)
		end
	end)

	Huo:OnTheme(function()
		pill.BackgroundColor3 = Huo.Theme.Card
		ps.Color = Huo.Theme.Stroke
	end)
	option:Set(option.value, true)
	return option
end

local function BuildInput(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local row, info = section:Row(spec.Desc and 44 or 34, spec.Title, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.44, -8, 0, 17) end

	local field = New("Frame", {
		Size = UDim2.new(0.56, -8, 0, 28),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Huo.Theme.Card,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(field, 8)
	local fs = Stroke(field, Huo.Theme.Stroke, 1, 0.5)
	Theme(fs, "Stroke", "Color")
	Theme(field, "Card", "BackgroundColor3")

	local box = New("TextBox", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.new(0, 9, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(spec.Value or ""),
		PlaceholderText = spec.Placeholder or "",
		PlaceholderColor3 = Huo.Theme.SubText,
		TextSize = 12,
		FontFace = Huo.Fonts.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = field,
	})
	Theme(box, "Text", "TextColor3")

	local option = {
		type = "input",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = tostring(spec.Value or ""),
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	function option:Set(value, nocallback)
		self.value = tostring(value or "")
		box.Text = self.value
		Huo:SetFlag(self.flag, self.value)
		if not nocallback then self.callback(self.value) end
		return self.value
	end

	function option:Get() return self.value end

	Connect(box.Focused, nil, function()
		Tween(fs, 0.15, {Color = Huo.Theme.Accent, Transparency = 0.1})
	end)
	Connect(box.FocusLost, nil, function()
		Tween(fs, 0.15, {Color = Huo.Theme.Stroke, Transparency = 0.5})
		option:Set(box.Text)
	end)

	Huo:OnTheme(function()
		field.BackgroundColor3 = Huo.Theme.Card
		fs.Color = Huo.Theme.Stroke
	end)
	return option
end

local function BuildKeybind(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local row, info = section:Row(spec.Desc and 44 or 34, spec.Title, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.5, -8, 0, 17) end

	local keyName = spec.Value or spec.Key or "None"
	if typeof(keyName) == "EnumItem" then keyName = keyName.Name end
	keyName = tostring(keyName)

	local cap = New("TextButton", {
		Size = UDim2.fromOffset(78, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Huo.Theme.Card,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(cap, 6)
	local cs = Stroke(cap, Huo.Theme.Stroke, 1, 0.5)
	Theme(cs, "Stroke", "Color")
	Theme(cap, "Card", "BackgroundColor3")
	local capText = Text(cap, keyName, 11, Huo.Fonts.Mono, "Text")
	capText.Size = UDim2.new(1, 0, 1, 0)
	capText.TextXAlignment = Enum.TextXAlignment.Center

	local option = {
		type = "keybind",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = keyName,
		Mode = spec.Mode or "toggle",
		Pressed = false,
		listening = false,
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	function option:Set(value, nocallback)
		if typeof(value) == "EnumItem" then value = value.Name end
		if value == nil or value == "" then value = "None" end
		self.value = tostring(value)
		capText.Text = self.value
		Huo:SetFlag(self.flag, self.value)
		if not nocallback then self.callback(self.value) end
		return self.value
	end

	function option:Get() return self.value end

	Connect(cap.MouseButton1Click, nil, function()
		if option.locked then return end
		option.listening = not option.listening
		capText.Text = option.listening and "..." or option.value
		if option.listening then Tween(cs, 0.15, {Color = Huo.Theme.Accent}) end
	end)

	Connect(UIS.InputBegan, nil, function(input, processed)
		if processed then return end
		if option.listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Backspace then
					option:Set("None")
				else
					option:Set(input.KeyCode.Name)
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				option:Set(input.UserInputType.Name)
			end
			option.listening = false
			Tween(cs, 0.15, {Color = Huo.Theme.Stroke})
			return
		end
		if option.locked or option.value == "None" then return end
		local isKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == option.value
		local isMouse = input.UserInputType.Name == option.value
		if not (isKey or isMouse) then return end
		if option.Mode == "hold" then
			option.Pressed = true
			option.callback(true, option.value)
		else
			option.Pressed = not option.Pressed
			Huo:SetFlag(option.flag, option.Pressed)
			option.callback(option.Pressed, option.value)
		end
	end)

	Connect(UIS.InputEnded, nil, function(input)
		if option.Mode ~= "hold" or not option.Pressed then return end
		local isKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == option.value
		local isMouse = input.UserInputType.Name == option.value
		if not (isKey or isMouse) then return end
		option.Pressed = false
		option.callback(false, option.value)
	end)

	Huo:OnTheme(function()
		cap.BackgroundColor3 = Huo.Theme.Card
		cs.Color = Huo.Theme.Stroke
	end)
	return option
end

local function BuildColorpicker(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local row, info = section:Row(34, spec.Title, spec.Desc)
	if info.label then info.label.Size = UDim2.new(0.7, -8, 0, 17) end

	local swatch = New("TextButton", {
		Size = UDim2.fromOffset(46, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = spec.Default or Color3.fromHex("FF4B2E"),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(swatch, 6)
	local ss = Stroke(swatch, Huo.Theme.Stroke, 1, 0.4)
	Theme(ss, "Stroke", "Color")

	local option = {
		type = "colorpicker",
		title = spec.Title,
		desc = spec.Desc,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = spec.Default or Color3.fromHex("FF4B2E"),
	}
	option.flag = Register(option)
	Decorate(option, info, window)

	function option:Set(value, nocallback)
		if typeof(value) == "table" then value = Color3.new(value[1], value[2], value[3]) end
		if typeof(value) ~= "Color3" then value = Color3.new(1, 1, 1) end
		self.value = value
		swatch.BackgroundColor3 = value
		Huo:SetFlag(self.flag, value)
		if self.Panel then self:Refresh() end
		if not nocallback then self.callback(value) end
		return value
	end

	function option:Get() return self.value end

	local hue, sat, val = Color3.toHSV(option.value)

	Connect(swatch.MouseButton1Click, nil, function()
		if option.locked then return end
		if window.OpenPopup and window.OpenPopup.Anchor == swatch then window.OpenPopup:Close() return end
		local popup = Popup(window, swatch, 224, 244)
		popup.Anchor = swatch
		option.Panel = popup.Holder

		local sv = New("ImageLabel", {
			Size = UDim2.new(1, -20, 0, 150),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
			BorderSizePixel = 0,
			Image = "rbxassetid://4155801252",
			Parent = popup.Holder,
		})
		Corner(sv, 6)
		local cursor = New("Frame", {
			Size = UDim2.fromOffset(10, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(sat, 0, 1 - val, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = sv,
		})
		Corner(cursor, 5)
		local cstroke = New("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, Parent = cursor})

		local hueBar = New("Frame", {
			Size = UDim2.new(1, -20, 0, 10),
			Position = UDim2.new(0, 10, 0, 168),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = popup.Holder,
		})
		Corner(hueBar, 5)
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Parent = hueBar,
		})
		local hueKnob = New("Frame", {
			Size = UDim2.fromOffset(6, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1 - hue, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = hueBar,
		})
		Corner(hueKnob, 3)
		local hstroke = New("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.5, Parent = hueKnob})

		local hexField = New("Frame", {
			Size = UDim2.new(1, -20, 0, 26),
			Position = UDim2.new(0, 10, 0, 186),
			BackgroundColor3 = Huo.Theme.Card,
			BorderSizePixel = 0,
			Parent = popup.Holder,
		})
		Corner(hexField, 6)
		local hexBox = New("TextBox", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			TextSize = 12,
			FontFace = Huo.Fonts.Mono,
			ClearTextOnFocus = false,
			Parent = hexField,
		})
		Theme(hexBox, "Text", "TextColor3")

		local swatches = {
			"FF4B2E", "FFD66A", "FFB7A0", "5C3418", "1E1E1E",
			"2FBF8F", "4C8DFF", "7A5CFF", "FF6BA9", "4ADEDE",
		}
		local strip = New("Frame", {
			Size = UDim2.new(1, -20, 0, 16),
			Position = UDim2.new(0, 10, 0, 218),
			BackgroundTransparency = 1,
			Parent = popup.Holder,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = strip,
		})
		for i, hex in ipairs(swatches) do
			local chip = New("TextButton", {
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.fromHex(hex),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				Parent = strip,
			})
			Corner(chip, 4)
			Connect(chip.MouseButton1Click, nil, function() option:Set(Color3.fromHex(hex)) end)
		end

		local editing = nil
		local function paint()
			hue, sat, val = Color3.toHSV(option.value)
			sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
			hueKnob.Position = UDim2.new(1 - hue, 0.5, 0)
			hexBox.Text = "#" .. option.value:ToHex()
		end
		option.Refresh = paint

		Connect(sv.InputBegan, nil, function(input)
			if not isPress(input) then return end
			editing = "sv"
			local x = math.clamp((input.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			local y = math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			option:Set(Color3.fromHSV(hue, x, 1 - y))
		end)
		Connect(hueBar.InputBegan, nil, function(input)
			if not isPress(input) then return end
			editing = "hue"
			local x = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
			option:Set(Color3.fromHSV(1 - x, sat, val))
		end)
		Connect(UIS.InputChanged, nil, function(input)
			if not editing or not isMove(input) then return end
			if editing == "sv" then
				local x = math.clamp((input.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
				local y = math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
				option:Set(Color3.fromHSV(hue, x, 1 - y))
			else
				local x = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
				option:Set(Color3.fromHSV(1 - x, sat, val))
			end
		end)
		Connect(UIS.InputEnded, nil, function(input)
			if isPress(input) then editing = nil end
		end)
		Connect(hexBox.FocusLost, nil, function()
			local hex = hexBox.Text:gsub("#", ""):gsub("%s", "")
			if #hex == 6 and tonumber(hex, 16) then
				option:Set(Color3.fromHex(hex))
			else
				paint()
			end
		end)

		paint()
	end)

	function option:ClosePanel()
		if window.OpenPopup and window.OpenPopup.Anchor == swatch then window.OpenPopup:Close() end
		self.Panel = nil
		self.Refresh = nil
	end

	Huo:OnTheme(function() ss.Color = Huo.Theme.Stroke end)
	return option
end

local function BuildButton(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local window = section.Window
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = section:NextOrder(),
		Parent = section.Card,
	})
	local btn = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = spec.Primary and Huo.Theme.Accent or Huo.Theme.Card,
		BackgroundTransparency = spec.Primary and 0 or 0.2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(btn, 8)
	local bs = Stroke(btn, spec.Primary and Huo.Theme.Accent or Huo.Theme.Stroke, 1, spec.Primary and 0.2 or 0.5)
	Theme(bs, "Stroke", "Color")
	Theme(btn, spec.Primary and "Accent" or "Card", "BackgroundColor3")
	local label = Text(btn, spec.Title, 13, Huo.Fonts.Semibold, spec.Primary and "AccentText" or "Text")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Center

	local option = {
		type = "button",
		title = spec.Title,
		tip = spec.tip,
		flag = spec.flag,
		skipflag = spec.skipflag,
		section = section,
		callback = spec.callback or function() end,
		value = false,
	}
	option.flag = Register(option)
	option.Row = row
	option.Window = window
	function option:SetTitle(v) label.Text = tostring(v) end
	function option:Press() option.callback() end

	Connect(btn.MouseEnter, nil, function() Tween(btn, 0.14, {BackgroundTransparency = spec.Primary and 0.1 or 0.05}) end)
	Connect(btn.MouseLeave, nil, function() Tween(btn, 0.14, {BackgroundTransparency = spec.Primary and 0 or 0.2}) end)
	Connect(btn.MouseButton1Click, nil, function()
		if option.locked then return end
		Huo:SetFlag(option.flag, os.clock())
		option.callback()
	end)

	Huo:OnTheme(function()
		btn.BackgroundColor3 = spec.Primary and Huo.Theme.Accent or Huo.Theme.Card
		bs.Color = spec.Primary and Huo.Theme.Accent or Huo.Theme.Stroke
	end)
	if spec.tip then section:Tooltip(row, spec.tip) end
	return option
end

local function BuildParagraph(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:NextOrder(),
		Parent = section.Card,
	})
	New("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row})

	if spec.Title then
		local t = Text(row, spec.Title, 13, Huo.Fonts.Semibold, "Text")
		t.Size = UDim2.new(1, 0, 0, 17)
		t.LayoutOrder = 1
		if spec.Tip then section:Tooltip(row, spec.Tip) end
	end
	if spec.Desc then
		local d = Text(row, spec.Desc, 12, Huo.Fonts.Regular, "SubText")
		d.Size = UDim2.new(1, 0, 0, 0)
		d.AutomaticSize = Enum.AutomaticSize.Y
		d.TextWrapped = true
		d.TextYAlignment = Enum.TextYAlignment.Top
		d.LayoutOrder = 2
	end
	return row
end

local function BuildDivider(section)
	local line = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Huo.Theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		LayoutOrder = section:NextOrder(),
		Parent = section.Card,
	})
	Theme(line, "Stroke", "BackgroundColor3")
	return line
end

local function BuildSpace(section, size)
	local gap = New("Frame", {
		Size = UDim2.new(1, 0, 0, size or 6),
		BackgroundTransparency = 1,
		LayoutOrder = section:NextOrder(),
		Parent = section.Card,
	})
	return gap
end

local function BuildProgress(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local row, info = section:Row(42, spec.Title, spec.Desc)
	local track = New("Frame", {
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Huo.Theme.Stroke,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(track, 3)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Huo.Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(fill, 3)
	local pct = Text(row, "0%", 12, Huo.Fonts.Mono, "SubText", Enum.TextXAlignment.Right)
	pct.Size = UDim2.new(0.3, -8, 0, 17)
	pct.Position = UDim2.new(0.7, 8, 0, 0)
	if info.label then info.label.Size = UDim2.new(0.7, -8, 0, 17) end

	local option = {type = "progress", title = spec.Title, section = section, value = 0}
	function option:Set(value, nocallback)
		local a = math.clamp(tonumber(value) or 0, 0, 1)
		self.value = a
		Tween(fill, 0.18, {Size = UDim2.new(a, 0, 1, 0)})
		pct.Text = string.format("%d%%", math.floor(a * 100 + 0.5))
		return a
	end
	function option:Get() return self.value end
	Huo:OnTheme(function()
		fill.BackgroundColor3 = Huo.Theme.Accent
		track.BackgroundColor3 = Huo.Theme.Stroke
	end)
	return option
end

local function BuildHeader(section, spec)
	spec = type(spec) == "table" and spec or {Title = tostring(spec)}
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = section:NextOrder(),
		Parent = section.Card,
	})
	New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row})
	local t = Text(row, spec.Title, 15, Huo.Fonts.Bold, "Text")
	t.Size = UDim2.new(1, 0, 0, 20)
	t.LayoutOrder = 1
	if spec.Desc then
		local d = Text(row, spec.Desc, 12, Huo.Fonts.Regular, "SubText")
		d.Size = UDim2.new(1, 0, 0, 16)
		d.LayoutOrder = 2
	end
	return row
end

local SECTION_METHODS = {
	Toggle = BuildToggle,
	Slider = BuildSlider,
	Dropdown = BuildDropdown,
	Input = BuildInput,
	Keybind = BuildKeybind,
	Colorpicker = BuildColorpicker,
	Button = BuildButton,
	Paragraph = BuildParagraph,
	Divider = BuildDivider,
	Space = BuildSpace,
	Progress = BuildProgress,
	Header = BuildHeader,
}

local function DecorateSection(section)
	if section.__decorated then return section end
	section.__decorated = true
	for name, builder in next, SECTION_METHODS do
		section[name] = function(self, spec, ...)
			return builder(self, spec, ...)
		end
	end
	section.MultiDropdown = function(self, spec)
		spec = type(spec) == "table" and spec or {Title = tostring(spec)}
		spec.Multi = true
		return BuildDropdown(self, spec)
	end
	section.Label = function(self, text)
		return BuildParagraph(self, {Title = tostring(text)})
	end
	return section
end

local originalCreateWindow = Huo.CreateWindow
function Huo:CreateWindow(config)
	local window = originalCreateWindow(self, config)
	local originalTab = window.Tab
	function window:Tab(spec)
		local tab = originalTab(self, spec)
		local originalSection = tab.Section
		tab.Sections = {}
		function tab:Section(spec2)
			return DecorateSection(originalSection(self, spec2))
		end
		return tab
	end
	function window:Notify(cfg)
		if type(cfg) == "table" then return Huo:Notify(cfg) end
		return Huo:Notify({Content = tostring(cfg), Duration = select(2, cfg, nil)})
	end
	function window:Dialog(cfg) return Huo:Dialog(cfg) end
	function window:SetTheme(name)
		Huo:ApplyTheme(name)
		local s = self.SearchInput
		if s then s.PlaceholderColor3 = Huo.Theme.SubText end
	end
	window.Huo = Huo
	return window
end

Huo.Overlay = {
	Enabled = typeof(Drawing) == "table" and typeof(Drawing.new) == "function",
	Objects = {},
	Connections = {},
}

function Huo.Overlay:New(class, props)
	if not self.Enabled then return nil end
	local obj = Drawing.new(class)
	if not obj then return nil end
	for k, v in next, props or {} do
		pcall(function() obj[k] = v end)
	end
	table.insert(self.Objects, obj)
	return obj
end

function Huo.Overlay:Circle(props)
	local o = self:New("Circle", props or {})
	if not o then return nil end
	return {
		Object = o,
		Set = function(_, cfg) for k, v in next, cfg do o[k] = v end end,
		Remove = function() pcall(function() o:Remove() end) end,
	}
end

function Huo.Overlay:Line(props)
	local o = self:New("Line", props or {})
	if not o then return nil end
	return {
		Object = o,
		Set = function(_, cfg) for k, v in next, cfg do o[k] = v end end,
		Remove = function() pcall(function() o:Remove() end) end,
	}
end

function Huo.Overlay:Text(props)
	local o = self:New("Text", props or {})
	if not o then return nil end
	return {
		Object = o,
		Set = function(_, cfg) for k, v in next, cfg do o[k] = v end end,
		Remove = function() pcall(function() o:Remove() end) end,
	}
end

function Huo.Overlay:Square(props)
	local o = self:New("Square", props or {})
	if not o then return nil end
	return {
		Object = o,
		Set = function(_, cfg) for k, v in next, cfg do o[k] = v end end,
		Remove = function() pcall(function() o:Remove() end) end,
	}
end

function Huo.Overlay:Quad(props)
	local o = self:New("Quad", props or {})
	if not o then return nil end
	return {
		Object = o,
		Set = function(_, cfg) for k, v in next, cfg do o[k] = v end end,
		Remove = function() pcall(function() o:Remove() end) end,
	}
end

function Huo.Overlay:Render(fn)
	local c = RunService.RenderStepped:Connect(fn)
	table.insert(self.Connections, c)
	return c
end

function Huo.Overlay:Clear()
	for _, o in next, self.Objects do
		pcall(function() o:Remove() end)
	end
	table.clear(self.Objects)
	for _, c in next, self.Connections do
		pcall(function() c:Disconnect() end)
	end
	table.clear(self.Connections)
end
