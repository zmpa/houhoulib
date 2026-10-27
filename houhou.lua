--[[
	╔══════════════════════════════════════════════════════════════╗
	║   HUOHUO  ·  Honkai: Star Rail themed control panel          ║
	║   Place as a LocalScript in StarterGui (or StarterPlayerScripts)
	╚══════════════════════════════════════════════════════════════╝

	Features
	  • Floating spirit orb (draggable) + RightControl keybind to open/close
	  • Animated gradient border, spinning sigil, drifting ghost-fire wisps
	  • Background blur + spirit-teal colour grading while open
	  • Animated tabs, toggles, sliders, buttons, toast notifications
	  • Draggable window, responsive sizing, mobile/touch friendly
	  • Demo features: WalkSpeed, JumpPower, Infinite Jump, FOV,
	    Time of Day, Brightness, Spirit Tint (all client-side)
]]

--// Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Debris           = game:GetService("Debris")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

--// Config ---------------------------------------------------------------
local CONFIG = {
	Title         = "Huohuo",
	Subtitle      = "Tail-guided Control Panel",
	ToggleKey     = Enum.KeyCode.RightControl,
	BlurSize      = 18,      -- default blur strength while the panel is open
	AutoOpen      = true,    -- open the panel when the script starts
	-- Upload your Huohuo art to Roblox, then paste its id, e.g. "rbxassetid://1234567890"
	-- Leave empty to show a stylised monogram instead.
	PortraitImage = "",
}

--// Theme (jade-teal ghost fire, midnight navy, gold trim) --------------------
local Theme = {
	Bg       = Color3.fromRGB(8, 18, 26),
	Panel    = Color3.fromRGB(13, 30, 40),
	Elevated = Color3.fromRGB(18, 42, 54),
	Off      = Color3.fromRGB(38, 64, 74),
	Teal     = Color3.fromRGB(70, 240, 208),
	Jade     = Color3.fromRGB(130, 220, 180),
	Gold     = Color3.fromRGB(242, 194, 90),
	Text     = Color3.fromRGB(233, 248, 243),
	Muted    = Color3.fromRGB(128, 165, 165),
	Dark     = Color3.fromRGB(6, 22, 28),
	Danger   = Color3.fromRGB(255, 110, 120),
}

--// Cleanup of any previous run ---------------------------------------------
local GUI_NAME = "HuohuoGUI"
do
	local old = playerGui:FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
	for _, n in ipairs({ "HuohuoBlur", "HuohuoTint" }) do
		local o = Lighting:FindFirstChild(n)
		if o then o:Destroy() end
	end
end

--// Helpers ------------------------------------------------------------------
local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function corner(r)
	return create("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function gradient(c0, c1, rotation)
	return create("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rotation or 0 })
end

local function label(props)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for k, v in pairs(props) do p[k] = v end
	return create("TextLabel", p)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

--// Drag helper (returns nothing; supports tap callback) ---------------------
local function makeDraggable(handle, target, onTap)
	local dragging, moved, dragStart, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, moved = true, false
			dragStart, startPos = input.Position, target.Position
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = input.Position - dragStart
			if d.Magnitude > 5 then moved = true end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and isPress(input) then
			dragging = false
			if not moved and onTap then onTap() end
		end
	end)
end

--// State ----------------------------------------------------------------------
local state = {
	open = false,
	blurEnabled = true,
	blurSize = CONFIG.BlurSize,
	spiritTint = false,
	wisps = true,
	infJump = false,
}

--// Lighting effects ---------------------------------------------------------
local blur = create("BlurEffect", { Name = "HuohuoBlur", Size = 0, Parent = Lighting })
local tint = create("ColorCorrectionEffect", { Name = "HuohuoTint", Parent = Lighting })

local function updateAmbience(duration)
	tween(blur, duration or 0.5, {
		Size = (state.open and state.blurEnabled) and state.blurSize or 0,
	})
	local level = (state.open and 0.35 or 0) + (state.spiritTint and 0.65 or 0)
	tween(tint, 0.7, {
		TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(190, 255, 235), level),
		Saturation = 0.12 * level,
		Contrast = 0.08 * level,
	})
