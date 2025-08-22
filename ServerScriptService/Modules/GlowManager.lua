-- Location: ServerScriptService.Modules.GlowManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlowValidator = require(script.Parent:WaitForChild("GlowValidator"))

-- Configuration
local GLOW_CONFIG = {
	COLORS = {
		SkyriseGlow = Color3.fromRGB(170, 0, 255),
		WeeklySkyriseGlow = Color3.fromRGB(255, 50, 50),
		JungleGlow = Color3.fromRGB(0, 150, 0), -- Green jungle color
		WeeklyJungleGlow = Color3.fromRGB(255, 165, 0), -- Orange weekly jungle color
		WinsGlow = Color3.fromRGB(255, 215, 0),
		ShadowGlow = Color3.fromRGB(0, 0, 0), -- Dark shadow color
		BubblesGlow = Color3.fromRGB(0, 150, 255), -- Blue bubbles color
		HeartsGlow = Color3.fromRGB(255, 100, 150), -- Pink hearts color
		GhostsGlow = Color3.fromRGB(150, 150, 255), -- Light blue ghosts color
		DonatorGlow = Color3.fromRGB(255, 100, 200) -- Pink/purple for donators
	},
	HIGHLIGHT_SETTINGS = {
		FillTransparency = 1,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.Occluded
	}
}

-- Events
local setEquippedEvent = ReplicatedStorage:WaitForChild("SetEquippedItemEvent")
local glowEvent = ReplicatedStorage:FindFirstChild("GlowEvent")
if not glowEvent then
	glowEvent = Instance.new("RemoteEvent")
	glowEvent.Name = "GlowEvent"
	glowEvent.Parent = ReplicatedStorage
end

-- State management
local GlowManager = {}
local activeGlowTags: { [number]: string } = {}
local topPlayers: { [string]: { [number]: boolean } } = {} -- [glowType][userId] = true

-- Utility Functions
local function getPlayerInventory(player: Player)
	if not player then return nil end
	return player:FindFirstChild("Inventory")
end

local function getOwnedGlows(inventory)
	if not inventory then return nil end
	return inventory:FindFirstChild("OwnedGlows")
end

local function getEquippedGlow(inventory)
	if not inventory then return nil end
	return inventory:FindFirstChild("EquippedGlow")
end

-- Inventory Management
function GlowManager.PlayerHasGlow(userId: number, glowName: string): boolean
	local player = Players:GetPlayerByUserId(userId)
	if not player then return false end

	local inventory = getPlayerInventory(player)
	local ownedGlows = getOwnedGlows(inventory)

	return ownedGlows and ownedGlows:FindFirstChild(glowName) ~= nil
end

function GlowManager.PlayerAlreadyOwnsGlow(player: Player, glowName: string): boolean
	local inventory = getPlayerInventory(player)
	local ownedGlows = getOwnedGlows(inventory)
	return ownedGlows and ownedGlows:FindFirstChild(glowName) ~= nil
end

function GlowManager.AddGlowToInventory(userId: number, glowName: string)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local inventory = getPlayerInventory(player)
	local ownedGlows = getOwnedGlows(inventory)

	if ownedGlows and not ownedGlows:FindFirstChild(glowName) then
		local glowValue = Instance.new("StringValue")
		glowValue.Name = glowName
		glowValue.Parent = ownedGlows
		print("Added", glowName, "to", player.Name, "'s inventory")
	end
end

function GlowManager.RemoveGlowFromInventory(userId: number, glowName: string, unequipCurrent: boolean)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local inventory = getPlayerInventory(player)
	if not inventory then return end

	-- Remove from owned glows
	local ownedGlows = getOwnedGlows(inventory)
	if ownedGlows then
		local glowItem = ownedGlows:FindFirstChild(glowName)
		if glowItem then
			glowItem:Destroy()
			print("Removed", glowName, "from", player.Name, "'s inventory")
		end
	end

	-- Unequip if currently equipped
	if unequipCurrent then
		local equippedGlow = getEquippedGlow(inventory)
		if equippedGlow and equippedGlow.Value == glowName then
			equippedGlow.Value = ""
			print("Unequipped", glowName, "from", player.Name)
		end
	end
end

function GlowManager.GrantGlow(userId: number, glowName: string)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	if GlowManager.PlayerAlreadyOwnsGlow(player, glowName) then
		return
	end

	local inventory = getPlayerInventory(player)
	local ownedGlows = getOwnedGlows(inventory)

	if ownedGlows and not ownedGlows:FindFirstChild(glowName) then
		local newGlow = Instance.new("StringValue")
		newGlow.Name = glowName
		newGlow.Parent = ownedGlows
	end

	-- Clean up duplicates
	GlowManager.CleanDuplicateGlows(ownedGlows, glowName)
