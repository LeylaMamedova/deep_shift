--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	Click (M1) / tap to swing as Phantom Puppet.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("HauntedForest", 30)
if not folder then
	return
end
local remotes = folder:WaitForChild("Remotes")
local m1Remote = remotes:WaitForChild("PhantomPuppetM1")

local COOLDOWN = 1.1
local last = 0

local function isKiller()
	local role = player:FindFirstChild("Role")
	if role and role.Value == "Killer" then
		return true
	end
	return player:GetAttribute("IsPhantomPuppet") == true
end

local function tryM1()
	if not isKiller() then
		return
	end
	local now = os.clock()
	if now - last < COOLDOWN then
		return
	end
	last = now
	m1Remote:FireServer()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryM1()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- mobile: tap (basic)
		tryM1()
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
		tryM1()
	end
end)
