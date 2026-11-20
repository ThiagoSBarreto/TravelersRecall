TravelersRecall = TravelersRecall or {}
TravelersRecall.unlocked = TravelersRecall.unlocked or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""
TravelersRecall.cooldowns = TravelersRecall.cooldowns or {}

local FRIEND_LOCATION_NAME = "Teleport to Friend"
local COOLDOWN_PREFIX = "Traveler's Recall: cooldown remaining "
local COOLDOWN_REQUEST_DELAY = 1.5
local COOLDOWN_SUPPRESS_TIME = 3

local DB_DEFAULTS = {
    favourites = {},
    collapsed = {},
    sortMode = "region",
    readyOnly = false,
}

local function GetDB()
    if type(TravelersRecallDB) ~= "table" then
        TravelersRecallDB = {}
    end

    for key, value in pairs(DB_DEFAULTS) do
        if TravelersRecallDB[key] == nil then
            if type(value) == "table" then
                TravelersRecallDB[key] = {}
            else
                TravelersRecallDB[key] = value
            end
        end
    end

    return TravelersRecallDB
end

local function NormalizeLocationData(rest)
    if not rest then
        return nil, nil
    end

    local lastColon = 0
    for i = 1, string.len(rest) do
        if string.sub(rest, i, i) == ":" then
            lastColon = i
        end
    end

    if lastColon == 0 then
        return nil, nil
    end

    return string.sub(rest, 1, lastColon - 1), string.sub(rest, lastColon + 1)
end

local function MatchesSearch(name, region)
    local query = TravelersRecall.searchText or ""
    if query == "" then
        return true
    end

    local normalizedName = string.lower(name or "")
    if string.find(normalizedName, query, 1, true) ~= nil then
        return true
    end

    local normalizedRegion = string.lower(region or "")
    return string.find(normalizedRegion, query, 1, true) ~= nil
end

local function StoreLocation(id, rest)
    if not id or not rest then
        return false
    end

    local name, icon = NormalizeLocationData(rest)
    if not name or not icon then
        return false
    end

    TravelersRecall.unlocked[tonumber(id)] = {
        name = name,
        icon = icon,
    }

    if TravelersRecall.UI and TravelersRecall.UI.RefreshLocations then
        TravelersRecall.UI.RefreshLocations()
    end

    return true
end

local function RemoveLocation(id)
    if not id then
        return
    end

    TravelersRecall.unlocked[tonumber(id)] = nil
    TravelersRecall.cooldowns[tonumber(id)] = nil

    if TravelersRecall.UI and TravelersRecall.UI.RefreshLocations then
        TravelersRecall.UI.RefreshLocations()
    end
end

local function IsFriendLocation(data)
    return data ~= nil and data.name == FRIEND_LOCATION_NAME
end

-- Seconds left on a location's cooldown, as last reported by the server.
local function GetCooldownRemaining(id)
    local expires = TravelersRecall.cooldowns[id]
    if not expires then
        return 0
    end

    local remaining = expires - GetTime()
    if remaining <= 0 then
        TravelersRecall.cooldowns[id] = nil
        return 0
    end

    return remaining
end

-- Returns: available (bool), reason (string or nil), warning (bool)
local function GetAvailability(id, data)
    if GetCooldownRemaining(id) > 0 then
        return false, "cooldown", false
    end

    if IsFriendLocation(data) then
        if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
            return false, "No party", false
        end

        local hasPartyTarget = UnitExists("target") and UnitIsPlayer("target")
            and not UnitIsUnit("target", "player")
            and (UnitInParty("target") or UnitInRaid("target"))
        if not hasPartyTarget then
            return true, "Target a party member", true
        end
    end

    return true, nil, false
end

-- Turns the server's "1 hour 5 mins 3 sec" into seconds.
local function ParseDuration(text)
    local total = 0
    for amount, unit in string.gmatch(text or "", "(%d+)%s*(%a+)") do
        amount = tonumber(amount)
        unit = string.lower(unit)
        if string.find(unit, "^hour") then
            total = total + amount * 3600
        elseif string.find(unit, "^min") then
            total = total + amount * 60
        elseif string.find(unit, "^sec") then
            total = total + amount
        end
    end
    return total
end

local function SetCooldownByName(name, seconds)
    for id, data in pairs(TravelersRecall.unlocked) do
        if data.name == name then
            if seconds > 0 then
                TravelersRecall.cooldowns[id] = GetTime() + seconds
            else
                TravelersRecall.cooldowns[id] = nil
            end
        end
    end
end

local function IsCooldownMessage(message)
    return string.find(message or "", COOLDOWN_PREFIX, 1, true) == 1
end

-- Reads the cooldown replies of ".tr cd", ".tr cd all" and failed teleports.
local function HandleCooldownMessage(message)
    if not IsCooldownMessage(message) then
        return false
    end

    local _, _, name, text = string.find(message, "^Traveler's Recall: cooldown remaining for (.+): (.-)%.?$")
    if name then
        SetCooldownByName(name, ParseDuration(text))
        return true
    end

    _, _, text = string.find(message, "^Traveler's Recall: cooldown remaining to teleport to a friend: (.-)%.?$")
    if text then
        SetCooldownByName(FRIEND_LOCATION_NAME, ParseDuration(text))
        return true
    end

    return false
end

local function IsTargetingOtherPlayer()
    return UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player")
end

local function IsChatBeingTyped()
    return ChatEdit_GetActiveWindow ~= nil and ChatEdit_GetActiveWindow() ~= nil
end

-- ".tr cd all" reports the cooldowns of the selected player, so it waits until no other player is targeted.
local function RequestCooldowns()
    if IsTargetingOtherPlayer() or IsChatBeingTyped() then
        TravelersRecall.cooldownRequestPending = true
        return false
    end

    TravelersRecall.cooldownRequestPending = false
    TravelersRecall.cooldowns = {}
    TravelersRecall.suppressCooldownUntil = GetTime() + COOLDOWN_SUPPRESS_TIME

    if TravelersRecall.UI and TravelersRecall.UI.SendEditBoxCommand then
        TravelersRecall.UI.SendEditBoxCommand(".tr cd all")
    end

    return true
end

local function ShouldSuppressCooldownMessage(message)
    return IsCooldownMessage(message) and GetTime() < (TravelersRecall.suppressCooldownUntil or 0)
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.remaining = (self.remaining or 0) - elapsed
    if self.remaining > 0 then
        return
    end

    if RequestCooldowns() then
        self:Hide()
    else
        -- Still blocked (chat open or a player targeted); try again shortly.
        self.remaining = 1
    end
end)

local function ScheduleCooldownRequest(delay)
    timerFrame.remaining = delay or COOLDOWN_REQUEST_DELAY
    timerFrame:Show()
end

TravelersRecall.Core = {
    GetDB = GetDB,
    MatchesSearch = MatchesSearch,
    NormalizeLocationData = NormalizeLocationData,
    StoreLocation = StoreLocation,
    RemoveLocation = RemoveLocation,
    IsFriendLocation = IsFriendLocation,
    GetCooldownRemaining = GetCooldownRemaining,
    GetAvailability = GetAvailability,
    ParseDuration = ParseDuration,
    HandleCooldownMessage = HandleCooldownMessage,
    ShouldSuppressCooldownMessage = ShouldSuppressCooldownMessage,
    RequestCooldowns = RequestCooldowns,
    ScheduleCooldownRequest = ScheduleCooldownRequest,
}
