-- The keeper's hands: a high follow camera over the island, mouse aim on the ground plane,
-- click for a flare bolt and Q for the beacon pulse. Sends requests; the server decides hits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local Controls = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local CAMERA_OFFSET = Vector3.new(0, 72, 26)
local TITLE_ORBIT_RADIUS = 120
local firing = false
local lastBolt = 0
local lastPulse = -math.huge

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Where the mouse points on the island's ground plane.
function Controls.aimPoint(): Vector3?
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local groundY = Config.Island.Height + 1.5
	if math.abs(ray.Direction.Y) < 1e-3 then
		return nil
	end
	local t = (groundY - ray.Origin.Y) / ray.Direction.Y
	return t > 0 and ray.Origin + ray.Direction * t or nil
end

local function tryFireBolt()
	local now = os.clock()
	local aim = Controls.aimPoint()
	if aim and now - lastBolt >= Config.Player.BoltCooldown then
		lastBolt = now
		Net.remote("FireBolt"):FireServer(aim)
	end
end

local function tryCastPulse()
	local now = os.clock()
	if now - lastPulse >= Config.Player.PulseCooldown then
		lastPulse = now
		Net.remote("CastPulse"):FireServer()
	end
end

function Controls.pulseCharge(): number
	return (os.clock() - lastPulse) / Config.Player.PulseCooldown
end

-- A slow orbit of the lighthouse behind the title card, the follow camera during a night.
local function updateCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	local phase = Net.getState("Phase")
	local root = rootPart()
	if phase == "Lobby" or not root then
		local angle = os.clock() * 0.08
		local eye = Vector3.new(math.cos(angle) * TITLE_ORBIT_RADIUS, 34, math.sin(angle) * TITLE_ORBIT_RADIUS)
		camera.CFrame = CFrame.lookAt(eye, Config.Tower.Position + Vector3.new(0, 22, 0))
	else
		local focus = root.Position:Lerp(Config.Tower.Position, 0.4)
		local goal = CFrame.lookAt(focus + CAMERA_OFFSET, focus)
		camera.CFrame = camera.CFrame:Lerp(goal, 0.15)
	end
end

function Controls.start()
	RunService:BindToRenderStep("LastLightCamera", Enum.RenderPriority.Camera.Value + 1, updateCamera)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or Net.getState("Phase") ~= "Wave" then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = true
			tryFireBolt()
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
			tryCastPulse()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = false
		end
	end)
	-- Holding the mouse keeps firing at the bolt's own rate.
	RunService.Heartbeat:Connect(function()
		if firing and Net.getState("Phase") == "Wave" then
			tryFireBolt()
		end
	end)
end

return Controls
