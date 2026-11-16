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

-- The server only sends id, name and icon, so zone and region are looked up by name.
-- Anything not listed here (custom locations) ends up under "Other".
local LOCATIONS = {
    -- Capital cities
    ["stormwind"] = { zone = "Elwynn Forest", region = REGION_EASTERN_KINGDOMS, capital = true },
    ["ironforge"] = { zone = "Dun Morogh", region = REGION_EASTERN_KINGDOMS, capital = true },
    ["undercity"] = { zone = "Tirisfal Glades", region = REGION_EASTERN_KINGDOMS, capital = true },
    ["silvermoon"] = { zone = "Eversong Woods", region = REGION_EASTERN_KINGDOMS, capital = true },
    ["darnassus"] = { zone = "Teldrassil", region = REGION_KALIMDOR, capital = true },
    ["the exodar"] = { zone = "Azuremyst Isle", region = REGION_KALIMDOR, capital = true },
    ["orgrimmar"] = { zone = "Durotar", region = REGION_KALIMDOR, capital = true },
    ["thunder bluff"] = { zone = "Mulgore", region = REGION_KALIMDOR, capital = true },
    ["shattrath"] = { zone = "Terokkar Forest", region = REGION_OUTLAND, capital = true },
    ["dalaran"] = { zone = "Crystalsong Forest", region = REGION_NORTHREND, capital = true },

    -- Eastern Kingdoms
    ["booty bay"] = { zone = "Stranglethorn Vale", region = REGION_EASTERN_KINGDOMS },
    ["brill"] = { zone = "Tirisfal Glades", region = REGION_EASTERN_KINGDOMS },
    ["darkshire"] = { zone = "Duskwood", region = REGION_EASTERN_KINGDOMS },
    ["goldshire"] = { zone = "Elwynn Forest", region = REGION_EASTERN_KINGDOMS },
    ["kharanos"] = { zone = "Dun Morogh", region = REGION_EASTERN_KINGDOMS },
    ["lakeshire"] = { zone = "Redridge Mountains", region = REGION_EASTERN_KINGDOMS },
    ["menethil harbor"] = { zone = "Wetlands", region = REGION_EASTERN_KINGDOMS },
    ["morgan's vigil"] = { zone = "Burning Steppes", region = REGION_EASTERN_KINGDOMS },
    ["nethergarde keep"] = { zone = "Blasted Lands", region = REGION_EASTERN_KINGDOMS },
    ["refuge pointe"] = { zone = "Arathi Highlands", region = REGION_EASTERN_KINGDOMS },
    ["sentinel hill"] = { zone = "Westfall", region = REGION_EASTERN_KINGDOMS },
    ["southshore"] = { zone = "Hillsbrad Foothills", region = REGION_EASTERN_KINGDOMS },
    ["tarren mill"] = { zone = "Hillsbrad Foothills", region = REGION_EASTERN_KINGDOMS },
    ["the sepulcher"] = { zone = "Silverpine Forest", region = REGION_EASTERN_KINGDOMS },
    ["thelsamar"] = { zone = "Loch Modan", region = REGION_EASTERN_KINGDOMS },
    ["thorium point"] = { zone = "Searing Gorge", region = REGION_EASTERN_KINGDOMS },

    -- Kalimdor
    ["astranaar"] = { zone = "Ashenvale", region = REGION_KALIMDOR },
    ["auberdine"] = { zone = "Darkshore", region = REGION_KALIMDOR },
    ["azure watch"] = { zone = "Azuremyst Isle", region = REGION_KALIMDOR },
    ["blood hoof village"] = { zone = "Mulgore", region = REGION_KALIMDOR },
    ["blood watch"] = { zone = "Bloodmyst Isle", region = REGION_KALIMDOR },
    ["bloodvenom post"] = { zone = "Felwood", region = REGION_KALIMDOR },
    ["brackenwall village"] = { zone = "Dustwallow Marsh", region = REGION_KALIMDOR },
    ["camp mojache"] = { zone = "Feralas", region = REGION_KALIMDOR },
    ["camp taurajo"] = { zone = "The Barrens", region = REGION_KALIMDOR },
    ["cenarion hold"] = { zone = "Silithus", region = REGION_KALIMDOR },
    ["crossroads"] = { zone = "The Barrens", region = REGION_KALIMDOR },
    ["dolanaar"] = { zone = "Teldrassil", region = REGION_KALIMDOR },
    ["emerald sanctuary"] = { zone = "Felwood", region = REGION_KALIMDOR },
    ["everlook"] = { zone = "Winterspring", region = REGION_KALIMDOR },
    ["feathermoon stronghold"] = { zone = "Feralas", region = REGION_KALIMDOR },
    ["freewind post"] = { zone = "Thousand Needles", region = REGION_KALIMDOR },
    ["gadgetzan"] = { zone = "Tanaris", region = REGION_KALIMDOR },
    ["grove of the ancients"] = { zone = "Darkshore", region = REGION_KALIMDOR },
    ["marshal's refuge"] = { zone = "Un'Goro Crater", region = REGION_KALIMDOR },
    ["ungoro crater"] = { zone = "Un'Goro Crater", region = REGION_KALIMDOR },
    ["mirage raceway"] = { zone = "Thousand Needles", region = REGION_KALIMDOR },
    ["nighthaven"] = { zone = "Moonglade", region = REGION_KALIMDOR },
    ["nijel's point"] = { zone = "Desolace", region = REGION_KALIMDOR },
    ["ratchet"] = { zone = "The Barrens", region = REGION_KALIMDOR },
    ["razor hill"] = { zone = "Durotar", region = REGION_KALIMDOR },
    ["shadowprey village"] = { zone = "Desolace", region = REGION_KALIMDOR },
    ["splintertree post"] = { zone = "Ashenvale", region = REGION_KALIMDOR },
    ["starfall village"] = { zone = "Winterspring", region = REGION_KALIMDOR },
    ["stonetalon peak"] = { zone = "Stonetalon Mountains", region = REGION_KALIMDOR },
    ["sun rock retreat"] = { zone = "Stonetalon Mountains", region = REGION_KALIMDOR },
    ["valormok"] = { zone = "Azshara", region = REGION_KALIMDOR },
    ["zoram'gar outpost"] = { zone = "Ashenvale", region = REGION_KALIMDOR },

    -- Outland
    ["allerian stronghold"] = { zone = "Terokkar Forest", region = REGION_OUTLAND },
    ["altar of sha'tar"] = { zone = "Shadowmoon Valley", region = REGION_OUTLAND },
    ["area 52"] = { zone = "Netherstorm", region = REGION_OUTLAND },
    ["cenarion refuge"] = { zone = "Zangarmarsh", region = REGION_OUTLAND },
    ["cosmowrench"] = { zone = "Netherstorm", region = REGION_OUTLAND },
    ["evergrove"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["falcon watch"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["honor hold"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["mok'nathal village"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["ogri'la"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["orebor harborage"] = { zone = "Zangarmarsh", region = REGION_OUTLAND },
    ["sanctum of the stars"] = { zone = "Shadowmoon Valley", region = REGION_OUTLAND },
    ["shadowmoon village"] = { zone = "Shadowmoon Valley", region = REGION_OUTLAND },
    ["spinebreaker post"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["stonebreaker hold"] = { zone = "Terokkar Forest", region = REGION_OUTLAND },
    ["stormspire"] = { zone = "Netherstorm", region = REGION_OUTLAND },
    ["swamprat post"] = { zone = "Zangarmarsh", region = REGION_OUTLAND },
    ["sylvanaar"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["telaar"] = { zone = "Nagrand", region = REGION_OUTLAND },
    ["telredor"] = { zone = "Zangarmarsh", region = REGION_OUTLAND },
    ["temple of telhamat"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["thrallmar"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["tharllmar"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["the stair of destiny"] = { zone = "Hellfire Peninsula", region = REGION_OUTLAND },
    ["thunderlord stronghold"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["toshley's station"] = { zone = "Blade's Edge Mountains", region = REGION_OUTLAND },
    ["wildhammer stronghold"] = { zone = "Shadowmoon Valley", region = REGION_OUTLAND },
    ["zabra'jin"] = { zone = "Zangarmarsh", region = REGION_OUTLAND },

    -- Northrend
    ["amberpine lodge"] = { zone = "Grizzly Hills", region = REGION_NORTHREND },
    ["argent tournament"] = { zone = "Icecrown", region = REGION_NORTHREND },
    ["dubra'jin"] = { zone = "Zul'Drak", region = REGION_NORTHREND },
    ["ebon watch"] = { zone = "Zul'Drak", region = REGION_NORTHREND },
    ["fort wildervar"] = { zone = "Howling Fjord", region = REGION_NORTHREND },
    ["kamagua"] = { zone = "Howling Fjord", region = REGION_NORTHREND },
    ["light's breach"] = { zone = "Zul'Drak", region = REGION_NORTHREND },
    ["the argent stand"] = { zone = "Zul'Drak", region = REGION_NORTHREND },
    ["valgarde"] = { zone = "Howling Fjord", region = REGION_NORTHREND },
    ["valiance keep"] = { zone = "Borean Tundra", region = REGION_NORTHREND },
    ["warsong hold"] = { zone = "Borean Tundra", region = REGION_NORTHREND },
    ["westfall brigade"] = { zone = "Grizzly Hills", region = REGION_NORTHREND },
    ["westguard keep"] = { zone = "Howling Fjord", region = REGION_NORTHREND },
    ["zim'torga"] = { zone = "Zul'Drak", region = REGION_NORTHREND },
}

local UNKNOWN_LOCATION = { region = REGION_OTHER }

local function GetLocationInfo(name)
    return LOCATIONS[string.lower(name or "")] or UNKNOWN_LOCATION
end

TravelersRecall.Data = {
    REGION_CAPITALS = REGION_CAPITALS,
    REGION_OTHER = REGION_OTHER,
    REGION_ORDER = REGION_ORDER,
    GetLocationInfo = GetLocationInfo,
}
