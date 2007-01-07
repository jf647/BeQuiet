--
-- $Id$
--

-- get global library instances
local C = AceLibrary("Crayon-2.0")
local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
local T = AceLibrary("Tablet-2.0")
local A = AceLibrary("Abacus-2.0")

-- setup addon
BeQuiet = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",
    "AceDebug-2.0",
    "AceConsole-2.0",
    "AceDB-2.0",
    "FuBarPlugin-2.0"
)

-- setup profile
BeQuiet.defaults = {
    sv_ver           = 10005,
    ignoretime       = "6h",           
    checktime        = "30m",
    add_del_wait     = "5s",
    max_add_attempts = 5,
    list             = {},
    add_queue        = {},
}
BeQuiet:RegisterDB("BeQuietDB", "BeQuietDBPC")
BeQuiet:RegisterDefaults("profile", BeQuiet.defaults)

-- setup slash commands
BeQuiet.consoleOptions = {
    type = "group",
    handler = BeQuiet,
    args = {
        [L["add"]] = {
            type = "text",
            cmdName = L["add"],
            guiName = L["add"],
            desc = L["add entry to BQ list"],
            order = 10,
            usage = L["<user> [#d#h#m#s]"],
            input = true,
            get = false,
            set = function(name, duration)
                BeQuiet:Debug("%s - %s", name, duration)
                BeQuiet:add(BeQuiet:initcap(name), duration, false)
            end,
            guiHidden = true,
        },
        [L["del"]] = {
            type = "text",
            cmdName = L["del"],
            guiName = L["del"],
            desc = L["remove entry from BQ list"],
            order = 20,
            usage = L["<user>"],
            get = false,
            set = function(name)
                BeQuiet:del(name)
            end,
            guiHidden = true,
        },
        [L["show"]] = {
            type = "execute",
            cmdName = L["show"],
            guiName = L["show"],
            desc = L["show BQ list"],
            order = 30,
            func = "show",
            guiHidden = true,
        },
        [L["list"]] = {
            type = "execute",
            cmdName = L["list"],
            guiName = L["list"],
            desc = L["show BQ list"],
            order = 40,
            func = "show",
            guiHidden = true,
        },
        ["header1"] = {
            type = "header",
            order = 100,
        },
        [L["clear"]] = {
            type = "execute",
            cmdName = L["clear"],
            guiName = L["Clear List"],
            desc = L["clear BQ list"],
            order = 110,
            func = "clear",
        },
        [L["scan"]] = {
            type = "execute",
            cmdName = L["scan"],
            guiName = L["Scan List"],
            desc = L["scan BQ list for queued adds or expired entries"],
            order = 120,
            func = function()
                BeQuiet:TriggerEvent("BeQuiet_Check")
            end,
        },
        ["header2"] = {
            type = "header",
            order = 200,
        },
        [L["ignoretime"]] = {
            type = "text",
            cmdName = L["ignoretime"],
            guiName = L["Default Ignore Time"],
            desc = L["set default ignore time"],
            usage = L["[#d#h#m#s]"],
            order = 210,
            get = function()
                return BeQuiet.db.profile.ignoretime
            end,
            set = function(duration)
                BeQuiet.db.profile.ignoretime = duration
            end,
            validate = function(v)
                return BeQuiet:duration_to_seconds(v) > 0
            end,
        },
        [L["checktime"]] = {
            type = "text",
            cmdName = L["checktime"],
            guiName = L["Check Time"],
            desc = L["set time in between checks for expired entries"],
            usage = L["[#d#h#m#s]"],
            order = 210,
            get = function()
                return BeQuiet.db.profile.checktime
            end,
            set = function(duration)
                BeQuiet.db.profile.checktime = duration
                local seconds = BeQuiet:duration_to_seconds(BeQuiet.db.profile.checktime)
                if( BeQuiet.event_id and BeQuiet:IsEventScheduled(BeQuiet.event_id) ) then
                    BeQuiet:CancelScheduledEvent(BeQuiet.event_id)
                    BeQuiet:Debug("scheduling every %d seconds", seconds)
                    BeQuiet.event_id = BeQuiet:ScheduleRepeatingEvent("BeQuiet_Check", seconds) 
                end
            end,
            validate = function(v)
                return BeQuiet:duration_to_seconds(v) > 0
            end,
        },
        [L["add_del_wait"]] = {
            type = "text",
            cmdName = L["add_del_wait"],
            guiName = L["Add/Delete Delay"],
            desc = L["set time to wait after adding or deleting to check if it worked"],
            usage = L["[#d#h#m#s]"],
            order = 220,
            get = function()
                return BeQuiet.db.profile.add_del_wait
            end,
            set = function(duration)
                BeQuiet.db.profile.add_del_wait = duration
            end,
            validate = function(v)
                return BeQuiet:duration_to_seconds(v) > 0
            end,
        },
        [L["max_add_attempts"]] = {
            type = "text",
            cmdName = L["max_add_attempts"],
            guiName = L["Max Add Attempts"],
            desc = L["set number of times to try to add someone who is offline"],
            usage = L["<attempts>"],
            order = 230,
            get = function()
                return BeQuiet.db.profile.max_add_attempts
            end,
            set = function(v)
                BeQuiet.db.profile.max_add_attempts = tonumber(v)
            end,
            validate = function(v)
                return string.find(v, "^%d+$") and tonumber(v) > 0
            end,
        },
    },
}
BeQuiet:RegisterChatCommand(L["AceConsole-Commands"], BeQuiet.consoleOptions )