end

--// ScreenGui ----------------------------------------------------------------
local gui = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
	Parent = playerGui,
})

--// Toast notifications ------------------------------------------------------
local toastHolder = create("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.fromOffset(280, 500),
	Parent = gui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}),
})

local function notify(title, text, duration)
	duration = duration or 3.5
	local wrapper = create("Frame", {
		Size = UDim2.fromOffset(270, 60),
		BackgroundTransparency = 1,
		Parent = toastHolder,
	})
	local card = create("CanvasGroup", {
		Position = UDim2.fromOffset(300, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Panel,
		GroupTransparency = 1,
		Parent = wrapper,
	}, { corner(12), stroke(Theme.Teal, 1, 0.45) })

	create("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Theme.Gold,
		BorderSizePixel = 0,
		Parent = card,
	})
	label({
		Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -26, 0, 18),
		Text = title, Font = Enum.Font.GothamBold, TextSize = 14, Parent = card,
	})
	label({
		Position = UDim2.fromOffset(16, 28), Size = UDim2.new(1, -26, 0, 16),
		Text = text, TextSize = 12, TextColor3 = Theme.Muted, Parent = card,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Theme.Teal,
		BorderSizePixel = 0,
		Parent = card,
	})

	tween(card, 0.5, { Position = UDim2.new(), GroupTransparency = 0 })
	tween(bar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(duration, function()
		if not wrapper.Parent then return end
		tween(card, 0.35, { Position = UDim2.fromOffset(300, 0), GroupTransparency = 1 })
		task.wait(0.4)
		wrapper:Destroy()
	end)
end

--// Main window --------------------------------------------------------------
local holder = create("Frame", {
	Name = "Holder",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(640, 400),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})

-- soft aura layers behind the window
local aura1 = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, 40, 1, 40), BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Parent = holder,
}, { corner(36), gradient(Theme.Teal, Theme.Gold, 45) })
local aura2 = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, 18, 1, 18), BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Parent = holder,
}, { corner(26), gradient(Theme.Gold, Theme.Teal, -45) })

local window = create("CanvasGroup", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	GroupTransparency = 1,
	Active = true,
	ZIndex = 1,
	Parent = holder,
}, { corner(18) })
local windowScale = create("UIScale", { Scale = 0.86, Parent = window })
gradient(Color3.fromRGB(15, 36, 46), Color3.fromRGB(7, 15, 22), 90).Parent = window

local windowStroke = stroke(Theme.Teal, 1.5, 0.05)
windowStroke.Parent = window
local strokeGradient = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Teal),
		ColorSequenceKeypoint.new(0.5, Theme.Gold),
		ColorSequenceKeypoint.new(1, Theme.Teal),
	}),
	Parent = windowStroke,
})

-- ghost-fire wisp layer (kept at the back)
local particleLayer = create("Frame", {
	Name = "Wisps", Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = window,
})

--// Header ---------------------------------------------------------------
local header = create("Frame", {
	Name = "Header", Size = UDim2.new(1, 0, 0, 58),
	BackgroundTransparency = 1, Parent = window,
})
local sigil = label({
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0),
	Size = UDim2.fromOffset(32, 32), Text = "☯", TextSize = 30,
	TextColor3 = Theme.Teal, TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBold, Parent = header,
})
local title = label({
	Position = UDim2.fromOffset(60, 9), Size = UDim2.new(1, -140, 0, 24),
	Text = CONFIG.Title, Font = Enum.Font.GothamBold, TextSize = 22,
	TextColor3 = Color3.new(1, 1, 1), Parent = header,
})
gradient(Theme.Teal, Theme.Text, 0).Parent = title
label({
	Position = UDim2.fromOffset(61, 33), Size = UDim2.new(1, -140, 0, 16),
	Text = CONFIG.Subtitle, TextSize = 12, TextColor3 = Theme.Muted, Parent = header,
})

