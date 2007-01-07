--
-- $Id$
--

-- get global library instances
local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
local T = AceLibrary("Tablet-2.0")
local A = AceLibrary("Abacus-2.0")
local D = AceLibrary("Dewdrop-2.0")

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
    profile = {
        profile_sv_ver   = 1,
        ignoretime       = "6h",           
        checktime        = "30m",
        add_del_wait     = "3s",
        max_add_attempts = 5,
    },
    realm = {
        realm_sv_ver     = 1,
        list             = {},
        add_queue        = {},
    },
}
BeQuiet:RegisterDB("BeQuietDB", "BeQuietDBPC")
BeQuiet:RegisterDefaults("profile", BeQuiet.defaults.profile)
BeQuiet:RegisterDefaults("realm", BeQuiet.defaults.realm)

-- AceConsole setup
BeQuiet.consoleOptions = {
    type = "group",
    handler = BeQuiet,
    args = {
        ignoretime = {
            type = "text",
            name = L["ignoretime"],
            desc = L["set default ignore time"],
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.ignoretime
            end,
            set = function(v)
                BeQuiet.db.profile.ignoretime = v
            end,
            validate = function(v)
                return BeQuiet:duration_to_seconds(v) > 0
            end,
        },
        add_del_wait = {
            type = "text",
            name = L["add_del_wait"],
            desc = L["set time to wait after adding or deleting to check if it worked"],
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.add_del_wait
            end,
            set = function(v)
                BeQuiet.db.profile.add_del_wait = v
            end,
            validate = function(v)
                return BeQuiet:duration_to_seconds(v) > 0
            end,
        },
        max_add_attempts = {
            type = "text",
            name = L["max_add_attempts"],
            desc = L["set number of times to try to add someone who is offline"],
            usage = L["<attempts>"],
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
        checktime = {
            type = "text",
            name = L["checktime"],
            desc = L["set time in between checks for expired entries"],
            usage = L["[#d#h#m#s]"],
            get = function()
                return BeQuiet.db.profile.checktime
            end,
            set = function(v)
                local seconds = BeQuiet:duration_to_seconds(v)
                BeQuiet.db.profile.checktime = v
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
        add = {
            type = "text",
            name = L["add"],
            desc = L["add entry to BQ list"],
            usage = L["<user> [#d#h#m#s]"],
            input = true,
            get = false,
            set = function(name, v)
                BeQuiet:Debug("%s - %s", name, v)
                BeQuiet:add(BeQuiet:initcap(name), v, false)
            end,
        },
        del = {
            type = "text",
            name = L["del"],
            desc = L["remove entry from BQ list"],
            usage = L["<user>"],
            get = false,
            set = function(name)
                BeQuiet:del(name)
            end,
        },
        show = {
            type = "execute",
            name = L["show"],
            desc = L["show BQ list"],
            func = "show",
        },
        list = {
            type = "execute",
            name = L["list"],
            desc = L["show BQ list"],
            func = "show",
        },
        clear = {
            type = "execute",
            name = L["clear"],
            desc = L["clear BQ list"],
            func = "clear",
        },
        scan = {
            type = "execute",
            name = L["scan"],
            desc = L["scan BQ list for queued adds or expired entries"],
            func = function()
                BeQuiet:TriggerEvent("BeQuiet_Check")
            end,
        },
    },
}
BeQuiet:RegisterChatCommand(L["AceConsole-Commands"], BeQuiet.consoleOptions )

-- function BeQuiet:OnInitialize()

    -- SV upgrades go here
    
-- end

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
        return
    end
    self.event_id = self:ScheduleRepeatingEvent("BeQuiet_Check", seconds)

end

function BeQuiet:add(name, duration)
    if( duration == nil ) then
        duration = BeQuiet.db.profile.ignoretime
    end
    local seconds = self:duration_to_seconds(duration)
    if( seconds < 1 ) then
        self:Print(L["invalid duration '%s'"], duration)
        return
    end
    local now = time()
    local untiltime = now + seconds
    local data = {
        name = name,
        now = now,
        duration = duration,
        seconds = seconds,
        untiltime = untiltime,
        attempts = 0
    }
    self:do_add(data)
    
end

function BeQuiet:do_add(data)

    data.attempts = data.attempts + 1
    if( BeQuiet.db.realm.list[data.name] ) then
        if( data.untiltime > BeQuiet.db.realm.list[data.name] ) then
            self:Print(L["attempting to ignore %s"], data.name)
            AddIgnore(data.name)
            self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), data)
        else
            self:Print(L["%s is already on the BQ list until %s (in %s)"], date(L["dateformat"], BeQuiet.db.realm.list[data.name]), A:FormatDurationFull(data.seconds))
        end
    else
        self:Print(L["attempting to ignore %s"], data.name)
        AddIgnore(data.name)
        self:ScheduleEvent("BeQuiet_Check_Add", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), data)
    end