-- setup FuBar
BeQuiet.OnMenuRequest = BeQuiet.consoleOptions
BeQuiet.hasIcon = "Interface\\Icons\\Spell_Holy_Silence"

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
        local ignoretime = BeQuiet.db.profile.ignoretime .. "s"
        BeQuiet.db.profile.ignoretime = ignoretime
        BeQuiet.db.profile.sv_ver = 10002
    end
    
    -- SV 10002 -> 10003: remove size and debug
    if( BeQuiet.db.profile.sv_ver == 10002 ) then
        BeQuiet.db.profile.size = nil
        BeQuiet.db.profile.debug = nil
        BeQuiet.db.profile.sv_ver = 10003
    end

    -- SV 10003 -> 10004: convert add_del_wait to units suffix
    if( BeQuiet.db.profile.sv_ver == 10003 ) then
        local add_del_wait = BeQuiet.db.profile.add_del_wait .. "s"
        BeQuiet.db.profile.ignoretime = add_del_wait
        BeQuiet.db.profile.sv_ver = 10004
    end

    -- SV 10004 -> 10005: convert checktime to units suffix
    if( BeQuiet.db.profile.sv_ver == 10004 ) then
        local checktime = BeQuiet.db.profile.checktime .. "s"
        BeQuiet.db.profile.checktime = checktime
        BeQuiet.db.profile.sv_ver = 10005
    end

    
end

function BeQuiet:OnEnable()

    self.event_id = nil
    
    self:UnregisterAllEvents()
    self:RegisterEvent("BeQuiet_Check")
    self:RegisterEvent("BeQuiet_Check_Add")
    self:RegisterEvent("BeQuiet_Check_Del")
    
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
    
end

function BeQuiet:AceEvent_FullyInitialized()

    self:Debug("scheduling every %d seconds", BeQuiet.db.profile.checktime)
    self:TriggerEvent("BeQuiet_Check")
    local seconds = BeQuiet:duration_to_seconds(BeQuiet.db.profile.checktime)
    if( seconds < 1 ) then
        self:Print(L["invalid checktime '%s' - regular scans are disabled"], BeQuiet.db.profile.checktime)
    end
    self.event_id = self:ScheduleRepeatingEvent("BeQuiet_Check", seconds)

end

function BeQuiet:add(name, duration, from_queue)
    if( duration == nil ) then
        duration = BeQuiet.db.profile.ignoretime
    end
    local seconds = self:duration_to_seconds(duration)
    if( seconds < 1 ) then
        self:Print(L["invalid duration '%s'"], duration)
        return
    end
    local untiltime = time() + seconds
    if( BeQuiet.db.profile.list[name] ) then
        if( untiltime > BeQuiet.db.profile.list[name] ) then
            self:Print(L["attempting to ignore %s"], name)
            AddIgnore(name)
            if( self:is_ignored(name) ) then
                self:Debug("ignored immediately")
            end
            self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), name, untiltime, false, from_queue)
        else
            self:Print(L["%s is already on the BQ list until %s (in %s)"], date(L["dateformat"], BeQuiet.db.profile.list[name]), A:FormatDurationFull(seconds))
        end
    else
        self:Print(L["attempting to ignore %s"], name)
        AddIgnore(name)
        if( self:is_ignored(name) ) then
            self:Debug("ignored immediately")
        end
        self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), name, untiltime, true, from_queue)
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
    self:Update()

end

function BeQuiet:del(name)

    if( BeQuiet.db.profile.list[name] ) then
        self:Print(L["attempting to unignore %s"], name)
        DelIgnore(name)
        self:ScheduleEvent("BeQuiet_Check_Del", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), name)
    elseif( BeQuiet.db.profile.add_queue[name] ) then
        self:Print(L["removing %s from add queue"], name)
        BeQuiet.db.profile.add_queue[name] = nil
    else
        self:Print(L["%s is not on the BQ list"])
    end

end

function BeQuiet:BeQuiet_Check_Del(name)

    if( self:is_ignored(name) ) then
        self:Print(L["could not remove %s from BQ list - will try again later"], name)
    else
        BeQuiet.db.profile.list[name] = nil
        self:Print(L["removed %s"], name)
    end
    self:Update()

end

