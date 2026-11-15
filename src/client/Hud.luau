-- Every screen the keeper reads: the title card, the night's HUD, the upgrade cards and the dawn
-- (or ruin) screen. It only reads the server's State and sends requests; it keeps no game state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local Hud = {}

local P = Config.Palette
local FONT = Enum.Font.FredokaOne
local BODY = Enum.Font.GothamBold
local gui: ScreenGui
local screens: { [string]: Frame } = {}

local function new(className: string, props: { [string]: any }, children: { Instance }?): Instance
	local object = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(object :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = object
	end
	object.Parent = props.Parent
	return object
end

local function corner(radius: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }) :: UICorner
end

local function stroke(color: Color3, thickness: number): UIStroke
	return new("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) :: UIStroke
end

local function label(props: { [string]: any }): TextLabel
	local defaults = { BackgroundTransparency = 1, Font = BODY, TextColor3 = P.Text, TextScaled = false, TextSize = 22 }
	for key, value in props do
		defaults[key] = value
	end
	return new("TextLabel", defaults) :: TextLabel
end

local function panel(props: { [string]: any }): Frame
	local defaults = { BackgroundColor3 = P.Panel, BackgroundTransparency = 0.12, BorderSizePixel = 0 }
	for key, value in props do
		defaults[key] = value
	end
	local frame = new("Frame", defaults) :: Frame
	corner(14).Parent = frame
	stroke(P.Ember, 2).Parent = frame
	return frame
end

local function button(text: string, props: { [string]: any }, onClick: () -> ()): TextButton
	local defaults = { BackgroundColor3 = P.Ember, Font = FONT, Text = text, TextColor3 = P.Night, TextSize = 34, AutoButtonColor = true, BorderSizePixel = 0 }
	for key, value in props do
		defaults[key] = value
	end
	local b = new("TextButton", defaults) :: TextButton
	corner(16).Parent = b
	stroke(Color3.fromRGB(255, 226, 170), 3).Parent = b
	b.Activated:Connect(onClick)
	return b
end

local function buildTitleScreen()
	local screen = new("Frame", { Name = "Title", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui }) :: Frame
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.6), NumberSequenceKeypoint.new(1, 0.05) }), Color = ColorSequence.new(P.Night) , Parent = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.Night, BorderSizePixel = 0, Parent = screen }) })
	label({ Text = "LAST LIGHT", Font = FONT, TextSize = 104, TextColor3 = P.Ember, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, -20), Size = UDim2.fromOffset(900, 110), TextStrokeTransparency = 0.4, Parent = screen })
	label({ Text = "Keep the lighthouse burning through five nights of the Drowned", TextSize = 26, TextColor3 = P.Text, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 92), Size = UDim2.fromOffset(900, 34), Parent = screen })
	label({ Text = "CLICK  fire a flare bolt      Q  beacon pulse      WASD  move", TextSize = 20, TextColor3 = P.Muted, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 132), Size = UDim2.fromOffset(900, 28), Parent = screen })
	button("LIGHT THE LAMP", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 178), Size = UDim2.fromOffset(330, 68), Parent = screen }, function()
		Net.remote("RequestStart"):FireServer()
	end)
	screens.Title = screen
end

local function bar(parent: Instance, name: string, color: Color3, position: UDim2, size: UDim2): (Frame, TextLabel)
	local back = new("Frame", { Name = name, BackgroundColor3 = Color3.fromRGB(10, 12, 26), BorderSizePixel = 0, Position = position, Size = size, Parent = parent }) :: Frame
	corner(9).Parent = back
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = back }) :: Frame
	corner(9).Parent = fill
	local text = label({ Size = UDim2.fromScale(1, 1), TextSize = 20, Font = FONT, TextStrokeTransparency = 0.5, ZIndex = 3, Parent = back })
	return fill, text
end

