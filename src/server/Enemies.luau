-- The Drowned: builds each kind's body, walks every living one toward its target in a single
-- Heartbeat step, and resolves damage, deaths and rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local Enemies = {}

local feedback = Net.remote("Feedback")
local living: { [Model]: { kind: string, health: number, maxHealth: number, stats: any, nextAttack: number } } = {}
local folder: Folder
local onDeath: (kind: string, reward: number, killer: Player?) -> () = function() end
local onTowerHit: (damage: number) -> () = function() end

local SKIN = {
	Crawler = { Body = Color3.fromRGB(38, 92, 96), Eye = Color3.fromRGB(130, 255, 210) },
	Brute = { Body = Color3.fromRGB(70, 62, 80), Eye = Color3.fromRGB(255, 120, 70) },
	Wisp = { Body = Color3.fromRGB(150, 220, 255), Eye = Color3.fromRGB(255, 255, 255) },
	Leviathan = { Body = Color3.fromRGB(30, 40, 70), Eye = Color3.fromRGB(255, 70, 90) },
}

local function addPart(model: Model, name: string, shape: Enum.PartType, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = offset
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = name == "Body"
	part.Parent = model
	return part
end

local function buildBody(kind: string, scale: number): Model
	local model = Instance.new("Model")
	model.Name = kind
	local skin = SKIN[kind]
	local body = addPart(model, "Body", Enum.PartType.Ball, Vector3.one * 3 * scale, CFrame.new(), skin.Body, kind == "Wisp" and Enum.Material.Neon or Enum.Material.Slate)
	if kind == "Wisp" then
		body.Transparency = 0.25
		local glow = Instance.new("PointLight")
		glow.Color = Config.Palette.Glow
		glow.Range = 14
		glow.Parent = body
	else
		-- Shell, claws and barnacles on everything that walks.
		addPart(model, "Shell", Enum.PartType.Block, Vector3.new(3.2, 1.2, 2.6) * scale, CFrame.new(0, 1.1 * scale, 0.3 * scale), skin.Body:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Basalt)
		for side = -1, 1, 2 do
			addPart(model, "Claw", Enum.PartType.Wedge, Vector3.new(0.8, 1.2, 2) * scale, CFrame.new(side * 1.9 * scale, -0.2 * scale, -1.4 * scale), skin.Body:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Slate)
			addPart(model, "Leg", Enum.PartType.Block, Vector3.new(0.5, 1.6, 0.5) * scale, CFrame.new(side * 1.3 * scale, -1.3 * scale, 0.6 * scale), skin.Body, Enum.Material.Slate)
		end
	end
	for side = -1, 1, 2 do
		addPart(model, "Eye", Enum.PartType.Ball, Vector3.one * 0.7 * scale, CFrame.new(side * 0.6 * scale, 0.5 * scale, -1.35 * scale), skin.Eye, Enum.Material.Neon)
	end
	model.PrimaryPart = body
	return model
end

local function addHealthBar(model: Model, kind: string)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(kind == "Leviathan" and 160 or 60, kind == "Leviathan" and 14 or 7)
	billboard.StudsOffset = Vector3.new(0, model.PrimaryPart.Size.Y * 0.75 + 1, 0)
	billboard.AlwaysOnTop = true
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
	back.BorderSizePixel = 0
	back.Parent = billboard
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Config.Palette.Danger
	fill.BorderSizePixel = 0
	fill.Parent = back
	billboard.Parent = model.PrimaryPart
end

function Enemies.init(enemyFolder: Folder, handlers: { onDeath: (string, number, Player?) -> (), onTowerHit: (number) -> () })
	folder = enemyFolder
	onDeath = handlers.onDeath
	onTowerHit = handlers.onTowerHit
	RunService.Heartbeat:Connect(Enemies.step)
end

function Enemies.spawn(kind: string, at: Vector3)
	local stats = Config.Enemies[kind]
	local scale = ({ Crawler = 0.9, Brute = 1.7, Wisp = 0.7, Leviathan = 3.6 })[kind]
	local model = buildBody(kind, scale)
	model:PivotTo(CFrame.new(at.X, -3, at.Z))
	addHealthBar(model, kind)
	model:SetAttribute("Kind", kind)
	model.Parent = folder
	living[model] = { kind = kind, health = stats.Health, maxHealth = stats.Health, stats = stats, nextAttack = 0 }
	feedback:FireAllClients("Rise", model:GetPivot().Position, kind)
	return model
end

local function nearestCharacterRoot(from: Vector3): BasePart?
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - from).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

