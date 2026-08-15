--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	FORSAKEN-STYLE TIMER
	- Counts DOWN to 0
	- Survivors win when timer hits 0 (still alive)
	- Objectives (beacons) REMOVE time
	- Survivor deaths ADD time

	Also paste ForsakenHud.lua as LocalScript in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- ===== TUNE THESE =====
local START_SECONDS = 480 -- 8 minutes (Forsaken-like)
local TIME_REMOVE_PER_BEACON = 12 -- like generators shaving the clock
local TIME_ADD_ON_DEATH = 25 -- killer gets more time when someone dies
local MIN_SECONDS = 30 -- timer never goes below this until last stretch
-- ======================

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

local timeLeft = ensure("NumberValue", "TimeLeft", START_SECONDS)
local clockText = ensure("StringValue", "ClockText", "")
local roundOver = ensure("BoolValue", "RoundOver", false)
local survivorsWin = ensure("BoolValue", "SurvivorsWin", false)
local litCount = folder:FindFirstChild("LitCount")
if not litCount then
	litCount = ensure("IntValue", "LitCount", 0)
end

-- Remotes for other scripts / future UI
local remotes = folder:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = folder
end

local removeTime = remotes:FindFirstChild("RemoveTime")
if not removeTime then
	removeTime = Instance.new("BindableEvent")
	removeTime.Name = "RemoveTime"
	removeTime.Parent = remotes
end

local addTime = remotes:FindFirstChild("AddTime")
if not addTime then
	addTime = Instance.new("BindableEvent")
	addTime.Name = "AddTime"
	addTime.Parent = remotes
end

local function formatCountdown(sec)
	sec = math.max(0, math.floor(sec))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%d:%02d", m, s)
end

local function setTime(sec)
	timeLeft.Value = math.max(0, sec)
	clockText.Value = formatCountdown(timeLeft.Value)
end

roundOver.Value = false
survivorsWin.Value = false

Lighting.ClockTime = 0
Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(40, 50, 45)
Lighting.OutdoorAmbient = Color3.fromRGB(30, 40, 35)

-- Wait for TeleportOnStart (shows START + teleports), then begin countdown
clockText.Value = "START"
local roundStarted = folder:WaitForChild("RoundStarted", 5)
if roundStarted and not roundStarted.Value then
	roundStarted.Changed:Wait()
elseif not roundStarted then
	task.wait(2) -- TeleportOnStart not present; start anyway
end
setTime(START_SECONDS)

-- Objectives remove time (call from BeaconServer or here via LitCount)
local lastLit = litCount.Value
litCount.Changed:Connect(function(v)
	local gained = v - lastLit
	lastLit = v
	if gained > 0 and not roundOver.Value then
		setTime(math.max(MIN_SECONDS, timeLeft.Value - TIME_REMOVE_PER_BEACON * gained))
		print("[ForsakenTimer] Objective done → -" .. (TIME_REMOVE_PER_BEACON * gained) .. "s → " .. clockText.Value)
	end
end)

removeTime.Event:Connect(function(amount)
	if roundOver.Value then
		return
	end
	amount = tonumber(amount) or TIME_REMOVE_PER_BEACON
	setTime(math.max(MIN_SECONDS, timeLeft.Value - amount))
end)

addTime.Event:Connect(function(amount)
	if roundOver.Value then
		return
	end
	amount = tonumber(amount) or TIME_ADD_ON_DEATH
	setTime(timeLeft.Value + amount)
	print("[ForsakenTimer] Death → +" .. amount .. "s → " .. clockText.Value)
end)

-- Survivor death = more time for the killer
local function hookCharacter(player, char)
	local hum = char:WaitForChild("Humanoid")
	local done = false
	hum.Died:Connect(function()
		if done or roundOver.Value then
			return
		end
		done = true
		addTime:Fire(TIME_ADD_ON_DEATH)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		hookCharacter(player, char)
	end)
	if player.Character then
		hookCharacter(player, player.Character)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(char)
		hookCharacter(player, char)
	end)
	if player.Character then
		hookCharacter(player, player.Character)
	end
end

-- Main countdown
task.spawn(function()
	while not roundOver.Value do
		task.wait(1)
		if roundOver.Value then
			break
		end
		setTime(timeLeft.Value - 1)
		if timeLeft.Value <= 0 then
			roundOver.Value = true
			survivorsWin.Value = true
			clockText.Value = "0:00"
			print("[ForsakenTimer] Time up — SURVIVORS WIN")
			break
		end
	end
end)
