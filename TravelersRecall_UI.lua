TravelersRecall = TravelersRecall or {}
TravelersRecall.UI = TravelersRecall.UI or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""

local FRIEND_NAME = "Teleport to Friend"
local OTHER_CONTINENT = 9
local CONTINENT_NAMES = {
    [1] = "Eastern Kingdoms",
    [2] = "Kalimdor",
    [3] = "Outland",
    [4] = "Northrend",
    [9] = "Other",
}
local ROW_HEIGHT = 26
local HEADER_HEIGHT = 18
local HEADER_GAP = 6

local function SendEditBoxCommand(command)
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return
    end

    editBox:SetText(command)
    ChatEdit_SendText(editBox)
    editBox:SetText("")
end

local function ToggleTravelersRecall()
    if not TravelersRecallFrame then
        return
    end

    if TravelersRecallFrame:IsShown() then
        TravelersRecallFrame:Hide()
        return
    end

    TravelersRecallFrame:Show()
    SendEditBoxCommand(".tr list")
end

local function CreateMinimapButton()
    local minimapButton = CreateFrame("Button", "TravelersRecallMinimapButton", Minimap)
    minimapButton:SetFrameStrata("MEDIUM")

    minimapButton:SetWidth(32)
    minimapButton:SetHeight(32)
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:RegisterForClicks("LeftButtonUp")
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -6, 6)

    local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
    minimapIcon:SetTexture("Interface\\Addons\\TravelersRecall\\Images\\icon")
    minimapIcon:SetWidth(17)
    minimapIcon:SetHeight(17)
    minimapIcon:SetPoint("CENTER", 1, -1)

    local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
    minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    minimapBorder:SetWidth(54)
    minimapBorder:SetHeight(54)
    minimapBorder:SetPoint("TOPLEFT")

    minimapButton:SetScript("OnClick", function()
        ToggleTravelersRecall()
    end)

    minimapButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    minimapButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Traveler's Recall 1.2.0")
        GameTooltip:AddLine(" ")
        -- GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return minimapButton
end

local FAVORITES_GROUP = 1
local CONTINENT_GROUP_BASE = 10

local RefreshLocations

local function GetGroupTitle(group)
    if group == FAVORITES_GROUP then
        return "Favourites"
    end
    local continent = group - CONTINENT_GROUP_BASE
    return CONTINENT_NAMES[continent] or CONTINENT_NAMES[OTHER_CONTINENT]
end

local function GetOrCreateHeader(content, index)
    local headers = TravelersRecall.UI.headers
    local header = headers[index]
    if header then
        return header
    end

    header = CreateFrame("Button", nil, content)
    header:SetWidth(214)
    header:SetHeight(HEADER_HEIGHT)
    header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("LEFT", header, "LEFT", 2, 0)
    header.text:SetJustifyH("LEFT")

    header:SetScript("OnClick", function(self)
        TravelersRecall.Core.ToggleCollapsed(self.group)
        RefreshLocations()
    end)

    headers[index] = header
    return header
end

local function GetOrCreateButton(content, index)
    local buttons = TravelersRecall.UI.buttons
    local button = buttons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetWidth(190)
    button:SetHeight(24)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetWidth(16)
    button.icon:SetHeight(16)
    button.icon:SetPoint("RIGHT", button, "LEFT", -4, 0)

    -- Star marking a favourite.
    button.fav = button:CreateTexture(nil, "OVERLAY")
    button.fav:SetWidth(12)
    button.fav:SetHeight(12)
    button.fav:SetPoint("LEFT", button, "LEFT", 6, 0)
    button.fav:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")

    -- Remaining cooldown, right-aligned inside the button.
    button.cd = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.cd:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    button.cd:SetTextColor(1, 0.35, 0.35)

    buttons[index] = button
    return button
end

