TravelersRecall = TravelersRecall or {}
TravelersRecall.UI = TravelersRecall.UI or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""

local ROW_HEIGHT = 22
local HEADER_HEIGHT = 20
local GROUP_SPACING = 4
local SCROLL_STEP = ROW_HEIGHT * 2

local GROUP_FAVOURITES = "Favourites"
local FAVOURITE_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
local HIGHLIGHT_TEXTURE = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

local COLOR_NORMAL = { 1, 1, 1 }
local COLOR_CAPITAL = { 1, 0.82, 0 }
local COLOR_UNAVAILABLE = { 0.5, 0.5, 0.5 }
local COLOR_COOLDOWN = { 1, 0.35, 0.35 }
local COLOR_WARNING = { 1, 0.65, 0.2 }

local needsRefresh = false

local function SendEditBoxCommand(command)
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return
    end

    editBox:SetText(command)
    ChatEdit_SendText(editBox)
    editBox:SetText("")
end

local function FormatCooldown(seconds)
    seconds = math.ceil(seconds)
    if seconds >= 3600 then
        return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
    if seconds >= 60 then
        return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
    end
    return string.format("%ds", seconds)
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

    if TravelersRecall.Core and TravelersRecall.Core.ScheduleCooldownRequest then
        TravelersRecall.Core.ScheduleCooldownRequest(0)
    end
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
        GameTooltip:AddLine("Traveler's Recall " .. (GetAddOnMetadata("TravelersRecall", "Version") or ""))
        GameTooltip:AddLine("Click to open, drag to move.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return minimapButton
end

local function GetDB()
    return TravelersRecall.Core.GetDB()
end

-- Name colour, status text and icon shading for one location row.
local function ApplyRowState(row)
    local location = row.location
    local core = TravelersRecall.Core
    local available, reason, warning = core.GetAvailability(location.id, location.data)
    local remaining = core.GetCooldownRemaining(location.id)

    if remaining > 0 then
        row.status:SetText(FormatCooldown(remaining))
        row.status:SetTextColor(COLOR_COOLDOWN[1], COLOR_COOLDOWN[2], COLOR_COOLDOWN[3])
    elseif reason then
        local color = warning and COLOR_WARNING or COLOR_UNAVAILABLE
        row.status:SetText(reason)
        row.status:SetTextColor(color[1], color[2], color[3])
    else
        row.status:SetText("")
    end

    local color = COLOR_NORMAL
    if not available then
        color = COLOR_UNAVAILABLE
    elseif location.info.capital then
        color = COLOR_CAPITAL
    end
    row.text:SetTextColor(color[1], color[2], color[3])

    row.icon:SetDesaturated(not available)
    row.icon:SetAlpha(available and 1 or 0.6)

    local changed = row.available ~= nil and row.available ~= available
    row.available = available
    return changed
end

local function ShowRowTooltip(row)
    local location = row.location
    local core = TravelersRecall.Core
    local isFriend = core.IsFriendLocation(location.data)
    local available, reason = core.GetAvailability(location.id, location.data)
    local remaining = core.GetCooldownRemaining(location.id)

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")

    local color = location.info.capital and COLOR_CAPITAL or COLOR_NORMAL
    GameTooltip:AddLine(location.data.name, color[1], color[2], color[3])

    if isFriend then
        GameTooltip:AddLine("Teleports you to your targeted party member.", 0.7, 0.7, 0.7, true)
    elseif location.info.capital then
        GameTooltip:AddLine(location.info.region .. " - Capital city", 0.7, 0.7, 0.7)
    else
        GameTooltip:AddLine(location.info.region, 0.7, 0.7, 0.7)
    end

    if remaining > 0 then
        GameTooltip:AddLine("Cooldown: " .. FormatCooldown(remaining), COLOR_COOLDOWN[1], COLOR_COOLDOWN[2], COLOR_COOLDOWN[3])
    elseif reason then
        local reasonColor = available and COLOR_WARNING or COLOR_UNAVAILABLE
        GameTooltip:AddLine(reason, reasonColor[1], reasonColor[2], reasonColor[3])
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click to teleport.", 0.5, 0.5, 0.5)
    if not isFriend then
        if GetDB().favourites[location.id] then
            GameTooltip:AddLine("Right-click to remove from favourites.", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Right-click to add to favourites.", 0.5, 0.5, 0.5)
        end
    end

    GameTooltip:Show()
end

local RefreshNow

local function CreateRow(content)
    local row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture(HIGHLIGHT_TEXTURE, "ADD")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(18)
    row.icon:SetHeight(18)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)

    row.favourite = row:CreateTexture(nil, "OVERLAY")
    row.favourite:SetTexture(FAVOURITE_TEXTURE)
    row.favourite:SetWidth(11)
    row.favourite:SetHeight(11)
    row.favourite:SetPoint("CENTER", row.icon, "TOPLEFT", 1, -1)

    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.status:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.status:SetJustifyH("RIGHT")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.text:SetPoint("RIGHT", row.status, "LEFT", -4, 0)
    row.text:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(self, button)
        local location = self.location
        if not location then
            return
        end

        if button == "RightButton" then
            if TravelersRecall.Core.IsFriendLocation(location.data) then
                return
            end

            local favourites = GetDB().favourites
            if favourites[location.id] then
                favourites[location.id] = nil
            else
                favourites[location.id] = true
            end
            GameTooltip:Hide()
            RefreshNow()
            return
        end

        SendEditBoxCommand(".tr teleport " .. location.id)
    end)

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return row
end

