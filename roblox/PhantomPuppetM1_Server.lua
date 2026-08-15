--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Phantom Puppet M1 attack (server):
	- Plays swing animation
	- Damages survivors in front
	- Cooldown between hits

	SETUP:
	1. Workspace Model named: PhantomPuppet (Humanoid + HumanoidRootPart)
	2. Optional: put an Animation named "M1" inside that model
	3. Paste PhantomPuppetM1_Client as LocalScript in StarterPlayerScripts
	4. Replace M1_ANIM_ID with your uploaded animation asset id
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KILLER_NAME = "PhantomPuppet"
-- Replace with YOUR animation id (publish anim in Studio → copy id)
local M1_ANIM_ID = "rbxassetid://522635514" -- placeholder swing; swap for your Puppet M1
local DAMAGE = 28
local RANGE = 7
local COOLDOWN = 1.1
local HITBOX_WIDTH = 5

local folder = ReplicatedStorage:FindFirstChild("HauntedForest") or Instance.new("Folder")
folder.Name = "HauntedForest"
folder.Parent = ReplicatedStorage

local remotes = folder:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = folder

local m1Remote = remotes:FindFirstChild("PhantomPuppetM1") or Instance.new("RemoteEvent")
m1Remote.Name = "PhantomPuppetM1"
m1Remote.Parent = remotes

local lastSwing = {} -- [player] = time
local tracks = {} -- [model] = AnimationTrack

local function getKillerModel()
	local m = workspace:FindFirstChild(KILLER_NAME)
	if m and m:IsA("Model") then
		return m
	end
	return nil
end

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)
end

local function findAnimId(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Animation") and (d.Name == "M1" or d.Name == "Attack" or d.Name == "Swing") then
			if d.AnimationId ~= "" then
				return d.AnimationId
			end
		end
	end
	return M1_ANIM_ID
end

local function getTrack(model)
	if tracks[model] and tracks[model].Parent then
		return tracks[model]
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = findAnimId(model)
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		tracks[model] = track
		return track
	end
	warn("[PhantomPuppetM1] Failed to load anim:", anim.AnimationId)
	return nil
end

local function playerIsControllingKiller(player)
	-- If player has Role Killer AND we treat PhantomPuppet as their body,
	-- OR player's character is named/tagged. Simple: allow if they own killer control attribute.
	local role = player:FindFirstChild("Role")
	if role and role.Value == "Killer" then
		return true
	end
	-- Solo test: if character is near the puppet OR attribute AllowM1
	if player:GetAttribute("IsPhantomPuppet") == true then
		return true
	end
	-- Dev-friendly: anyone can M1 while testing if no Role system yet
	if not role then
		return true
	end
	return false
end

local function getSwingOrigin(player)
	-- Player-controlled Phantom Puppet: swing from THEIR character
	if player:GetAttribute("IsPhantomPuppet") == true or (player:FindFirstChild("Role") and player.Role.Value == "Killer") then
		local char = player.Character
		local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
		if root then
			return root, char
		end
	end
	-- NPC fallback
	local killer = getKillerModel()
	if killer then
		local root = getRoot(killer)
		if root then
			return root, killer
		end
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root, char
end

local function victimsInFront(originPart, attacker)
	local hits = {}
	local origin = originPart.Position
	local look = originPart.CFrame.LookVector
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == attacker then
			continue
		end
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			local offset = root.Position - origin
			local dist = offset.Magnitude
			if dist <= RANGE then
				local flat = Vector3.new(offset.X, 0, offset.Z)
				if flat.Magnitude > 0.05 then
					local dir = flat.Unit
					local dot = dir:Dot(Vector3.new(look.X, 0, look.Z).Unit)
					-- roughly in front cone
					if dot > 0.35 then
						local side = math.abs(offset:Cross(look).Y)
						if side < HITBOX_WIDTH then
							table.insert(hits, hum)
						end
					end
				end
			end
		end
	end
	return hits
end

m1Remote.OnServerEvent:Connect(function(player)
	if not playerIsControllingKiller(player) then
		return
	end

	local now = os.clock()
	if (lastSwing[player] or 0) + COOLDOWN > now then
		return
	end
	lastSwing[player] = now

	local origin, model = getSwingOrigin(player)
	if not origin then
		return
	end

	-- Play M1 animation on killer (or player character)
	local animModel = (model and model:IsA("Model") and model) or getKillerModel() or player.Character
	if animModel then
		local track = getTrack(animModel)
		if track then
			track:Stop(0)
			track:Play(0.05, 1, 1.15)
		end
	end

	-- Small delay so the swing connects mid-anim
	task.delay(0.18, function()
		if not origin.Parent then
			return
		end
		for _, hum in ipairs(victimsInFront(origin, player)) do
			hum:TakeDamage(DAMAGE)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSwing[player] = nil
end)

print("[PhantomPuppetM1] Server ready — use your M1 anim id in M1_ANIM_ID")
