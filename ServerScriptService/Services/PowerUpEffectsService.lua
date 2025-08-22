local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PowerUpEffectsService = {}

-- RemoteEvents
local powerUpActivatedEvent = ReplicatedStorage:FindFirstChild("PowerUpActivatedEvent") or Instance.new("RemoteEvent")
local powerUpEffectsEvent = ReplicatedStorage:FindFirstChild("PowerUpEffectsEvent") or Instance.new("RemoteEvent")

-- Set the name and parent for the events if they were just created
if not ReplicatedStorage:FindFirstChild("PowerUpActivatedEvent") then
	powerUpActivatedEvent.Name = "PowerUpActivatedEvent"
	powerUpActivatedEvent.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("PowerUpEffectsEvent") then
	powerUpEffectsEvent.Name = "PowerUpEffectsEvent"
	powerUpEffectsEvent.Parent = ReplicatedStorage
end

-- State
local activeEffects = {} -- Track active effects for cleanup

-- Helper function to get all players in the game
local function getAllPlayers()
	local players = {}
	for _, player in pairs(Players:GetPlayers()) do
		if player and player.Parent then
			table.insert(players, player)
		end
	end
	return players
end

-- Create trail effect for a character
local function createTrailEffect(character, effectType)
	if not character or not character.Parent then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create attachments
	local att0 = Instance.new("Attachment", rootPart)
	local att1 = Instance.new("Attachment", rootPart)
	att0.Position = Vector3.new(0, 1, 0)
	att1.Position = Vector3.new(0, -1, 0)

	-- Create trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.LightEmission = 1
	trail.MinLength = 0.1

	-- Customize trail based on effect type
	if effectType == "RocketBoost" then
		trail.Lifetime = 0.3
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 200, 200)) -- Red/Orange for rocket
	elseif effectType == "SuperJump" then
		trail.Lifetime = 0.5
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		trail.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100), Color3.fromRGB(200, 255, 200)) -- Green for super jump
	elseif effectType == "LowGravity" then
		trail.Lifetime = 0.8
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		trail.Color = ColorSequence.new(Color3.fromRGB(100, 100, 255), Color3.fromRGB(200, 200, 255)) -- Blue for low gravity
	end

	trail.Parent = rootPart

	-- Store effect for cleanup
	local effectId = character.Name .. "_" .. effectType .. "_" .. tick()
	activeEffects[effectId] = {
		trail = trail,
		att0 = att0,
		att1 = att1,
		character = character,
		type = effectType
	}

	return effectId
end

-- Create float bubble effect
local function createFloatBubble(character, duration)
	if not character or not character.Parent then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create bubble
	local bubble = Instance.new("Part")
	bubble.Name = "FloatBubble_" .. character.Name
	bubble.Shape = Enum.PartType.Ball
	bubble.Size = Vector3.new(8, 8, 8)
	bubble.Transparency = 0.9
	bubble.Material = Enum.Material.Neon
	bubble.Color = Color3.fromRGB(135, 206, 235) -- Light blue
	bubble.Anchored = true -- Keep anchored to avoid physics issues
	bubble.CanCollide = false
	bubble.Parent = workspace -- Keep in workspace to avoid being destroyed with character

	-- Position bubble at character's center (slightly above root part for better visual)
	local characterCenter = rootPart.Position + Vector3.new(0, 2, 0)
	bubble.CFrame = CFrame.new(characterCenter)

	-- Update bubble position every frame to follow character
	local bubbleConnection = RunService.Heartbeat:Connect(function()
		if bubble and bubble.Parent and rootPart and rootPart.Parent then
			-- Update position every frame for immediate response
			local newCenter = rootPart.Position + Vector3.new(0, 2, 0)
			bubble.CFrame = CFrame.new(newCenter)
		end
	end)

	-- Store effect for cleanup
	local effectId = character.Name .. "_Float_" .. tick()
	activeEffects[effectId] = {
		bubble = bubble,
		connection = bubbleConnection,
		character = character,
		type = "Float"
	}

	-- Auto-cleanup after duration
	if duration > 0 then
		task.delay(duration, function()
			PowerUpEffectsService.CleanupEffect(effectId)
		end)
	end

	return effectId
end

-- Cleanup a specific effect
function PowerUpEffectsService.CleanupEffect(effectId)
	local effect = activeEffects[effectId]
	if not effect then return end

	if effect.trail then
		effect.trail:Destroy()
	end
	if effect.att0 then
		effect.att0:Destroy()
	end
	if effect.att1 then
		effect.att1:Destroy()
	end
	if effect.bubble then
		effect.bubble:Destroy()
	end
	if effect.connection then
		effect.connection:Disconnect()
	end

	activeEffects[effectId] = nil
end

-- Cleanup all effects for a specific character
function PowerUpEffectsService.CleanupCharacterEffects(character)
	for effectId, effect in pairs(activeEffects) do
		if effect.character == character then
			PowerUpEffectsService.CleanupEffect(effectId)
		end
	end
end

-- Cleanup all effects
function PowerUpEffectsService.CleanupAllEffects()
	for effectId, _ in pairs(activeEffects) do
		PowerUpEffectsService.CleanupEffect(effectId)
	end
end

-- Handle powerup activation from clients
powerUpActivatedEvent.OnServerEvent:Connect(function(player, powerUpType, duration)
	if not player or not player.Parent then return end

	local character = player.Character
	if not character or not character.Parent then return end

	-- Validate duration parameter
	if type(duration) ~= "number" or duration < 0 then
		print("Warning: Invalid duration for powerup:", powerUpType, "duration:", duration, "type:", type(duration))
		duration = 0 -- Default to 0 if invalid
	end

	print("PowerUp activated:", powerUpType, "by", player.Name, "duration:", duration)

	-- Create the appropriate effect
	local effectId
	if powerUpType == "RocketBoost" then
		effectId = createTrailEffect(character, "RocketBoost")
		-- Auto-cleanup after duration
		if duration > 0 then
			task.delay(duration, function()
				PowerUpEffectsService.CleanupEffect(effectId)
			end)
		end

	elseif powerUpType == "SuperJump" then
		effectId = createTrailEffect(character, "SuperJump")
		-- Auto-cleanup after duration
		if duration > 0 then
			task.delay(duration, function()
				PowerUpEffectsService.CleanupEffect(effectId)
			end)
		end

	elseif powerUpType == "LowGravity" then
		effectId = createTrailEffect(character, "LowGravity")
		-- Auto-cleanup after duration
		if duration > 0 then
			task.delay(duration, function()
				PowerUpEffectsService.CleanupEffect(effectId)
			end)
		end

	elseif powerUpType == "Float" then
		effectId = createFloatBubble(character, duration)

	elseif powerUpType == "FloatStop" then
		-- Cleanup float effects for this character
		PowerUpEffectsService.CleanupCharacterEffects(character)
	end

	-- Notify all clients about the powerup effect (optional - for additional client-side effects)
	powerUpEffectsEvent:FireAllClients(powerUpType, player, duration)
end)

-- Cleanup effects when players leave
Players.PlayerRemoving:Connect(function(player)
	PowerUpEffectsService.CleanupCharacterEffects(player.Character)
end)

-- Cleanup effects when characters are removed
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		PowerUpEffectsService.CleanupCharacterEffects(character)
	end)
end)

return PowerUpEffectsService
