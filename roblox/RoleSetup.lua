--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Creates a Role value on every player (default Survivor).
	ChoosePhantomPuppet.lua then picks one random player as Killer.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("HauntedForest") or Instance.new("Folder")
folder.Name = "HauntedForest"
folder.Parent = ReplicatedStorage

local function ensureRole(player)
	local role = player:FindFirstChild("Role")
	if not role then
		role = Instance.new("StringValue")
		role.Name = "Role"
		role.Value = "Survivor"
		role.Parent = player
	end
	return role
end

local function applySpeed(player, char)
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	if not hum then
		return
	end
	local role = player:FindFirstChild("Role")
	if role and role.Value == "Killer" then
		hum.WalkSpeed = 18
	else
		hum.WalkSpeed = 16
	end
end

local function setup(player)
	ensureRole(player)
	player.CharacterAdded:Connect(function(char)
		applySpeed(player, char)
	end)
	if player.Character then
		applySpeed(player, player.Character)
	end
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do
	setup(player)
end