local closeBtn = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Theme.Elevated,
	Text = "×", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Theme.Text,
	AutoButtonColor = false, Parent = header,
}, { corner(15) })

-- gold divider that fades at the edges
local divider = create("Frame", {
	Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = Theme.Gold, BorderSizePixel = 0, Parent = window,
})
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = divider,
})

closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, 0.2, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Dark })
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, 0.2, { BackgroundColor3 = Theme.Elevated, TextColor3 = Theme.Text })
end)

makeDraggable(header, holder)

--// Sidebar --------------------------------------------------------------
local sidebar = create("Frame", {
	Name = "Sidebar", Position = UDim2.fromOffset(0, 60),
	Size = UDim2.new(0, 150, 1, -60), BackgroundTransparency = 1, Parent = window,
})
local sideLine = create("Frame", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Teal,
	BorderSizePixel = 0, Parent = sidebar,
})
create("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = sideLine,
})

local TAB_ORDER = { "Home", "Player", "World", "Settings" }
local TAB_H, TAB_GAP, TAB_TOP = 38, 6, 12

local tabList = create("Frame", {
	Position = UDim2.fromOffset(10, TAB_TOP),
	Size = UDim2.new(1, -20, 0, #TAB_ORDER * (TAB_H + TAB_GAP)),
	BackgroundTransparency = 1, Parent = sidebar,
}, {
	create("UIListLayout", { Padding = UDim.new(0, TAB_GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local indicator = create("Frame", {
	Position = UDim2.fromOffset(0, TAB_TOP + 8), Size = UDim2.fromOffset(3, 22),
	BackgroundColor3 = Theme.Gold, BorderSizePixel = 0, Parent = sidebar,
}, { corner(2) })

-- character card
local portraitCard = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, -20, 0, 66), BackgroundColor3 = Theme.Elevated,
	BackgroundTransparency = 0.2, Parent = sidebar,
}, { corner(12), stroke(Theme.Gold, 1, 0.65) })

local portraitCircle = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(42, 42), BackgroundColor3 = Color3.new(1, 1, 1),
	ClipsDescendants = true, Parent = portraitCard,
}, { corner(21), stroke(Theme.Gold, 1.5, 0), gradient(Theme.Teal, Theme.Jade, 45) })
if CONFIG.PortraitImage ~= "" then
	create("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Image = CONFIG.PortraitImage, ScaleType = Enum.ScaleType.Crop, Parent = portraitCircle,
	})
else
	label({
		Size = UDim2.fromScale(1, 1), Text = "藿", Font = Enum.Font.GothamBold,
		TextSize = 24, TextColor3 = Theme.Dark, TextXAlignment = Enum.TextXAlignment.Center,
		Parent = portraitCircle,
	})
end
label({
	Position = UDim2.fromOffset(60, 14), Size = UDim2.new(1, -66, 0, 18),
	Text = "Huohuo", Font = Enum.Font.GothamBold, TextSize = 14, Parent = portraitCard,
})
label({
	Position = UDim2.fromOffset(60, 33), Size = UDim2.new(1, -66, 0, 16),
	Text = "& Tail", TextSize = 12, TextColor3 = Theme.Jade, Parent = portraitCard,
})

--// Pages ----------------------------------------------------------------
local pagesFrame = create("Frame", {
	Name = "Pages", Position = UDim2.fromOffset(150, 60),
	Size = UDim2.new(1, -150, 1, -60), BackgroundTransparency = 1, Parent = window,
})

local pages, orders = {}, {}
local function nextOrder(page)
	orders[page] = (orders[page] or 0) + 1
	return orders[page]
end

local function createPage(name)
	local group = create("CanvasGroup", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		GroupTransparency = 1, Visible = false, Parent = pagesFrame,
	})
	local scroller = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Teal, ScrollBarImageTransparency = 0.3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = group,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
		}),
	})
	pages[name] = { group = group, scroller = scroller }
	return scroller
