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
    sv_ver           = 10002,
    announce         = true,
    ignoretime       = "6h",           
    checktime        = 600,            -- 60*10    (10 minutes)
    list             = {},
    size             = 0,
    debug            = false,
    add_del_wait     = 5,
    add_queue        = {},
    max_add_attempts = 5,
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
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.ignoretime
            end,
            set = function(duration)
                BeQuiet.db.profile.ignoretime = duration
            end,
        },
        [L["add_del_wait"]] = {
            type = "text",
            name = L["add_del_wait"],
            desc = L["set time to wait after adding or deleting to check if it worked"],
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.add_del_wait
            end,
            set = function(duration)
                BeQuiet.db.profile.add_del_wait = BeQuiet:duration_to_seconds(duration)
            end,
        },
        [L["max_add_attempts"]] = {
            type = "text",
            name = L["max_add_attempts"],
            desc = L["set number of times to try to add someone who is offline"],
            usage = L["<attempts>"],
            get = function()
                return BeQuiet.db.profile.max_add_attempts
            end,
            set = function(seconds)
                BeQuiet.db.profile.max_add_attempts = tonumber(seconds)
            end,
            validate = function(seconds)
                return string.find(seconds, "^%d+$") and tonumber(seconds) > 0
            end,
        },
        [L["checktime"]] = {
            type = "text",
            name = L["checktime"],
            desc = L["set time in between checks for expired entries in seconds"],
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.checktime
            end,
            set = function(duration)
                BeQuiet.db.profile.checktime = BeQuiet:duration_to_seconds(duration)
                if( BeQuiet.event_id and BeQuiet:IsEventScheduled(BeQuiet.event_id) ) then
                    BeQuiet:CancelScheduledEvent(BeQuiet.event_id)
                    BeQuiet:Debug("scheduling every %d seconds", BeQuiet.db.profile.checktime)
                    BeQuiet.event_id = BeQuiet:ScheduleRepeatingEvent("BeQuiet_Check", BeQuiet.db.profile.checktime) 
                end
            end,
        },
        [L["add"]] = {
            type = "text",
            name = L["add"],
            desc = L["add entry to BQ list"],
            usage = L["<user> [#d#h#m#s]"],
            input = true,
            get = false,
            set = function(name, duration)
                BeQuiet:Debug("%s - %s", name, seconds)
                BeQuiet:add(name, duration, false)
            end,
        },
        [L["del"]] = {
            type = "text",
            name = L["del"],
            desc = L["remove entry from BQ list"],
            usage = L["<user>"],
            get = false,
            set = function(name)
                BeQuiet:del(name)
            end,
        },
        [L["show"]] = {
            type = "execute",
            name = L["show"],
            desc = L["show BQ list"],
            func = "show",
        },
        [L["clear"]] = {
            type = "execute",
            name = L["clear"],
            desc = L["clear BQ list"],
            func = "clear",
        },
        ["dump"] = {
            type = "execute",
            name = "dump",
            desc = "dump profile",
            func = "dump",
        },
    },
}
BeQuiet:RegisterChatCommand(L["AceConsole-Commands"], BeQuiet.consoleOptions )

function BeQuiet:OnInitialize()

    -- SV 10000 -> 10001: new vars add_del_wait, add_queue, max_add_attempts
    if( BeQuiet.db.profile.sv_ver == 10000 ) then
        self:Print(L["upgrading config from SV %d to %d"], 10000, 10001)
        BeQuiet.db.profile.add_del_wait = BeQuiet.defaults.add_del_wait
        BeQuiet.db.profile.add_queue = BeQuiet.defaults.add_queue
        BeQuiet.db.profile.max_add_attempts = BeQuiet.defaults.max_add_attempts
        BeQuiet.db.profile.sv_ver = 10001
    end

    -- SV 10001 -> 10002: convert ignoretime to units suffix
    if( BeQuiet.db.profile.sv_ver == 10001 ) then
        local ignoretime = string.format("%ds", BeQuiet.db.profile.ignoretime);
        BeQuiet.db.profile.ignoretime = ignoretime
        BeQuiet.db.profile.sv_ver = 10002
    end

