TravelersRecall = TravelersRecall or {}
TravelersRecall.Events = TravelersRecall.Events or {}

local function HandleChatMessage(event, message)
    if event ~= "CHAT_MSG_SYSTEM" then
        return
    end

    if string.find(message, "TR_LIST:") then
        local _, _, id, rest = string.find(message, "TR_LIST:(%d+):(.*)")
        if TravelersRecall.Core and TravelersRecall.Core.StoreLocation then
            TravelersRecall.Core.StoreLocation(id, rest)
        end
        return
    end

    if string.find(message, "TR_UNLOCK:") or string.find(message, "TR_LEARN:") then
        local prefix = "TR_UNLOCK:"
        if string.find(message, "TR_LEARN:") then
            prefix = "TR_LEARN:"
        end

        local _, _, id, rest = string.find(message, prefix .. "(%d+):(.*)")
        if TravelersRecall.Core and TravelersRecall.Core.StoreLocation then
            TravelersRecall.Core.StoreLocation(id, rest)
        end
        return
    end

    if string.find(message, "TR_REMOVE:") then
        local _, _, id = string.find(message, "TR_REMOVE:(%d+)")
        if id and TravelersRecall.Core and TravelersRecall.Core.RemoveLocation then
            TravelersRecall.Core.RemoveLocation(id)
        end
        return
    end

    if TravelersRecall.Core and TravelersRecall.Core.HandleCooldownMessage(message) then
        if TravelersRecall.UI and TravelersRecall.UI.UpdateLocationStates then
            TravelersRecall.UI.UpdateLocationStates()
        end
        return
    end

    -- The server writes the new cooldown after teleporting, so ask for it a moment later.
    if string.find(message, "^Traveler's Recall: teleported") then
        if TravelersRecall.Core and TravelersRecall.Core.ScheduleCooldownRequest then
            TravelersRecall.Core.ScheduleCooldownRequest()
        end
    end
end

local function HandleStateChange()
    if TravelersRecall.UI and TravelersRecall.UI.UpdateLocationStates then
        TravelersRecall.UI.UpdateLocationStates()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "CHAT_MSG_SYSTEM" then
        HandleChatMessage(event, arg1)
    elseif event == "ADDON_LOADED" then
        if arg1 == "TravelersRecall" and TravelersRecall.UI and TravelersRecall.UI.ApplySettings then
            TravelersRecall.UI.ApplySettings()
        end
    else
        HandleStateChange()
    end
end)

TravelersRecall.Events.HandleChatMessage = HandleChatMessage