local function CreateHeader(content)
    local header = CreateFrame("Button", nil, content)
    header:SetHeight(HEADER_HEIGHT)
    header:SetHighlightTexture(HIGHLIGHT_TEXTURE, "ADD")

    header.background = header:CreateTexture(nil, "BACKGROUND")
    header.background:SetAllPoints(header)
    header.background:SetTexture(1, 1, 1, 0.06)

    header.toggle = header:CreateTexture(nil, "ARTWORK")
    header.toggle:SetWidth(14)
    header.toggle:SetHeight(14)
    header.toggle:SetPoint("LEFT", header, "LEFT", 4, 0)

    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("LEFT", header.toggle, "RIGHT", 4, 0)

    header.count = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    header.count:SetPoint("LEFT", header.text, "RIGHT", 6, 0)

    header:SetScript("OnClick", function(self)
        local collapsed = GetDB().collapsed
        if collapsed[self.group] then
            collapsed[self.group] = nil
        else
            collapsed[self.group] = true
        end
        RefreshNow()
    end)

    return header
end

local function SortByName(left, right)
    return string.lower(left.data.name) < string.lower(right.data.name)
end

-- Builds the ordered list of headers and rows for the current search, filter and sort mode.
local function BuildEntries()
    local core = TravelersRecall.Core
    local data = TravelersRecall.Data
    local db = GetDB()

    local friendLocations = {}
    local favouriteLocations = {}
    local otherLocations = {}
    local groups = {}
    local total, onCooldown = 0, 0

    for id, locationData in pairs(TravelersRecall.unlocked) do
        local info = data.GetLocationInfo(locationData.name)
        total = total + 1
        if core.GetCooldownRemaining(id) > 0 then
            onCooldown = onCooldown + 1
        end

        local searchRegion = info.region
        if info.capital then
            searchRegion = data.REGION_CAPITALS .. " " .. info.region
        end

        if core.MatchesSearch(locationData.name, searchRegion)
            and (not db.readyOnly or core.GetAvailability(id, locationData)) then
            local location = { id = id, data = locationData, info = info }

            if core.IsFriendLocation(locationData) then
                table.insert(friendLocations, location)
            elseif db.favourites[id] then
                table.insert(favouriteLocations, location)
            else
                local group = info.capital and data.REGION_CAPITALS or info.region
                groups[group] = groups[group] or {}
                table.insert(groups[group], location)
                table.insert(otherLocations, location)
            end
        end
    end

    local entries = {}
    local searching = (TravelersRecall.searchText or "") ~= ""

    for _, location in ipairs(friendLocations) do
        table.insert(entries, { location = location })
    end

    table.sort(favouriteLocations, SortByName)

    if db.sortMode == "name" then
        for _, location in ipairs(favouriteLocations) do
            table.insert(entries, { location = location })
        end

        table.sort(otherLocations, SortByName)
        for _, location in ipairs(otherLocations) do
            table.insert(entries, { location = location })
        end

        return entries, total, onCooldown
    end

    local function AddGroup(group, locations)
        if not locations or #locations == 0 then
            return
        end

        local collapsed = db.collapsed[group] and not searching
        table.insert(entries, { group = group, count = #locations, collapsed = collapsed })

        if not collapsed then
            table.sort(locations, SortByName)
            for _, location in ipairs(locations) do
                table.insert(entries, { location = location })
            end
        end
    end

    AddGroup(GROUP_FAVOURITES, favouriteLocations)
    for _, group in ipairs(data.REGION_ORDER) do
        AddGroup(group, groups[group])
    end

    return entries, total, onCooldown
end

local function UpdateStatusText(total, onCooldown)
    if not TravelersRecallStatusText then
        return
    end

    if total == 0 then
        TravelersRecallStatusText:SetText("No locations unlocked yet")
        return
    end

    local text = total .. (total == 1 and " location" or " locations")
    if onCooldown > 0 then
        text = text .. ", " .. onCooldown .. " on cooldown"
    end
    TravelersRecallStatusText:SetText(text)
end

RefreshNow = function()
    needsRefresh = false

    local content = TravelersRecallScrollFrame and TravelersRecallScrollFrame:GetScrollChild()
    if not content then
        return
    end

    local rows = TravelersRecall.UI.rows or {}
    local headers = TravelersRecall.UI.headers or {}
    TravelersRecall.UI.rows = rows
    TravelersRecall.UI.headers = headers

    for _, row in ipairs(rows) do
        row:Hide()
        row.location = nil
    end
    for _, header in ipairs(headers) do
        header:Hide()
    end

    local width = TravelersRecallScrollFrame:GetWidth()
    content:SetWidth(width)

    local entries, total, onCooldown = BuildEntries()
    local favourites = GetDB().favourites
    local rowIndex, headerIndex = 0, 0
    local offset = 0

    for index, entry in ipairs(entries) do
        if entry.group then
            if index > 1 then
                offset = offset + GROUP_SPACING
            end

            headerIndex = headerIndex + 1
            local header = headers[headerIndex]
            if not header then
                header = CreateHeader(content)
                headers[headerIndex] = header
            end

            header.group = entry.group
            header.text:SetText(entry.group)
            header.count:SetText("(" .. entry.count .. ")")
            if entry.collapsed then
                header.toggle:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            else
                header.toggle:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
            end

            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -offset)
            header:SetWidth(width)
            header:Show()
            offset = offset + HEADER_HEIGHT
        else
            rowIndex = rowIndex + 1
            local row = rows[rowIndex]
            if not row then
                row = CreateRow(content)
                rows[rowIndex] = row
            end

            local location = entry.location
            row.location = location
            row.available = nil
            row.text:SetText(location.data.name)
            row.icon:SetTexture(location.data.icon)

            if favourites[location.id] then
                row.favourite:Show()
            else
                row.favourite:Hide()
            end

            ApplyRowState(row)

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -offset)
            row:SetWidth(width)
            row:Show()
            offset = offset + ROW_HEIGHT
        end
    end

    content:SetHeight(math.max(1, offset))

    local maxScroll = math.max(0, offset - TravelersRecallScrollFrame:GetHeight())
    TravelersRecallScrollBar:SetMinMaxValues(0, maxScroll)
    if TravelersRecallScrollBar:GetValue() > maxScroll then
        TravelersRecallScrollBar:SetValue(maxScroll)
    end
    if maxScroll > 0 then
        TravelersRecallScrollBar:Show()
    else
        TravelersRecallScrollBar:Hide()
        TravelersRecallScrollFrame:SetVerticalScroll(0)
    end

    UpdateStatusText(total, onCooldown)
