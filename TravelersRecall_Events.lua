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
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(_, event, message)
    HandleChatMessage(event, message)
end)

TravelersRecall.Events.HandleChatMessage = HandleChatMessage