end

--// UI components --------------------------------------------------------
local function row(page, height)
	local f = create("Frame", {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = 0.25, LayoutOrder = nextOrder(page), Parent = page,
	}, { corner(10) })
	local s = stroke(Theme.Teal, 1, 0.88)
	s.Parent = f
	f.MouseEnter:Connect(function() tween(s, 0.25, { Transparency = 0.45 }) end)
	f.MouseLeave:Connect(function() tween(s, 0.25, { Transparency = 0.88 }) end)
	return f, s
end

local function rowText(f, name, desc, rightPad)
	rightPad = rightPad or 90
	label({
		Position = UDim2.fromOffset(14, desc and 9 or 0),
		Size = UDim2.new(1, -rightPad, 0, desc and 18 or f.Size.Y.Offset),
		Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, Parent = f,
	})
	if desc then
		label({
			Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -rightPad, 0, 16),
			Text = desc, TextSize = 11, TextColor3 = Theme.Muted, Parent = f,
		})
	end
end

local function section(page, text)
	label({
		Size = UDim2.new(1, 0, 0, 20), Text = string.upper(text),
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Gold,
		LayoutOrder = nextOrder(page), Parent = page,
	})
end

local function toggle(page, name, desc, default, callback)
	local f = row(page, 52)
	rowText(f, name, desc, 90)
	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(44, 24), BackgroundColor3 = Theme.Off, Parent = f,
	}, { corner(12) })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.Text, Parent = track,
	}, { corner(9) })
	local btn = create("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = f,
	})

	local value
	local function set(v, fire, instant)
		value = v
		local d = instant and 0 or 0.3
		tween(track, d, { BackgroundColor3 = v and Theme.Teal or Theme.Off })
		tween(knob, d, {
			Position = v and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = v and Theme.Dark or Theme.Text,
		}, Enum.EasingStyle.Back)
		if fire then callback(v) end
	end
	set(default, false, true)
	btn.MouseButton1Click:Connect(function() set(not value, true) end)
	return { Set = function(v) set(v, true) end }
end

local function fmt(v, step)
	if step < 1 then return string.format("%.1f", v) end
	return tostring(math.floor(v + 0.5))
end

local function slider(page, name, min, max, default, step, callback, suffix)
	local f = row(page, 62)
	label({
		Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -110, 0, 18),
		Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, Parent = f,
	})
	local valueLabel = label({
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 9),
		Size = UDim2.fromOffset(90, 18), Text = "", Font = Enum.Font.GothamBold,
		TextSize = 13, TextColor3 = Theme.Teal, TextXAlignment = Enum.TextXAlignment.Right, Parent = f,
	})
	local track = create("Frame", {
		Position = UDim2.new(0, 14, 0, 43), Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Theme.Off, Parent = f,
	}, { corner(3) })
	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track,
	}, { corner(3), gradient(Theme.Teal, Theme.Jade, 0) })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Theme.Text, ZIndex = 2, Parent = track,
	}, { corner(7), stroke(Theme.Teal, 2, 0) })
	local hit = create("TextButton", {
		Position = UDim2.new(0, 14, 0, 30), Size = UDim2.new(1, -28, 0, 30),
		BackgroundTransparency = 1, Text = "", Parent = f,
	})

	local value
	local function setValue(v, fire, instant)
		v = math.clamp(v, min, max)
		v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		if v == value and not instant then return end
		value = v
		local a = (max == min) and 0 or (v - min) / (max - min)
		local d = instant and 0 or 0.08
		tween(fill, d, { Size = UDim2.fromScale(a, 1) }, Enum.EasingStyle.Quad)
		tween(knob, d, { Position = UDim2.new(a, 0, 0.5, 0) }, Enum.EasingStyle.Quad)
		valueLabel.Text = fmt(v, step) .. (suffix or "")
		if fire then callback(v) end
	end
	setValue(default, false, true)

	local dragging = false
	local function fromInput(input)
		local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(min + (max - min) * rel, true)
	end
	hit.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			tween(knob, 0.2, { Size = UDim2.fromOffset(19, 19) }, Enum.EasingStyle.Back)
			fromInput(input)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then fromInput(input) end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and isPress(input) then
			dragging = false
			tween(knob, 0.2, { Size = UDim2.fromOffset(14, 14) }, Enum.EasingStyle.Back)
		end
	end)

	return { Set = function(v) setValue(v, true) end }
