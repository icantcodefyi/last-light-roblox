-- The night's state machine: Lobby -> Wave -> Upgrade -> ... -> Victory or Defeat -> Lobby.
-- Every value the HUD shows is written here, once, through Net.setState.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Enemies = require(script.Parent.Enemies)
local Combat = require(script.Parent.Combat)
local World = require(script.Parent.World)

local Waves = {}

local feedback = Net.remote("Feedback")
local random = Random.new()
local runId = 0 -- bumps on every restart so an old night's threads stop
local chosen: { [Player]: boolean } = {}
local towerHealth = Config.Tower.MaxHealth

local function setPhase(phase: string)
	Net.setState("Phase", phase)
end

local function setTowerHealth(value: number)
	towerHealth = math.clamp(value, 0, Config.Tower.MaxHealth)
	Net.setState("TowerHealth", math.floor(towerHealth))
end

local function resetNight()
	runId += 1
	Enemies.clear()
	Combat.resetLoadouts()
	setTowerHealth(Config.Tower.MaxHealth)
	Net.setState("TowerMax", Config.Tower.MaxHealth)
	Net.setState("Wave", 0)
	Net.setState("WaveCount", #Config.Waves)
	Net.setState("Embers", 0)
	Net.setState("Banished", 0)
	Net.setState("Remaining", 0)
	Net.setState("StartedAt", os.time())
	Net.setState("Offer", "")
end

local function respawnKeepers()
	for _, player in Players:GetPlayers() do
		local ok, err = pcall(player.LoadCharacter, player)
		if not ok then
			warn("could not respawn " .. player.Name .. ": " .. tostring(err))
		end
	end
end

local function endNight(won: boolean)
	Net.setState("EndedAt", os.time())
	setPhase(won and "Victory" or "Defeat")
	Enemies.clear()
	feedback:FireAllClients(won and "Victory" or "Defeat")
end

local function offerUpgrades()
	local ids = {}
	for id in Config.Upgrades do
		table.insert(ids, id)
	end
	table.sort(ids)
	local offer = {}
	for _ = 1, Config.UpgradeChoices do
		table.insert(offer, table.remove(ids, random:NextInteger(1, #ids)))
	end
	table.clear(chosen)
	Net.setState("Offer", table.concat(offer, ","))
	setPhase("Upgrade")
end

-- Spawns one wave's Drowned on the tide ring, the boss first, and waits until all are banished.
local function runWave(waveNumber: number, myRun: number): boolean
	local wave = Config.Waves[waveNumber]
	Net.setState("Wave", waveNumber)
	Net.setState("WaveName", wave.Name)
	setPhase("Wave")
	feedback:FireAllClients("WaveStart", waveNumber, wave.Name)
	local bosses, queue = {}, {}
	for kind, count in wave.Spawns do
		for _ = 1, count do
			table.insert(Config.Enemies[kind].Boss and bosses or queue, kind)
		end
	end
	for i = #queue, 2, -1 do -- shuffle the swarm, then the boss leads it
		local j = random:NextInteger(1, i)
		queue[i], queue[j] = queue[j], queue[i]
	end
	for i, kind in bosses do
		table.insert(queue, i, kind)
	end
	local remaining = #queue
	Net.setState("Remaining", remaining)
	task.wait(2.5)
	for _, kind in queue do
		if runId ~= myRun or towerHealth <= 0 then
			return false
		end
		Enemies.spawn(kind, World.tideSpawnPoint(random))
		task.wait(wave.Interval)
	end
	while Enemies.count() > 0 do
		if runId ~= myRun or towerHealth <= 0 then
			return false
		end
		task.wait(0.25)
	end
	return runId == myRun and towerHealth > 0
end

local function waitForUpgrades(myRun: number)
	offerUpgrades()
	local deadline = os.clock() + Config.IntermissionSeconds
	Net.setState("UpgradeEndsAt", workspace:GetServerTimeNow() + Config.IntermissionSeconds)
	while os.clock() < deadline and runId == myRun do
		local everyone = true
		for _, player in Players:GetPlayers() do
			everyone = everyone and chosen[player] == true
		end
		if everyone then
			break
		end
		task.wait(0.2)
	end
	Net.setState("Offer", "")
end

local function runNight()
	resetNight()
	local myRun = runId
	respawnKeepers()
	for waveNumber = 1, #Config.Waves do
		if not runWave(waveNumber, myRun) then
			if runId == myRun then
				endNight(false)
			end
			return
		end
		if waveNumber < #Config.Waves then
			feedback:FireAllClients("WaveCleared", waveNumber)
			waitForUpgrades(myRun)
		end
	end
	endNight(true)
end

function Waves.onTowerHit(damage: number)
	if Net.getState("Phase") ~= "Wave" then
		return
	end
	setTowerHealth(towerHealth - damage)
	feedback:FireAllClients("TowerHit", damage)
	if towerHealth <= 0 then
		runId += 1 -- stops the running wave's thread
		endNight(false)
	end
end

function Waves.onBanished(kind: string, reward: number, _killer: Player?)
	Net.setState("Embers", (Net.getState("Embers") or 0) + reward)
	Net.setState("Banished", (Net.getState("Banished") or 0) + 1)
	Net.setState("Remaining", math.max((Net.getState("Remaining") or 1) - 1, 0))
	if Config.Enemies[kind].Boss then
		feedback:FireAllClients("BossBanished")
	end
end

function Waves.requestStart(_player: Player)
	local phase = Net.getState("Phase")
	if phase == "Lobby" or phase == "Victory" or phase == "Defeat" then
		task.spawn(runNight)
	end
end

function Waves.chooseUpgrade(player: Player, upgradeId: string)
	local offer = Net.getState("Offer") or ""
	if Net.getState("Phase") ~= "Upgrade" or chosen[player] or typeof(upgradeId) ~= "string" then
		return
	end
	if not table.find(string.split(offer, ","), upgradeId) then
		return
	end
	chosen[player] = true
	if upgradeId == "Repair" then
		setTowerHealth(towerHealth + 200)
		feedback:FireAllClients("TowerMended", 200)
	else
		Combat.applyUpgrade(player, upgradeId)
	end
	feedback:FireClient(player, "Upgraded", Config.Upgrades[upgradeId].Title)
end

function Waves.init()
	resetNight()
	setPhase("Lobby")
end

return Waves
