
-- Functions 

-- Returns the Health Percentage of a given unit
-- @Param Unit - UnitId such as "Player", "Target"
-- @Return Number - The Health Percentage of the Unit
local function HealthPercentage(Unit)
    return UnitHealth(Unit) / UnitHealthMax(Unit) * 100 or 0
end

-- Returns appropriate string if a Unit is in Combat.
-- @Param Unit - UnitId such as "Player", "Target"
-- @Return String - Accompanying string if unit is in combat or not
local function CombatCheck(Unit)
    local Combat = UnitAffectingCombat(Unit)
    return Combat and "Is in Combat." or "Is not in Combat."
end


-- Returns XY map position of a unit, but anything other than "Player" is not guaranteed.
-- @Param arg - UnitId for the unit to be parsed such as "player", or "Target".
-- @Return Function - the function from the WoWApi C_Map.GetPlayerMapPosition, eventually returning X/Y for the arg. 
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

-- Send an addon chat message with necessary information
-- @Param String - The Text for the message, ideally delimited with //.
-- @Param String - The channel you want to send the message to such as "RAID", "CHANNEL"
-- @Param String/Number - If using "WHISPER" channel, this will be the string of the targets name, otherwise it is the numerical channel Identifier (i.e 1 for General).
-- @Return void
local function AddonMessage (Text, Channel, Target)
    local Success = C_ChatInfo.IsAddonMessagePrefixRegistered("DTA")
    if Text and Channel and Target and Success then
        if Debugging then
            print("Sending Addon Information", Text)
        end
        C_ChatInfo.SendAddonMessage("DTA", Text, Channel, Target)
    end
end


-- Button Settings
local settings
local DuckButton = CreateFrame("BUTTON", nil, UIParent, "SecureHandlerClickTemplate");
DuckButton:SetSize(50, 50)
DuckButton:SetPoint("CENTER",0,0)
DuckButton:RegisterForClicks("AnyDown")
DuckButton:SetNormalTexture("Interface\\AddOns\\DuckTools\\Media\\duck")
DuckButton:SetPushedTexture("Interface\\AddOns\\DuckTools\\Media\\duckinator")
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
    local Register = C_ChatInfo.RegisterAddonMessagePrefix("DTA")
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
            print("Debugging Disabled")
            DuckButton:SetNormalTexture("Interface\\AddOns\\DuckTools\\Media\\duck")
        elseif not Debugging then
            Debugging = true
            print("Debugging Enabled")
            DuckButton:SetNormalTexture("Interface\\AddOns\\DuckTools\\Media\\duckinator")
        end
    end
    if Event == "LeftButton" then
        if Debugging and UnitExists("Target") then
            print("Sending Addon Information")
            AddonMessage("DuckTools".."//".."Rare".."//"..UnitGUID("Target"), CHANNEL, 1)
        else
            print("This button hasn't been completed yet :)")
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
        if (not SeenRares[UnitGuid] or SeenRares[UnitGuid].Time < GetTime()) and UnitId and UnitExists(UnitId) and not UnitIsDeadOrGhost(UnitId) then
            if ClassificationTable[UnitClassification(UnitId)] then
                local PlayerX, PlayerY = MapPositionToXY("player")
                local Combat = UnitAffectingCombat(UnitId)
                if PlayerX and PlayerY and HealthPercentage(UnitId) > 20 then
                    SendChatMessage("Duck Tools: ".. "Rare " .. UnitName(UnitId) .. " is up at: " .. "X: " .. floor(PlayerX * 100) .. ", Y: " .. floor(PlayerY * 100).." at "..floor(HealthPercentage(UnitId)).."%".. " and ".. CombatCheck(UnitId).." Get an update on the Rare's HP by typing #update.", "CHANNEL", nil, 1)
                    AddonMessage("Duck Tools".."//".."Rare".."//"..UnitGuid, "CHANNEL", 1)
                    SeenRares[UnitGuid] = {Time = GetTime() + 300, Identifier = UnitId, Name = UnitName(UnitId)}
                    LastRare = SeenRares[UnitGuid]
                end                   
            end
        end
        for Guid, Table in pairs(SeenRares) do 
            if not UnitExists(Table.Identifier) or UnitName(Table.Identifier) ~= Table.Name then
                if Table.Time < GetTime() then
                    if Debugging then
                        print("Clearing: ", Guid)
                    end
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
            AddonMessage("Duck Tools".."//".."Died".."//"..DestGuid, "CHANNEL", 1)
        end
    end
end
DuckCombatFrame:SetScript("OnEvent", DuckCombatEvents)
-- Chat Parse Frame
local DuckChatFrame = CreateFrame("Frame", nil, UIParent)
DuckChatFrame:RegisterEvent("CHAT_MSG_CHANNEL")
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD")
DuckChatFrame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
DuckChatFrame:RegisterEvent("CHAT_MSG_WHISPER")
local LastMessage = 0
function DuckChatEvents (self, Event, ...) 
    if Debugging then
        print("Duck Chat Events: ", Event)
    end
    
    if LastRare and not UnitIsDeadOrGhost(LastRare.Identifier) and (LastMessage < GetTime() or Event == "CHAT_MSG_WHISPER")then
        if Event == "CHAT_MSG_WHISPER" then
            local Message, Author, _ = ...
            if Debugging then
                print("Checking the whisper, ", strfind(Message, "#update"))
            end
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
    _G.DuckRares = { SeenRares, LastRare, LastMessage }
end
DuckChatFrame:SetScript("OnEvent", DuckChatEvents)


local DuckCommunicationFrame = CreateFrame("Frame", nil, UIParent)
DuckCommunicationFrame:RegisterEvent("CHAT_MSG_ADDON")
function DuckCommunicationEvents(self, Event, ...)
    if Event == "CHAT_MSG_ADDON" then
        local Prefix, Text, _ = ...
        -- DTA is the DuckToolsAddon prefix
        if Prefix == "DTA" then
            -- [1] Is the addon, [2] is the Function, [3] and onward for arguments
            local FixedMessage = strsplit("//", Text)
            if FixedMessage and FixedMessage[1] == "Duck Tools" then
                local Function = FixedMessage[2]
                if Function == "Rare" and not SeenRares[FixedMessage[3]] then
                    if Debugging then
                        print("Adding", FixedMessage[3])
                    end
                    SeenRares[FixedMessage[3]] = {Time = GetTime() + 300, Identifier = "", Name = ""}
                end
                if Function == "Died" and SeenRares[FixedMessage[3]] then
                    SeenRares[FixedMessage[3]] = nil
                end
            end
        end
    end
end
DuckCommunicationFrame:SetScript("OnEvent", DuckCommunicationEvents)