end

-- Batches the many TR_LIST messages into one rebuild on the next frame.
local function RefreshLocations()
    needsRefresh = true
end

-- Cheap update of the visible rows (cooldown timers, party state) without rebuilding the list.
local function UpdateLocationStates()
    if not TravelersRecallFrame or not TravelersRecallFrame:IsShown() then
        return
    end

    local changed = false
    for _, row in ipairs(TravelersRecall.UI.rows or {}) do
        if row:IsShown() and row.location then
            if ApplyRowState(row) then
                changed = true
            end
        end
    end

    if changed and GetDB().readyOnly then
        needsRefresh = true
        return
    end

    local total, onCooldown = 0, 0
    for id in pairs(TravelersRecall.unlocked) do
        total = total + 1
        if TravelersRecall.Core.GetCooldownRemaining(id) > 0 then
            onCooldown = onCooldown + 1
        end
    end
    UpdateStatusText(total, onCooldown)

    if GameTooltip:IsShown() then
        local owner = GameTooltip:GetOwner()
        if owner and owner.location and owner:IsShown() then
            ShowRowTooltip(owner)
        end
    end
end

local function UpdateSortButton()
    if not TravelersRecallSortButton then
        return
    end

    if GetDB().sortMode == "name" then
        TravelersRecallSortButton:SetText("A - Z")
    else
        TravelersRecallSortButton:SetText("By Region")
    end
