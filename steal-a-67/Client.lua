--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	HUD + hold E to buy / steal / lock / place.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("StealA67", 30)
if not folder then
	warn("[StealA67] Missing StealA67 folder — is Server.lua running?")
	return
end

local remotes = folder:WaitForChild("Remotes")
local holdRemote = remotes:WaitForChild("Hold")
local notifyRemote = remotes:WaitForChild("Notify")
local chaseRemote = remotes:WaitForChild("Chase")

local gui = Instance.new("ScreenGui")
gui.Name = "StealA67Hud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Size = UDim2.new(0, 220, 0, 48)
cashLabel.Position = UDim2.new(0, 20, 0, 20)
cashLabel.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
cashLabel.BackgroundTransparency = 0.15
cashLabel.BorderSizePixel = 0
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextSize = 26
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
cashLabel.Text = "$0"
cashLabel.Parent = gui

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Name = "Rebirth"
rebirthLabel.Size = UDim2.new(0, 220, 0, 32)
rebirthLabel.Position = UDim2.new(0, 20, 0, 72)
rebirthLabel.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
rebirthLabel.BackgroundTransparency = 0.2
rebirthLabel.BorderSizePixel = 0
rebirthLabel.Font = Enum.Font.GothamBold
rebirthLabel.TextSize = 16
rebirthLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
rebirthLabel.Text = "Rebirth 0/7"
rebirthLabel.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 520, 0, 28)
hint.Position = UDim2.new(0.5, -260, 1, -44)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 16
hint.TextColor3 = Color3.fromRGB(210, 210, 230)
hint.Text = "Hold E: buy  ·  steal  ·  lock  ·  rebirth (7-JUMP at rebirth 7)"
hint.Parent = gui

local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 400, 0, 36)
toast.Position = UDim2.new(0.5, -200, 0, 24)
toast.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
toast.BackgroundTransparency = 0.2
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.Text = ""
toast.Visible = false
toast.Parent = gui

local chaseBanner = Instance.new("TextLabel")
chaseBanner.Size = UDim2.new(0, 420, 0, 44)
chaseBanner.Position = UDim2.new(0.5, -210, 0, 70)
chaseBanner.BackgroundColor3 = Color3.fromRGB(90, 10, 16)
chaseBanner.BackgroundTransparency = 0.1
chaseBanner.BorderSizePixel = 0
chaseBanner.Font = Enum.Font.GothamBlack
chaseBanner.TextSize = 22
chaseBanner.TextColor3 = Color3.fromRGB(255, 80, 80)
chaseBanner.Text = "CAYLUS IS CHASING YOU — RUN HOME"
chaseBanner.Visible = false
chaseBanner.Parent = gui

local function moneyText(n)
	if n >= 1000 then
		return string.format("$%.1fK", n / 1000)
	end
	return "$" .. tostring(n)
end

local function refreshHud()
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Cash")
	local rebirth = ls and ls:FindFirstChild("Rebirth")
	if cash then
		cashLabel.Text = moneyText(cash.Value)
	end
	if rebirth then
		if rebirth.Value >= 7 then
			rebirthLabel.Text = "Rebirth " .. rebirth.Value .. "  ·  7-JUMP ON"
		else
			rebirthLabel.Text = "Rebirth " .. rebirth.Value .. "/7  →  7-JUMP"
		end
	end
end

task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 20)
	if not ls then
		return
	end
	local cash = ls:WaitForChild("Cash")
	local rebirth = ls:WaitForChild("Rebirth")
	cash.Changed:Connect(refreshHud)
	rebirth.Changed:Connect(refreshHud)
	refreshHud()
end)

local extraJumps = player:WaitForChild("ExtraJumps", 20)
local jumpsLeft = 0
local jumpBusy = false

local function hookJumps(char)
	local hum = char:WaitForChild("Humanoid")
	jumpsLeft = extraJumps and extraJumps.Value or 0
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			jumpsLeft = extraJumps and extraJumps.Value or 0
		end
	end)
end

if player.Character then
	task.spawn(hookJumps, player.Character)
end
player.CharacterAdded:Connect(hookJumps)

UserInputService.JumpRequest:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or jumpBusy then
		return
	end
	if hum.FloorMaterial ~= Enum.Material.Air then
		return
	end
	if jumpsLeft <= 0 then
		return
	end
	jumpBusy = true
	jumpsLeft -= 1
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	task.delay(0.22, function()
		jumpBusy = false
	end)
end)

local toastToken = 0
notifyRemote.OnClientEvent:Connect(function(text)
	toastToken += 1
	local id = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(2.4, function()
		if toastToken == id then
			toast.Visible = false
		end
	end)
end)

chaseRemote.OnClientEvent:Connect(function(on)
	chaseBanner.Visible = on and true or false
end)

local holding = false

local function setHold(on)
	if holding == on then
		return
	end
	holding = on
	holdRemote:FireServer(on)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		setHold(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		setHold(false)
	end
end)
