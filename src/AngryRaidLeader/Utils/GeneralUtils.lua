function IsPlayerOffHandAWeapon()
	-- Get the item ID of the off-hand slot
	local offHandItemID = GetInventoryItemID("player", 17) -- 17 is the off-hand slot

	if not offHandItemID then
		return false
	end

	-- Get item information
	local _, _, _, _, _, itemType = GetItemInfo(offHandItemID)

	-- Check if the item is a weapon
	if itemType == "Weapon" then
		return true
	else
		return false
	end
end

function IsInRaidInstance()
	local _, _, instanceType = GetInstanceInfo()
	return instanceType == 14 or instanceType == 15 or instanceType == 16
end

function IsInSameInstanceAndInRange(unit)
	if not UnitExists(unit) then
		return false
	end

	-- Check if the unit is in the same instance
	local phaseReason = UnitPhaseReason(unit)
	if phaseReason then
		return false
	end

	-- Check if user is in range
	return UnitInRange(unit)
end

function DoesPlayerNeedToRepair()
	for slot = 1, 17 do -- Iterate through all equipment slots
		local current, maximum = GetInventoryItemDurability(slot)
		if current and maximum then
			local durabilityPercent = (current / maximum) * 100
			if durabilityPercent < 40 then
				return true -- Found an item with durability < 40%
			end
		end
	end
	return false -- All items are above 40% durability
end

function IsPlayerInCombat()
	return UnitAffectingCombat("player")
end
