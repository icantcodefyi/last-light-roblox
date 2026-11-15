-- LAST LIGHT server: builds the island, then wires each client request to the module that owns it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local World = require(script.World)
local Enemies = require(script.Enemies)
local Combat = require(script.Combat)
local Waves = require(script.Waves)

local drowned = World.build()
Enemies.init(drowned, {
	onDeath = Waves.onBanished,
	onTowerHit = Waves.onTowerHit,
	onSpawn = Waves.onSpawned,
	onBossHealth = Waves.onBossHealth,
})
Waves.init()

Net.remote("RequestStart").OnServerEvent:Connect(Waves.requestStart)
Net.remote("ChooseUpgrade").OnServerEvent:Connect(Waves.chooseUpgrade)
Net.remote("FireBolt").OnServerEvent:Connect(Combat.fireBolt)
Net.remote("CastPulse").OnServerEvent:Connect(Combat.castPulse)
