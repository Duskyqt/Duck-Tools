
-- Functions 

local function HealthPercentage(Unit)
    return UnitHealth(Unit) / UnitHealthMax(Unit) * 100 or 0
end

local function CombatCheck(Unit)
    local Combat = UnitAffectingCombat(Unit)
    return Combat and "Is in Combat." or "Is not in Combat."
end


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
local LastRare = nil
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
                local Combat = UnitAffectingCombat(UnitId)
                if PlayerX and PlayerY then
                    SendChatMessage("Duck Tools: ".. "Rare " .. UnitName(UnitId) .. " is up at: " .. "X: " .. floor(PlayerX * 100) .. ", Y: " .. floor(PlayerY * 100).." at "..floor(HealthPercentage(UnitId)).."%".. " and ".. CombatCheck(UnitId).." Get an update on the Rare's HP by typing #update.", "CHANNEL", nil, 1)
                    SeenRares[UnitGuid] = {Time = GetTime(), Identifier = UnitId}
                    LastRare = SeenRares[UnitGuid]
                end                   
            end
        end
        for Guid, Table in pairs(SeenRares) do
            if UnitIsDeadOrGhost(Table.Identifier) then 
                if Table.Time + 90 < GetTime() then
                    print("Clearing: ", Guid)
                    SeenRares[Guid] = nil
                    LastRare = nil
                end
            end
        end
    end
end



DuckNameplateFrame:SetScript("OnEvent", DuckNameplateEvents)

-- Duck Combat Frame

local DuckCombatFrame = CreateFrame("Frame", nil, UIParent)
DuckCombatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

function DuckCombatEvents (self, Event, ...)
    local TimeStamp, Type, _, SourceGuid, SourceName, _, _, DestGuid, DestName, _, _, SpellId, SpellName, _, SpellType = CombatLogGetCurrentEventInfo()
    if Type == "UNIT_DIED" then
        if SeenRares[DestGuid] then
            SeenRares[DestGuid] = nil
            LastRare = nil
            SendChatMessage("Duck Tools: ".. "Rare " .. DestName .. " has died.", "CHANNEL", nil, 1)
        end
    end
end
DuckCombatFrame:SetScript("OnEvent", DuckCombatEvents)
-- Chat Parse Frame
local DuckChatFrame = CreateFrame("Frame", nil, UIParent)
DuckChatFrame:RegisterEvent("CHAT_MSG_CHANNEL")
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD")
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
DuckChatFrame:RegisterEvent("CHAT_MSG_ADDON")
DuckChatFrame:RegisterEvent("CHAT_MSG_WHISPER")
local LastMessage = 0
function DuckChatEvents (self, Event, ...) 
    if Debugging and Event ~= "CHAT_MSG_ADDON" then
        print("Duck Chat Events: ", Event)
    end
    local TestMessage = ...
    if LastRare and not UnitIsDeadOrGhost(LastRare.Identifier) and (LastMessage < GetTime() or Event == "CHAT_MSG_WHISPER")then
        if Debugging then
            if Event == "CHAT_MSG_WHISPER" then
                local Message, Author, _ = ...
                print("Checking the whisper, ", strfind(Message, "#update"))
                if strfind(Message, "#update") then
                    SendChatMessage("Duck Tools: ".."Rare: "..UnitName(LastRare.Identifier).." is at "..floor(HealthPercentage(LastRare.Identifier)).."%", "WHISPER", nil, Author)
                end
            elseif Event == "CHAT_MSG_CHANNEL" then
                local Message, Author, _, Channel = ...
                if Channel == 1 and strfind(Message, "#update") then
                    SendChatMessage("Duck Tools: ".."Rare: "..UnitName(LastRare.Identifier).." is at "..floor(HealthPercentage(LastRare.Identifier)).."%", "CHANNEL", nil, 1)
                    LastMessage = GetTime() + 30
                end
            end
        end
    end
    _G.DuckRares = { SeenRares, LastRare, LastMessage }
end
DuckChatFrame:SetScript("OnEvent", DuckChatEvents)

-- Functions

