# Traveler's Recall — Client Addon

Progressive fast-travel system for AzerothCore.

---

Client-side addon for the [Traveler's Recall Module](https://github.com/EvilTactician/mod-travelers-recall), providing the user interface for browsing and using unlocked teleport locations.

---

## Description

Traveler's Recall is the client addon responsible for displaying the teleport interface used by the Traveler's Recall AzerothCore module.

Players can browse their unlocked locations, search for destinations, and initiate teleports directly from the interface.

---

## Features

- Open the teleport window using `/tr`
- Open the teleport window by clicking the minimap button
- Display all unlocked teleport locations
- Click a location to initiate a teleport
- Locations grouped by region (Capital Cities, Eastern Kingdoms, Kalimdor, Outland, Northrend, Other) with collapsible headers, or shown as a plain A - Z list
- Capital cities highlighted in gold
- Favourites: right-click a location to pin it to the top of the list
- Cooldowns shown next to each location and counted down live; locations on cooldown are greyed out
- Teleport to Friend is greyed out when you are not in a party, and hints when no party member is targeted
- "Hide unavailable" filter
- Search by location name or region using the search bar at the top of the window
- Optional DragonUI skin: when DragonUI is loaded the window uses its frame style automatically

---

## Required Module

This addon requires the server-side module:

[**Traveler's Recall — AzerothCore Module**](https://github.com/EvilTactician/mod-travelers-recall)

The addon does not provide teleport functionality by itself. It communicates with the server-side module to retrieve unlocked locations and execute teleport requests.

---

## Installation
Git clone or [download from GitHub](https://github.com/EvilTactician/TravelersRecall/archive/refs/heads/main.zip)

Copy the `TravelersRecall` folder into your World of Warcraft AddOns directory.
If downloaded from github, it will likely be called TravelersRecall-main, rename it to TravelersRecall.

Expected structure:

World of Warcraft/
└── Interface/
    └── AddOns/
        └── TravelersRecall/

After installation, ensure the addon is enabled on the character-selection screen.

---
## Usage

Open the teleport window using: `/tr`
Alternatively, click the Traveler's Recall button on the minimap.
A handy macro in-game for your hotbar:
```
#showtooltip Hearthstone
/use [nobutton:2] Hearthstone
/stopmacro [nobutton:2]
/tr
```
Left-click uses your hearthstone, right-click opens Traveler's Recall.

The window displays the teleport locations unlocked by your character. Click any available location to teleport there.

Locations on cooldown are greyed out and show the time remaining. The cooldowns are read from the server's `.tr cd all` command when the window opens and after each teleport, so no server changes are needed. Because that command reports the cooldowns of your selected player, the lookup waits until you are not targeting another player.

Use the search bar at the top of the window to filter by name or region, the sort button to switch between region groups and an A - Z list, and right-click any location to add it to your favourites. Favourites, collapsed groups and filter settings are saved per character.

---
## Images

<img width="382" height="646" alt="image" src="https://github.com/user-attachments/assets/606e409e-e99a-411f-814f-87e14b324be0" />
<img width="388" height="647" alt="image" src="https://github.com/user-attachments/assets/07f8ad7c-f936-43d4-a463-8b1322fc0deb" />

---
## Author
1.1: EvilTactician
1.0: **ThiagoSBarreto**  
LesmaSamuray

---
## Update

Delete the TravelersRecall folder from /WoW Client/Interface/Addons and re-install as per installation instructions.

---

## Changelog

### November 4, 2026 — Version 1.1.0

- Location list grouped by region with collapsible headers, A - Z sort option and favourites
- Cooldowns and Teleport to Friend availability shown in the list
- "Hide unavailable" filter, search by region, search bar moved to the top
- Optional DragonUI skin
- Simpler minimap icon

### September 16, 2026 — Version 1.0.0

- Code refactor
- Updated minimap icon
