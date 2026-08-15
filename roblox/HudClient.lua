--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	Shows the night clock + beacons lit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("HauntedForest", 30)
if not folder then
	warn("[HauntedForest] Missing HauntedForest folder")
	return
end

local clockText = folder:WaitForChild("ClockText")
local litCount = folder:WaitForChild("LitCount")

local gui = Instance.new("ScreenGui")
gui.Name = "HauntedForestHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local clock = Instance.new("TextLabel")
clock.Name = "Clock"
clock.Size = UDim2.new(0, 220, 0, 48)
clock.Position = UDim2.new(0.5, -110, 0, 16)
clock.BackgroundColor3 = Color3.fromRGB(10, 16, 12)
clock.BackgroundTransparency = 0.25
clock.BorderSizePixel = 0
clock.Font = Enum.Font.GothamBold
clock.TextSize = 28
clock.TextColor3 = Color3.fromRGB(230, 240, 232)
clock.Text = clockText.Value
clock.Parent = gui

local obj = Instance.new("TextLabel")
obj.Name = "Objective"
obj.Size = UDim2.new(0, 220, 0, 28)
obj.Position = UDim2.new(0.5, -110, 0, 68)
obj.BackgroundColor3 = Color3.fromRGB(10, 16, 12)
obj.BackgroundTransparency = 0.35
obj.BorderSizePixel = 0
obj.Font = Enum.Font.Gotham
obj.TextSize = 16
obj.TextColor3 = Color3.fromRGB(180, 210, 190)
obj.Text = "Beacons lit 0 / 4"
obj.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 320, 0, 24)
hint.Position = UDim2.new(0.5, -160, 1, -40)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(160, 180, 165)
hint.Text = "Hold E near a Beacon to light it"
hint.Parent = gui

local function refresh()
	clock.Text = clockText.Value
	obj.Text = string.format("Beacons lit %d / 4", litCount.Value)
end

clockText.Changed:Connect(refresh)
litCount.Changed:Connect(refresh)
refresh()
