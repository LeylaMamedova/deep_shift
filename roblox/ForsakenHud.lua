--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	Shows Forsaken-style countdown (8:00 → 0:00).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("HauntedForest", 30)
if not folder then
	return
end

local clockText = folder:WaitForChild("ClockText")
local litCount = folder:WaitForChild("LitCount")
local timeLeft = folder:WaitForChild("TimeLeft")

local gui = Instance.new("ScreenGui")
gui.Name = "ForsakenTimerHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local clock = Instance.new("TextLabel")
clock.Size = UDim2.new(0, 200, 0, 52)
clock.Position = UDim2.new(0.5, -100, 0, 14)
clock.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
clock.BackgroundTransparency = 0.2
clock.BorderSizePixel = 0
clock.Font = Enum.Font.GothamBold
clock.TextSize = 32
clock.TextColor3 = Color3.fromRGB(240, 240, 245)
clock.Text = clockText.Value
clock.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = clock

local obj = Instance.new("TextLabel")
obj.Size = UDim2.new(0, 200, 0, 26)
obj.Position = UDim2.new(0.5, -100, 0, 70)
obj.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
obj.BackgroundTransparency = 0.35
obj.BorderSizePixel = 0
obj.Font = Enum.Font.Gotham
obj.TextSize = 15
obj.TextColor3 = Color3.fromRGB(180, 185, 200)
obj.Text = "Beacons 0 / 4"
obj.Parent = gui

local function refresh()
	clock.Text = clockText.Value
	obj.Text = string.format("Beacons %d / 4", litCount.Value)
	-- turn red under 2 minutes
	if timeLeft.Value <= 120 then
		clock.TextColor3 = Color3.fromRGB(255, 90, 90)
	else
		clock.TextColor3 = Color3.fromRGB(240, 240, 245)
	end
end

clockText.Changed:Connect(refresh)
litCount.Changed:Connect(refresh)
timeLeft.Changed:Connect(refresh)
refresh()
