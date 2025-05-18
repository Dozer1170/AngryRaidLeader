function GetEnchantId(itemLink)
	if not itemLink then
		return nil
	end

	local itemString = string.match(itemLink, "item:([%-?%d:]+)")
	if not itemString then
		return nil
	end

	local fields = { strsplit(":", itemString) }
	return fields[2] or nil
end

function IsPlayerMissingEnchant()
	if UnitLevel("player") < GetMaxPlayerLevel() then
		return false -- No gem check for players below max level
	end

	local slotsToCheck = { 5, 9, 7, 8, 11, 12, 15, 16 } -- Chest, Bracers, Legs, Boots, Rings, Cloak, Weapon
	for _, slot in ipairs(slotsToCheck) do -- Iterate through all equipment slots
		local itemLink = GetInventoryItemLink("player", slot)
		if itemLink then
			-- Check for missing enchants
			if GetEnchantId(itemLink) == "" then
				return true
			end
		end
	end

	if IsPlayerOffHandAWeapon() then
		local itemLink = GetInventoryItemLink("player", 17) -- 17 is the off-hand slot
		if itemLink then
			-- Check for missing enchants
			if GetEnchantId(itemLink) == "" then
				return true
			end
		end
	end

	return false
end

function IsPlayerMissingWeaponOil()
	-- Get temporary enchant info
	local hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
	local doesOffHandNeedEnchant = IsPlayerOffHandAWeapon() and not hasOffHandEnchant
	if hasMainHandEnchant and not doesOffHandNeedEnchant then
		return false
	end

	return IsInRaidInstance() -- Only check for oil in raid instances
end
