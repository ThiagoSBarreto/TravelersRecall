TravelersRecall = TravelersRecall or {}
TravelersRecall.unlocked = TravelersRecall.unlocked or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""

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

local function MatchesSearch(name)
    local query = TravelersRecall.searchText or ""
    if query == "" then
        return true
    end

    local normalizedName = string.lower(name or "")
    return string.find(normalizedName, query, 1, true) ~= nil
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
    NormalizeLocationData = NormalizeLocationData,
    StoreLocation = StoreLocation,
    RemoveLocation = RemoveLocation,
}
