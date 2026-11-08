---@type QuestiePopup
local Popup = QuestieSmazakLoader:ImportModule("QuestiePopup")

-------------------------
--Import modules.
-------------------------
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type QuestieNameplate
local QuestieNameplate = QuestieSmazakLoader:ImportModule("QuestieNameplate")
---@type MinimapIcon
local MinimapIcon = QuestieSmazakLoader:ImportModule("MinimapIcon")
---@type QuestieMap
local QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap")
---@type AvailableQuests
local AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
---@type QuestieDBMIntegration
local QuestieDBMIntegration = QuestieSmazakLoader:ImportModule("QuestieDBMIntegration")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

QuestieOptionsEngine.tabs.profiles = { ... }

local selectedDeleteProfile = nil

---Applies the new profile to QuestieSmazak's visuals and to the option controls being shown. AceDB calls this for every
---change of profile. Refreshing a control never runs its setter, so what setters do to apply a value is covered here.
local function _OnProfileChanged()
    if QuestieSmazak.SetIcons then
        QuestieSmazak:SetIcons()
    end
    if QuestieMap and QuestieMap.RescaleIcons then
        QuestieMap:RescaleIcons()
        QuestieMap:RescaleTownsfolkIcons()
    end
    -- Resets draw available quests again a few frames later, which has to use the new profile's level filters
    AvailableQuests.ResetLevelRequirementCache()
    if QuestieQuest and QuestieQuest.SmoothReset then
        QuestieQuest:SmoothReset()
    end
    if QuestieTracker and QuestieTracker.Update then
        QuestieTracker:Update()
        QuestieTracker:UpdateFormatting()
    end
    if QuestieNameplate and QuestieNameplate.RedrawIcons then
        QuestieNameplate:RedrawIcons()
        QuestieNameplate:RedrawFrameIcon()
    end
    MinimapIcon.RefreshProfile()
    QuestieDBMIntegration:ChangeZoomLevel(QuestieSmazak.db.profile.DBMHUDZoom)
    QuestieDBMIntegration:ChangeRefreshRate(QuestieSmazak.db.profile.DBMHUDRefresh)
    QuestieOptionsEngine:RefreshStates()
end

---Returns existing profiles PLUS AceDB standard stand-in presets
---@return table<string, string>
local function _GetChooseProfiles()
    local profiles = {}

    for _, name in ipairs(QuestieSmazak.db:GetProfiles({})) do
        profiles[name] = name
    end

    local keys = QuestieSmazak.db.keys
    local localizedClass = UnitClass("player")

    profiles["Default"] = l10n("Default")

    if keys.char then
        profiles[keys.char] = keys.char
    end

    if keys.class then
        profiles[keys.class] = localizedClass or keys.class
    end

    if keys.realm then
        profiles[keys.realm] = keys.realm
    end

    return profiles
end

---Returns only profiles that ACTUALLY exist in the database, excluding the current profile
---@return table<string, string>
local function _GetExistingNonActiveProfiles()
    local profiles = {}
    local current = QuestieSmazak.db:GetCurrentProfile()
    for _, name in ipairs(QuestieSmazak.db:GetProfiles({})) do
        if name ~= current then
            profiles[name] = name
        end
    end
    return profiles
end

---Checks whether any non-active saved profile exists
---@return boolean
local function _HasExistingNonActiveProfiles()
    return next(_GetExistingNonActiveProfiles()) ~= nil
end

