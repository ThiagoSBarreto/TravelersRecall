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
        GameTooltip:AddLine("Traveler's Recall 1.0.0")
        GameTooltip:AddLine(" ")
        -- GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return minimapButton
end

local function RefreshLocations()
    local content = TravelersRecallScrollFrame and TravelersRecallScrollFrame:GetScrollChild()
    if not content then
        return
    end

    local buttons = TravelersRecall.UI.buttons or {}
    TravelersRecall.UI.buttons = buttons

    for _, button in ipairs(buttons) do
        button:Hide()
    end

    local headers = TravelersRecall.UI.headers or {}
    TravelersRecall.UI.headers = headers

    for _, header in ipairs(headers) do
        header:Hide()
    end

    local allMeta = TravelersRecall.meta or {}
    local locations = {}
    for id, data in pairs(TravelersRecall.unlocked) do
        local meta = allMeta[id]
        local zone = meta and meta.zone or nil
        if TravelersRecall.Core and TravelersRecall.Core.MatchesSearch(data and data.name, zone) then
            local isFriend = data.name == FRIEND_NAME
            table.insert(locations, {
                id = id,
                data = data,
                zone = zone or "",
                isFriend = isFriend,
                continent = isFriend and 0 or (meta and meta.continent) or OTHER_CONTINENT,
                sortName = string.lower(data.name or ""),
            })
        end
    end

    -- Teleport to Friend first, then continent, zone and name.
    -- Every key is compared in full, so the comparator is a strict ordering.
    table.sort(locations, function(left, right)
        if left.continent ~= right.continent then
            return left.continent < right.continent
        end
        if left.zone ~= right.zone then
            return left.zone < right.zone
        end
        if left.sortName ~= right.sortName then
            return left.sortName < right.sortName
        end
        return left.id < right.id
    end)

    -- Only show headers when the server sends grouping info (newer module versions).
    local showHeaders = next(allMeta) ~= nil

    local offset = 0
    local visibleIndex = 0
    local headerIndex = 0
    local currentContinent = nil
    for _, location in ipairs(locations) do
        local id = location.id
        local data = location.data

        if showHeaders and not location.isFriend and location.continent ~= currentContinent then
            currentContinent = location.continent
            headerIndex = headerIndex + 1

            local header = headers[headerIndex]
            if not header then
                header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                header:SetJustifyH("LEFT")
                headers[headerIndex] = header
            end

            if offset > 0 then
                offset = offset + HEADER_GAP
            end

            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -offset)
            header:SetText(CONTINENT_NAMES[currentContinent] or CONTINENT_NAMES[OTHER_CONTINENT])
            header:Show()
            offset = offset + HEADER_HEIGHT
        end

        visibleIndex = visibleIndex + 1

        local button = buttons[visibleIndex]
        if not button then
            button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            button:SetWidth(190)
            button:SetHeight(24)

            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetWidth(16)
            button.icon:SetHeight(16)
            button.icon:SetPoint("RIGHT", button, "LEFT", -4, 0)

            buttons[visibleIndex] = button
        end

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -offset)
        button:SetText(data.name)
        button.icon:SetTexture(data.icon)
        button:SetScript("OnClick", function()
            SendEditBoxCommand(".tr teleport " .. id)
        end)

        local zone = location.zone
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.name)
            if zone ~= "" then
                GameTooltip:AddLine(zone, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        button:Show()
        offset = offset + ROW_HEIGHT
    end

    content:SetHeight(math.max(offset, 1))

    local maxScroll = math.max(0, offset - 370)
    TravelersRecallScrollBar:SetMinMaxValues(0, maxScroll)
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