end

function BeQuiet:BeQuiet_Check_Add(data)

    if( self:is_ignored(data.name) ) then
        if( BeQuiet.db.realm.add_queue[data.name] ) then
            self:Debug("successfully added %s from queue - removing from pending", data.name)
            BeQuiet.db.realm.add_queue[data.name] = nil
        end
        if( BeQuiet.db.realm.list[data.name] ) then
            self:Print(L["%s was already on the BQ list; extended until %s (in %s)"], data.name,
                date(L["dateformat"], BeQuiet.db.realm.list[data.name]), A:FormatDurationFull(data.seconds))
        else
            self:Print(L["added %s until %s (in %s)"], data.name,
                date(L["dateformat"], BeQuiet.db.realm.list[data.name]), A:FormatDurationFull(data.seconds))
        end
        BeQuiet.db.realm.list[data.name] = data.untiltime
    else
        if( data.attempts >= BeQuiet.db.profile.max_add_attempts ) then
            self:Print(L["giving up trying to add %s (max attempts exceeded)"], data.name)
            BeQuiet.db.realm.add_queue[data.name] = nil
        elseif( not BeQuiet.db.realm.add_queue[data.name] ) then
            self:Print(L["could not add %s to BQ list (possibly offline?)"], data.name)
            self:Print(L["queueing %s for later addition"], data.name)
            BeQuiet.db.realm.add_queue[data.name] = data
        end
    end
    self:Update()

end

function BeQuiet:del(name)

    if( BeQuiet.db.realm.list[name] ) then
        self:Print(L["attempting to unignore %s"], name)
        DelIgnore(name)
        self:ScheduleEvent("BeQuiet_Check_Del", BeQuiet:duration_to_seconds(BeQuiet.db.profile.add_del_wait), name)
    elseif( BeQuiet.db.realm.add_queue[name] ) then
        self:Print(L["removing %s from add queue"], name)
        BeQuiet.db.realm.add_queue[name] = nil
        self:Update()
    else
        self:Print(L["%s is not on the BQ list"])
    end

end

function BeQuiet:BeQuiet_Check_Del(name)

    if( self:is_ignored(name) ) then
        self:Print(L["could not remove %s from BQ list - will try again later"], name)
    else
        BeQuiet.db.realm.list[name] = nil
        self:Print(L["removed %s"], name)
    end
    self:Update()

end

function BeQuiet:show()

    local now = time()
    local duration
    if( pairs(BeQuiet.db.realm.list) ) then
        self:Print(L["current BQ list:"])
        for name, expire in pairs(BeQuiet.db.realm.list) do
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
    if( pairs(BeQuiet.db.realm.add_queue) ) then
        self:Print(L["current BQ queued adds:"])
        for name, v in pairs(BeQuiet.db.realm.add_queue) do
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
    for name in pairs(BeQuiet.db.realm.list) do
        self:del(name)
    end
    BeQuiet.db.realm.add_queue = BeQuiet.defaults.realm.add_queue
    self:Update()

end