-- How high a Drowned stands: wading in the tide, then up on the island's grass; wisps bob above both.
function Enemies.heightAt(position: Vector3, stats: any, now: number, dt: number): number
	local fromCentre = Vector3.new(position.X, 0, position.Z).Magnitude
	local ground = fromCentre < Config.Island.Radius - 2 and Config.Island.Height or 0.2
	local bob = stats.Target == "Player" and math.sin(now * 3 + position.X) * 0.8 or 0
	local goal = ground + stats.Height + bob
	return position.Y + math.clamp(goal - position.Y, -dt * 6, dt * 6) -- rises out of the tide, climbs the shore
end

-- One pass over every living Drowned: move, face, rise out of the water, and attack in reach.
function Enemies.step(dt: number)
	local now = os.clock()
	for model, enemy in living do
		local stats = enemy.stats
		local pivot = model:GetPivot()
		local position = pivot.Position
		local targetPosition, reach, targetRoot = Config.Tower.Position, Config.Tower.Reach + (stats.Boss and 8 or 0), nil
		if stats.Target == "Player" then
			targetRoot = nearestCharacterRoot(position)
			if targetRoot then
				targetPosition, reach = targetRoot.Position, 3.5
			end
		end
		local flat = Vector3.new(targetPosition.X - position.X, 0, targetPosition.Z - position.Z)
		local distance = flat.Magnitude
		local nextPosition = Vector3.new(position.X, Enemies.heightAt(position, stats, now, dt), position.Z)
		if distance > reach then
			nextPosition += flat.Unit * math.min(stats.Speed * dt, distance - reach)
		elseif now >= enemy.nextAttack then
			enemy.nextAttack = now + 1.5
			if targetRoot then
				local humanoid = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:TakeDamage(stats.Damage)
					feedback:FireAllClients("PlayerHit", targetRoot.Position, stats.Damage)
				end
			else
				onTowerHit(stats.Damage)
			end
		end
		local look = distance > 0.1 and flat.Unit or pivot.LookVector
		model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + look))
	end
end

function Enemies.damage(model: Model, amount: number, attacker: Player?): boolean
	local enemy = living[model]
	if not enemy then
		return false
	end
	enemy.health -= amount
	local bar = model.PrimaryPart:FindFirstChild("HealthBar")
	if bar then
		bar.Frame.Fill.Size = UDim2.fromScale(math.max(enemy.health, 0) / enemy.maxHealth, 1)
	end
	feedback:FireAllClients("Hit", model:GetPivot().Position, math.floor(amount))
	if enemy.health <= 0 then
		living[model] = nil
		feedback:FireAllClients("Banish", model:GetPivot().Position, enemy.kind, enemy.stats.Reward)
		model:Destroy()
		onDeath(enemy.kind, enemy.stats.Reward, attacker)
	end
	return true
end

-- The Drowned a flat shot from `origin` along `direction` passes through, nearest first, with how far along.
function Enemies.alongLine(origin: Vector3, direction: Vector3, range: number, radius: number): { { model: Model, along: number } }
	local hits = {}
	for model in living do
		local offset = model:GetPivot().Position - origin
		local flatOffset = Vector3.new(offset.X, 0, offset.Z)
		local along = flatOffset:Dot(direction)
		local reach = radius + model.PrimaryPart.Size.X * 0.5
		if along > 0 and along <= range and (flatOffset - direction * along).Magnitude <= reach then
			table.insert(hits, { model = model, along = along })
		end
	end
	table.sort(hits, function(a, b)
		return a.along < b.along
	end)
	return hits
end

function Enemies.count(): number
	local n = 0
	for _ in living do
		n += 1
	end
	return n
end

function Enemies.clear()
	for model in living do
		model:Destroy()
	end
	table.clear(living)
end

return Enemies
