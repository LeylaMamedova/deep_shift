--[[
	LocalScript
	Parent: StarterPlayer → StarterPlayerScripts

	Shows who you are when the round picks a killer:
	  PHANTOM PUPPET  or  SURVIVOR
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("HauntedForest", 30)
if not folder then
	return
end

local remotes = folder:WaitForChild("Remotes")
local roleRemote = remotes:WaitForChild("RoleAssigned")

local gui = Instance.new("ScreenGui")
gui.Name = "RoleReveal"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(6, 4, 8)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.44)
title.Size = UDim2.new(0.9, 0, 0, 72)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 52
title.Text = ""
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextStrokeTransparency = 0.4
title.Parent = overlay

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.56)
subtitle.Size = UDim2.new(0.8, 0, 0, 36)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 20
subtitle.Text = ""
subtitle.TextColor3 = Color3.fromRGB(200, 190, 210)
subtitle.Parent = overlay

local roleTag = Instance.new("TextLabel")
roleTag.Name = "RoleTag"
roleTag.AnchorPoint = Vector2.new(0.5, 0)
roleTag.Position = UDim2.new(0.5, 0, 0, 18)
roleTag.Size = UDim2.new(0, 280, 0, 28)
roleTag.BackgroundColor3 = Color3.fromRGB(20, 12, 18)
roleTag.BackgroundTransparency = 0.25
roleTag.BorderSizePixel = 0
roleTag.Font = Enum.Font.GothamBold
roleTag.TextSize = 16
roleTag.Text = ""
roleTag.TextColor3 = Color3.fromRGB(230, 220, 235)
roleTag.Visible = false
roleTag.Parent = gui

local tagCorner = Instance.new("UICorner")
tagCorner.CornerRadius = UDim.new(0, 6)
tagCorner.Parent = roleTag

local COLORS = {
	Killer = Color3.fromRGB(190, 40, 70),
	Survivor = Color3.fromRGB(120, 210, 160),
	Choosing = Color3.fromRGB(200, 180, 90),
}

local function showReveal(payload)
	local role = payload.role or "Survivor"
	title.Text = payload.title or role
	subtitle.Text = payload.subtitle or ""
	title.TextColor3 = COLORS[role] or Color3.fromRGB(255, 255, 255)

	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	title.TextTransparency = 1
	subtitle.TextTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 0.25 }):Play()
	TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()

	local hold = (role == "Choosing") and 6.5 or 3.5
	task.delay(hold, function()
		TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.55)
		if overlay.BackgroundTransparency >= 0.99 then
			overlay.Visible = false
		end
	end)

	if role == "Killer" then
		roleTag.Visible = true
		roleTag.Text = "KILLER  ·  PHANTOM PUPPET"
		roleTag.TextColor3 = COLORS.Killer
	elseif role == "Survivor" then
		roleTag.Visible = true
		roleTag.Text = "SURVIVOR"
		roleTag.TextColor3 = COLORS.Survivor
	end
end

roleRemote.OnClientEvent:Connect(showReveal)