end

local function SetupSearchBox()
    if not TravelersRecallSearchBox then
        return
    end

    local placeholder = TravelersRecallSearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", TravelersRecallSearchBox, "LEFT", 1, 0)
    placeholder:SetText("Search name or region")
    TravelersRecallSearchBox.placeholder = placeholder

    local function UpdatePlaceholder(self)
        if self:GetText() == "" and not self.hasFocus then
            self.placeholder:Show()
        else
            self.placeholder:Hide()
        end
    end

    TravelersRecallSearchBox:SetText("")
    TravelersRecallSearchBox:SetScript("OnTextChanged", function(self)
        TravelersRecall.searchText = string.lower(self:GetText() or "")
        UpdatePlaceholder(self)
        TravelersRecallScrollBar:SetValue(0)
        RefreshNow()
    end)
    TravelersRecallSearchBox:HookScript("OnEditFocusGained", function(self)
        self.hasFocus = true
        UpdatePlaceholder(self)
    end)
    TravelersRecallSearchBox:HookScript("OnEditFocusLost", function(self)
        self.hasFocus = false
        UpdatePlaceholder(self)
    end)
end

local function SetupFilters()
    if TravelersRecallSortButton then
        TravelersRecallSortButton:SetScript("OnClick", function()
            local db = GetDB()
            if db.sortMode == "name" then
                db.sortMode = "region"
            else
                db.sortMode = "name"
            end
            UpdateSortButton()
            TravelersRecallScrollBar:SetValue(0)
            RefreshNow()
        end)
        TravelersRecallSortButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Sort order")
            GameTooltip:AddLine("Switch between grouping by region and a plain A - Z list.", 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end)
        TravelersRecallSortButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    if TravelersRecallReadyOnlyCheck then
        local label = _G[TravelersRecallReadyOnlyCheck:GetName() .. "Text"]
        if label then
            label:SetText("Hide unavailable")
        end
        TravelersRecallReadyOnlyCheck:SetScript("OnClick", function(self)
            GetDB().readyOnly = self:GetChecked() and true or false
            RefreshNow()
        end)
    end
end

-- Runs once the saved variables are loaded.
local function ApplySettings()
    if TravelersRecallReadyOnlyCheck then
        TravelersRecallReadyOnlyCheck:SetChecked(GetDB().readyOnly)
    end
    UpdateSortButton()
    RefreshLocations()
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
            TravelersRecallScrollBar:SetValue(math.max(current - SCROLL_STEP, min))
        else
            TravelersRecallScrollBar:SetValue(math.min(current + SCROLL_STEP, max))
        end
    end)

    local content = CreateFrame("Frame", "TravelersRecallContentFrame", TravelersRecallScrollFrame)
    content:SetWidth(TravelersRecallScrollFrame:GetWidth())
    content:SetHeight(1)
    TravelersRecallScrollFrame:SetScrollChild(content)
end

local function SetupFrame()
    tinsert(UISpecialFrames, "TravelersRecallFrame")

    TravelersRecallFrame:SetScript("OnShow", function()
        RefreshNow()
    end)

    TravelersRecallFrame:SetScript("OnUpdate", function(self, elapsed)
        if needsRefresh then
            RefreshNow()
        end

        self.cooldownTimer = (self.cooldownTimer or 0) + elapsed
        if self.cooldownTimer >= 1 then
            self.cooldownTimer = 0
            if next(TravelersRecall.cooldowns) ~= nil then
                UpdateLocationStates()
            end
        end
    end)
end

TravelersRecall.UI.SendEditBoxCommand = SendEditBoxCommand
TravelersRecall.UI.Toggle = ToggleTravelersRecall
TravelersRecall.UI.RefreshLocations = RefreshLocations
TravelersRecall.UI.RefreshNow = RefreshNow
TravelersRecall.UI.UpdateLocationStates = UpdateLocationStates
TravelersRecall.UI.ApplySettings = ApplySettings
TravelersRecall.UI.CreateMinimapButton = CreateMinimapButton
TravelersRecall.UI.SetupSearchBox = SetupSearchBox
TravelersRecall.UI.SetupScrollFrame = SetupScrollFrame

TravelersRecall.UI.minimapButton = CreateMinimapButton()
SetupScrollFrame()
SetupSearchBox()
SetupFilters()
SetupFrame()
UpdateSortButton()
