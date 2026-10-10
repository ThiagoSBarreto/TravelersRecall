TravelersRecall = TravelersRecall or {}
TravelersRecall.UI = TravelersRecall.UI or {}
TravelersRecall.searchText = TravelersRecall.searchText or ""

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

    local locations = {}
    for id, data in pairs(TravelersRecall.unlocked) do
        if TravelersRecall.Core and TravelersRecall.Core.MatchesSearch(data and data.name) then
            table.insert(locations, { id = id, data = data })
        end
    end

    table.sort(locations, function(left, right)
        return left.data.name == "Teleport to Friend" and right.data.name ~= "Teleport to Friend"
    end)

    local visibleIndex = 0
    for _, location in ipairs(locations) do
        local id = location.id
        local data = location.data
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

        button:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -((visibleIndex - 1) * 26))
        button:SetText(data.name)
        button.icon:SetTexture(data.icon)
        button:SetScript("OnClick", function()
            SendEditBoxCommand(".tr teleport " .. id)
        end)
        button:Show()
    end

    content:SetHeight(visibleIndex * 26)

    local maxScroll = math.max(0, (visibleIndex * 26) - 370)
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