local function UpdateButtonCooldown(button)
    local remaining = TravelersRecall.Core.GetCooldownRemaining(button.locationId)
    button.onCooldown = remaining > 0

    if remaining > 0 then
        button:SetText("|cff8a8a8a" .. button.locationName .. "|r")
        button.cd:SetText(TravelersRecall.Core.FormatCooldown(remaining))
        button.cd:Show()
    else
        button:SetText(button.locationName)
        button.cd:Hide()
    end
end

local function ShowButtonTooltip(button)
    local core = TravelersRecall.Core
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(button.locationName)
    if button.zone ~= "" then
        GameTooltip:AddLine(button.zone, 0.8, 0.8, 0.8)
    end

    local remaining = core.GetCooldownRemaining(button.locationId)
    if remaining > 0 then
        GameTooltip:AddLine("Cooldown: " .. core.FormatCooldown(remaining), 1, 0.35, 0.35)
    end

    if core.IsFavorite(button.locationId) then
        GameTooltip:AddLine("Shift-click to remove from favourites", 0.5, 0.5, 0.5)
    else
        GameTooltip:AddLine("Shift-click to add to favourites", 0.5, 0.5, 0.5)
    end
    GameTooltip:Show()
end

RefreshLocations = function()
    local content = TravelersRecallScrollFrame and TravelersRecallScrollFrame:GetScrollChild()
    if not content then
        return
    end

    local core = TravelersRecall.Core
    TravelersRecall.UI.buttons = TravelersRecall.UI.buttons or {}
    TravelersRecall.UI.headers = TravelersRecall.UI.headers or {}

    for _, button in ipairs(TravelersRecall.UI.buttons) do
        button:Hide()
        button.locationId = nil
    end

    for _, header in ipairs(TravelersRecall.UI.headers) do
        header:Hide()
    end

    local allMeta = TravelersRecall.meta or {}
    local locations = {}
    local groupCounts = {}
    for id, data in pairs(TravelersRecall.unlocked) do
        local meta = allMeta[id]
        local zone = meta and meta.zone or nil
        if core.MatchesSearch(data and data.name, zone) then
            local group
            if data.name == FRIEND_NAME then
                group = 0
            elseif core.IsFavorite(id) then
                group = FAVORITES_GROUP
            else
                group = CONTINENT_GROUP_BASE + ((meta and meta.continent) or OTHER_CONTINENT)
            end

            groupCounts[group] = (groupCounts[group] or 0) + 1
            table.insert(locations, {
                id = id,
                data = data,
                zone = zone or "",
                group = group,
                -- Favourites are sorted by name only.
                zoneKey = group == FAVORITES_GROUP and "" or string.lower(zone or ""),
                sortName = string.lower(data.name or ""),
            })
        end
    end

    -- Teleport to Friend, favourites, then continent, zone and name.
    -- Every key is compared in full, so the comparator is a strict ordering.
    table.sort(locations, function(left, right)
        if left.group ~= right.group then
            return left.group < right.group
        end
        if left.zoneKey ~= right.zoneKey then
            return left.zoneKey < right.zoneKey
        end
        if left.sortName ~= right.sortName then
            return left.sortName < right.sortName
        end
        return left.id < right.id
    end)

    -- Continent headers only make sense when the server sends grouping info,
    -- but favourites always get one.
    local hasMeta = next(allMeta) ~= nil
    local searching = (TravelersRecall.searchText or "") ~= ""

    local offset = 0
    local buttonIndex = 0
    local headerIndex = 0
    local currentGroup = nil
    local collapsed = false

    for _, location in ipairs(locations) do
        if location.group ~= currentGroup then
            currentGroup = location.group
            collapsed = false

            local wantsHeader = currentGroup == FAVORITES_GROUP
                or (currentGroup >= CONTINENT_GROUP_BASE and hasMeta)

            if wantsHeader then
                -- While searching, show every match regardless of collapsed groups.
                collapsed = not searching and core.IsCollapsed(currentGroup)

                headerIndex = headerIndex + 1
                local header = GetOrCreateHeader(content, headerIndex)

                if offset > 0 then
                    offset = offset + HEADER_GAP
                end

                header.group = currentGroup
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -offset)
                header.text:SetText(string.format("%s %s |cff808080(%d)|r",
                    collapsed and "+" or "-",
                    GetGroupTitle(currentGroup),
                    groupCounts[currentGroup] or 0))
                header:Show()
                offset = offset + HEADER_HEIGHT
            end
        end

        if not collapsed then
            local id = location.id
            local data = location.data

            buttonIndex = buttonIndex + 1
            local button = GetOrCreateButton(content, buttonIndex)

            button.locationId = id
            button.locationName = data.name
            button.zone = location.zone

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -offset)
            button.icon:SetTexture(data.icon)

            if location.group == FAVORITES_GROUP then
                button.fav:Show()
            else
                button.fav:Hide()
            end

            UpdateButtonCooldown(button)

            button:SetScript("OnClick", function(self)
                if IsShiftKeyDown() and data.name ~= FRIEND_NAME then
                    core.ToggleFavorite(id)
                    RefreshLocations()
                    if GameTooltip:IsOwned(self) then
                        ShowButtonTooltip(self)
                    end
                    return
                end
                SendEditBoxCommand(".tr teleport " .. id)
            end)
            button:SetScript("OnEnter", ShowButtonTooltip)
            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            button:Show()
            offset = offset + ROW_HEIGHT
        end
    end

    content:SetHeight(math.max(offset, 1))

    local maxScroll = math.max(0, offset - 370)
    TravelersRecallScrollBar:SetMinMaxValues(0, maxScroll)
