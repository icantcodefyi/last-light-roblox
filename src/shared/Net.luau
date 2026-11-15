-- The game's remotes and its replicated state, in one place.
-- The server owns every value; clients only read them (State attributes) and send requests (remotes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local REMOTE_NAMES = { "FireBolt", "CastPulse", "ChooseUpgrade", "RequestStart", "Feedback" }

local function getOrCreateFolder(name: string): Folder
	local folder = ReplicatedStorage:FindFirstChild(name)
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(name)
end

local remotes = getOrCreateFolder("Remotes")
local state = getOrCreateFolder("State")

function Net.remote(name: string): RemoteEvent
	assert(table.find(REMOTE_NAMES, name), "unknown remote " .. name)
	local remote = remotes:FindFirstChild(name)
	if not remote and RunService:IsServer() then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote or remotes:WaitForChild(name)
end

function Net.setState(key: string, value: any)
	assert(RunService:IsServer(), "only the server writes game state")
	state:SetAttribute(key, value)
end

function Net.getState(key: string): any
	return state:GetAttribute(key)
end

function Net.onState(key: string, callback: (any) -> ())
	state:GetAttributeChangedSignal(key):Connect(function()
		callback(state:GetAttribute(key))
	end)
	callback(state:GetAttribute(key))
end

if RunService:IsServer() then
	for _, name in REMOTE_NAMES do
		Net.remote(name)
	end
end

return Net