end

local function button(page, name, desc, text, callback, danger)
	local f = row(page, 52)
	rowText(f, name, desc, 130)
	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(98, 28), BackgroundColor3 = danger and Theme.Danger or Color3.new(1, 1, 1),
		Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Dark,
		AutoButtonColor = false, Parent = f,
	}, { corner(8) })
	if not danger then gradient(Theme.Teal, Theme.Jade, 0).Parent = btn end
	local scale = create("UIScale", { Parent = btn })
	btn.MouseEnter:Connect(function() tween(scale, 0.2, { Scale = 1.06 }, Enum.EasingStyle.Back) end)
	btn.MouseLeave:Connect(function() tween(scale, 0.2, { Scale = 1 }) end)
	btn.MouseButton1Down:Connect(function() tween(scale, 0.1, { Scale = 0.92 }) end)
	btn.MouseButton1Up:Connect(function() tween(scale, 0.2, { Scale = 1.06 }, Enum.EasingStyle.Back) end)
	btn.MouseButton1Click:Connect(callback)
end

--// Build pages ------------------------------------------------------------
local home     = createPage("Home")
local playerPg = createPage("Player")
local worldPg  = createPage("World")
local settings = createPage("Settings")

-- HOME ---------------------------------------------------------------------
do
	local hero = create("Frame", {
		Size = UDim2.new(1, 0, 0, 124), BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = nextOrder(home), Parent = home,
	}, {
		corner(14),
		stroke(Theme.Gold, 1, 0.6),
		gradient(Color3.fromRGB(20, 70, 70), Color3.fromRGB(11, 24, 36), 20),
	})
	local pc = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(88, 88), BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true, Parent = hero,
	}, { corner(44), stroke(Theme.Gold, 2, 0), gradient(Theme.Teal, Theme.Jade, 45) })
	if CONFIG.PortraitImage ~= "" then
		create("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Image = CONFIG.PortraitImage, ScaleType = Enum.ScaleType.Crop, Parent = pc,
		})
	else
		label({
			Size = UDim2.fromScale(1, 1), Text = "藿", Font = Enum.Font.GothamBold, TextSize = 48,
			TextColor3 = Theme.Dark, TextXAlignment = Enum.TextXAlignment.Center, Parent = pc,
		})
	end
	local name = label({
		Position = UDim2.fromOffset(120, 20), Size = UDim2.new(1, -130, 0, 30),
		Text = "Huohuo", Font = Enum.Font.GothamBold, TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1), Parent = hero,
	})
	gradient(Theme.Teal, Theme.Gold, 0).Parent = name
	label({
		Position = UDim2.fromOffset(121, 52), Size = UDim2.new(1, -130, 0, 16),
		Text = "Wind  •  Abundance  •  Accompanied by Tail", TextSize = 12,
		TextColor3 = Theme.Jade, Parent = hero,
	})
	label({
		Position = UDim2.fromOffset(121, 74), Size = UDim2.new(1, -130, 0, 34),
		Text = "“Please stay close, Tail… I'm not scared. Really.”",
		TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.GothamMedium, Parent = hero,
	})

	-- live stats
	local statsRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
		LayoutOrder = nextOrder(home), Parent = home,
	})
	local function statCard(xScale, xOffset, caption)
		local card = create("Frame", {
			Position = UDim2.new(xScale, xOffset, 0, 0), Size = UDim2.new(0.5, -4, 1, 0),
			BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 0.25, Parent = statsRow,
		}, { corner(10), stroke(Theme.Teal, 1, 0.88) })
		label({
			Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 14),
			Text = string.upper(caption), Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = Theme.Muted, Parent = card,
		})
		return label({
			Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -28, 0, 28),
			Text = "--", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Theme.Teal, Parent = card,
		})
	end
	local fpsValue  = statCard(0, 0, "Frame rate")
	local pingValue = statCard(0.5, 4, "Ping (ms)")

	local acc, frames = 0, 0
	connect(RunService.Heartbeat, function(dt)
		acc += dt
		frames += 1
		if acc >= 0.5 then
			if state.open then
				fpsValue.Text = tostring(math.floor(frames / acc + 0.5))
				pingValue.Text = tostring(math.floor(player:GetNetworkPing() * 1000 + 0.5))
			end
			acc, frames = 0, 0
		end
	end)

	section(home, "Quick actions")
	button(home, "Greet Tail", "Send a friendly notification", "Say hi", function()
		notify("Tail says hello", "Huohuo hides behind you. Nervously.", 3)
	end)
	local info = row(home, 64)
	label({
		Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 48),
		Text = "Press " .. CONFIG.ToggleKey.Name .. " or tap the spirit orb to open and close this panel. "
			.. "Drag the header to move the window.",
		TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, Parent = info,
	})
