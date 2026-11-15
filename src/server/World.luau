-- Builds the island, the lighthouse, the sea and the dusk sky once, when the server starts.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local World = {}

local ISLAND = Config.Island
local TOWER = Config.Tower

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function buildTerrain()
	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(28, 64, 104)
	terrain.WaterReflectance = 0.6
	terrain.WaterTransparency = 0.35
	terrain.WaterWaveSize = 0.35
	terrain.WaterWaveSpeed = 9
	-- The sea, then the island rising out of it in rings of rock, sand and grass.
	terrain:FillBlock(CFrame.new(0, -14, 0), Vector3.new(700, 28, 700), Enum.Material.Water)
	terrain:FillCylinder(CFrame.new(0, -6, 0), 20, ISLAND.Radius + 10, Enum.Material.Rock)
	terrain:FillCylinder(CFrame.new(0, 0.5, 0), 5, ISLAND.Radius + 4, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(0, ISLAND.Height - 2, 0), 4, ISLAND.Radius - 6, Enum.Material.LeafyGrass)
	local random = Random.new(7)
	for i = 1, 26 do
		local angle = (i / 26) * math.pi * 2 + random:NextNumber(-0.1, 0.1)
		local radius = ISLAND.Radius + random:NextNumber(-2, 8)
		local size = random:NextNumber(4, 9)
		terrain:FillBall(Vector3.new(math.cos(angle) * radius, random:NextNumber(-1, 2), math.sin(angle) * radius), size, Enum.Material.Basalt)
	end
	-- Sea stacks out in the tide, where the Drowned come from.
	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2 + 0.4
		local radius = ISLAND.SpawnRadius + random:NextNumber(8, 20)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		terrain:FillBall(base, random:NextNumber(6, 10), Enum.Material.Basalt)
		terrain:FillBall(base + Vector3.new(0, 7, 0), random:NextNumber(3, 6), Enum.Material.Basalt)
	end
end

local function buildLighthouse(): Model
	local model = Instance.new("Model")
	model.Name = "Lighthouse"
	local base = TOWER.Position
	local stripes = { Color3.fromRGB(242, 238, 228), Color3.fromRGB(200, 52, 60) }
	-- Six striped drums, each a little narrower, make the tower.
	for i = 0, 5 do
		local radius = 13 - i * 0.9
		makePart({
			Name = "Drum" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(5, radius, radius),
			CFrame = CFrame.new(base + Vector3.new(0, 2.5 + i * 5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = stripes[i % 2 + 1],
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end
	local top = base + Vector3.new(0, 30, 0)
	makePart({ Name = "Gallery", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 13, 13), CFrame = CFrame.new(top) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 44, 60), Material = Enum.Material.Metal, Parent = model })
	local lantern = makePart({ Name = "Lantern", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 7, 7), CFrame = CFrame.new(top + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Config.Palette.Ember, Material = Enum.Material.Neon, Parent = model })
	makePart({ Name = "Cap", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), CFrame = CFrame.new(top + Vector3.new(0, 6.5, 0)), Color = Color3.fromRGB(40, 44, 60), Material = Enum.Material.Metal, Parent = model })
	local light = Instance.new("PointLight")
	light.Color = Config.Palette.Ember
	light.Range = 60
	light.Brightness = 3
	light.Parent = lantern
	-- The beam the client sweeps around the sea (see Client.Fx.sweepBeam).
	local beam = makePart({ Name = "Beam", Size = Vector3.new(4, 4, 120), CFrame = CFrame.new(top + Vector3.new(0, 3, 0)) * CFrame.new(0, 0, -60), Color = Color3.fromRGB(255, 226, 160), Material = Enum.Material.Neon, Transparency = 0.82, CanCollide = false, CanQuery = false, CastShadow = false, Parent = model })
	beam:SetAttribute("PivotY", top.Y + 3)
	-- Lit windows up the tower.
	for i = 1, 4 do
		makePart({ Name = "Window" .. i, Size = Vector3.new(1.4, 2.2, 0.4), CFrame = CFrame.new(base + Vector3.new(0, 4 + i * 5.5, 0)) * CFrame.Angles(0, i * 1.7, 0) * CFrame.new(0, 0, -(6.6 - i * 0.45)), Color = Config.Palette.Ember, Material = Enum.Material.Neon, Parent = model })
	end
	model.PrimaryPart = lantern
	model.Parent = workspace
	return model
end

local function buildProps()
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = workspace
	local random = Random.new(11)
	-- Lamp posts around the path the player guards.
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local at = Vector3.new(math.cos(angle) * 30, ISLAND.Height, math.sin(angle) * 30)
		makePart({ Name = "Post", Size = Vector3.new(0.6, 7, 0.6), CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0)), Color = Color3.fromRGB(34, 36, 48), Material = Enum.Material.Metal, Parent = props })
		local lamp = makePart({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(at + Vector3.new(0, 7.4, 0)), Color = Config.Palette.Ember, Material = Enum.Material.Neon, Parent = props })
		local glow = Instance.new("PointLight")
		glow.Color = Config.Palette.Ember
		glow.Range = 18
		glow.Brightness = 1.6
		glow.Parent = lamp
	end
	-- Crates, barrels and pines for a lived-in keeper's island.
	for i = 1, 10 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(16, 36)
		local at = Vector3.new(math.cos(angle) * radius, ISLAND.Height, math.sin(angle) * radius)
		if i % 2 == 0 then
			makePart({ Name = "Crate", Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(at + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, angle, 0), Color = Color3.fromRGB(120, 84, 52), Material = Enum.Material.WoodPlanks, Parent = props })
		else
			makePart({ Name = "Pine", Size = Vector3.new(1, 5, 1), CFrame = CFrame.new(at + Vector3.new(0, 2.5, 0)), Color = Color3.fromRGB(70, 48, 36), Material = Enum.Material.Wood, Parent = props })
			local crown = Instance.new("WedgePart")
			crown.Anchored = true
			crown.Size = Vector3.new(5, 7, 5)
			crown.CFrame = CFrame.new(at + Vector3.new(0, 7.5, 0)) * CFrame.Angles(0, angle, 0)
			crown.Color = Color3.fromRGB(36, 92, 70)
			crown.Material = Enum.Material.Grass
			crown.Parent = props
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "KeeperSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, ISLAND.Height + 0.5, 18)
	spawn.Color = Config.Palette.Ember
	spawn.Material = Enum.Material.Slate
	spawn.Duration = 0
	spawn.Parent = workspace
end

local function setDuskLighting()
	Lighting.ClockTime = 17.75
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(70, 60, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 90, 150)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.GlobalShadows = true
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Color = Color3.fromRGB(200, 140, 190)
	atmosphere.Decay = Color3.fromRGB(255, 140, 90)
	atmosphere.Glare = 0.6
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 30
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.18
	grade.Contrast = 0.08
	grade.TintColor = Color3.fromRGB(255, 244, 236)
	grade.Parent = Lighting
end

function World.build()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	buildTerrain()
	buildLighthouse()
	buildProps()
	setDuskLighting()
	local enemies = Instance.new("Folder")
	enemies.Name = "Drowned"
	enemies.Parent = workspace
	return enemies
end

-- A point on the tide ring for a Drowned to rise at.
function World.tideSpawnPoint(random: Random): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	return Vector3.new(math.cos(angle) * ISLAND.SpawnRadius, 0, math.sin(angle) * ISLAND.SpawnRadius)
end

return World
