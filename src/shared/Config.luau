-- LAST LIGHT: every tuning number of the game lives here, read by server and client alike.

local Config = {}

Config.Palette = {
	Night = Color3.fromRGB(16, 20, 44),
	Panel = Color3.fromRGB(22, 28, 58),
	Ember = Color3.fromRGB(255, 176, 72),
	Flame = Color3.fromRGB(255, 120, 48),
	Glow = Color3.fromRGB(130, 232, 255),
	Danger = Color3.fromRGB(255, 78, 96),
	Heal = Color3.fromRGB(120, 255, 170),
	Text = Color3.fromRGB(246, 240, 228),
	Muted = Color3.fromRGB(168, 176, 210),
}

Config.Tower = {
	MaxHealth = 1000,
	Position = Vector3.new(0, 4, 0),
	Reach = 11, -- enemies stop and claw at the tower from this far away
}

Config.Island = {
	Radius = 46,
	Height = 4, -- ground level of the island top
	SpawnRadius = 96, -- where the Drowned rise from the tide
}

Config.Player = {
	BoltDamage = 34,
	BoltCooldown = 0.3,
	BoltRange = 95,
	BoltRadius = 2.2,
	PulseDamage = 70,
	PulseRadius = 22,
	PulseCooldown = 7,
}

-- The Drowned: four kinds, each with its own body, speed and target.
Config.Enemies = {
	Crawler = { Health = 60, Speed = 6, Damage = 6, Reward = 5, Target = "Tower", Height = 1.6 },
	Brute = { Health = 280, Speed = 3.5, Damage = 16, Reward = 15, Target = "Tower", Height = 2.8 },
	Wisp = { Health = 40, Speed = 8, Damage = 8, Reward = 8, Target = "Player", Height = 4.5 },
	Leviathan = { Health = 2600, Speed = 2.4, Damage = 26, Reward = 120, Target = "Tower", Height = 5.6, Boss = true },
}

-- Five nights. Each entry is how many of each kind rise, and how fast they come.
Config.Waves = {
	{ Name = "First Tide", Spawns = { Crawler = 8 }, Interval = 1.1 },
	{ Name = "Will-o'-Wisps", Spawns = { Crawler = 10, Wisp = 4 }, Interval = 0.95 },
	{ Name = "Barnacle Brutes", Spawns = { Crawler = 12, Wisp = 5, Brute = 2 }, Interval = 0.85 },
	{ Name = "Storm Surge", Spawns = { Crawler = 16, Wisp = 8, Brute = 4 }, Interval = 0.7 },
	{ Name = "The Leviathan", Spawns = { Leviathan = 1, Crawler = 12, Wisp = 6, Brute = 3 }, Interval = 0.9 },
}

Config.Upgrades = {
	Damage = { Title = "Hotter Flame", Detail = "+35% bolt damage", Icon = "+35%" },
	Rate = { Title = "Quick Wick", Detail = "Bolts fire 25% faster", Icon = "x1.33" },
	Pulse = { Title = "Wider Beacon", Detail = "+40% pulse radius", Icon = "+40%" },
	Repair = { Title = "Mend the Tower", Detail = "Restore 200 tower health", Icon = "+200" },
	Pierce = { Title = "Lance of Light", Detail = "Bolts pierce 2 more foes", Icon = "+2" },
}

Config.IntermissionSeconds = 12
Config.UpgradeChoices = 3

return Config