end

function BeQuiet:OnEnable()

    self.event_id = nil
    
    self:UnregisterAllEvents()
    self:RegisterEvent("BeQuiet_Check")
    self:RegisterEvent("BeQuiet_Check_Add")
    self:RegisterEvent("BeQuiet_Check_Del")
    
    if( BeQuiet.db.profile.debug ) then
        self:SetDebugging(true)
    end

	if( AceLibrary("AceEvent-2.0"):IsFullyInitialized() ) then
		self:AceEvent_FullyInitialized()
	else
		self:RegisterEvent("AceEvent_FullyInitialized")
	end
    
end

function BeQuiet:OnDisable()

    self:TriggerEvent("BeQuiet_Check")
    self.event_id = nil
    self:UnregisterAllEvents()
    
    if( self:IsDebugging() ) then
        BeQuiet.db.profile.debug = true
    end

end

function BeQuiet:AceEvent_FullyInitialized()

    self:Debug("scheduling every %d seconds", BeQuiet.db.profile.checktime)
    self:TriggerEvent("BeQuiet_Check")
    self.event_id = self:ScheduleRepeatingEvent("BeQuiet_Check", BeQuiet.db.profile.checktime)

end

function BeQuiet:add(name, duration, from_queue)
    if( duration == nil ) then
        duration = BeQuiet.db.profile.ignoretime
    end
    local seconds = self:duration_to_seconds(duration)
    local untiltime = time() + seconds
    if( BeQuiet.db.profile.list[name] ) then
        if( untiltime > BeQuiet.db.profile.list[name] ) then
            self:Print(L["attempting to ignore %s"], name)
            AddIgnore(name)
            if( self:is_ignored(name) ) then
                self:Debug("ignored immediately")
            end
            self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet.db.profile.add_del_wait, name, untiltime, false, from_queue)
        else
            self:Print(L["%s is already on the BQ list until %s (in %s)"], date(L["dateformat"], BeQuiet.db.profile.list[name]), A:FormatDurationFull(seconds))
        end
    else
        self:Print(L["attempting to ignore %s"], name)
        AddIgnore(name)
        if( self:is_ignored(name) ) then
            self:Debug("ignored immediately")
        end
        self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet.db.profile.add_del_wait, name, untiltime, true, from_queue)
    end
end

function BeQuiet:BeQuiet_Check_Add(name, untiltime, new, from_queue)

    local seconds = untiltime - time()
    if( self:is_ignored(name) ) then
        if( from_queue) then
            self:Debug("successfully added from queue - removing from pending")
            BeQuiet.db.profile.add_queue[name] = nil
        end
        BeQuiet.db.profile.list[name] = untiltime
        if( new ) then
            BeQuiet.db.profile.size = BeQuiet.db.profile.size + 1
            self:Print(L["added %s until %s (in %s)"], name, date(L["dateformat"], BeQuiet.db.profile.list[name]), A:FormatDurationFull(seconds))
        else
            self:Print(L["%s was already on the BQ list; extended until %s (in %s)"], name, date(L["dateformat"], BeQuiet.db.profile.list[name]), A:FormatDurationFull(seconds))
        end
    else
        if( not from_queue ) then
            self:Print(L["could not add %s to BQ list (possibly offline?)"], name)
            self:Print(L["queueing %s for later addition"], name)
            BeQuiet.db.profile.add_queue[name] = {}
            BeQuiet.db.profile.add_queue[name].untiltime = untiltime
            BeQuiet.db.profile.add_queue[name].attempts = 0
        end
    end

end

function BeQuiet:del(name)

    if( BeQuiet.db.profile.list[name] ) then
        self:Print(L["attempting to unignore %s"], name)
        DelIgnore(name)
        self:ScheduleEvent("BeQuiet_Check_Del", BeQuiet.db.profile.add_del_wait, name)
    else
        self:Print(L["%s is not on the BQ list"])
    end

