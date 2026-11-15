-- Feedback for every action: damage numbers, banish bursts, pulse rings, camera shake,
-- the sweeping lighthouse beam and the night's banners.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local Fx = {}

local P = Config.Palette
local camera = workspace.CurrentCamera
local shake = 0
local hud

local function floatingText(position: Vector3, text: string, color: Color3, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(0, 3, 0)
	anchor.Parent = workspace
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 50)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = size
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard
	TweenService:Create(anchor, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.85)
end

local function ring(position: Vector3, radius: number, color: Color3, duration: number)
	local disc = Instance.new("Part")
	disc.Shape = Enum.PartType.Cylinder
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.Material = Enum.Material.Neon
	disc.Color = color
	disc.Transparency = 0.2
	disc.Size = Vector3.new(0.4, 2, 2)
	disc.CFrame = CFrame.new(position.X, Config.Island.Height + 0.6, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = workspace
	TweenService:Create(disc, TweenInfo.new(duration, Enum.EasingStyle.Quint), { Size = Vector3.new(0.4, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(disc, duration + 0.05)
end

local function burst(position: Vector3, color: Color3, count: number)
	for _ = 1, count do
		local spark = Instance.new("Part")
		spark.Shape = Enum.PartType.Ball
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanQuery = false
		spark.Material = Enum.Material.Neon
		spark.Color = color
		spark.Size = Vector3.one * math.random(6, 12) / 10
		spark.Position = position
		spark.Parent = workspace
		local fly = Vector3.new(math.random(-10, 10), math.random(4, 12), math.random(-10, 10))
		TweenService:Create(spark, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Position = position + fly, Transparency = 1, Size = Vector3.one * 0.1 }):Play()
		Debris:AddItem(spark, 0.65)
	end
end

-- The lighthouse beam turns once every eight seconds, on this client only.
local function sweepBeam()
	local lighthouse = workspace:WaitForChild("Lighthouse", 10)
	local beam = lighthouse and lighthouse:WaitForChild("Beam", 10)
	if not beam then
		warn("lighthouse beam not found")
		return
	end
	local pivotY = beam:GetAttribute("PivotY")
	RunService.RenderStepped:Connect(function()
		local angle = os.clock() * math.pi / 4
		beam.CFrame = CFrame.new(0, pivotY, 0) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-6), 0, 0) * CFrame.new(0, 0, -60)
	end)
end

local function onFeedback(kind: string, a: any, b: any, c: any)
	if kind == "Hit" then
		floatingText(a, tostring(b), P.Ember, 26)
	elseif kind == "Banish" then
		burst(a, P.Glow, b == "Leviathan" and 40 or 10)
		floatingText(a, "+" .. tostring(c) .. " embers", P.Glow, 30)
	elseif kind == "Rise" then
		ring(a, b == "Leviathan" and 30 or 6, Color3.fromRGB(120, 200, 255), 0.8)
	elseif kind == "Pulse" then
		ring(a, b, P.Glow, 0.45)
		shake = math.max(shake, 0.5)
	elseif kind == "TowerHit" then
		shake = math.max(shake, 0.35)
	elseif kind == "PlayerHit" then
		floatingText(a, "-" .. tostring(b), P.Danger, 30)
		shake = math.max(shake, 0.6)
	elseif kind == "WaveStart" then
		hud.banner(string.format("NIGHT %d — %s", a, b), a == #Config.Waves and P.Danger or P.Ember)
	elseif kind == "WaveCleared" then
		hud.banner("THE TIDE RECEDES", P.Glow)
	elseif kind == "BossBanished" then
		hud.banner("THE LEVIATHAN SINKS!", P.Glow)
		shake = 1.2
	elseif kind == "TowerMended" then
		hud.banner("+" .. tostring(a) .. " TOWER MENDED", P.Heal)
	elseif kind == "Upgraded" then
		hud.banner(tostring(a), P.Glow)
	end
end

local function applyShake()
	if shake > 0 then
		local s = shake * 0.6
		camera.CFrame *= CFrame.new(math.random(-10, 10) / 10 * s, math.random(-10, 10) / 10 * s, 0)
		shake = math.max(0, shake - 0.05)
	end
end

function Fx.start(hudModule)
	hud = hudModule
	Net.remote("Feedback").OnClientEvent:Connect(onFeedback)
	RunService:BindToRenderStep("LastLightShake", Enum.RenderPriority.Camera.Value + 2, applyShake)
	task.spawn(sweepBeam)
end

return Fx