end

function GlowManager.CleanDuplicateGlows(glowFolder, glowName)
	if not glowFolder then return end

	local found = false
	for _, child in pairs(glowFolder:GetChildren()) do
		if child.Name == glowName then
			if not found then
				found = true
			else
				child:Destroy()
			end
		end
	end
end

-- Top Players Management
function GlowManager.UpdateTopPlayers(glowType: string, newTopPlayers: {number})
	if not topPlayers[glowType] then
		topPlayers[glowType] = {}
	end

	-- Clear old players
	for userId in pairs(topPlayers[glowType]) do
		topPlayers[glowType][userId] = nil
	end

	-- Add new players
	for _, userId in ipairs(newTopPlayers) do
		topPlayers[glowType][userId] = true
	end
end

function GlowManager.CanUseGlow(userId: number, glowType: string): boolean
	return topPlayers[glowType] and topPlayers[glowType][userId] == true
end

-- Visual Effects
function GlowManager.ApplyGlow(character: Model, glowName: string)
	if not character or not glowName then return end

	local color = GLOW_CONFIG.COLORS[glowName]
	if not color then return end

	-- Remove existing glow (both highlight and particles)
	GlowManager.RemoveGlow(character)

	-- Create new highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "LeaderboardGlow"
	highlight.FillTransparency = GLOW_CONFIG.HIGHLIGHT_SETTINGS.FillTransparency
	highlight.OutlineTransparency = GLOW_CONFIG.HIGHLIGHT_SETTINGS.OutlineTransparency
	highlight.OutlineColor = color
	highlight.Adornee = character
	highlight.DepthMode = GLOW_CONFIG.HIGHLIGHT_SETTINGS.DepthMode
	highlight.Parent = character

	-- Track glow application
	local userId = character:GetAttribute("UserId")
	if not userId then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			userId = player.UserId
			character:SetAttribute("UserId", userId)
		end
	end

	if userId then
		activeGlowTags[userId] = glowName
	end

	-- Attach particle effect
	GlowManager.AttachParticleEffect(character, color, glowName)
end

function GlowManager.AttachParticleEffect(character: Model, color: Color3, glowName: string)
	local particleTemplate = ReplicatedStorage:FindFirstChild("GlowParticleTemplate")
	local shadowTemplate = ReplicatedStorage:FindFirstChild("ShadowParticleTemplate")
	local bubblesTemplate = ReplicatedStorage:FindFirstChild("BubblesParticleEmitter")
	local heartsTemplate = ReplicatedStorage:FindFirstChild("HeartsParticleEmitter")
	local ghostsTemplate = ReplicatedStorage:FindFirstChild("GhostsParticleEmitter")

	if not character:FindFirstChild("HumanoidRootPart") then return end

	local humanoidRootPart = character.HumanoidRootPart

	-- Remove any existing particles first (extra safety)
	local existingParticles = humanoidRootPart:FindFirstChild("LeaderboardParticles")
	if existingParticles then
		existingParticles:Destroy()
	end

	-- Choose the appropriate particle template based on glow type
	local templateToUse = particleTemplate
	if glowName == "ShadowGlow" and shadowTemplate then
		templateToUse = shadowTemplate
	elseif glowName == "BubblesGlow" and bubblesTemplate then
		templateToUse = bubblesTemplate
	elseif glowName == "HeartsGlow" and heartsTemplate then
		templateToUse = heartsTemplate
	elseif glowName == "GhostsGlow" and ghostsTemplate then
		templateToUse = ghostsTemplate
	end

	if not templateToUse then return end

	local particleClone = templateToUse:Clone()
	particleClone.Name = "LeaderboardParticles"

	-- Only set color if it's not a special particle effect (these use their own particle settings)
	if glowName ~= "ShadowGlow" and glowName ~= "BubblesGlow" and glowName ~= "HeartsGlow" and glowName ~= "GhostsGlow" then
		particleClone.Color = ColorSequence.new(color)
	end

	particleClone.Enabled = true
	particleClone.Parent = humanoidRootPart
end

function GlowManager.RemoveGlow(character: Model)
	if not character then return end

	local highlight = character:FindFirstChild("LeaderboardGlow")
	if highlight then highlight:Destroy() end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local particles = humanoidRootPart:FindFirstChild("LeaderboardParticles")
		if particles then particles:Destroy() end
	end
