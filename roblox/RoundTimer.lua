--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Bite by Night–style clock: 12:00 AM → 6:00 AM
	Default real length ~3.5 minutes (change NIGHT_SECONDS).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local NIGHT_SECONDS = 210 -- real time for full night (like our browser build)

local folder = ReplicatedStorage:FindFirstChild("HauntedForest")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "HauntedForest"
	folder.Parent = ReplicatedStorage
end

local nightT = folder:FindFirstChild("NightT")
if not nightT then
	nightT = Instance.new("NumberValue")
	nightT.Name = "NightT"
	nightT.Parent = folder
end

local clockText = folder:FindFirstChild("ClockText")
if not clockText then
	clockText = Instance.new("StringValue")
	clockText.Name = "ClockText"
	clockText.Parent = folder
end

local roundOver = folder:FindFirstChild("RoundOver")
if not roundOver then
	roundOver = Instance.new("BoolValue")
	roundOver.Name = "RoundOver"
	roundOver.Parent = folder
end

local function formatClock(t)
	local minutes = math.floor(t * 6 * 60)
	local hour24 = math.floor(minutes / 60)
	local min = minutes % 60
	local hour12 = hour24 == 0 and 12 or hour24
	return string.format("%d:%02d AM", hour12, min)
end

nightT.Value = 0
roundOver.Value = false
clockText.Value = "12:00 AM"
Lighting.ClockTime = 0 -- midnight look
Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(40, 50, 45)
Lighting.OutdoorAmbient = Color3.fromRGB(30, 40, 35)

task.spawn(function()
	local t0 = os.clock()
	while not roundOver.Value do
		local elapsed = os.clock() - t0
		local t = math.clamp(elapsed / NIGHT_SECONDS, 0, 1)
		nightT.Value = t
		clockText.Value = formatClock(t)
		Lighting.ClockTime = t * 6 -- 0 → 6
		if t >= 1 then
			roundOver.Value = true
			clockText.Value = "6:00 AM"
			break
		end
		task.wait(0.1)
	end
	print("[HauntedForest] Dawn — survivors win if still alive")
end)