local function buildNightHud()
	local screen = new("Frame", { Name = "Night", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui }) :: Frame
	-- Top centre: the night and what is left of it.
	local top = panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(460, 92), Parent = screen })
	local waveText = label({ Name = "Wave", Font = FONT, TextSize = 34, TextColor3 = P.Ember, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 40), Parent = top })
	local remainingText = label({ Name = "Remaining", TextSize = 20, TextColor3 = P.Muted, Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 30), Parent = top })
	-- Bottom: the tower's health, the keeper's embers and the pulse's charge.
	local bottom = panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(620, 96), Parent = screen })
	label({ Text = "LIGHTHOUSE", TextSize = 16, TextColor3 = P.Muted, Position = UDim2.fromOffset(18, 8), Size = UDim2.fromOffset(200, 20), TextXAlignment = Enum.TextXAlignment.Left, Parent = bottom })
	local towerFill, towerText = bar(bottom, "Tower", P.Ember, UDim2.fromOffset(18, 30), UDim2.fromOffset(380, 30))
	local embersText = label({ Name = "Embers", Font = FONT, TextSize = 30, TextColor3 = P.Ember, Position = UDim2.fromOffset(410, 10), Size = UDim2.fromOffset(190, 36), TextXAlignment = Enum.TextXAlignment.Right, Parent = bottom })
	local pulseFill, pulseText = bar(bottom, "Pulse", P.Glow, UDim2.fromOffset(410, 52), UDim2.fromOffset(190, 26))
	label({ Text = "CLICK bolt  ·  Q pulse", TextSize = 16, TextColor3 = P.Muted, Position = UDim2.fromOffset(18, 66), Size = UDim2.fromOffset(380, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = bottom })

	Net.onState("Wave", function(wave)
		waveText.Text = string.format("NIGHT %d / %d", wave or 0, Net.getState("WaveCount") or #Config.Waves)
	end)
	local function showRemaining()
		remainingText.Text = string.format("%s  ·  %d Drowned left", Net.getState("WaveName") or "", Net.getState("Remaining") or 0)
	end
	Net.onState("Remaining", showRemaining)
	Net.onState("WaveName", showRemaining)
	Net.onState("TowerHealth", function(health)
		local max = Net.getState("TowerMax") or Config.Tower.MaxHealth
		local share = math.clamp((health or max) / max, 0, 1)
		TweenService:Create(towerFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(share, 1), BackgroundColor3 = share < 0.3 and P.Danger or P.Ember }):Play()
		towerText.Text = string.format("%d / %d", health or max, max)
	end)
	Net.onState("Embers", function(embers)
		embersText.Text = string.format("EMBERS %d", embers or 0)
	end)
	Hud.pulseFill, Hud.pulseText = pulseFill, pulseText
	screens.Night = screen
end

local function buildUpgradeCards()
	local screen = new("Frame", { Name = "Upgrade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui }) :: Frame
	label({ Text = "DAWN BREAK — CHOOSE A BLESSING", Font = FONT, TextSize = 44, TextColor3 = P.Ember, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, -190), Size = UDim2.fromOffset(900, 50), TextStrokeTransparency = 0.3, Parent = screen })
	local row = new("Frame", { Name = "Cards", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(780, 240), BackgroundTransparency = 1, Parent = screen }) :: Frame
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 24), Parent = row })
	Net.onState("Offer", function(offer)
		for _, child in row:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, id in string.split(offer or "", ",") do
			local upgrade = Config.Upgrades[id]
			if upgrade then
				local card = button("", { Size = UDim2.fromOffset(240, 240), BackgroundColor3 = P.Panel, Parent = row }, function()
					Net.remote("ChooseUpgrade"):FireServer(id)
				end)
				label({ Text = upgrade.Icon, Font = FONT, TextColor3 = P.Glow, TextSize = 60, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 76), Parent = card })
				label({ Text = upgrade.Title, Font = FONT, TextSize = 30, TextColor3 = P.Ember, Position = UDim2.fromOffset(10, 104), Size = UDim2.new(1, -20, 0, 36), Parent = card })
				label({ Text = upgrade.Detail, TextSize = 20, TextColor3 = P.Text, TextWrapped = true, Position = UDim2.fromOffset(14, 148), Size = UDim2.new(1, -28, 0, 60), Parent = card })
			end
		end
	end)
	screens.Upgrade = screen
end

local function buildEndScreen()
	local screen = new("Frame", { Name = "End", Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.Night, BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, Parent = gui }) :: Frame
	local box = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 400), Parent = screen })
	local headline = label({ Name = "Headline", Font = FONT, TextSize = 72, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 80), Parent = box })
	local subline = label({ Name = "Subline", TextSize = 24, TextColor3 = P.Text, Position = UDim2.fromOffset(0, 106), Size = UDim2.new(1, 0, 0, 30), Parent = box })
	local stats = label({ Name = "Stats", Font = FONT, TextSize = 28, TextColor3 = P.Text, Position = UDim2.fromOffset(40, 152), Size = UDim2.new(1, -80, 0, 120), TextYAlignment = Enum.TextYAlignment.Top, Parent = box })
	button("KEEP ANOTHER NIGHT", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -28), Size = UDim2.fromOffset(380, 66), Parent = box }, function()
		Net.remote("RequestStart"):FireServer()
	end)
	function Hud.showEnd(won: boolean)
		headline.Text = won and "DAWN!" or "THE LIGHT IS OUT"
		headline.TextColor3 = won and P.Ember or P.Danger
		subline.Text = won and "The Leviathan sinks. The lighthouse stands." or "The Drowned took the tower."
		local seconds = (Net.getState("EndedAt") or 0) - (Net.getState("StartedAt") or 0)
		stats.Text = string.format("Nights kept   %d / %d\nDrowned banished   %d\nEmbers   %d     Time   %d:%02d",
			won and #Config.Waves or math.max((Net.getState("Wave") or 1) - 1, 0), #Config.Waves,
			Net.getState("Banished") or 0, Net.getState("Embers") or 0, seconds // 60, seconds % 60)
	end
	screens.End = screen
end

-- Shows the screens that belong to a phase of the night.
function Hud.showPhase(phase: string)
	screens.Title.Visible = phase == "Lobby"
	screens.Night.Visible = phase == "Wave" or phase == "Upgrade"
	screens.Upgrade.Visible = phase == "Upgrade"
	screens.End.Visible = phase == "Victory" or phase == "Defeat"
	if screens.End.Visible then
		Hud.showEnd(phase == "Victory")
	end
end

function Hud.setPulseCharge(share: number)
	Hud.pulseFill.Size = UDim2.fromScale(math.clamp(share, 0, 1), 1)
	Hud.pulseText.Text = share >= 1 and "PULSE READY" or "charging…"
end

function Hud.banner(text: string, color: Color3?)
	local big = label({ Text = text, Font = FONT, TextSize = 64, TextColor3 = color or P.Ember, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(1000, 80), TextStrokeTransparency = 0.2, TextTransparency = 1, Parent = gui })
	TweenService:Create(big, TweenInfo.new(0.35, Enum.EasingStyle.Back), { TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.28) }):Play()
	task.delay(2.2, function()
		local fade = TweenService:Create(big, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		big:Destroy()
	end)
end

function Hud.build()
	gui = new("ScreenGui", { Name = "LastLightHud", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") }) :: ScreenGui
	buildTitleScreen()
	buildNightHud()
	buildUpgradeCards()
	buildEndScreen()
	Net.onState("Phase", function(phase)
		Hud.showPhase(phase or "Lobby")
	end)
	return gui
end

return Hud
