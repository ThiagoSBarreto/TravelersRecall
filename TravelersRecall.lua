
TravelersRecall = TravelersRecall or {}
TravelersRecall.unlocked = TravelersRecall.unlocked or {}
TravelersRecall.searchText = ""
TravelersRecall.UI = TravelersRecall.UI or {}
TravelersRecall.Core = TravelersRecall.Core or {}
TravelersRecall.Events = TravelersRecall.Events or {}

local function SendEditBoxCommand(command)
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return
    end

    editBox:SetText(command)
    ChatEdit_SendText(editBox)
    editBox:SetText("")
end

TravelersRecall.UI.SendEditBoxCommand = SendEditBoxCommand

ChatFrame_AddMessageEventFilter(
    "CHAT_MSG_SYSTEM",
    function(_, _, msg)
        if string.find(msg, "TR_") then
            return true
        end
    end
)

SLASH_TRAVELERSRECALL1 = "/tr"
SlashCmdList["TRAVELERSRECALL"] = function()
    if TravelersRecall.UI and TravelersRecall.UI.Toggle then
        TravelersRecall.UI.Toggle()
    end
end