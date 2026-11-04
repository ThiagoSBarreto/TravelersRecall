TravelersRecall = TravelersRecall or {}
TravelersRecall.Data = TravelersRecall.Data or {}

local REGION_CAPITALS = "Capital Cities"
local REGION_EASTERN_KINGDOMS = "Eastern Kingdoms"
local REGION_KALIMDOR = "Kalimdor"
local REGION_OUTLAND = "Outland"
local REGION_NORTHREND = "Northrend"
local REGION_OTHER = "Other"

-- Display order of the groups in the location list.
local REGION_ORDER = {
    REGION_CAPITALS,
    REGION_EASTERN_KINGDOMS,
    REGION_KALIMDOR,
    REGION_OUTLAND,
    REGION_NORTHREND,
    REGION_OTHER,
}

-- The server only sends id, name and icon, so locations are grouped by name.
-- Anything not listed here (custom locations) ends up under "Other".
local LOCATIONS = {
    -- Capital cities
    ["stormwind"] = { region = REGION_EASTERN_KINGDOMS, capital = true },
    ["ironforge"] = { region = REGION_EASTERN_KINGDOMS, capital = true },
    ["undercity"] = { region = REGION_EASTERN_KINGDOMS, capital = true },
    ["silvermoon"] = { region = REGION_EASTERN_KINGDOMS, capital = true },
    ["darnassus"] = { region = REGION_KALIMDOR, capital = true },
    ["the exodar"] = { region = REGION_KALIMDOR, capital = true },
    ["orgrimmar"] = { region = REGION_KALIMDOR, capital = true },
    ["thunder bluff"] = { region = REGION_KALIMDOR, capital = true },
    ["shattrath"] = { region = REGION_OUTLAND, capital = true },
    ["dalaran"] = { region = REGION_NORTHREND, capital = true },

    -- Eastern Kingdoms
    ["booty bay"] = { region = REGION_EASTERN_KINGDOMS },
    ["brill"] = { region = REGION_EASTERN_KINGDOMS },
    ["goldshire"] = { region = REGION_EASTERN_KINGDOMS },
    ["kharanos"] = { region = REGION_EASTERN_KINGDOMS },
    ["the sepulcher"] = { region = REGION_EASTERN_KINGDOMS },
    ["thelsamar"] = { region = REGION_EASTERN_KINGDOMS },

    -- Kalimdor
    ["astranaar"] = { region = REGION_KALIMDOR },
    ["auberdine"] = { region = REGION_KALIMDOR },
    ["azure watch"] = { region = REGION_KALIMDOR },
    ["blood hoof village"] = { region = REGION_KALIMDOR },
    ["blood watch"] = { region = REGION_KALIMDOR },
    ["bloodvenom post"] = { region = REGION_KALIMDOR },
    ["brackenwall village"] = { region = REGION_KALIMDOR },
    ["camp mojache"] = { region = REGION_KALIMDOR },
    ["camp taurajo"] = { region = REGION_KALIMDOR },
    ["cenarion hold"] = { region = REGION_KALIMDOR },
    ["crossroads"] = { region = REGION_KALIMDOR },
    ["dolanaar"] = { region = REGION_KALIMDOR },
    ["emerald sanctuary"] = { region = REGION_KALIMDOR },
    ["everlook"] = { region = REGION_KALIMDOR },
    ["feathermoon stronghold"] = { region = REGION_KALIMDOR },
    ["freewind post"] = { region = REGION_KALIMDOR },
    ["gadgetzan"] = { region = REGION_KALIMDOR },
    ["grove of the ancients"] = { region = REGION_KALIMDOR },
    ["marshal's refuge"] = { region = REGION_KALIMDOR },
    ["ungoro crater"] = { region = REGION_KALIMDOR },
    ["mirage raceway"] = { region = REGION_KALIMDOR },
    ["nighthaven"] = { region = REGION_KALIMDOR },
    ["ratchet"] = { region = REGION_KALIMDOR },
    ["razor hill"] = { region = REGION_KALIMDOR },
    ["splintertree post"] = { region = REGION_KALIMDOR },
    ["starfall village"] = { region = REGION_KALIMDOR },
    ["valormok"] = { region = REGION_KALIMDOR },
    ["zoram'gar outpost"] = { region = REGION_KALIMDOR },

    -- Outland
    ["allerian stronghold"] = { region = REGION_OUTLAND },
    ["altar of sha'tar"] = { region = REGION_OUTLAND },
    ["area 52"] = { region = REGION_OUTLAND },
    ["cenarion refuge"] = { region = REGION_OUTLAND },
    ["cosmowrench"] = { region = REGION_OUTLAND },
    ["evergrove"] = { region = REGION_OUTLAND },
    ["falcon watch"] = { region = REGION_OUTLAND },
    ["honor hold"] = { region = REGION_OUTLAND },
    ["mok'nathal village"] = { region = REGION_OUTLAND },
    ["ogri'la"] = { region = REGION_OUTLAND },
    ["orebor harborage"] = { region = REGION_OUTLAND },
    ["sanctum of the stars"] = { region = REGION_OUTLAND },
    ["shadowmoon village"] = { region = REGION_OUTLAND },
    ["spinebreaker post"] = { region = REGION_OUTLAND },
    ["stonebreaker hold"] = { region = REGION_OUTLAND },
    ["stormspire"] = { region = REGION_OUTLAND },
    ["swamprat post"] = { region = REGION_OUTLAND },
    ["sylvanaar"] = { region = REGION_OUTLAND },
    ["telaar"] = { region = REGION_OUTLAND },
    ["telredor"] = { region = REGION_OUTLAND },
    ["temple of telhamat"] = { region = REGION_OUTLAND },
    ["thrallmar"] = { region = REGION_OUTLAND },
    ["tharllmar"] = { region = REGION_OUTLAND },
    ["the stair of destiny"] = { region = REGION_OUTLAND },
    ["thunderlord stronghold"] = { region = REGION_OUTLAND },
    ["toshley's station"] = { region = REGION_OUTLAND },
    ["wildhammer stronghold"] = { region = REGION_OUTLAND },
    ["zabra'jin"] = { region = REGION_OUTLAND },

    -- Northrend
    ["amberpine lodge"] = { region = REGION_NORTHREND },
    ["argent tournament"] = { region = REGION_NORTHREND },
    ["dubra'jin"] = { region = REGION_NORTHREND },
    ["ebon watch"] = { region = REGION_NORTHREND },
    ["fort wildervar"] = { region = REGION_NORTHREND },
    ["kamagua"] = { region = REGION_NORTHREND },
    ["light's breach"] = { region = REGION_NORTHREND },
    ["the argent stand"] = { region = REGION_NORTHREND },
    ["valgarde"] = { region = REGION_NORTHREND },
    ["valiance keep"] = { region = REGION_NORTHREND },
    ["warsong hold"] = { region = REGION_NORTHREND },
    ["westfall brigade"] = { region = REGION_NORTHREND },
    ["westguard keep"] = { region = REGION_NORTHREND },
    ["zim'torga"] = { region = REGION_NORTHREND },
}

local UNKNOWN_LOCATION = { region = REGION_OTHER }

local function GetLocationInfo(name)
    return LOCATIONS[string.lower(name or "")] or UNKNOWN_LOCATION
end

TravelersRecall.Data = {
    REGION_CAPITALS = REGION_CAPITALS,
    REGION_ORDER = REGION_ORDER,
    GetLocationInfo = GetLocationInfo,
}
