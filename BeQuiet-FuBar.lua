--
-- $Date$ $Revision$
--

-- get global library instances
local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
local T = AceLibrary("Tablet-2.0")
local A = AceLibrary("Abacus-2.0")
local D = AceLibrary("Dewdrop-2.0")

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
            desc = L["Configuration Parameters"],
            args = {
                ignoretime = {
                    order = 100,
                    type = "text",
                    name = L["Ignore Time"],
                    desc = L["set default ignore time"],
                    usage = L["[#M#w#d#h#m#s]"],
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
                    usage = L["[#M#w#d#h#m#s]"],
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
                    usage = L["[#M#w#d#h#m#s]"],
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
                add_popup_menu = {
                    order = 500,
                    type = "toggle",
                    name = L["Add to Pop-up menu"],
                    desc = L["Add BeQuiet to right-click pop-up menu"],
                    get = function() return BeQuiet.db.profile.add_popup_menu end,
                    set = function()
                        if( BeQuiet.db.profile.add_popup_menu ) then
                            BeQuiet:Print(L["removing BeQuiet from right-click popup menu"])
                            BeQuiet:Remove_Popup_Hook()
                        else
                            BeQuiet:Print(L["adding BeQuiet to right-click popup menu"])
                            BeQuiet:Add_Popup_Hook()
                        end
                        BeQuiet.db.profile.add_popup_menu = not BeQuiet.db.profile.add_popup_menu
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
                'text2', date(L["dateformat"], v.untiltime),
                'text3', A:FormatDurationFull(duration),
                'text4', v.attempts,
                'func', 'del',
                'arg1', self,
                'arg2', name
            )
        else
            queue:AddLine(
                'text', name,
                'text2',  date(L["dateformat"], v.untiltime),
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

