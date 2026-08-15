--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Beacons named Beacon1..Beacon4 in Workspace.
	Client asks to light them when holding E nearby.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local folder = ReplicatedStorage:FindFirstChild("HauntedForest") or Instance.new("Folder")
folder.Name = "HauntedForest"
folder.Parent = ReplicatedStorage

local remotes = folder:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = folder

local lightBeacon = remotes:FindFirstChild("LightBeacon") or Instance.new("RemoteEvent")
lightBeacon.Name = "LightBeacon"
lightBeacon.Parent = remotes

local litCount = folder:FindFirstChild("LitCount") or Instance.new("IntValue")
litCount.Name = "LitCount"
litCount.Value = 0
litCount.Parent = folder

local RANGE = 12
local HOLD_SECONDS = 3.5

local progress = {} -- [player] = { beacon = Part, t = number }

local function findBeacons()
	local list = {}
	for i = 1, 4 do
		local b = workspace:FindFirstChild("Beacon" .. i)
		if b and b:IsA("BasePart") then
			if b:GetAttribute("Lit") == nil then
				b:SetAttribute("Lit", false)
				b.Color = Color3.fromRGB(30, 50, 35)
				b.Material = Enum.Material.Metal
			end
			table.insert(list, b)
		end
	end
	return list
end

local beacons = findBeacons()
if #beacons == 0 then
	warn("[HauntedForest] No Beacon1..Beacon4 parts found in Workspace yet.")
end

lightBeacon.OnServerEvent:Connect(function(player, beaconName, holding)
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local beacon = workspace:FindFirstChild(beaconName)
	if not beacon or not beacon:IsA("BasePart") then
		return
	end
	if beacon:GetAttribute("Lit") then
		return
	end
	if (root.Position - beacon.Position).Magnitude > RANGE then
		progress[player] = nil
		return
	end

	if not holding then
		progress[player] = nil
		return
	end

	local p = progress[player]
	if not p or p.beacon ~= beacon then
		progress[player] = { beacon = beacon, t = 0 }
		p = progress[player]
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		for player, p in pairs(progress) do
			local ok = player.Parent and p.beacon and not p.beacon:GetAttribute("Lit")
			local char = ok and player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not ok or not root or (root.Position - p.beacon.Position).Magnitude > RANGE then
				progress[player] = nil
			else
				p.t = p.t + 0.1
				if p.t >= HOLD_SECONDS then
					p.beacon:SetAttribute("Lit", true)
					p.beacon.Color = Color3.fromRGB(120, 255, 140)
					p.beacon.Material = Enum.Material.Neon
					litCount.Value = litCount.Value + 1
					progress[player] = nil
					print("[HauntedForest] Beacon lit by", player.Name, "→", litCount.Value)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	progress[player] = nil
end)
