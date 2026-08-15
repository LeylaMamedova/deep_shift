--[[
	SCRIPT (not LocalScript)
	Parent: ServerScriptService

	Rob 67s From Caylus
	Steal-a-Brainrot loop + Caylus chase, but units are 67s.
	No combat: if Caylus tags you, the 67 returns home.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local START_CASH = 100
local LOCK_SECONDS = 45
local LOCK_COOLDOWN = 20
local HOLD_SECONDS = 1.1
local RANGE = 10
local MAX_PLOTS = 4
local PADS_PER_PLOT = 4
local WALK_SPEED = 16
local CARRY_SPEED = 11
local CAYLUS_SPEED = 20
local CAYLUS_CATCH = 5.5
local CONVEYOR_SPAWN = 4.5
local CONVEYOR_TRAVEL = 16
local JUMP_REBIRTH = 7
local EXTRA_JUMPS_AT_7 = 6 -- 1 normal + 6 air = 7 jumps

local UNITS = {
	{ id = "Common67", name = "Common 67", cost = 50, income = 2, color = Color3.fromRGB(90, 255, 130), weight = 55 },
	{ id = "Rare67", name = "Rare 67", cost = 200, income = 10, color = Color3.fromRGB(80, 190, 255), weight = 27 },
	{ id = "Epic67", name = "Epic 67", cost = 700, income = 35, color = Color3.fromRGB(190, 90, 255), weight = 14 },
	{ id = "Secret67", name = "Secret 67", cost = 2200, income = 110, color = Color3.fromRGB(255, 210, 60), weight = 4 },
}

local VAULT = {
	{ id = "Vault67", name = "Vault 67", cost = 0, income = 28, color = Color3.fromRGB(255, 140, 70) },
	{ id = "Caylus67", name = "Caylus 67", cost = 0, income = 95, color = Color3.fromRGB(255, 60, 80) },
}

local folder = ReplicatedStorage:FindFirstChild("StealA67") or Instance.new("Folder")
folder.Name = "StealA67"
folder.Parent = ReplicatedStorage

local remotes = folder:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = folder

local function remote(name)
	local r = remotes:FindFirstChild(name) or Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local holdRemote = remote("Hold")
local notifyRemote = remote("Notify")
local chaseRemote = remote("Chase")

local function notify(player, text)
	notifyRemote:FireClient(player, text)
end

local function cashOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Cash")
end

local function addCash(player, amount)
	local cash = cashOf(player)
	if cash then
		cash.Value = math.max(0, cash.Value + amount)
	end
end

local function rebirthOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Rebirth")
end

local function rebirthCost(n)
	return 200 * (n + 1)
end

local function cashMultiplier(player)
	local r = rebirthOf(player)
	return 1 + (r and r.Value or 0)
end

local function refreshJumps(player)
	local r = rebirthOf(player)
	local jumps = player:FindFirstChild("ExtraJumps")
	if not jumps then
		jumps = Instance.new("IntValue")
		jumps.Name = "ExtraJumps"
		jumps.Parent = player
	end
	jumps.Value = (r and r.Value >= JUMP_REBIRTH) and EXTRA_JUMPS_AT_7 or 0
end

local function setSpeed(player, speed)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speed
	end
end

local function makeBillboard(parent, text, color, height, name)
	local old = parent:FindFirstChild(name or "Label")
	if old then
		old:Destroy()
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = name or "Label"
	bb.Size = UDim2.fromOffset(180, 54)
	bb.StudsOffset = Vector3.new(0, height or 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = bb
	return bb
end

local function create67(info, scale)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = info.name

	local body = Instance.new("Part")
	body.Name = "Primary"
	body.Size = Vector3.new(2.2, 3.4, 1.4) * scale
	body.Color = info.color
	body.Material = Enum.Material.Neon
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local face = Instance.new("Part")
	face.Name = "Face"
	face.Size = Vector3.new(1.6, 1.2, 0.2) * scale
	face.Color = Color3.fromRGB(20, 20, 28)
	face.Material = Enum.Material.SmoothPlastic
	face.Anchored = false
	face.CanCollide = false
	face.CFrame = body.CFrame * CFrame.new(0, 0.5 * scale, -0.7 * scale)
	face.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = face
	weld.Parent = body

	makeBillboard(body, "67", Color3.new(1, 1, 1), 2.6 * scale)
	local price = Instance.new("BillboardGui")
	price.Name = "Stats"
	price.Size = UDim2.fromOffset(160, 36)
	price.StudsOffset = Vector3.new(0, 4.4 * scale, 0)
	price.AlwaysOnTop = true
	price.Parent = body
	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.fromScale(1, 1)
	stats.BackgroundTransparency = 1
	stats.Font = Enum.Font.GothamBold
	stats.TextScaled = true
	stats.TextColor3 = info.color
	stats.TextStrokeTransparency = 0.4
	if info.cost > 0 then
		stats.Text = info.name .. "  $" .. info.cost .. "  +$" .. info.income .. "/s"
	else
		stats.Text = info.name .. "  STEAL  +$" .. info.income .. "/s"
	end
	stats.Parent = price

	model.PrimaryPart = body
	model:SetAttribute("Id", info.id)
	model:SetAttribute("Income", info.income)
	model:SetAttribute("Cost", info.cost)
	model:SetAttribute("DisplayName", info.name)
	return model
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local world = workspace:FindFirstChild("StealA67World")
if not world then
	world = Instance.new("Folder")
	world.Name = "StealA67World"
	world.Parent = workspace
end

local plotsFolder = world:FindFirstChild("Plots") or Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = world

local conveyorFolder = world:FindFirstChild("Conveyor") or Instance.new("Folder")
conveyorFolder.Name = "Conveyor"
conveyorFolder.Parent = world

local function buildMapIfNeeded()
	if plotsFolder:FindFirstChild("Plot1") then
		return
	end

	part({
		Name = "Ground",
		Size = Vector3.new(280, 1, 280),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(24, 26, 40),
		Material = Enum.Material.Slate,
		Parent = world,
	})

	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.Position = Vector3.new(0, 3, 18)
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Anchored = true
		spawn.Neutral = true
	end

	local belt = part({
		Name = "Belt",
		Size = Vector3.new(96, 1, 8),
		Position = Vector3.new(0, 1.2, 0),
		Color = Color3.fromRGB(180, 40, 50),
		Material = Enum.Material.Neon,
		Parent = conveyorFolder,
	})
	makeBillboard(belt, "CONVEYOR — hold E on a 67 to buy", Color3.fromRGB(255, 220, 80), 9)

	part({
		Name = "RailL",
		Size = Vector3.new(96, 1.4, 0.6),
		Position = Vector3.new(0, 2, -4.2),
		Color = Color3.fromRGB(40, 20, 24),
		Parent = conveyorFolder,
	})
	part({
		Name = "RailR",
		Size = Vector3.new(96, 1.4, 0.6),
		Position = Vector3.new(0, 2, 4.2),
		Color = Color3.fromRGB(40, 20, 24),
		Parent = conveyorFolder,
	})

	local startMarker = part({
		Name = "Start",
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(-44, 4, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = conveyorFolder,
	})
	local finishMarker = part({
		Name = "Finish",
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(44, 4, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = conveyorFolder,
	})
	startMarker.Name = "Start"
	finishMarker.Name = "Finish"

	local offsets = {
		Vector3.new(0, 0, 85),
		Vector3.new(95, 0, 25),
		Vector3.new(-95, 0, 25),
		Vector3.new(95, 0, -55),
	}
	local colors = {
		Color3.fromRGB(70, 40, 90),
		Color3.fromRGB(40, 70, 90),
		Color3.fromRGB(40, 90, 60),
		Color3.fromRGB(90, 60, 40),
	}

	for i = 1, MAX_PLOTS do
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. i
		plot.Parent = plotsFolder

		local origin = offsets[i]
		local floor = part({
			Name = "Floor",
			Size = Vector3.new(40, 1, 32),
			Position = origin + Vector3.new(0, 1, 0),
			Color = colors[i],
			Material = Enum.Material.Concrete,
			Parent = plot,
		})

		part({
			Name = "Spawn",
			Size = Vector3.new(6, 1, 6),
			Position = origin + Vector3.new(0, 1.6, 12),
			Color = Color3.fromRGB(220, 220, 230),
			Material = Enum.Material.Neon,
			Parent = plot,
		})

		local lockBtn = part({
			Name = "LockButton",
			Size = Vector3.new(4, 3, 1.2),
			Position = origin + Vector3.new(14, 3.2, 12),
			Color = Color3.fromRGB(80, 200, 90),
			Material = Enum.Material.Neon,
			Parent = plot,
		})
		makeBillboard(lockBtn, "LOCK\nhold E", Color3.fromRGB(180, 255, 180), 3)

		local rebirthBtn = part({
			Name = "RebirthButton",
			Size = Vector3.new(4, 3, 1.2),
			Position = origin + Vector3.new(-14, 3.2, 12),
			Color = Color3.fromRGB(255, 190, 60),
			Material = Enum.Material.Neon,
			Parent = plot,
		})
		makeBillboard(rebirthBtn, "REBIRTH\n0/7 → 7-JUMP", Color3.fromRGB(255, 230, 140), 3)

		for p = 1, PADS_PER_PLOT do
			local pad = part({
				Name = "Pad" .. p,
				Size = Vector3.new(6, 0.6, 6),
				Position = origin + Vector3.new(-12 + (p - 1) * 8, 1.8, -4),
				Color = Color3.fromRGB(20, 20, 30),
				Material = Enum.Material.Metal,
				Parent = plot,
			})
			makeBillboard(pad, "PAD " .. p, Color3.fromRGB(160, 160, 180), 2)
		end

		plot.PrimaryPart = floor
		plot:SetAttribute("Locked", false)
	end

	local caylusBase = Instance.new("Model")
	caylusBase.Name = "CaylusBase"
	caylusBase.Parent = world
	local vaultOrigin = Vector3.new(0, 0, -110)
	local vaultFloor = part({
		Name = "Floor",
		Size = Vector3.new(48, 1, 36),
		Position = vaultOrigin + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(90, 20, 30),
		Material = Enum.Material.Marble,
		Parent = caylusBase,
	})
	makeBillboard(vaultFloor, "CAYLUS VAULT — steal a 67 and RUN", Color3.fromRGB(255, 80, 80), 12, "Title")
	for p = 1, 4 do
		local pad = part({
			Name = "Pad" .. p,
			Size = Vector3.new(6, 0.6, 6),
			Position = vaultOrigin + Vector3.new(-12 + (p - 1) * 8, 1.8, -2),
			Color = Color3.fromRGB(40, 10, 16),
			Material = Enum.Material.Metal,
			Parent = caylusBase,
		})
		makeBillboard(pad, "VAULT " .. p, Color3.fromRGB(255, 180, 180), 2)
	end
	caylusBase.PrimaryPart = vaultFloor

	print("[StealA67] Built Caylus map (conveyor + 4 bases + vault).")
end

buildMapIfNeeded()

local function ensureRebirthButtons()
	for i = 1, MAX_PLOTS do
		local plot = plotsFolder:FindFirstChild("Plot" .. i)
		if plot and not plot:FindFirstChild("RebirthButton") then
			local floor = plot:FindFirstChild("Floor")
			local lockBtn = plot:FindFirstChild("LockButton")
			if floor and lockBtn then
				local rebirthBtn = part({
					Name = "RebirthButton",
					Size = Vector3.new(4, 3, 1.2),
					Position = lockBtn.Position + Vector3.new(-28, 0, 0),
					Color = Color3.fromRGB(255, 190, 60),
					Material = Enum.Material.Neon,
					Parent = plot,
				})
				makeBillboard(rebirthBtn, "REBIRTH\n0/7 → 7-JUMP", Color3.fromRGB(255, 230, 140), 3)
			end
		end
	end
end

ensureRebirthButtons()

local function updateRebirthSign(plot, player)
	local btn = plot and plot:FindFirstChild("RebirthButton")
	if not btn then
		return
	end
	local n = 0
	if player then
		local r = rebirthOf(player)
		n = r and r.Value or 0
	end
	local cost = rebirthCost(n)
	if n >= JUMP_REBIRTH then
		makeBillboard(btn, "REBIRTH\n$" .. cost .. "  " .. cashMultiplier(player) .. "x\n7-JUMP ON", Color3.fromRGB(255, 230, 140), 3)
	else
		makeBillboard(btn, "REBIRTH\n$" .. cost .. "\n" .. n .. "/7 → 7-JUMP", Color3.fromRGB(255, 230, 140), 3)
	end
end

local caylusBase = world:FindFirstChild("CaylusBase")
local beltStart = conveyorFolder:FindFirstChild("Start")
local beltFinish = conveyorFolder:FindFirstChild("Finish")

local assigned = {}
local carrying = {}
local hold = {}
local lockUntil = {}
local lockReady = {}
local conveyorItems = {}
local chaseTarget = nil
local origin = {} -- [model] = { plot = Instance, pad = Instance }

local function plotOf(player)
	return assigned[player]
end

local function ownerOfPlot(plot)
	for plr, p in pairs(assigned) do
		if p == plot then
			return plr
		end
	end
	return nil
end

local function isPlotLocked(plot)
	if not plot or plot.Name == "CaylusBase" then
		return false
	end
	local untilT = lockUntil[plot]
	return untilT ~= nil and os.clock() < untilT
end

local function emptyPad(plot)
	if not plot then
		return nil
	end
	for i = 1, PADS_PER_PLOT do
		local pad = plot:FindFirstChild("Pad" .. i)
		if pad and not pad:GetAttribute("Occupied") then
			return pad
		end
	end
	return nil
end

local function setPadOccupied(pad, yes)
	if not pad then
		return
	end
	pad:SetAttribute("Occupied", yes and true or false)
	if pad.Parent and pad.Parent.Name == "CaylusBase" then
		pad.Color = yes and Color3.fromRGB(90, 30, 40) or Color3.fromRGB(40, 10, 16)
	else
		pad.Color = yes and Color3.fromRGB(60, 40, 90) or Color3.fromRGB(20, 20, 30)
	end
end

local function clearCarryWeld(model)
	local body = model and model.PrimaryPart
	if not body then
		return
	end
	for _, d in ipairs(body:GetChildren()) do
		if d:IsA("WeldConstraint") and d.Name == "CarryWeld" then
			d:Destroy()
		end
	end
	body.Anchored = true
	body.AssemblyLinearVelocity = Vector3.zero
end

local function placeOnPad(model, pad, player)
	clearCarryWeld(model)
	model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 2.6, 0)))
	model:SetAttribute("OwnerUserId", player and player.UserId or 0)
	model:SetAttribute("PadName", pad.Name)
	model.Parent = pad.Parent
	origin[model] = { plot = pad.Parent, pad = pad }
	setPadOccupied(pad, true)
end

local function returnHome(model)
	if not model or not model.Parent then
		return
	end
	clearCarryWeld(model)
	local home = origin[model]
	local plot = home and home.plot
	local pad = home and home.pad
	if not (plot and plot.Parent and pad and pad.Parent) then
		model:Destroy()
		origin[model] = nil
		return
	end
	if pad:GetAttribute("Occupied") then
		pad = emptyPad(plot)
	end
	if not pad then
		model:Destroy()
		origin[model] = nil
		return
	end
	local owner = ownerOfPlot(plot)
	placeOnPad(model, pad, owner)
end

local function stopChase(player)
	if chaseTarget == player then
		chaseTarget = nil
		chaseRemote:FireClient(player, false)
	end
end

local function startChase(player)
	chaseTarget = player
	chaseRemote:FireClient(player, true)
	notify(player, "CAYLUS IS CHASING YOU — run home!")
end

local function dropCarry(player, asPlace)
	local model = carrying[player]
	carrying[player] = nil
	setSpeed(player, WALK_SPEED)
	stopChase(player)
	if not model or not model.Parent then
		return
	end
	if asPlace then
		local plot = plotOf(player)
		local pad = plot and emptyPad(plot)
		if pad then
			placeOnPad(model, pad, player)
			notify(player, "Safe! " .. (model:GetAttribute("DisplayName") or "67") .. " is yours")
		else
			returnHome(model)
			notify(player, "No empty pad — 67 went back")
		end
	else
		returnHome(model)
	end
end

local function attachCarry(player, model)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local body = model.PrimaryPart
	if not hrp or not body then
		return false
	end

	local oldPadName = model:GetAttribute("PadName")
	if oldPadName and model.Parent then
		local oldPad = model.Parent:FindFirstChild(oldPadName)
		setPadOccupied(oldPad, false)
	end

	body.Anchored = false
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("PadName", "")
	model.Parent = char
	model:PivotTo(hrp.CFrame * CFrame.new(0, 1.4, -3.2))

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = hrp
	weld.Part1 = body
	weld.Parent = body

	carrying[player] = model
	setSpeed(player, CARRY_SPEED)
	return true
end

local function rollUnit()
	local total = 0
	for _, info in ipairs(UNITS) do
		total += info.weight
	end
	local n = math.random(1, total)
	local acc = 0
	for _, info in ipairs(UNITS) do
		acc += info.weight
		if n <= acc then
			return info
		end
	end
	return UNITS[1]
end

local function assignPlot(player)
	for i = 1, MAX_PLOTS do
		local plot = plotsFolder:FindFirstChild("Plot" .. i)
		if plot and not ownerOfPlot(plot) then
			assigned[player] = plot
			plot:SetAttribute("OwnerUserId", player.UserId)
			local floor = plot:FindFirstChild("Floor")
			if floor then
				makeBillboard(floor, player.Name .. "'s base", Color3.fromRGB(255, 255, 255), 10, "OwnerBillboard")
			end
			updateRebirthSign(plot, player)
			return plot
		end
	end
	return nil
end

local function clearPlot(plot)
	if not plot then
		return
	end
	plot:SetAttribute("OwnerUserId", 0)
	plot:SetAttribute("Locked", false)
	lockUntil[plot] = nil
	lockReady[plot] = nil
	local floor = plot:FindFirstChild("Floor")
	local sign = floor and floor:FindFirstChild("OwnerBillboard")
	if sign then
		sign:Destroy()
	end
	for i = 1, PADS_PER_PLOT do
		local pad = plot:FindFirstChild("Pad" .. i)
		if pad then
			setPadOccupied(pad, false)
		end
	end
	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("Id") then
			origin[child] = nil
			child:Destroy()
		end
	end
	local lockBtn = plot:FindFirstChild("LockButton")
	if lockBtn then
		lockBtn.Color = Color3.fromRGB(80, 200, 90)
	end
end

local function teleportToPlot(player)
	local plot = plotOf(player)
	local spawnPart = plot and plot:FindFirstChild("Spawn")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if spawnPart and hrp then
		hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
	end
	if carrying[player] then
		setSpeed(player, CARRY_SPEED)
	else
		setSpeed(player, WALK_SPEED)
	end
end

local function setupPlayer(player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = START_CASH
	cash.Parent = ls
	local rebirth = Instance.new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Value = 0
	rebirth.Parent = ls
	refreshJumps(player)

	local plot = assignPlot(player)
	if not plot then
		notify(player, "Server full — 4 bases max")
		return
	end

	player.CharacterAdded:Connect(function()
		if carrying[player] then
			returnHome(carrying[player])
			carrying[player] = nil
			stopChase(player)
		end
		task.wait(0.4)
		teleportToPlot(player)
	end)
	if player.Character then
		task.defer(teleportToPlot, player)
	end
end

local function rootOf(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function near(player, inst)
	local root = rootOf(player)
	if not root or not inst then
		return false
	end
	local pos = inst:IsA("Model") and inst.PrimaryPart and inst.PrimaryPart.Position or (inst:IsA("BasePart") and inst.Position)
	return pos and (root.Position - pos).Magnitude <= RANGE
end

local function findHoldTarget(player)
	if carrying[player] then
		local plot = plotOf(player)
		local pad = plot and emptyPad(plot)
		if pad and near(player, pad) then
			return { kind = "place", target = pad }
		end
		return nil
	end

	local plot = plotOf(player)
	if plot then
		local lockBtn = plot:FindFirstChild("LockButton")
		if lockBtn and near(player, lockBtn) then
			return { kind = "lock", target = lockBtn }
		end
		local rebirthBtn = plot:FindFirstChild("RebirthButton")
		if rebirthBtn and near(player, rebirthBtn) then
			return { kind = "rebirth", target = rebirthBtn }
		end
	end

	for _, item in ipairs(conveyorItems) do
		if item.model and item.model.Parent and near(player, item.model) then
			return { kind = "buy", target = item.model, info = item.info }
		end
	end

	local function scanPlot(otherPlot)
		if otherPlot == plot then
			return nil
		end
		for _, child in ipairs(otherPlot:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("Id") and child.PrimaryPart and near(player, child) then
				return { kind = "steal", target = child, from = otherPlot }
			end
		end
		return nil
	end

	for _, otherPlot in ipairs(plotsFolder:GetChildren()) do
		local found = scanPlot(otherPlot)
		if found then
			return found
		end
	end
	if caylusBase then
		local found = scanPlot(caylusBase)
		if found then
			return found
		end
	end
	return nil
end

local function takeOffConveyor(model)
	for i, item in ipairs(conveyorItems) do
		if item.model == model then
			table.remove(conveyorItems, i)
			return item
		end
	end
end

local function finishHold(player, data)
	if data.kind == "buy" then
		local info = data.info
		local model = data.target
		local cash = cashOf(player)
		local plot = plotOf(player)
		if not info or not model or not model.Parent or not cash or not plot then
			return
		end
		if cash.Value < info.cost then
			notify(player, "Need $" .. info.cost)
			return
		end
		local pad = emptyPad(plot)
		if not pad then
			notify(player, "Base full")
			return
		end
		cash.Value -= info.cost
		takeOffConveyor(model)
		placeOnPad(model, pad, player)
		notify(player, "Bought " .. info.name)
		return
	end

	if data.kind == "steal" then
		local model = data.target
		if not model or not model.Parent or not model:GetAttribute("Id") then
			return
		end
		local otherPlot = data.from or model.Parent
		if isPlotLocked(otherPlot) then
			notify(player, "Base is LOCKED")
			return
		end
		if model:GetAttribute("OwnerUserId") == player.UserId then
			return
		end
		if attachCarry(player, model) then
			local victim = ownerOfPlot(otherPlot)
			notify(player, "Stole " .. (model:GetAttribute("DisplayName") or "67") .. "! Run home")
			if victim then
				notify(victim, player.Name .. " stole your 67!")
			end
			startChase(player)
		end
		return
	end

	if data.kind == "place" then
		dropCarry(player, true)
		return
	end

	if data.kind == "lock" then
		local plot = plotOf(player)
		if not plot then
			return
		end
		if isPlotLocked(plot) then
			notify(player, "Already locked")
			return
		end
		local ready = lockReady[plot] or 0
		if os.clock() < ready then
			notify(player, "Lock cooling down")
			return
		end
		lockUntil[plot] = os.clock() + LOCK_SECONDS
		lockReady[plot] = os.clock() + LOCK_SECONDS + LOCK_COOLDOWN
		plot:SetAttribute("Locked", true)
		local lockBtn = plot:FindFirstChild("LockButton")
		if lockBtn then
			lockBtn.Color = Color3.fromRGB(255, 70, 70)
		end
		notify(player, "Base locked for " .. LOCK_SECONDS .. "s")
		task.delay(LOCK_SECONDS, function()
			if plot.Parent then
				plot:SetAttribute("Locked", false)
				if lockBtn and lockBtn.Parent then
					lockBtn.Color = Color3.fromRGB(80, 200, 90)
				end
				notify(player, "Lock ended — protect your 67s")
			end
		end)
		return
	end

	if data.kind == "rebirth" then
		local plot = plotOf(player)
		local cash = cashOf(player)
		local rebirth = rebirthOf(player)
		if not plot or not cash or not rebirth then
			return
		end
		local cost = rebirthCost(rebirth.Value)
		if cash.Value < cost then
			notify(player, "Need $" .. cost .. " to rebirth")
			return
		end
		for _, child in ipairs(plot:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("Id") then
				origin[child] = nil
				child:Destroy()
			end
		end
		for i = 1, PADS_PER_PLOT do
			setPadOccupied(plot:FindFirstChild("Pad" .. i), false)
		end
		rebirth.Value += 1
		cash.Value = START_CASH
		refreshJumps(player)
		updateRebirthSign(plot, player)
		if rebirth.Value == JUMP_REBIRTH then
			notify(player, "REBIRTH " .. rebirth.Value .. " — 7-JUMP UNLOCKED")
		elseif rebirth.Value > JUMP_REBIRTH then
			notify(player, "Rebirth " .. rebirth.Value .. " — " .. cashMultiplier(player) .. "x cash, 7-JUMP on")
		else
			notify(player, "Rebirth " .. rebirth.Value .. "/" .. JUMP_REBIRTH .. " — 7-JUMP at 7")
		end
	end
end

local function createCaylus()
	local existing = world:FindFirstChild("Caylus")
	if existing then
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Caylus"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Color = Color3.fromRGB(28, 28, 36)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.Parent = model

	local hat = Instance.new("Part")
	hat.Name = "Hat"
	hat.Size = Vector3.new(2.6, 0.45, 2.6)
	hat.Color = Color3.fromRGB(20, 20, 24)
	hat.Material = Enum.Material.SmoothPlastic
	hat.CanCollide = false
	hat.Massless = true
	hat.CFrame = root.CFrame * CFrame.new(0, 2.7, 0)
	hat.Parent = model
	local hatWeld = Instance.new("WeldConstraint")
	hatWeld.Part0 = root
	hatWeld.Part1 = hat
	hatWeld.Parent = hat

	local brim = Instance.new("Part")
	brim.Name = "Brim"
	brim.Size = Vector3.new(1.2, 1.1, 1.2)
	brim.Color = Color3.fromRGB(20, 20, 24)
	brim.CanCollide = false
	brim.Massless = true
	brim.CFrame = root.CFrame * CFrame.new(0, 3.4, 0)
	brim.Parent = model
	local brimWeld = Instance.new("WeldConstraint")
	brimWeld.Part0 = root
	brimWeld.Part1 = brim
	brimWeld.Parent = brim

	makeBillboard(root, "CAYLUS", Color3.fromRGB(255, 80, 80), 4.2, "Name")
	model.PrimaryPart = root
	model.Parent = world
	model:PivotTo(CFrame.new(0, 4.5, -96))
	return model, root
end

local caylusModel, caylusRoot = createCaylus()
local patrol = {
	Vector3.new(-16, 4.5, -100),
	Vector3.new(16, 4.5, -100),
	Vector3.new(0, 4.5, -120),
	Vector3.new(0, 4.5, -96),
}
local patrolIndex = 1

local function restockVault()
	if not caylusBase then
		return
	end
	for i = 1, 4 do
		local pad = caylusBase:FindFirstChild("Pad" .. i)
		if pad and not pad:GetAttribute("Occupied") then
			local info = (i == 4) and VAULT[2] or VAULT[1]
			local model = create67(info, 1)
			placeOnPad(model, pad, nil)
		end
	end
end

restockVault()

task.spawn(function()
	while true do
		task.wait(22)
		restockVault()
	end
end)

task.spawn(function()
	while true do
		task.wait(CONVEYOR_SPAWN)
		if beltStart and beltFinish then
			local info = rollUnit()
			local model = create67(info, 0.9)
			model:SetAttribute("OnConveyor", true)
			model:PivotTo(CFrame.new(beltStart.Position))
			model.Parent = conveyorFolder
			table.insert(conveyorItems, { model = model, info = info, t = 0 })
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.05)
		if beltStart and beltFinish then
			for i = #conveyorItems, 1, -1 do
				local item = conveyorItems[i]
				if not item.model or not item.model.Parent then
					table.remove(conveyorItems, i)
				else
					item.t += 0.05
					local alpha = item.t / CONVEYOR_TRAVEL
					if alpha >= 1 then
						item.model:Destroy()
						table.remove(conveyorItems, i)
					else
						local pos = beltStart.Position:Lerp(beltFinish.Position, alpha)
						item.model:PivotTo(CFrame.new(pos))
					end
				end
			end
		end
	end
end)

holdRemote.OnServerEvent:Connect(function(player, isHolding)
	if not isHolding then
		hold[player] = nil
		return
	end
	local found = findHoldTarget(player)
	if not found then
		hold[player] = nil
		return
	end
	hold[player] = {
		kind = found.kind,
		target = found.target,
		info = found.info,
		from = found.from,
		t = 0,
	}
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		for player, data in pairs(hold) do
			local still = findHoldTarget(player)
			local same = still and still.kind == data.kind and still.target == data.target
			if not same then
				hold[player] = nil
			else
				data.t += 0.1
				if data.t >= HOLD_SECONDS then
					hold[player] = nil
					finishHold(player, data)
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		for player, plot in pairs(assigned) do
			if player.Parent and plot then
				local total = 0
				for _, child in ipairs(plot:GetChildren()) do
					if child:IsA("Model") and child:GetAttribute("Income") then
						total += child:GetAttribute("Income")
					end
				end
				if total > 0 then
					addCash(player, total * cashMultiplier(player))
				end
			end
		end
	end
end)

local function moveCaylus(dt, goal)
	if not caylusRoot or not caylusRoot.Parent then
		return
	end
	local pos = caylusRoot.Position
	local flat = Vector3.new(goal.X, pos.Y, goal.Z)
	local delta = flat - pos
	if delta.Magnitude < 0.4 then
		return true
	end
	local step = math.min(CAYLUS_SPEED * dt, delta.Magnitude)
	local nextPos = pos + delta.Unit * step
	caylusRoot.CFrame = CFrame.lookAt(nextPos, nextPos + delta.Unit)
	return false
end

RunService.Heartbeat:Connect(function(dt)
	if chaseTarget and chaseTarget.Parent and carrying[chaseTarget] then
		local hrp = rootOf(chaseTarget)
		if hrp then
			moveCaylus(dt, hrp.Position)
			local pos = caylusRoot.Position
			local target = Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z)
			if (pos - target).Magnitude <= CAYLUS_CATCH then
				notify(chaseTarget, "Caylus caught you! 67 went back")
				dropCarry(chaseTarget, false)
			end
		end
	else
		if chaseTarget then
			stopChase(chaseTarget)
		end
		local arrived = moveCaylus(dt, patrol[patrolIndex])
		if arrived then
			patrolIndex = patrolIndex % #patrol + 1
		end
	end
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	if carrying[player] then
		returnHome(carrying[player])
	end
	carrying[player] = nil
	hold[player] = nil
	stopChase(player)
	local plot = assigned[player]
	assigned[player] = nil
	clearPlot(plot)
end)

print("[StealA67] Caylus server ready. Buy from conveyor, steal 67s, don't get tagged.")
