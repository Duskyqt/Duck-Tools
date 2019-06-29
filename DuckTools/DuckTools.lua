



-- Button Settings
local settings
local DuckButton = CreateFrame("BUTTON", nil, UIParent, "SecureHandlerClickTemplate");
DuckButton:SetSize(50,50)
DuckButton:SetPoint("CENTER",0,0)
DuckButton:RegisterForClicks("AnyDown")
DuckButton:SetNormalTexture(319458)
DuckButton:SetPushedTexture(319458)
DuckButton:SetHighlightTexture(319458)
DuckButton:SetMovable(true)
DuckButton:EnableMouse(true)
DuckButton:RegisterForDrag("LeftButton")
DuckButton:SetScript("OnDragStart", DuckButton.StartMoving)
DuckButton:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    settings.XPos = self:GetLeft()
    settings.YPos = self:GetBottom()
  end) 

function DuckButtonEvents (self, Event, ...)
    if Event == "PLAYER_LOGIN" then
        MyAddonPerSettings = MyAddonPerSettings or {} -- create table if one doesn't exist
        settings = MyAddonPerSettings -- assign settings declared above
        if settings.XPos then
            DuckButton:ClearAllPoints()
            DuckButton:SetPoint("BOTTOMLEFT",settings.XPos,settings.YPos)
        end
    end
end
DuckButton:RegisterEvent("PLAYER_LOGIN")
DuckButton:SetScript("OnEvent", DuckButtonEvents)

-- From MapCoords addon
local function MapPositionToXY(arg)
	local mapID = C_Map.GetBestMapForUnit(arg)
	
	if mapID and arg then
		local mapPos = C_Map.GetPlayerMapPosition(mapID, arg)
		if mapPos then
			return mapPos:GetXY()
		end
	end
	
	return 0, 0
end
function DuckButtonClickEvents (self, Event, ...)
    if Debugging then
        print("Duck Button Events: ", Event)
    end  
    if Event == "RightButton" then
        if Debugging then
            Debugging = false
            DuckButton:SetNormalTexture(319458)
        elseif not Debugging then
            Debugging = true
            DuckButton:SetNormalTexture(237552)
        end
    end

end
DuckButton:SetScript("OnClick", DuckButtonClickEvents)

-- Duck Nameplate Frame
local ClassificationTable = {
    ["rare"] = true, 
    ["rareelite"] = true,
}
local SeenRares = {}

local DuckNameplateFrame = CreateFrame("Frame", nil, UIParent)
DuckNameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
function DuckNameplateEvents (self, Event, ...)
    if Debugging then
        print("Duck Nameplate Events: ", Event)
    end
    if Event == "NAME_PLATE_UNIT_ADDED" then
        local UnitId = ...
        local UnitGuid = UnitGUID(UnitId)
        if (not SeenRares[UnitGuid] or SeenRares[UnitGuid].Time + 90 < GetTime()) and UnitExists(UnitId) and not UnitIsDeadOrGhost(UnitId) and UnitId then
            if ClassificationTable[UnitClassification(UnitId)] then
                local PlayerX, PlayerY = MapPositionToXY("player")
                local HealthPercentage = UnitHealth(UnitId) / UnitHealthMax(UnitId) * 100
                local Combat = UnitAffectingCombat(UnitId)
                if PlayerX and PlayerY and Debugging then
                    SendChatMessage("Duck Tools: ".. "Rare " .. UnitName(UnitId) .. " is up at: " .. "X: " .. floor(PlayerX * 100) .. ", Y: " .. floor(PlayerY * 100).." at "..floor(HealthPercentage).."%".. " and ".. Combat and "is in combat." or "is not in combat.", "CHANNEL", nil, 1)
                    SeenRares[UnitGuid] = {Time = GetTime()}
                end                   
            end
        end
        for Guid, Table in pairs(SeenRares) do
            for Property, Value in pairs(Table) do
                if Value + 90 < GetTime() then
                    print("Clearing: ", Guid)
                    SeenRares[Guid] = nil
                end
            end
        end
    end
end

DuckNameplateFrame:SetScript("OnEvent", DuckNameplateEvents)


-- Chat Parse Frame
local DuckChatFrame = CreateFrame("Frame", nil, UIParent)
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD")
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
DuckChatFrame:RegisterEvent("CHAT_MSG_CHANNEL")
DuckChatFrame:RegisterEvent("CHAT_MSG_ADDON")

function DuckChatEvents (self, Event, ...) 
    if Debugging and Event ~= "CHAT_MSG_ADDON" then
        print("Duck Chat Events: ", Event)
    end
    
   
end
DuckChatFrame:SetScript("OnEvent", DuckChatEvents)