function BeQuiet:BeQuiet_Check()

    self:Print(L["scanning BQ list"])
    local now = time()
    for name, expire in pairs(BeQuiet.db.realm.list) do
        if( now > expire ) then
            self:Print(L["BQ entry for %s has expired"], name)
            self:del(name)
        end
    end
    for name, data in pairs(BeQuiet.db.realm.add_queue) do
        if( data.untiltime < now ) then
            self:Print(L["giving up trying to add %s (expire time exceeded)"], name)
            BeQuiet.db.realm.add_queue[name] = nil
        else
            self:Print(L["attempting to ignore %s (queued from previous failure)"], name)
            self:do_add(data)
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
BeQuiet.hasIcon = "Interface\\Icons\\Spell_Holy_Silence"
BeQuiet.clickableTooltip = true
BeQuiet.defaultPosition = "RIGHT"
BeQuiet.fubarOptions = {
    type = "group",
    handler = BeQuiet,
    args = {
        add = {
            order = 100,
            type = "execute",
            name = L["Add Target"],
            desc = L["Add current target to BQ list with default time"],
            func = "add_target",
        },
        scan = {
            order = 120,
            type = "execute",
            name = L["Scan List"],
            desc = L["scan BQ list for queued adds or expired entries"],
            func = function()
                BeQuiet:TriggerEvent("BeQuiet_Check")
            end,
        },
        clear = {
            order = 130,
            type = "execute",
            name = L["Clear List"],
            desc = L["clear BQ list"],
            func = "clear",
        },
        spacer1 = {
            order = 199,
            type = "header",
        },
        config = {
            order = 200,
            type = "group",
            name = L["Config"],
            desc = L["Addon Configuration Parameters"],
            args = {
                ignoretime = {
                    order = 100,
                    type = "text",
                    name = L["Ignore Time"],
                    desc = L["set default ignore time"],
                    usage = L["[#d#h#m#s]"],
                    get = function()
                        return BeQuiet.db.profile.ignoretime
                    end,
                    set = function(v)
                        BeQuiet.db.profile.ignoretime = v
                    end,
                    validate = function(v)
                        return BeQuiet:duration_to_seconds(v) > 0
                    end,
                },
                checktime = {
                    order = 200,
                    type = "text",
                    name = L["Check Time"],
                    desc = L["set time in between checks for expired entries"],
                    usage = L["[#d#h#m#s]"],
                    get = function()
                        return BeQuiet.db.profile.checktime
                    end,
                    set = function(v)
                        local seconds = BeQuiet:duration_to_seconds(v)
                        BeQuiet.db.profile.checktime = v
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
                max_add_attempts = {
                    order = 300,
                    type = "text",
                    name = L["Max Add Attempts"],
                    desc = L["set number of times to try to add someone who is offline"],
                    usage = L["<attempts>"],
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
                add_del_wait = {
                    order = 400,
                    type = "text",
                    name = L["Add/Delete Delay"],
                    desc = L["set time to wait after adding or deleting to check if it worked"],
                    usage = L["[#d#h#m#s]"],
                    get = function()
                        return BeQuiet.db.profile.add_del_wait
                    end,
                    set = function(v)
                        BeQuiet.db.profile.add_del_wait = v
                    end,
                    validate = function(v)
                        return BeQuiet:duration_to_seconds(v) > 0
                    end,
                },
            },
        },
        spacer2 = {
            order = 999,
            type = "header",
        },
    },
}

function BeQuiet:OnTextUpdate()

    local list_size = 0
    local queue_size = 0
    for k, _ in pairs(BeQuiet.db.realm.list) do
        list_size = list_size + 1
    end
    for k, _ in pairs(BeQuiet.db.realm.add_queue) do
        queue_size = queue_size + 1
    end
    self:SetText(string.format("%d / %d", list_size, queue_size))

end

function BeQuiet:OnMenuRequest()

    local del_added = false
    local list_added = false
    local queue_added = false
    local table = BeQuiet.fubarOptions
    for name, _ in pairs(BeQuiet.db.realm.list) do
        if( not del_added ) then
            table.args.del = {
                order = 110,
                name = L["Delete"],
                type = "group",
                desc = L["Delete from BQ List"],
                args = {},
            }
            del_added = true
        end
        if( not list_added ) then
            table.args.del.args.list = {
                order = 100,
                name = L["List"],
                type = "group",
                desc = L["Delete Ignored Names"],
                args = {}
            }
            list_added = true
        end
        table.args.del.args.list.args[name] = {
            type = "execute",
            name = name,
            desc = string.format(L["Remove %s from BQ list"], name),
            func = function()
                self:del(name)
                self:Update()
            end,
        }
    end
    for name, _ in pairs(BeQuiet.db.realm.add_queue) do
        if( not del_added ) then
            table.args.del = {
                order = 110,
                name = L["Delete"],
                type = "group",
                desc = L["Delete from BQ List"],
                args = {},
            }
            del_added = true
        end
        if( not queue_added ) then
            table.args.del.args.queue = {
                order = 110,
                name = L["Queue"],
                type = "group",
                desc = L["Delete Queued Names"],
                args = {}
            }
            queue_added = true
        end
        table.args.del.args.queue.args[name] = {
            type = "execute",
            name = name,
            desc = string.format(L["Remove %s from BQ queue"], name),
            func = function()
                self:del(name)
                self:Update()
            end,
        }
    end
    D:FeedAceOptionsTable(table)

end

function BeQuiet:OnTooltipUpdate()

    local supercat = T:AddCategory(
        'columns', 4
    )

    -- list
    local list = supercat:AddCategory(
        'text', L["On BQ List"],
        'textR', 0,
        'textG', 1,
        'textB', 0
    )
    local now = time()
    local duration
    local count = 0
    local header = false
    for name, expire in pairs(BeQuiet.db.realm.list) do
        count = count + 1
        duration = expire - now
        if( not header ) then
            list:AddLine(
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
        if( duration > 0 ) then
            list:AddLine(
                'text', name,
                'text2', date(L["dateformat"], expire),
                'text3', A:FormatDurationFull(duration),
                'func', 'del',
                'arg1', self,
                'arg2', name
            )
        else
            list:AddLine(
                'text', name, 
                'text2', date(L["dateformat"], expire),
                'text3', L["(expired)"],
                'func', 'del',
                'arg1', self,
                'arg2', name
            )
        end
    end
    if( count == 0 ) then
        list:AddLine('text', L["no entries"])
    end
    
    -- add queue
    local queue = supercat:AddCategory(
        'text', L["In Queue to be Added"],
        'textR', 0,
        'textG', 1,
        'textB', 0
    )
    count = 0
    header = false
    for name, v in pairs(BeQuiet.db.realm.add_queue) do
        count = count + 1
        if( not header ) then
            queue:AddLine(
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
            queue:AddLine(
                'text', name,
                'text2', date(L["dateformat"], expire),
                'text3', A:FormatDurationFull(duration),
                'text4', v.attempts,
                'func', 'del',
                'arg1', self,
                'arg2', name
            )
        else
            queue:AddLine(
                'text', name,
                'text2',  date(L["dateformat"], expire),
                'text3', L["(expired)"],
                'text4', v.attempts,
                'func', 'del',
                'arg1', self,
                'arg2', name
            )
        end
    end
    if( count == 0 ) then
        queue:AddLine('text', L["no entries"])
    end
    
    -- hint
    T:SetHint(L["Click to add or remove your current target. Shift-Click to re-scan for expired or queued entries"])

end

function BeQuiet:OnClick(button)

    self:Debug("button = " .. button)
    if( button == "LeftButton" ) then
        if( not IsShiftKeyDown() ) then
            self:add_target()
        else
            BeQuiet:TriggerEvent("BeQuiet_Check")
        end
    end

end

function BeQuiet:add_target()

    if( UnitExists("target") ) then
        local name = UnitName("target")
        if( UnitIsPlayer("target") ) then
            if( BeQuiet.db.realm.list[name] ) then
                self:del(name)
            else
                self:add(name)
            end
        else
            self:Print(L["'%s' is not a player"], name)
            return
        end
    end

end

--
-- EOF

