AngryRaidLeader = {}

local classBuffs = {
	["PRIEST"] = "Power Word: Fortitude",
	["MAGE"] = "Arcane Intellect",
	["DRUID"] = "Mark of the Wild",
	["SHAMAN"] = "Skyfury",
	["EVOKER"] = "Blessing of the Bronze",
	["WARRIOR"] = "Battle Shout",
}

local function IsOffHandWeapon()
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

local function IsInRaidInstance()
	local _, _, instanceType = GetInstanceInfo()
	return instanceType == 14 or instanceType == 15 or instanceType == 16
end

local function IsInSameInstanceAndInRange(unit)
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

local function IsBuffMissing(unit, buffName)
	local name = AuraUtil.FindAuraByName(buffName, unit, "HELPFUL")
	return name == nil
end

local function IsBuffMissingFromPartyOrRaid(buffName)
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

local function DoesPlayerNeedToBuff()
	local _, playerClass = UnitClass("player") -- Get the player's class
	local buffName = classBuffs[playerClass] -- Get the buff for the player's class
	if not buffName then
		return
	end

	local missing, _ = IsBuffMissingFromPartyOrRaid(buffName) -- Assuming you have this function
	return missing
end

local function DoesPlayerNeedToRepair()
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

local function GetEnchantId(itemLink)
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

local function IsMissingEnchant()
	if UnitLevel("player") < GetMaxPlayerLevel() then
		return false -- No gem check for players below level 10
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

	if IsOffHandWeapon() then
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

local function GetGemIDsFromItemLink(itemLink)
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

local function IsMissingGem()
	if UnitLevel("player") < GetMaxPlayerLevel() then
		return false -- No gem check for players below level 10
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

local function IsMissingFlask()
	local flaskSpellNames = {
		"Flask of Alchemical Chaos",
		"Flask of Tempered Swiftness",
		"Flask of Tempered Aggression",
		"Flask of Tempered Versatility",
		"Flask of Tempered Mastery",
	}
	for _, name in ipairs(flaskSpellNames) do
		if not IsBuffMissing("player", name) then
			return false
		end
	end

	-- Only say we are missing flask of none of the buffs are on and we are in a raid instance
	return IsInRaidInstance()
end

local function IsMissingFoodBuff()
	if not IsBuffMissing("player", "Well Fed") then
		return false
	end

	-- Only say we are missing flask of none of the buffs are on and we are in a raid instance
	return IsInRaidInstance()
end

local function IsWeaponMissingOil()
	-- Get temporary enchant info
	local hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
	local doesOffHandNeedEnchant = IsOffHandWeapon() and not hasOffHandEnchant
	if hasMainHandEnchant and not doesOffHandNeedEnchant then
		return false
	end

	return IsInRaidInstance() -- Only check for oil in raid instances
end

local function SetFrameAnchor(frame, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
	-- Set the anchor for the frame
	frame:ClearAllPoints() -- Clear any existing anchors
	frame:SetPoint(anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
end

local shouldIgnoreRotten = false
function AngryRaidLeader:IgnoreRotten()
	shouldIgnoreRotten = true
	print("The angry raid leader is very disappointed in you...")
end

local shouldIgnoreBeth = false
function AngryRaidLeader:IgnoreBeth()
	shouldIgnoreBeth = true
	print("The angry raid leader is very disappointed in you and thinks your mog sucks...")
end

local updateFrame = CreateFrame("frame")
local interval = 3 -- Time in seconds
local nextUpdateTime = 0
GinnyFrame:Hide()
RottenFrame:Hide()
BethFrame:Hide()

updateFrame:SetScript("OnUpdate", function(_, _)
	local currentTime = GetTime()
	if currentTime > nextUpdateTime then
		nextUpdateTime = currentTime + interval

		if UnitIsDeadOrGhost("player") then
			GinnyFrame:Hide()
			RottenFrame:Hide()
			BethFrame:Hide()
			return
		end

		local needsToBuff = DoesPlayerNeedToBuff()
		local needsToRepair = DoesPlayerNeedToRepair()
		if needsToBuff or needsToRepair then
			GinnyFrame:Show()
			if needsToBuff then
				GinnyText:SetText("Missing Buff")
			elseif needsToRepair then
				GinnyText:SetText("Durability < 40%")
			else
				GinnyText:SetText("You are okay.... for now")
			end
		else
			GinnyFrame:Hide()
		end

		local isMissingEnchant = IsMissingEnchant()
		local isMissingGem = IsMissingGem()
		if (isMissingEnchant or isMissingGem) and not shouldIgnoreRotten then
			RottenFrame:Show()
			if isMissingEnchant then
				RottenText:SetText("Missing Enchant")
			elseif isMissingGem then
				RottenText:SetText("Missing Gem")
			else
				RottenText:SetText("You are okay.... for now")
			end
		else
			RottenFrame:Hide()
		end

		local isMissingFlask = IsMissingFlask()
		local isMissingFoodBuff = IsMissingFoodBuff()
		local isWeaponMissingOil = IsWeaponMissingOil()
		if (isMissingFlask or isMissingFoodBuff or isWeaponMissingOil) and not shouldIgnoreBeth then
			BethFrame:Show()
			BethAngryImage:Hide()
			BethHangryImage:Hide()
			BethSadImage:Hide()
			if isMissingFlask then
				BethText:SetText("Missing Flask")
				SetFrameAnchor(BethText, "TOP", BethAngryImage, "BOTTOM", 0, 0)
				BethAngryImage:Show()
			elseif isMissingFoodBuff then
				BethText:SetText("Missing Food Buff")
				SetFrameAnchor(BethText, "TOP", BethHangryImage, "BOTTOM", 0, 0)
				BethHangryImage:Show()
			elseif isWeaponMissingOil then
				BethText:SetText("Missing Weapon Oil")
				SetFrameAnchor(BethText, "TOP", BethSadImage, "BOTTOM", 0, 0)
				BethSadImage:Show()
			else
				BethText:SetText("You are okay.... for now")
			end
		else
			BethFrame:Hide()
		end
	end
end)