end

-- PLAYER -------------------------------------------------------------------
local custom = { WalkSpeed = nil, JumpPower = nil }
local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end
local function applyMovement()
	local hum = getHumanoid()
	if not hum then return end
	if custom.WalkSpeed then hum.WalkSpeed = custom.WalkSpeed end
	if custom.JumpPower then
		hum.UseJumpPower = true
		hum.JumpPower = custom.JumpPower
	end
end
connect(player.CharacterAdded, function(char)
	char:WaitForChild("Humanoid")
	task.wait(0.1)
	applyMovement()
end)
connect(UserInputService.JumpRequest, function()
	if state.infJump then
		local hum = getHumanoid()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

do
	local hum = getHumanoid()
	section(playerPg, "Movement")
	slider(playerPg, "Walk Speed", 0, 100, hum and hum.WalkSpeed or 16, 1, function(v)
		custom.WalkSpeed = v
		applyMovement()
	end)
	slider(playerPg, "Jump Power", 0, 200, hum and hum.JumpPower or 50, 1, function(v)
		custom.JumpPower = v
		applyMovement()
	end)
	toggle(playerPg, "Infinite Jump", "Keep jumping in mid-air", false, function(v)
		state.infJump = v
		notify("Infinite Jump", v and "Enabled" or "Disabled", 2)
	end)
	section(playerPg, "Camera & character")
	slider(playerPg, "Field of View", 40, 120, camera.FieldOfView, 1, function(v)
		camera.FieldOfView = v
	end, "°")
	button(playerPg, "Reset Character", "Respawn instantly", "Reset", function()
		local h = getHumanoid()
		if h then h.Health = 0 end
	end, true)
end

-- WORLD --------------------------------------------------------------------
do
	local original = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness }
	section(worldPg, "Atmosphere")
	local timeSlider = slider(worldPg, "Time of Day", 0, 24, original.ClockTime, 0.5, function(v)
		Lighting.ClockTime = v
	end, " h")
	local brightSlider = slider(worldPg, "Brightness", 0, 5, original.Brightness, 0.1, function(v)
		Lighting.Brightness = v
	end)
	local tintToggle = toggle(worldPg, "Spirit Tint", "Wash the world in ghost-fire teal", false, function(v)
		state.spiritTint = v
		updateAmbience()
	end)
	button(worldPg, "Restore Lighting", "Back to the original look", "Restore", function()
		timeSlider.Set(original.ClockTime)
		brightSlider.Set(original.Brightness)
		tintToggle.Set(false)
		notify("Lighting restored", "Everything is back to normal.", 2.5)
	end)
end

