---@type Tutorial
local Tutorial = QuestieSmazakLoader:ImportModule("Tutorial")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

function Tutorial.AutoRejectInBattlegroundsFrame()
    local baseFrame = CreateFrame("Frame", "QuestieSmazakTutorialAutoRejectInBattlegrounds", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    baseFrame:SetSize(420, 170)
    baseFrame:SetPoint("CENTER", 0, 50)
    baseFrame:SetFrameStrata("HIGH")
    baseFrame:EnableMouse(true)
    baseFrame:SetMovable(true)
    baseFrame:RegisterForDrag("LeftButton")
    baseFrame:SetScript("OnDragStart", baseFrame.StartMoving)
    baseFrame:SetScript("OnDragStop", baseFrame.StopMovingOrSizing)
    baseFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    baseFrame:SetBackdropColor(0, 0, 0, 1)
    baseFrame:SetBackdropBorderColor(1, 1, 1, 1)

    local titleText = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetText(l10n("Welcome to QuestieSmazak"))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 16)
    titleText:SetPoint("TOP", 0, -10)

    local customText = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customText:SetText(
        l10n("QuestieSmazak can automatically reject quests shared to you\nwhile you are in a battleground.\n\n\nDo you want to activate this?")
    )
    customText:SetPoint("TOP", 0, -35)

    local noButton = CreateFrame("Button", nil, baseFrame, "UIPanelButtonTemplate")
    noButton:SetText(NO)
    noButton:SetSize(100, 24)
    noButton:SetPoint("BOTTOMLEFT", 60, 15)
    noButton:SetScript("OnClick", function()
        QuestieSmazak.db.profile.autoAccept.rejectSharedInBattleground = false
        QuestieSmazak.db.profile.tutorialRejectInBattlegroundsDone = true
        baseFrame:Hide()
    end)

    local yesButton = CreateFrame("Button", nil, baseFrame, "UIPanelButtonTemplate")
    yesButton:SetText(YES)
    yesButton:SetSize(100, 24)
    yesButton:SetPoint("BOTTOMRIGHT", -60, 15)
    yesButton:SetScript("OnClick", function()
        QuestieSmazak.db.profile.autoAccept.rejectSharedInBattleground = true
        QuestieSmazak.db.profile.tutorialRejectInBattlegroundsDone = true
        baseFrame:Hide()
    end)
end
