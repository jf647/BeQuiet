--
-- $Id: Core.lua 4156 2006-11-11 03:06:04Z james $
--

-- get global library instances
local C = AceLibrary("Crayon-2.0")
local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
local A = AceLibrary("Abacus-2.0")

-- setup addon
BeQuiet = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",
    "AceDebug-2.0",
    "AceConsole-2.0",
    "AceDB-2.0"
)

-- setup profile
BeQuiet.defaults = {
    announce   = true,
    ignoretime = 86400,          -- 60*60*24 (1 day)
    checktime  = 600,            -- 60*10    (10 minutes)
    list       = {},
}
BeQuiet:RegisterDB("BeQuietDB", "BeQuietDBPC")
BeQuiet:RegisterDefaults("profile", BeQuiet.defaults)

-- setup slash commands
BeQuiet.consoleOptions = {
    type = "group",
    handler = BeQuiet,
    args = {
        [L["announce"]] = {
            type = "toggle",
            name = L["announce"],
            desc = L["announce periodic purges in the chat frame"],
            get = function() return BeQuiet.db.profile.announce end,
            set = function(v)
                BeQuiet.db.profile.announce = not BeQuiet.db.profile.announce
            end,
        },
        [L["ignoretime"]] = {
            type = "text",
            name = L["ignoretime"],
            desc = L["set default ignore time in seconds"],
            usage = L["<seconds>"],
            get = function()
                return BeQuiet.db.profile.ignoretime
            end,
            set = function(seconds)
                BeQuiet.db.profile.ignoretime = tonumber(seconds)
            end,
            validate = function(seconds)
                return string.find(seconds, "^%d+$") and tonumber(seconds) > 0
            end,
        },
        [L["checktime"]] = {
            type = "text",
            name = L["checktime"],
            desc = L["set time in between checks for expired entries in seconds"],
            usage = L["<seconds>"],
            get = function()
                return BeQuiet.db.profile.checktime
            end,
            set = function(seconds)
                BeQuiet.db.profile.checktime = tonumber(seconds)
                if( BeQuiet.event_id and BeQuiet:IsEventScheduled(BeQuiet.event_id) ) then
                    BeQuiet:CancelScheduledEvent(BeQuiet.event_id)
                    BeQuiet:Debug("scheduling every %d seconds", BeQuiet.db.profile.checktime)
                    BeQuiet.event_id = BeQuiet:ScheduleRepeatingEvent("BeQuiet_Check", BeQuiet.db.profile.checktime) 
                end
            end,
            validate = function(seconds)
                return string.find(seconds, "^%d+$") and tonumber(seconds) > 0
            end,
        },
        [L["add"]] = {
            type = "text",
            name = L["add"],
            desc = L["add entry to bequiet list"],
            usage = L["<user> [seconds]"],
            input = true,
            get = false,
            set = function(name, seconds)
                BeQuiet:Debug("%s - %s", name, seconds)
                BeQuiet:add(name, seconds)
            end,
            validate = function(name, seconds)
                if( seconds ~= nil ) then
                    return string.find(seconds, "^%d+$") and tonumber(seconds) > 0
                else
                    return true
                end
            end,
        },
        [L["del"]] = {
            type = "text",
            name = L["del"],
            desc = L["remove entry from bequiet list"],
            usage = L["<user>"],
            get = false,
            set = function(name)
                BeQuiet:del(name)
            end,
        },
        [L["show"]] = {
            type = "execute",
            name = L["show"],
            desc = L["show bequiet list"],
            func = "show",
        },
        [L["clear"]] = {
            type = "execute",
            name = L["clear"],
            desc = L["clear bequiet list"],
            func = "clear",
        },
    },
}
BeQuiet:RegisterChatCommand(L["AceConsole-Commands"], BeQuiet.consoleOptions )

function BeQuiet:OnInitialize()

end

function BeQuiet:OnEnable()

    self.event_id = nil
    
    self:UnregisterAllEvents()
    self:RegisterEvent("BeQuiet_Check")

	if AceLibrary("AceEvent-2.0"):IsFullyInitialized() then
		self:AceEvent_FullyInitialized()
	else
		self:RegisterEvent("AceEvent_FullyInitialized")
	end
    
end

function BeQuiet:OnDisable()

    self.event_id = nil

end

function BeQuiet:AceEvent_FullyInitialized()

    self:Debug("scheduling every %d seconds", BeQuiet.db.profile.checktime)
    self.event_id = self:ScheduleRepeatingEvent("BeQuiet_Check", BeQuiet.db.profile.checktime)

end

function BeQuiet:add(name, seconds)
    --- XXX: check if they're already on the list before adding them
    AddIgnore(name)
    if( seconds == nil ) then
        seconds = BeQuiet.db.profile.ignoretime
    end
    BeQuiet.db.profile.list[name] = time() + seconds
    self:Print(L["added %s until %s (in %s)"], name, date(L["dateformat"], BeQuiet.db.profile.list[name]), A:FormatDurationFull(seconds))
end

function BeQuiet:del(name)

    if( BeQuiet.db.profile.list[name] ) then
        --- XXX: need to defer removal if they aren't online
        DelIgnore(name)
        BeQuiet.db.profile.list[name] = nil
        self:Print(L["removed %s"], name)
    else
        self:Print(L["%s is not on the BQ list"])
    end

end

function BeQuiet:show()

    local now = time()
    local duration
    self:Print(L["current list:"])
    for name, expire in pairs(BeQuiet.db.profile.list) do
        if( expire ~= nil ) then 
            duration = expire - now
            if( duration > 0 ) then
                self:Print(L["%s - %s (in %s)"], name, date(L["dateformat"], expire), A:FormatDurationFull(duration))
            else
                self:Print(L["%s - %s (expired)"], name, date(L["dateformat"], expire))
            end
        end
    end

end

function BeQuiet:clear()

    local now = time()
    local duration
    self:Print(L["clearing list"])
    for name in pairs(BeQuiet.db.profile.list) do
        self:del(name)
    end

end

function BeQuiet:BeQuiet_Check()

    self:Debug("checking list for expiries")
    local now = time()
    for name, expire in pairs(BeQuiet.db.profile.list) do
        if( now > expire ) then
            if( BeQuiet.db.profile.announce ) then
                self:Print(L["be quiet for %s has expired"], name)
            end
            self:del(name)
        end
    end

end

--
-- EOF

