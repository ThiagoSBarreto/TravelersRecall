TravelersRecall = TravelersRecall or {}
TravelersRecall.unlocked = TravelersRecall.unlocked or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""
-- Per-location grouping info sent by the server (TR_META): { continent = n, zone = "..." }
TravelersRecall.meta = TravelersRecall.meta or {}
-- Cooldown expiry per location id, in GetTime() seconds (TR_CD).
TravelersRecall.cooldowns = TravelersRecall.cooldowns or {}

-- Per-character saved settings. Saved variables are loaded after the addon's
-- files run, so always go through this accessor instead of caching the table.
local function GetDB()
    TravelersRecallDB = TravelersRecallDB or {}
    TravelersRecallDB.favorites = TravelersRecallDB.favorites or {}
    TravelersRecallDB.collapsed = TravelersRecallDB.collapsed or {}
    return TravelersRecallDB
end

local function IsFavorite(id)
    return GetDB().favorites[tonumber(id)] == true
end

local function ToggleFavorite(id)
    local favorites = GetDB().favorites
    id = tonumber(id)
    if favorites[id] then
        favorites[id] = nil
    else
        favorites[id] = true
    end
end

local function IsCollapsed(group)
    return GetDB().collapsed[group] == true
end

local function ToggleCollapsed(group)
    local collapsed = GetDB().collapsed
    collapsed[group] = not collapsed[group] or nil
end

local function GetCooldownRemaining(id)
    local expires = TravelersRecall.cooldowns[tonumber(id)]
    if not expires then
        return 0
    end

    local remaining = expires - GetTime()
    if remaining <= 0 then
        TravelersRecall.cooldowns[tonumber(id)] = nil
        return 0
    end

    return remaining
end

local function StoreCooldown(id, seconds)
    id = tonumber(id)
    seconds = tonumber(seconds) or 0

    if id == 0 then
        -- "all locations" (GM reset all)
        TravelersRecall.cooldowns = {}
    elseif seconds > 0 then
        TravelersRecall.cooldowns[id] = GetTime() + seconds
    else
        TravelersRecall.cooldowns[id] = nil
    end

    if TravelersRecall.UI and TravelersRecall.UI.RefreshLocations then
        TravelersRecall.UI.RefreshLocations()
    end
end

local function FormatCooldown(seconds)
    seconds = math.ceil(seconds)
    if seconds >= 3600 then
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    elseif seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    end
    return string.format("%ds", seconds)
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

local function MatchesSearch(name, zone)
    local query = TravelersRecall.searchText or ""
    if query == "" then
        return true
    end

    local normalizedName = string.lower(name or "")
    if string.find(normalizedName, query, 1, true) ~= nil then
        return true
    end

    -- Searching for a zone ("nagrand") also finds the hubs inside it.
    local normalizedZone = string.lower(zone or "")
    return normalizedZone ~= "" and string.find(normalizedZone, query, 1, true) ~= nil
end

local function StoreMeta(id, continent, zone)
    if not id then
        return
    end

    TravelersRecall.meta[tonumber(id)] = {
        continent = tonumber(continent),
        zone = zone,
    }
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

    if TravelersRecall.UI and TravelersRecall.UI.RefreshLocations then
        TravelersRecall.UI.RefreshLocations()
    end
end

TravelersRecall.Core = {
    MatchesSearch = MatchesSearch,
    StoreMeta = StoreMeta,
    StoreCooldown = StoreCooldown,
    GetCooldownRemaining = GetCooldownRemaining,
    FormatCooldown = FormatCooldown,
    IsFavorite = IsFavorite,
    ToggleFavorite = ToggleFavorite,
    IsCollapsed = IsCollapsed,
    ToggleCollapsed = ToggleCollapsed,
    NormalizeLocationData = NormalizeLocationData,
    StoreLocation = StoreLocation,
    RemoveLocation = RemoveLocation,
}
