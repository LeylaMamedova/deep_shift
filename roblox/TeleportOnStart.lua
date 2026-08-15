--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	START  → teleport everyone to RoundSpawn (the map)
	TIMER END (0:00 / RoundOver) → teleport everyone back to LobbySpawn

	SETUP:
	1. Workspace Part named: RoundSpawn  (forest / match)
	2. Workspace Part named: LobbySpawn  (lobby)
	3. Keep ForsakenTimer in ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROUND_SPAWN = "RoundSpawn"
local LOBBY_SPAWN = "LobbySpawn"
local START_HOLD = 2
local END_HOLD = 2 -- show END on timer before / while sending to lobby
local Y_OFFSET = 3

local folder = ReplicatedStorage:FindFirstChild("HauntedForest")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "HauntedForest"
	folder.Parent = ReplicatedStorage
end

local function ensure(className, name, default)
	local v = folder:FindFirstChild(name)
	if not v then
		v = Instance.new(className)
		v.Name = name
		v.Parent = folder
	end
	if default ~= nil then
		v.Value = default
	end
	return v
end

local clockText = ensure("StringValue", "ClockText", "START")
local roundStarted = ensure("BoolValue", "RoundStarted", false)
local roundOver = ensure("BoolValue", "RoundOver", false)
local inLobby = ensure("BoolValue", "InLobby", true)

local function getPartCFrame(name)
	local p = workspace:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p.CFrame + Vector3.new(0, Y_OFFSET, 0)
	end
	if p and p:IsA("SpawnLocation") then
		return p.CFrame + Vector3.new(0, Y_OFFSET, 0)
	end
	if p and p:IsA("Model") then
		local root = p.PrimaryPart or p:FindFirstChild("HumanoidRootPart") or p:FindFirstChildWhichIsA("BasePart", true)
		if root then
			return root.CFrame + Vector3.new(0, Y_OFFSET, 0)
		end
	end
	return nil
end

local function teleportPlayer(player, cf)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local offset = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = cf + offset
end

local function teleportEveryone(partName, label)
	local cf = getPartCFrame(partName)
	if not cf then
		warn("[RoundTeleport] Missing Workspace part named:", partName)
		return false
	end
	for _, player in ipairs(Players:GetPlayers()) do
		teleportPlayer(player, cf)
	end
	print("[RoundTeleport]", label, "→", partName)
	return true
end

local function sendToLobby()
	clockText.Value = "END"
	task.wait(0.15)
	teleportEveryone(LOBBY_SPAWN, "Timer ended — lobby")
	inLobby.Value = true
	roundStarted.Value = false
	clockText.Value = "LOBBY"
end

-- START of round → map
task.spawn(function()
	task.wait(1)
	roundOver.Value = false
	clockText.Value = "START"
	teleportEveryone(ROUND_SPAWN, "Round start")
	inLobby.Value = false
	roundStarted.Value = true
	task.wait(START_HOLD)
end)

-- When ForsakenTimer sets RoundOver = true (timer hit 0:00)
roundOver.Changed:Connect(function(over)
	if over then
		task.spawn(function()
			task.wait(END_HOLD)
			sendToLobby()
		end)
	end
end)

-- Also watch clock text for 0:00 as a backup
clockText.Changed:Connect(function(text)
	if text == "0:00" and not inLobby.Value then
		-- RoundOver handler usually covers this; backup if needed
		if roundOver.Value then
			return
		end
	end
end)

-- Late join during round → map; if lobby phase → lobby
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		if inLobby.Value then
			local cf = getPartCFrame(LOBBY_SPAWN)
			if cf then
				teleportPlayer(player, cf)
			end
		elseif roundStarted.Value and not roundOver.Value then
			local cf = getPartCFrame(ROUND_SPAWN)
			if cf then
				teleportPlayer(player, cf)
			end
		end
	end)
end)