end

-- Glow State Management
function GlowManager.SetEquippedGlow(userId: number, tag: string)
	activeGlowTags[userId] = tag
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local inventory = getPlayerInventory(player)
	if inventory then
		local equipped = getEquippedGlow(inventory)
		if equipped then
			equipped.Value = tag
		end
	end

	-- Apply on server
	local character = player.Character
	if character then
		GlowManager.ApplyGlow(character, tag)
	end

	glowEvent:FireAllClients(userId, tag)
end

-- Ensure equipped glow is applied (for when player data is loaded)
function GlowManager.EnsureEquippedGlowApplied(player: Player)
	if not player then return end

	local inventory = getPlayerInventory(player)
	if not inventory then return end

	local equipped = getEquippedGlow(inventory)
	if not equipped or equipped.Value == "" then return end

	local character = player.Character
	if character then
		GlowManager.ApplyGlow(character, equipped.Value)
		activeGlowTags[player.UserId] = equipped.Value
		glowEvent:FireAllClients(player.UserId, equipped.Value)
	end
end

function GlowManager.RemoveGlowFromPlayer(userId: number)
	activeGlowTags[userId] = nil
	local player = Players:GetPlayerByUserId(userId)
	if player then
		glowEvent:FireAllClients(userId, nil)

		-- Remove visual glow from character
		local character = player.Character
		if character then
			GlowManager.RemoveGlow(character)
		end
	end
end

function GlowManager.FullyRemoveGlow(userId: number, glowName: string, skipClientBroadcast: boolean?)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local inventory = getPlayerInventory(player)
	if not inventory then return end

	-- Unequip if currently equipped
	local equipped = getEquippedGlow(inventory)
	if equipped and equipped.Value == glowName then
		equipped.Value = ""
		GlowManager.RemoveGlowFromPlayer(userId)
	end

	-- Remove from inventory
	local ownedGlows = getOwnedGlows(inventory)
	if ownedGlows then
		local toRemove = ownedGlows:FindFirstChild(glowName)
		if toRemove then
			toRemove:Destroy()
		end
	end

	-- Tell clients to remove visual glow
	if not skipClientBroadcast then
		glowEvent:FireAllClients(userId, nil)
	end

	-- Save updated player data
	local PlayerDataService = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
	if PlayerDataService and PlayerDataService.Save then
		PlayerDataService.Save(player)
	end

	-- Update UI
	local RefreshInventoryEvent = ReplicatedStorage:WaitForChild("RefreshInventoryEvent")
	task.delay(0.2, function()
		RefreshInventoryEvent:FireClient(player, "Glow")
	end)
end

-- Event Handlers
setEquippedEvent.OnServerEvent:Connect(function(player, category, itemName)
	if category == "EquippedGlow" then
		GlowManager.SetEquippedGlow(player.UserId, itemName)
	end
end)

-- Remote Functions
local glowStateRequest = Instance.new("RemoteFunction")
glowStateRequest.Name = "GlowStateRequest"
glowStateRequest.Parent = ReplicatedStorage

glowStateRequest.OnServerInvoke = function(player)
	local state = {}
	for userId, glowName in pairs(activeGlowTags) do
		state[userId] = glowName
	end
	return state
end

-- Player Lifecycle Management
Players.PlayerRemoving:Connect(function(player)
	activeGlowTags[player.UserId] = nil
end)

Players.PlayerAdded:Connect(function(player)
	GlowValidator.ValidateGlowsOnJoin(player, GlowManager, glowEvent)

	-- Apply equipped glow when player joins (for existing character)
	task.defer(function()
		local inventory = player:WaitForChild("Inventory", 2)
		if inventory then
			local equipped = getEquippedGlow(inventory)
			if equipped and equipped.Value ~= "" then
				local character = player.Character
				if character then
					GlowManager.ApplyGlow(character, equipped.Value)
					activeGlowTags[player.UserId] = equipped.Value
				end
			end
		end
	end)

	-- Apply equipped glow when character spawns
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			local inventory = player:WaitForChild("Inventory", 2)
			if inventory then
				local equipped = getEquippedGlow(inventory)
				if equipped and equipped.Value ~= "" then
					GlowManager.ApplyGlow(character, equipped.Value)
					activeGlowTags[player.UserId] = equipped.Value
				end
			end
		end)
	end)

	-- Apply equipped glow after a short delay to ensure data is loaded
	task.delay(3, function()
		if player and player.Parent then
			GlowManager.EnsureEquippedGlowApplied(player)
		end
	end)
end)

return GlowManager 