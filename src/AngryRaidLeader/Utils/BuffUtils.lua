local classBuffs = {
	["PRIEST"] = "Power Word: Fortitude",
	["MAGE"] = "Arcane Intellect",
	["DRUID"] = "Mark of the Wild",
	["SHAMAN"] = "Skyfury",
	["EVOKER"] = "Blessing of the Bronze",
	["WARRIOR"] = "Battle Shout",
}

function IsBuffMissing(unit, buffName)
	local name = AuraUtil.FindAuraByName(buffName, unit, "HELPFUL")
	return name == nil
end

function IsBuffMissingFromPartyOrRaid(buffName)
	if IsBuffMissing("player", buffName) then
		return true, "player"
	end

	for i = 1, 5 do
		local unit = "party" .. i
		if not UnitIsDeadOrGhost(unit) and IsInSameInstanceAndInRange(unit) then
			if IsBuffMissing(unit, buffName) then
				return true, unit
			end
		end
	end

	local numRaidMembers = GetNumGroupMembers()
	for i = 1, numRaidMembers do
		local unit = "raid" .. i
		if not UnitIsDeadOrGhost(unit) and IsInSameInstanceAndInRange(unit) then
			if IsBuffMissing(unit, buffName) then
				return true
			end
		end
	end
	return false -- Buff is present on all raid members
end

function DoesPlayerNeedToBuff()
	local _, playerClass = UnitClass("player") -- Get the player's class
	local buffName = classBuffs[playerClass] -- Get the buff for the player's class
	if not buffName then
		return
	end

	local missing, _ = IsBuffMissingFromPartyOrRaid(buffName) -- Assuming you have this function
	return missing
end

function IsPlayerMissingFlask()
	local flaskSpellNames = {
		"Flask of Alchemical Chaos",
		"Flask of Tempered Swiftness",
		"Flask of Tempered Aggression",
		"Flask of Tempered Versatility",
		"Flask of Tempered Mastery",
		"Flask of Saving Graces",
	}
	for _, name in ipairs(flaskSpellNames) do
		if not IsBuffMissing("player", name) then
			return false
		end
	end

	-- Only say we are missing flask of none of the buffs are on and we are in a raid instance
	return IsInRaidInstance()
end

function IsPlayerMissingFoodBuff()
	if not IsBuffMissing("player", "Well Fed") or not IsBuffMissing("player", "Hearty Well Fed") then
		return false
	end

	-- Only say we are missing flask of none of the buffs are on and we are in a raid instance
	return IsInRaidInstance()
end
