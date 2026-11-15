-- LAST LIGHT client: builds the HUD, starts the camera and controls, and plays the feedback.

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- The night's own HUD replaces Roblox's chat and player list.
local function hideCoreGui()
	for _, kind in { Enum.CoreGuiType.Chat, Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack } do
		local ok, err = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, kind, false)
		if not ok then
			warn("could not hide " .. kind.Name .. ": " .. tostring(err))
		end
	end
end
hideCoreGui()

local Hud = require(script.Hud)
local Controls = require(script.Controls)
local Fx = require(script.Fx)

Hud.build()
Controls.start()
Fx.start(Hud)

RunService.Heartbeat:Connect(function()
	Hud.setPulseCharge(Controls.pulseCharge())
end)