-- SETTINGS -----------------------------------------------------------------
local unload
do
	section(settings, "Visuals")
	toggle(settings, "Background Blur", "Blur the world behind the panel", true, function(v)
		state.blurEnabled = v
		updateAmbience()
	end)
	slider(settings, "Blur Intensity", 0, 40, CONFIG.BlurSize, 1, function(v)
		state.blurSize = v
		updateAmbience(0.2)
	end)
	toggle(settings, "Ghost-fire Wisps", "Drifting spirit particles", true, function(v)
		state.wisps = v
	end)
	section(settings, "General")
	button(settings, "Test Notification", "Preview a toast", "Notify", function()
		notify("Huohuo", "Tail approves of this notification.", 3)
	end)
	button(settings, "Unload GUI", "Remove everything and clean up", "Unload", function()
		unload()
	end, true)
end

--// Tab switching ------------------------------------------------------------
local tabButtons = {}
local currentTab

local function selectTab(name)
	if currentTab == name then return end
	local prevName = currentTab
	currentTab = name

	for n, t in pairs(tabButtons) do
		local active = (n == name)
		tween(t.button, 0.3, { BackgroundTransparency = active and 0.85 or 1 })
		tween(t.label, 0.3, { TextColor3 = active and Theme.Text or Theme.Muted })
		tween(t.dot, 0.3, { BackgroundColor3 = active and Theme.Teal or Theme.Muted })
	end
	tween(indicator, 0.45, {
		Position = UDim2.fromOffset(0, TAB_TOP + (tabButtons[name].index - 1) * (TAB_H + TAB_GAP) + 8),
	}, Enum.EasingStyle.Back)

	if prevName then
		local prev = pages[prevName].group
		tween(prev, 0.18, { GroupTransparency = 1, Position = UDim2.fromOffset(-18, 0) })
		task.delay(0.2, function()
			if currentTab ~= prevName then prev.Visible = false end
		end)
	end

	local pg = pages[name].group
	pg.Visible = true
	pg.Position = UDim2.fromOffset(26, 0)
	pg.GroupTransparency = 1
	task.delay(prevName and 0.12 or 0, function()
		if currentTab == name then
			tween(pg, 0.45, { GroupTransparency = 0, Position = UDim2.new() })
		end
	end)
end

for i, name in ipairs(TAB_ORDER) do
	local btn = create("TextButton", {
		Name = name, Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = Theme.Teal,
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		LayoutOrder = i, Parent = tabList,
	}, { corner(10) })
	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Muted, Parent = btn,
	}, { corner(3) })
	local text = label({
		Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -30, 1, 0), Text = name,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Muted, Parent = btn,
	})
	tabButtons[name] = { button = btn, dot = dot, label = text, index = i }

	btn.MouseEnter:Connect(function()
		if currentTab ~= name then tween(btn, 0.2, { BackgroundTransparency = 0.93 }) end
	end)
	btn.MouseLeave:Connect(function()
		if currentTab ~= name then tween(btn, 0.2, { BackgroundTransparency = 1 }) end
	end)
	btn.MouseButton1Click:Connect(function() selectTab(name) end)
end

--// Open / close -------------------------------------------------------------
local function setOpen(value)
	if state.open == value then return end
	state.open = value
	updateAmbience()
	if value then
		holder.Visible = true
		windowScale.Scale = 0.86
		window.GroupTransparency = 1
		tween(windowScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(window, 0.4, { GroupTransparency = 0 })
		tween(aura1, 0.8, { BackgroundTransparency = 0.95 })
		tween(aura2, 0.8, { BackgroundTransparency = 0.9 })
	else
		tween(windowScale, 0.3, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(window, 0.28, { GroupTransparency = 1 })
		tween(aura1, 0.3, { BackgroundTransparency = 1 })
		tween(aura2, 0.3, { BackgroundTransparency = 1 })
		task.delay(0.35, function()
			if not state.open then holder.Visible = false end
		end)
	end
end

closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == CONFIG.ToggleKey then
		setOpen(not state.open)
	end
end)

--// Floating spirit orb ------------------------------------------------------
local orb = create("TextButton", {
	Name = "Orb", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 46, 0.5, 0),
	Size = UDim2.fromOffset(54, 54), BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "", AutoButtonColor = false, ZIndex = 5, Parent = gui,
}, { corner(27), stroke(Theme.Gold, 2, 0), gradient(Theme.Teal, Theme.Jade, 45) })
local orbScale = create("UIScale", { Parent = orb })
local orbSigil = label({
	Size = UDim2.fromScale(1, 1), Text = "☯", TextSize = 32, Font = Enum.Font.GothamBold,
	TextColor3 = Theme.Dark, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = orb,
})

