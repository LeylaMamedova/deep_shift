--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Picks one of your animatronics and chases survivors:
	  PhantomPuppet, Ennard, WitheredBonnie
	Put those Models in Workspace (with Humanoid + HumanoidRootPart).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NAMES = { "PhantomPuppet", "Ennard", "WitheredBonnie" }
local CATCH_DISTANCE = 5
local SPEED = {
	PhantomPuppet = 15,
	Ennard = 17,
	WitheredBonnie = 13,
}

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)
end

local function findKillers()
	local list = {}
	for _, name in ipairs(NAMES) do
		local m = workspace:FindFirstChild(name)
		if m and m:IsA("Model") and getRoot(m) then
			table.insert(list, m)
		end
	end
	return list
end

local function nearestSurvivor(fromPos)
	local best, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local role = plr:FindFirstChild("Role")
		if role and role.Value == "Killer" then
			-- skip the player killer
		elseif hum and root and hum.Health > 0 then
			local d = (root.Position - fromPos).Magnitude
			if d < bestDist then
				bestDist = d
				best = root
			end
		end
	end
	return best, bestDist
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:FindFirstChild("HauntedForest")
local playerKiller = folder and folder:FindFirstChild("PlayerKiller")

-- Give ChoosePhantomPuppet time to pick a player killer first
task.wait(11)
playerKiller = folder and folder:FindFirstChild("PlayerKiller")
if playerKiller and playerKiller.Value == true then
	print("[HauntedForest] Player is Phantom Puppet — KillerAI off")
	return
end

local killers = findKillers()
if #killers == 0 then
	warn("[HauntedForest] No animatronic models found. Name them PhantomPuppet / Ennard / WitheredBonnie")
	return
end

-- Hide extras; activate one random hunter
local active = killers[math.random(1, #killers)]
for _, m in ipairs(killers) do
	if m ~= active then
		m.Parent = game:GetService("ServerStorage")
	end
end

local hum = active:FindFirstChildOfClass("Humanoid")
local root = getRoot(active)
if not hum or not root then
	warn("[HauntedForest] Active killer missing Humanoid/root")
	return
end

if not active.PrimaryPart then
	active.PrimaryPart = root
end

hum.WalkSpeed = SPEED[active.Name] or 15
print("[HauntedForest] Hunter this night:", active.Name)

local lastPath = 0

RunService.Heartbeat:Connect(function()
	if playerKiller and playerKiller.Value == true then
		return
	end
	if hum.Health <= 0 then
		return
	end
	local target, dist = nearestSurvivor(root.Position)
	if not target then
		return
	end

	if dist <= CATCH_DISTANCE then
		local th = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
		if th then
			th.Health = 0
		end
		return
	end

	-- simple chase (no full pathfinding spam)
	if os.clock() - lastPath > 0.35 then
		lastPath = os.clock()
		hum:MoveTo(target.Position)
	end
end)
