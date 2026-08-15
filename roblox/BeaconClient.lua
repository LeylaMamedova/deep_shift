--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	Hold E near Beacon1..Beacon4 to light them.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("HauntedForest", 30)
if not folder then
	return
end
local remotes = folder:WaitForChild("Remotes")
local lightBeacon = remotes:WaitForChild("LightBeacon")

local RANGE = 12
local holding = false

local function nearestBeacon()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best, bestD = nil, RANGE
	for i = 1, 4 do
		local b = workspace:FindFirstChild("Beacon" .. i)
		if b and b:IsA("BasePart") and not b:GetAttribute("Lit") then
			local d = (b.Position - root.Position).Magnitude
			if d < bestD then
				bestD = d
				best = b
			end
		end
	end
	return best
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		holding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		holding = false
		lightBeacon:FireServer("", false)
	end
end)

RunService.RenderStepped:Connect(function()
	if not holding then
		return
	end
	local b = nearestBeacon()
	if b then
		lightBeacon:FireServer(b.Name, true)
	else
		lightBeacon:FireServer("", false)
	end
end)