function BeQuiet:show()

    local now = time()
    local duration
    if( pairs(BeQuiet.db.profile.list) ) then
        self:Print(L["current BQ list:"])
        for name, expire in pairs(BeQuiet.db.profile.list) do
            if( expire ~= nil ) then 
                duration = expire - now
                if( duration > 0 ) then
                    self:Print(L["   %s - %s (in %s)"], name, date(L["dateformat"], expire), A:FormatDurationFull(duration))
                else
                    self:Print(L["   %s - %s (expired)"], name, date(L["dateformat"], expire))
                end
            end
        end
    else
        self:Print(L["no entries on BQ list"])
    end
    if( pairs(BeQuiet.db.profile.add_queue) ) then
        self:Print(L["current BQ queued adds:"])
        for name, v in pairs(BeQuiet.db.profile.add_queue) do
            duration = v.untiltime - now
            if( duration > 0 ) then
                self:Print(L["   %s - %s (in %s) - %d attempts"], name, date(L["dateformat"], v.untiltime), A:FormatDurationFull(duration), v.attempts)
            else
                self:Print(L["   %s - %s (expired) - %d attempts"], name, date(L["dateformat"], v.untiltime), v.attempts)
            end
        end
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
    self:Update()

end

function BeQuiet:BeQuiet_Check()

    self:Debug("checking BQ list for expired entries")
    local now = time()
    for name, expire in pairs(BeQuiet.db.profile.list) do
        if( now > expire ) then
            self:Print(L["BQ entry for %s has expired"], name)
            self:del(name)
        end
    end
    
    self:Debug("checking add queue for missed adds")
    for name, v in pairs(BeQuiet.db.profile.add_queue) do
        v.attempts = v.attempts + 1
        if( v.attempts > BeQuiet.db.profile.max_add_attempts ) then
            self:Print(L["giving up trying to add %s (max attempts exceeded)"], name)
            BeQuiet.db.profile.add_queue[name] = nil
        elseif( v.untiltime < now ) then
            self:Print(L["giving up trying to add %s (expire time exceeded)"], name)
            BeQuiet.db.profile.add_queue[name] = nil
        else
            self:Print(L["attempting to ignore %s (queued from previous failure)"], name)
            self:add(name, v.untiltime, true)
        end
    end
    self:Update()

end

function BeQuiet:is_ignored(name)

    for i = 1, GetNumIgnores() do
        if( name == GetIgnoreName(i) ) then
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

function BeQuiet:initcap(name)

    return strupper(strsub(name,1,1)) .. strlower(strsub(name,2))

end

-- FuBar specific stuff
function BeQuiet:OnTextUpdate()

    local list_size = 0
    local queue_size = 0
    for k, _ in pairs(BeQuiet.db.profile.list) do
        list_size = list_size + 1
    end
    for k, _ in pairs(BeQuiet.db.profile.add_queue) do
        queue_size = queue_size + 1
    end
    self:SetText(string.format("%d / %d", list_size, queue_size))

end

function BeQuiet:OnTooltipUpdate()

    local cat = T:AddCategory(
        'columns', 4,
        'textR', 0,
        'textG', 1,
        'textB', 0,
        'text2R', 0,
        'text2G', 1,
        'text2B', 0,
        'text3R', 0,
        'text3G', 1,
        'text3B', 0,
        'text4R', 0,
        'text4G', 1,
        'text4B', 0
    )

    -- list
    local now = time()
    local duration
    local header = false
    for name, expire in pairs(BeQuiet.db.profile.list) do
        if( not header ) then
            cat:AddLine(
                'text', L["On BQ List"],
                'textR', 1,
                'textG', 1,
                'textB', 1
            )
            cat:AddLine(
                'text', L["Name"],
                'textR', 1,
                'textG', 1,
                'textB', 1,
                'text2', L["Until"],
                'text2R', 1,
                'text2G', 1,
                'text2B', 1,
                'text3', L["In"],
                'text3R', 1,
                'text3G', 1,
                'text3B', 1
            )
            header = true
        end
        if( expire ~= nil ) then 
            duration = expire - now
            if( duration > 0 ) then
                cat:AddLine('text', name, 'text2',  date(L["dateformat"], expire), 'text3', A:FormatDurationFull(duration))
            else
                cat:AddLine('text', name, 'text2',  date(L["dateformat"], expire), 'text3', L["(expired)"])
            end
        end
    end

    -- add queue
    header = false
    for name, v in pairs(BeQuiet.db.profile.add_queue) do
        if( not header ) then
            cat:AddLine(
                'text', L["In BQ Add Queue"],
                'textR', 1,
                'textG', 1,
                'textB', 1
            )
            cat:AddLine(
                'text', L["Name"],
                'textR', 1,
                'textG', 1,
                'textB', 1,
                'text2', L["Until"],
                'text2R', 1,
                'text2G', 1,
                'text2B', 1,
                'text3', L["In"],
                'text3R', 1,
                'text3G', 1,
                'text3B', 1,
                'text4', L["Attempts"],
                'text4R', 1,
                'text4G', 1,
                'text4B', 1
            )
            header = true
        end
        duration = v.untiltime - now
        if( duration > 0 ) then
            cat:AddLine('text', name, 'text2',  date(L["dateformat"], expire), 'text3', A:FormatDurationFull(duration), 'text4', v.attempts)
        else
            cat:AddLine('text', name, 'text2',  date(L["dateformat"], expire), 'text3', L["(expired)"], 'text4', v.attempts)
        end
    end

end

--
-- EOF