end

-- Count cooldowns down once per second while the window is open.
local function SetupCooldownTicker()
    if not TravelersRecallFrame then
        return
    end

    local elapsedSinceTick = 0
    TravelersRecallFrame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceTick = elapsedSinceTick + elapsed
        if elapsedSinceTick < 1 then
            return
        end
        elapsedSinceTick = 0

        for _, button in ipairs(TravelersRecall.UI.buttons or {}) do
            if button:IsShown() and button.locationId and button.onCooldown then
                UpdateButtonCooldown(button)
            end
        end
    end)
end

local function SetupSearchBox()
    if not TravelersRecallSearchBox then
        return
    end

    TravelersRecallSearchBox:SetText("")
    TravelersRecallSearchBox:SetScript("OnTextChanged", function(self)
        TravelersRecall.searchText = string.lower(self:GetText() or "")
        RefreshLocations()
    end)
end

local function SetupScrollFrame()
    TravelersRecallScrollBar:SetScript("OnValueChanged", function(self)
        TravelersRecallScrollFrame:SetVerticalScroll(self:GetValue())
    end)

    TravelersRecallScrollFrame:EnableMouseWheel(true)
    TravelersRecallScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local current = TravelersRecallScrollBar:GetValue()
        local min, max = TravelersRecallScrollBar:GetMinMaxValues()

        if delta > 0 then
            TravelersRecallScrollBar:SetValue(math.max(current - 20, min))
        else
            TravelersRecallScrollBar:SetValue(math.min(current + 20, max))
        end
    end)

    local content = CreateFrame("Frame", "TravelersRecallContentFrame", TravelersRecallScrollFrame)
    content:SetWidth(200)
    content:SetHeight(1)
    TravelersRecallScrollFrame:SetScrollChild(content)
end

TravelersRecall.UI.SendEditBoxCommand = SendEditBoxCommand
TravelersRecall.UI.Toggle = ToggleTravelersRecall
TravelersRecall.UI.RefreshLocations = RefreshLocations
TravelersRecall.UI.CreateMinimapButton = CreateMinimapButton
TravelersRecall.UI.SetupSearchBox = SetupSearchBox
TravelersRecall.UI.SetupScrollFrame = SetupScrollFrame

CreateMinimapButton()
SetupScrollFrame()
SetupSearchBox()
SetupCooldownTicker()