function QuestieOptionsEngine.tabs.profiles:Initialize()
    -- Register AceDB callbacks to keep profile display and dropdowns synced
    if QuestieSmazak.db and QuestieSmazak.db.RegisterCallback then
        QuestieSmazak.db.RegisterCallback(QuestieOptionsEngine.tabs.profiles, "OnProfileChanged", _OnProfileChanged)
        QuestieSmazak.db.RegisterCallback(QuestieOptionsEngine.tabs.profiles, "OnProfileCopied", _OnProfileChanged)
        QuestieSmazak.db.RegisterCallback(QuestieOptionsEngine.tabs.profiles, "OnProfileReset", _OnProfileChanged)
    end

    return {
        title = "Profiles",
        subtitle = "Manage Profiles",
        order = 7,
        icon = 136047,
        items = {
            intro_text = {
                type = "text",
                order = 0.5,
                description = "You can change the active database profile, so you can have different settings for every character.",
                descriptionAlign = "CENTER",
                --descriptionSize = 11,
                width = "full",
            },
            current_profile_header = {
                type = "text",
                order = 1,
                width = 0.6,
                titleAlign = "RIGHT",
                get = function()
                    local current = QuestieSmazak.db:GetCurrentProfile() or "Default"
                    return l10n("Current Profile: %s", QuestieSmazak:Colorize(current, "yellow"))
                end,
            },
            reset_profile = {
                type = "button",
                order = 2,
                title = "Reset Profile",
                btnLabel = "Reset Profile",
                tooltip = "Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over.",
                width = 0.39,
                align = "LEFT",
                func = function()
                    Popup.Show("QUESTIE_PROFILE_RESET_CONFIRM")
                end,
            },
            choose_desc = {
                type = "text",
                order = 3,
                title = "",
                description = "You can either create a new profile by entering a name in the editbox, or choose one of the already existing profiles.",
                width = "full",
                newline = true,
            },
            new_profile = {
                type = "textbox",
                order = 4,
                title = "New",
                tooltip = "Create a new empty profile.",
                width = "half",
                get = function()
                    return ""
                end,
                set = function(val)
                    val = strtrim(val or "")
                    if val == "" then
                        return
                    end
                    if strlenutf8(val) > 50 then
                        QuestieSmazak.Error("Profile names cannot be longer than 50 characters")
                        return
                    end
                    selectedDeleteProfile = nil
                    QuestieSmazak.db:SetProfile(val)
                end,
                textBoxCharLimit = 50,
            },
            existing_profiles = {
                type = "dropdown",
                order = 5,
                title = "Existing Profiles",
                tooltip = "Select one of your currently available profiles.",
                width = "half",
                options = _GetChooseProfiles,
                get = function()
                    return QuestieSmazak.db:GetCurrentProfile()
                end,
                set = function(val)
                    if val and val ~= QuestieSmazak.db:GetCurrentProfile() then
                        if selectedDeleteProfile == val then
                            selectedDeleteProfile = nil
                        end
                        QuestieSmazak.db:SetProfile(val)
                    end
                end,
            },
            copy_divider = {
                type = "divider",
                order = 6,
                title = "Copy From",
                width = "full",
            },
            copy_desc = {
                type = "text",
                order = 7,
                title = "",
                description = "Copy the settings from one existing profile into the currently active profile.",
                width = "full",
            },
            copy_profile = {
                type = "dropdown",
                order = 8,
                title = "Copy From",
                tooltip = "Copy the settings from one existing profile into the currently active profile.",
                width = "half",
                options = _GetExistingNonActiveProfiles,
                enabled = _HasExistingNonActiveProfiles,
                get = function()
                    return nil
                end,
                set = function(val)
                    if val then
                        QuestieSmazak.db:CopyProfile(val)
                    end
                end,
            },
            delete_divider = {
                type = "divider",
                order = 9,
                title = "Delete a Profile",
                width = "full",
            },
            delete_desc = {
                type = "text",
                order = 10,
                title = "",
                description = "Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file.",
                width = "full",
            },
            delete_dropdown = {
                type = "dropdown",
                order = 11,
                title = "Profiles",
                tooltip = "Select a profile to delete from the database.",
                width = "half",
                options = _GetExistingNonActiveProfiles,
                enabled = _HasExistingNonActiveProfiles,
                get = function()
                    if selectedDeleteProfile and _GetExistingNonActiveProfiles()[selectedDeleteProfile] then
                        return selectedDeleteProfile
                    end
                    selectedDeleteProfile = nil
                    return nil
                end,
                set = function(val)
                    selectedDeleteProfile = val
                end,
            },
            delete_button = {
                type = "button",
                order = 12,
                title = "Delete",
                btnLabel = "Delete",
                tooltip = "Deletes the selected profile from the database.",
                width = "half",
                align = "LEFT",
                enabled = function()
                    return selectedDeleteProfile ~= nil and _GetExistingNonActiveProfiles()[selectedDeleteProfile] ~= nil
                end,
                func = function()
                    if selectedDeleteProfile then
                        Popup.Show("QUESTIE_PROFILE_DELETE_CONFIRM")
                    end
                end,
            },
        },
    }
end

Popup.Dialogs["QUESTIE_PROFILE_RESET_CONFIRM"] = {
    text = "",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        QuestieSmazak.db:ResetProfile()
    end,
    OnShow = function(self)
        local current = QuestieSmazak.db:GetCurrentProfile() or ""
        self.Text:SetText(l10n("Are you sure you want to reset the '%s' profile to default settings?", current))
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:Raise()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

Popup.Dialogs["QUESTIE_PROFILE_DELETE_CONFIRM"] = {
    text = "",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if selectedDeleteProfile and selectedDeleteProfile ~= QuestieSmazak.db:GetCurrentProfile() then
            local toDelete = selectedDeleteProfile
            selectedDeleteProfile = nil
            QuestieSmazak.db:DeleteProfile(toDelete, true)
            QuestieOptionsEngine:RefreshStates()
        end
    end,
    OnShow = function(self)
        self.Text:SetText(l10n("Are you sure you want to delete the selected profile?"))
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:Raise()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}