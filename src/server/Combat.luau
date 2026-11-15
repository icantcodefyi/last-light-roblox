-- The keeper's light: validates every bolt and pulse a client asks for, applies upgrades,
-- and draws the shots for everyone.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Enemies = require(script.Parent.Enemies)

local Combat = {}

local feedback = Net.remote("Feedback")
local loadouts: { [Player]: { damage: number, cooldown: number, pulseRadius: number, pierce: number, lastBolt: number, lastPulse: number } } = {}

local function freshLoadout()
	local p = Config.Player
	return { damage = p.BoltDamage, cooldown = p.BoltCooldown, pulseRadius = p.PulseRadius, pierce = 0, lastBolt = 0, lastPulse = 0 }
end

local function loadoutOf(player: Player)
	local loadout = loadouts[player]
	if not loadout then
		loadout = freshLoadout()
		loadouts[player] = loadout
	end
	return loadout
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function drawBolt(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local bolt = Instance.new("Part")
	bolt.Name = "Bolt"
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = Config.Palette.Ember
	bolt.Size = Vector3.new(0.6, 0.6, length)
	bolt.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	bolt.Parent = workspace
	TweenService:Create(bolt, TweenInfo.new(0.18), { Transparency = 1, Size = Vector3.new(0.1, 0.1, length) }):Play()
	Debris:AddItem(bolt, 0.2)
end

-- A bolt flies flat from the keeper toward the aimed point and hits up to 1 + pierce Drowned.
function Combat.fireBolt(player: Player, aim: Vector3)
	local loadout = loadoutOf(player)
	local root = rootOf(player)
	local now = os.clock()
	if not root or typeof(aim) ~= "Vector3" or now - loadout.lastBolt < loadout.cooldown * 0.9 then
		return
	end
	loadout.lastBolt = now
	local origin = root.Position + Vector3.new(0, 1.5, 0)
	local flat = Vector3.new(aim.X - origin.X, 0, aim.Z - origin.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local direction = flat.Unit
	local finish = origin + direction * Config.Player.BoltRange
	local hits = Enemies.alongLine(origin, direction, Config.Player.BoltRange, Config.Player.BoltRadius)
	for i, hit in hits do
		if i > 1 + loadout.pierce then
			break
		end
		finish = hit.model:GetPivot().Position
		Enemies.damage(hit.model, loadout.damage, player)
	end
	drawBolt(origin, finish)
end

-- The beacon pulse: a ring of light that scorches every Drowned near the keeper.
function Combat.castPulse(player: Player)
	local loadout = loadoutOf(player)
	local root = rootOf(player)
	local now = os.clock()
	if not root or now - loadout.lastPulse < Config.Player.PulseCooldown * 0.95 then
		return
	end
	loadout.lastPulse = now
	local center = root.Position
	for _, enemy in Enemies.within(center, loadout.pulseRadius) do
		Enemies.damage(enemy, Config.Player.PulseDamage, player)
	end
	feedback:FireAllClients("Pulse", center, loadout.pulseRadius)
end

function Combat.applyUpgrade(player: Player, upgradeId: string): boolean
	local loadout = loadoutOf(player)
	if upgradeId == "Damage" then
		loadout.damage *= 1.35
	elseif upgradeId == "Rate" then
		loadout.cooldown *= 0.75
	elseif upgradeId == "Pulse" then
		loadout.pulseRadius *= 1.4
	elseif upgradeId == "Pierce" then
		loadout.pierce += 2
	elseif upgradeId ~= "Repair" then
		return false -- Repair is applied to the tower by Waves
	end
	return true
end

function Combat.resetLoadouts()
	table.clear(loadouts)
end

Players.PlayerRemoving:Connect(function(player)
	loadouts[player] = nil
end)

return Combat
