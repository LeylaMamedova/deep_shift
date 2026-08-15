--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Randomly picks ONE player to be the Phantom Puppet killer.
	Everyone else is a Survivor.

	SETUP:
	1. Put a Model named PhantomPuppet in ServerStorage (best)
	   or Workspace. Needs Humanoid + HumanoidRootPart.
	2. Optional Workspace parts: KillerSpawn, RoundSpawn
	3. Paste RoleReveal.lua as a LocalScript in StarterPlayerScripts
	4. Keep PhantomPuppetM1_Server + Client so the killer can M1
	5. Disable KillerAI.lua if you do NOT want an extra NPC hunter

	Solo Play is fine — you will be chosen as Phantom Puppet.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- ===== TUNE THESE =====
local MIN_PLAYERS = 1 -- set to 2 when friends are playing
local INTERMISSION = 8 -- seconds of "choosing..." before the pick
local KILLER_WALKSPEED = 18
local SURVIVOR_WALKSPEED = 16
local KILLER_SPAWN = "KillerSpawn"
local SURVIVOR_SPAWN = "RoundSpawn"
local Y_OFFSET = 3
-- ======================

local folder = ReplicatedStorage:FindFirstChild("HauntedForest") or Instance.new("Folder")
folder.Name = "HauntedForest"
folder.Parent = ReplicatedStorage

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

local remotes = folder:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = folder

local roleRemote = remotes:FindFirstChild("RoleAssigned") or Instance.new("RemoteEvent")
roleRemote.Name = "RoleAssigned"
roleRemote.Parent = remotes

local playerKiller = ensure("BoolValue", "PlayerKiller", false)
local chosenKillerName = ensure("StringValue", "ChosenKillerName", "")
local roundStarted = ensure("BoolValue", "RoundStarted", false)
local roundOver = ensure("BoolValue", "RoundOver", false)

local picked = false
local currentKiller = nil
local morphing = {}

local function getRole(player)
	local role = player:FindFirstChild("Role")
	if not role then
		role = Instance.new("StringValue")
		role.Name = "Role"
		role.Value = "Survivor"
		role.Parent = player
	end
	return role
end

local function getTemplate()
	local fromStorage = ServerStorage:FindFirstChild("PhantomPuppet")
	if fromStorage and fromStorage:IsA("Model") then
		return fromStorage
	end
	local fromWorkspace = workspace:FindFirstChild("PhantomPuppet")
	if fromWorkspace and fromWorkspace:IsA("Model") then
		return fromWorkspace
	end
	local fromReplicated = ReplicatedStorage:FindFirstChild("PhantomPuppet")
	if fromReplicated and fromReplicated:IsA("Model") then
		return fromReplicated
	end
	return nil
end

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)
end

local function spawnCFrame(partName, fallbackName)
	local p = workspace:FindFirstChild(partName) or workspace:FindFirstChild(fallbackName)
	if not p then
		return nil
	end
	if p:IsA("BasePart") or p:IsA("SpawnLocation") then
		return p.CFrame + Vector3.new(0, Y_OFFSET, 0)
	end
	if p:IsA("Model") then
		local root = getRoot(p)
		if root then
			return root.CFrame + Vector3.new(0, Y_OFFSET, 0)
		end
	end
	return nil
end

local function teleportTo(player, cf)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not cf then
		return
	end
	local offset = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = cf + offset
end

local function hideNpcPuppet()
	local npc = workspace:FindFirstChild("PhantomPuppet")
	if npc and npc:IsA("Model") then
		npc.Parent = ServerStorage
		print("[ChoosePhantomPuppet] Hid NPC PhantomPuppet (player is the killer)")
	end
end