end

function BeQuiet:BeQuiet_Check_Del(name)

    if( self:is_ignored(name) ) then
        self:Print(L["could not remove %s from BQ list - will try again later"], name)
    else
        BeQuiet.db.profile.list[name] = nil
        BeQuiet.db.profile.size = BeQuiet.db.profile.size - 1
        self:Print(L["removed %s"], name)
    end

end

function BeQuiet:show()

    if( BeQuiet.db.profile.size > 0 ) then
        local now = time()
        local duration
        self:Print(L["current BQ list:"])
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
    else
        self:Print(L["no entries on BQ list"])
    end

end

function BeQuiet:clear()

    local now = time()
    local duration
    self:Print(L["clearing BQ list"])
    for name in pairs(BeQuiet.db.profile.list) do
        self:del(name)
    end
    BeQuiet.db.profile.add_queue = BeQuiet.defaults.add_queue

end

function BeQuiet:BeQuiet_Check()

    self:Debug("checking BQ list for expired entries")
    local now = time()
    for name, expire in pairs(BeQuiet.db.profile.list) do
        if( now > expire ) then
            if( BeQuiet.db.profile.announce ) then
                self:Print(L["BQ entry for %s has expired"], name)
            end
            self:del(name)
        end
    end
    
    self:Debug("checking add queue for missed adds")
    for name, v in pairs(BeQuiet.db.profile.add_queue) do
        v.attempts = v.attempts + 1
        if( v.attempts > BeQuiet.db.profile.max_add_attempts ) then
            self:Print(L["giving up trying to add %s (max attempts exceeded)"], name)
            BeQuiet.db.profile.add_queue[name] = nil
        else
            self:Print(L["attempting to ignore %s (queued from previous failure)"], name)
            self:add(name, v.untiltime, true)
        end
    end

end

function BeQuiet:dump()

    self:Debug("sv_ver = " .. BeQuiet.db.profile.sv_ver)
    self:Debug("ignoretime = " .. BeQuiet.db.profile.ignoretime)
    self:Debug("checktime = " .. BeQuiet.db.profile.checktime)
    self:Debug("add_del_wait = " .. BeQuiet.db.profile.add_del_wait)
    self:Debug("max_add_attempts = " .. BeQuiet.db.profile.max_add_attempts)
    self:Debug("size = " .. BeQuiet.db.profile.size)
    if( BeQuiet.db.profile.announce ) then
        self:Debug("announce = true")
    else
        self:Debug("announce = false")
    end
    if( BeQuiet.db.profile.debug ) then
        self:Debug("debug = true")
    else
        self:Debug("debug = false")
    end
    self:Debug("list:")
    for name, expire in pairs(BeQuiet.db.profile.list) do
        self:Debug("%s - %d", name, expire)
    end
    self:Debug("queued adds:")
    for name, v in pairs(BeQuiet.db.profile.add_queue) do
        self:Debug("%s - %d (%d attempts)", name, v.untiltime, v.attempts)
    end

end

function BeQuiet:is_ignored(name)

    for i = 1, GetNumIgnores() do
        if( string.upper(name) == string.upper(GetIgnoreName(i)) ) then
            return true
        end
    end
    
    return false

end

function BeQuiet:duration_to_seconds(duration)

    local seconds = 0
    self:Debug("duration = %s", duration)
    for num, unit in string.gmatch(duration, "(%d+)([dhms])") do
        self:Debug("found %d %s", num, unit)
        if( unit == "d" ) then
            seconds = seconds + (num*60*60*24)
        elseif( unit == "h" ) then
            seconds = seconds + (num*60*60)
        elseif( unit == "m" ) then
            seconds = seconds + (num*60)
        elseif( unit == "s" ) then
            seconds = seconds + num
        end
        self:Debug("seconds = %d", seconds)
    end
    
    return seconds

end

--
-- EOF

