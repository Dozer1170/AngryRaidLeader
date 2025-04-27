AngryRaidLeader = {}

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

		local isMissingEnchant = IsPlayerMissingEnchant()
		local isMissingGem = IsPlayerMissingGem()
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

		local isMissingFlask = IsPlayerMissingFlask()
		local isMissingFoodBuff = IsPlayerMissingFoodBuff()
		local isWeaponMissingOil = IsPlayerMissingWeaponOil()
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