-- pulsing ripple ring
local ringStroke = stroke(Theme.Teal, 2, 0.2)
local ring = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, ZIndex = 4, Parent = orb,
}, { corner(60), ringStroke })
local pulseInfo = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1)
TweenService:Create(ring, pulseInfo, { Size = UDim2.fromOffset(88, 88) }):Play()
TweenService:Create(ringStroke, pulseInfo, { Transparency = 1 }):Play()

orb.MouseEnter:Connect(function() tween(orbScale, 0.25, { Scale = 1.12 }, Enum.EasingStyle.Back) end)
orb.MouseLeave:Connect(function() tween(orbScale, 0.25, { Scale = 1 }) end)
makeDraggable(orb, orb, function() setOpen(not state.open) end)

--// Ambient animation loops --------------------------------------------------
connect(RunService.RenderStepped, function()
	local t = os.clock()
	orbSigil.Rotation = (t * 25) % 360
	if holder.Visible then
		strokeGradient.Rotation = (t * 45) % 360
		sigil.Rotation = (-t * 30) % 360
	end
end)

local function spawnWisp()
	local size = math.random(3, 8)
	local x = math.random()
	local dur = math.random(45, 80) / 10
	local wisp = create("Frame", {
		Size = UDim2.fromOffset(size, size), Position = UDim2.new(x, 0, 1, 10),
		BackgroundColor3 = (math.random() < 0.2) and Theme.Gold or Theme.Teal,
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = particleLayer,
	}, { corner(size) })
	tween(wisp, dur, {
		Position = UDim2.new(x, math.random(-40, 40), 0, -20),
	}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	tween(wisp, 1, { BackgroundTransparency = 0.55 })
	task.delay(dur - 1.3, function()
		if wisp.Parent then tween(wisp, 1.2, { BackgroundTransparency = 1 }) end
	end)
	Debris:AddItem(wisp, dur + 0.3)
end

task.spawn(function()
	while gui.Parent do
		if state.open and state.wisps then spawnWisp() end
		task.wait(0.3 + math.random() * 0.35)
	end
end)

--// Responsive sizing ----------------------------------------------------------
local function resize()
	local vp = camera.ViewportSize
	local w = math.clamp(vp.X - 40, 380, 640)
	local h = math.clamp(vp.Y - 80, 360, 410)
	holder.Size = UDim2.fromOffset(w, h)
	portraitCard.Visible = h >= 380
end
resize()
connect(camera:GetPropertyChangedSignal("ViewportSize"), resize)

--// Unload -------------------------------------------------------------------
unload = function()
	for _, c in ipairs(connections) do c:Disconnect() end
	state.open = false
	tween(blur, 0.3, { Size = 0 })
	tween(tint, 0.3, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0 })
	tween(windowScale, 0.3, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(window, 0.28, { GroupTransparency = 1 })
	tween(orbScale, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.45, function()
		blur:Destroy()
		tint:Destroy()
		gui:Destroy()
	end)
end

--// Start --------------------------------------------------------------------
selectTab("Home")
if CONFIG.AutoOpen then
	task.delay(0.6, function()
		setOpen(true)
		task.delay(0.8, function()
			notify("Huohuo", "Tail and I are ready. " .. CONFIG.ToggleKey.Name .. " toggles the panel.", 4)
		end)
	end)
end
