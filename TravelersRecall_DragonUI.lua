TravelersRecall = TravelersRecall or {}
TravelersRecall.UI = TravelersRecall.UI or {}

-- Optional skin: when DragonUI is loaded, dress the window in its metal frame chrome.
-- Without DragonUI (or with a DragonUI version lacking these helpers) the default look is kept.

local function GetForeverUI()
    if not IsAddOnLoaded("DragonUI") then
        return nil
    end

    local foreverUI = type(DragonUI) == "table" and DragonUI.ForeverUI
    if type(foreverUI) ~= "table" then
        return nil
    end

    if type(foreverUI.SkinWindow) ~= "function"
        or type(foreverUI.CreateInnerFrame) ~= "function"
        or type(foreverUI.SkinButton) ~= "function" then
        return nil
    end

    return foreverUI
end

local function ApplyDragonUISkin()
    local foreverUI = GetForeverUI()
    local frame = TravelersRecallFrame
    if not foreverUI or not frame or frame.dragonUISkinned then
        return
    end

    local ok = pcall(foreverUI.SkinWindow, frame, { title = "Traveler's Recall" })
    if not ok then
        return
    end
    frame.dragonUISkinned = true

    frame:SetBackdrop(nil)
    if TravelersRecallFrameHeader then
        TravelersRecallFrameHeader:Hide()
    end
    if frame.legacyTitle then
        frame.legacyTitle:Hide()
    end
    if frame.legacyCloseButton then
        frame.legacyCloseButton:Hide()
    end

    local inset = foreverUI.CreateInnerFrame(frame)
    inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -86)
    inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 40)
    inset:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.listInset = inset

    TravelersRecallSearchBox:ClearAllPoints()
    TravelersRecallSearchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -38)

    TravelersRecallSortButton:ClearAllPoints()
    TravelersRecallSortButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -37)
    pcall(foreverUI.SkinButton, TravelersRecallSortButton)

    TravelersRecallReadyOnlyCheck:ClearAllPoints()
    TravelersRecallReadyOnlyCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
    if type(foreverUI.SkinCheckButton) == "function" then
        pcall(foreverUI.SkinCheckButton, TravelersRecallReadyOnlyCheck)
    end

    TravelersRecallScrollFrame:ClearAllPoints()
    TravelersRecallScrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, -8)
    TravelersRecallScrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -30, 8)
    TravelersRecallScrollFrame:SetFrameLevel(inset:GetFrameLevel() + 1)

    TravelersRecallScrollBar:ClearAllPoints()
    TravelersRecallScrollBar:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -8, -24)
    TravelersRecallScrollBar:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -8, 24)
    TravelersRecallScrollBar:SetFrameLevel(inset:GetFrameLevel() + 1)

    TravelersRecallStatusFrame:ClearAllPoints()
    TravelersRecallStatusFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 14)

    if TravelersRecall.UI.RefreshLocations then
        TravelersRecall.UI.RefreshLocations()
    end
end

local skinFrame = CreateFrame("Frame")
skinFrame:RegisterEvent("PLAYER_LOGIN")
skinFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    ApplyDragonUISkin()
end)

TravelersRecall.UI.ApplyDragonUISkin = ApplyDragonUISkin