local function morphIntoPuppet(player)
	if morphing[player] then
		return
	end

	local template = getTemplate()
	if not template then
		warn("[ChoosePhantomPuppet] No PhantomPuppet model. Killer keeps their avatar.")
		return
	end

	local char = player.Character
	local oldRoot = char and char:FindFirstChild("HumanoidRootPart")
	local keepCf = oldRoot and oldRoot.CFrame or spawnCFrame(KILLER_SPAWN, SURVIVOR_SPAWN)

	morphing[player] = true

	local clone = template:Clone()
	clone:SetAttribute("PhantomPuppetBody", true)
	clone.Name = player.Name

	local hum = clone:FindFirstChildOfClass("Humanoid")
	if not hum then
		hum = Instance.new("Humanoid")
		hum.Parent = clone
	end
	hum.WalkSpeed = KILLER_WALKSPEED
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local root = getRoot(clone)
	if root then
		clone.PrimaryPart = root
		if keepCf then
			clone:PivotTo(keepCf)
		end
	end

	-- Animate if the template had an Animator
	if not hum:FindFirstChildOfClass("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = hum
	end

	player.Character = clone
	clone.Parent = workspace

	task.defer(function()
		morphing[player] = false
	end)
end

local function applyKiller(player)
	local role = getRole(player)
	role.Value = "Killer"
	player:SetAttribute("IsPhantomPuppet", true)
	player:SetAttribute("KillerName", "Phantom Puppet")

	hideNpcPuppet()
	morphIntoPuppet(player)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = KILLER_WALKSPEED
	end

	local cf = spawnCFrame(KILLER_SPAWN, SURVIVOR_SPAWN)
	if cf then
		task.wait(0.15)
		teleportTo(player, cf)
	end

	roleRemote:FireClient(player, {
		role = "Killer",
		title = "PHANTOM PUPPET",
		subtitle = "You are the killer. Hunt the survivors.",
	})
end

local function applySurvivor(player)
	local role = getRole(player)
	role.Value = "Survivor"
	player:SetAttribute("IsPhantomPuppet", false)
	player:SetAttribute("KillerName", "")

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = SURVIVOR_WALKSPEED
	end

	local cf = spawnCFrame(SURVIVOR_SPAWN, "LobbySpawn")
	if cf then
		teleportTo(player, cf)
	end

	roleRemote:FireClient(player, {
		role = "Survivor",
		title = "SURVIVOR",
		subtitle = "Phantom Puppet is hunting. Stay alive.",
	})
end

local function pickKiller()
	if picked then
		return
	end

	local list = Players:GetPlayers()
	if #list < MIN_PLAYERS then
		return
	end

	-- Prefer players who already have a character
	local ready = {}
	for _, player in ipairs(list) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(ready, player)
		end
	end
	if #ready == 0 then
		ready = list
	end

	picked = true
	currentKiller = ready[math.random(1, #ready)]
	playerKiller.Value = true
	chosenKillerName.Value = currentKiller.Name

	print("[ChoosePhantomPuppet] Killer this round:", currentKiller.Name)

	for _, player in ipairs(Players:GetPlayers()) do
		if player == currentKiller then
			applyKiller(player)
		else
			applySurvivor(player)
		end
	end
end

local function waitThenPick()
	print("[ChoosePhantomPuppet] Waiting for players...")

	while #Players:GetPlayers() < MIN_PLAYERS do
		task.wait(0.5)
	end

	-- Let late joiners / character loads catch up a bit
	task.wait(1)

	-- Tell everyone a pick is coming
	for _, player in ipairs(Players:GetPlayers()) do
		roleRemote:FireClient(player, {
			role = "Choosing",
			title = "CHOOSING KILLER",
			subtitle = "Someone will become Phantom Puppet...",
		})
	end

	task.wait(INTERMISSION)
	pickKiller()
end

Players.PlayerAdded:Connect(function(player)
	getRole(player)
	player:SetAttribute("IsPhantomPuppet", false)

	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		if morphing[player] then
			return
		end
		if char:GetAttribute("PhantomPuppetBody") == true then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = KILLER_WALKSPEED
			end
			return
		end

		local role = getRole(player)
		local hum = char:FindFirstChildOfClass("Humanoid")

		if picked and player == currentKiller and role.Value == "Killer" and not roundOver.Value then
			-- They respawned as a normal avatar — put the puppet back on
			applyKiller(player)
		elseif hum then
			if role.Value == "Killer" then
				hum.WalkSpeed = KILLER_WALKSPEED
			else
				hum.WalkSpeed = SURVIVOR_WALKSPEED
			end
		end
	end)

	-- Late join after pick → survivor only
	if picked and player ~= currentKiller then
		player.CharacterAdded:Wait()
		task.wait(0.3)
		applySurvivor(player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	getRole(player)
end

Players.PlayerRemoving:Connect(function(player)
	if player == currentKiller then
		currentKiller = nil
	end
	morphing[player] = nil
end)

task.spawn(waitThenPick)

print("[ChoosePhantomPuppet] Ready — one random player becomes Phantom Puppet")
