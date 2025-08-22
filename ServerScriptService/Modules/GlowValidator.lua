-- ServerScriptService.Modules.GlowValidator

local DataStoreService = game:GetService("DataStoreService")

local GlowValidator = {}

local WeekKeyUtil = require(game.ServerScriptService.Modules.WeekKeyUtil)

-- Configuration
local LEADERBOARD_KEYS = {
	WinsGlow = "GlobalWinsLeaderboard",
	SkyriseGlow = "GlobalBestTime_Map_SkyRise",
	WeeklySkyriseGlow = function()
		local weekKey = WeekKeyUtil.GetCurrentWeekKey()
		return "WeeklyBestTime_Map_SkyRise_" .. weekKey
	end,
	JungleGlow = "GlobalBestTime_Map_Jungle",
	WeeklyJungleGlow = function()
		local weekKey = WeekKeyUtil.GetCurrentWeekKey()
		return "WeeklyBestTime_Map_Jungle_" .. weekKey
	end,
	DonatorGlow = "GlobalDonationLeaderboard"
}

-- Utility Functions
local function getLeaderboardKey(glowName: string): string?
	local key = LEADERBOARD_KEYS[glowName]
	if type(key) == "function" then
		return key()
	end
	return key
end

local function fetchTopPlayers(leaderboardKey: string, count: number): {number}?
	local success, pages = pcall(function()
		return DataStoreService:GetOrderedDataStore(leaderboardKey):GetSortedAsync(true, count)
	end)

	if not success or not pages then
		warn("Failed to fetch leaderboard data for:", leaderboardKey)
		return nil
	end

	local topPlayers = {}
	local currentPage = pages:GetCurrentPage()

	for _, entry in ipairs(currentPage) do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(topPlayers, userId)
		end
	end

	return topPlayers
end

-- Main Validation Function
function GlowValidator.ValidateGlowsOnJoin(player: Player, GlowManager, glowEvent)
	if not player or not GlowManager or not glowEvent then
		warn("Invalid parameters passed to ValidateGlowsOnJoin")
		return
	end

	for glowName, _ in pairs(LEADERBOARD_KEYS) do
		local leaderboardKey = getLeaderboardKey(glowName)
		if not leaderboardKey then
			warn("Could not get leaderboard key for glow:", glowName)
			continue
		end

		local topPlayers = fetchTopPlayers(leaderboardKey, 3)
		if not topPlayers then
			continue
		end

		-- Update who should have the glow
		GlowManager.UpdateTopPlayers(glowName, topPlayers)

		-- Special handling for DonatorGlow - check if player has donated
		if glowName == "DonatorGlow" then
			local stats = player:FindFirstChild("leaderstats")
			local donated = stats and stats:FindFirstChild("TotalDonated")
			local hasDonated = donated and donated.Value > 0

			local ownsGlow = GlowManager.PlayerAlreadyOwnsGlow(player, glowName)

			-- If player has donated but doesn't own the glow, give it to them
			if hasDonated and not ownsGlow then
				print("Player", player.Name, "has donated but doesn't own DonatorGlow - granting it")
				GlowManager.GrantGlow(player.UserId, glowName)
				-- If player owns the glow but hasn't donated, remove it (shouldn't happen with new system)
			elseif ownsGlow and not hasDonated then
				print("Player", player.Name, "owns DonatorGlow but hasn't donated - removing it")
				GlowManager.FullyRemoveGlow(player.UserId, glowName, false)
			end
		else
			-- Regular glow validation for other glows
			local ownsGlow = GlowManager.PlayerAlreadyOwnsGlow(player, glowName)
			local canUseGlow = GlowManager.CanUseGlow(player.UserId, glowName)

			if ownsGlow and not canUseGlow then
				print("Player", player.Name, "owns glow but should not — removing", glowName)
				GlowManager.FullyRemoveGlow(player.UserId, glowName, false)
			end
		end
	end
end

-- Additional validation functions for external use
function GlowValidator.ValidateSpecificGlow(player: Player, glowName: string, GlowManager, glowEvent)
	if not player or not glowName or not GlowManager or not glowEvent then
		warn("Invalid parameters passed to ValidateSpecificGlow")
		return false
	end

	local leaderboardKey = getLeaderboardKey(glowName)
	if not leaderboardKey then
		warn("Could not get leaderboard key for glow:", glowName)
		return false
	end

	local topPlayers = fetchTopPlayers(leaderboardKey, 3)
	if not topPlayers then
		return false
	end

	GlowManager.UpdateTopPlayers(glowName, topPlayers)

	-- Special handling for DonatorGlow - check if player has donated
	if glowName == "DonatorGlow" then
		local stats = player:FindFirstChild("leaderstats")
		local donated = stats and stats:FindFirstChild("TotalDonated")
		local hasDonated = donated and donated.Value > 0

		local ownsGlow = GlowManager.PlayerAlreadyOwnsGlow(player, glowName)

		-- If player has donated but doesn't own the glow, give it to them
		if hasDonated and not ownsGlow then
			print("Player", player.Name, "has donated but doesn't own DonatorGlow - granting it")
			GlowManager.GrantGlow(player.UserId, glowName)
			return true
			-- If player owns the glow but hasn't donated, remove it
		elseif ownsGlow and not hasDonated then
			print("Player", player.Name, "owns DonatorGlow but hasn't donated - removing it")
			GlowManager.FullyRemoveGlow(player.UserId, glowName, false)
			return false
		end

		return hasDonated
	else
		-- Regular glow validation for other glows
		local ownsGlow = GlowManager.PlayerAlreadyOwnsGlow(player, glowName)
		local canUseGlow = GlowManager.CanUseGlow(player.UserId, glowName)

		if ownsGlow and not canUseGlow then
			print("Player", player.Name, "owns glow but should not — removing", glowName)
			GlowManager.FullyRemoveGlow(player.UserId, glowName, false)
			return false
		end

		return canUseGlow
	end
end

function GlowValidator.GetLeaderboardKeys()
	local keys = {}
	for glowName, _ in pairs(LEADERBOARD_KEYS) do
		keys[glowName] = getLeaderboardKey(glowName)
	end
	return keys
end

return GlowValidator 