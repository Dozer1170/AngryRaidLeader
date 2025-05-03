function GetGemIDsFromItemLink(itemLink)
	if not itemLink then
		return nil
	end

	-- Extract the item string from the item link
	local itemString = string.match(itemLink, "item:([%-?%d:]+)")
	if not itemString then
		return nil
	end

	-- Split the item string by colons
	local fields = { strsplit(":", itemString) }

	-- Gem IDs are in fields 3, 4, 5, and 6
	local gemId1 = fields[3] or nil
	local gemId2 = fields[4] or nil
	local gemId3 = fields[5] or nil
	local gemId4 = fields[6] or nil

	return { gemId1, gemId2, gemId3, gemId4 }
end

function IsPlayerMissingGemSlotsInJewelry()
	local jewelerySlots = { 2, 11, 12 }
	for _, slot in ipairs(jewelerySlots) do
		local itemLink = GetInventoryItemLink("player", slot)
		if itemLink then
			local stats = C_Item.GetItemStats(itemLink)
			if stats then
				local singingSeaSockets = stats["EMPTY_SOCKET_SINGINGSEA"] or 0
				local singingThunderSockets = stats["EMPTY_SOCKET_SINGINGTHUNDER"] or 0
				local singingWindSockets = stats["EMPTY_SOCKET_SINGINGWIND"] or 0
				local prismaticSockets = stats["EMPTY_SOCKET_PRISMATIC"] or 0
				local totalSockets = singingSeaSockets + singingThunderSockets + singingWindSockets + prismaticSockets
				if totalSockets < 2 then
					return true
				end
			end
		end
	end
end

function IsPlayerMissingGem()
	if UnitLevel("player") < GetMaxPlayerLevel() then
		return false -- No gem check for players below max level
	end

	for slot = 1, 17 do -- Iterate through all equipment slots
		local itemLink = GetInventoryItemLink("player", slot)
		if itemLink then
			-- Check for missing gems
			local stats = C_Item.GetItemStats(itemLink)
			if stats then
				local numSockets = stats["EMPTY_SOCKET_PRISMATIC"] or 0
				if numSockets > 0 then
					local gemIds = GetGemIDsFromItemLink(itemLink)
					for i = 1, numSockets do
						-- Check corresponding gem ID and see if it's empty
						if gemIds and gemIds[i] == "" then
							return true -- Found an item with missing gems
						end
					end
				end
			end
		end
	end
	return false
end
