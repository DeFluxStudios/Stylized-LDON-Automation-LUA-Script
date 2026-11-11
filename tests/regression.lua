-- Run from the repository root with Lua 5.1 or LuaJIT: lua tests\regression.lua
local sourceFile = 'LDON_Triune.lua'
assert(loadfile(sourceFile))
local file = assert(io.open(sourceFile, 'r'))
local source = file:read('*a')
file:close()

local function section(first, following)
    local start = assert(source:find(first, 1, true), first)
    local finish = assert(source:find(following, start + #first, true), following)
    return source:sub(start, finish - 1)
end

local function run(env, code)
    local chunk = assert(loadstring(code))
    setfenv(chunk, env)
    return chunk()
end

local function definition(env, name, following)
    local code = section('local function ' .. name .. '(', following)
    run(env, (code:gsub('^local function', 'function', 1)))
end

local function contains(list, text)
    for _, value in ipairs(list) do
        if value:find(text, 1, true) then return true end
    end
    return false
end

local function environment()
    local e = setmetatable({
        commands = {}, messages = {}, points = {},
        zone = 392, homeHubZone = 30, open = true,
        labels = { 'Random', 'Single Boss', 'Mob count', 'Collection', 'Rescue' },
        assigned = false, completed = false, dialogue = '',
        missionTypeIndex = 3, hardMode = true, active = false, runnerStartPending = false,
        campaignInitialized = false, campaignLegIndex = 1,
        campaignPlan = { { hubZone = 392, count = 1, missionTypeIndex = 3 } },
        campaignCompleted = {}, stats = {}, failureStreak = 0,
        doorId = 7, doorDistance = 8, doorName = 'MineDoor', groupSize = 0,
        MAGUS_NAMES_BY_ZONE = {}, travelReady = true,
    }, { __index = _G })
    run(e, (section('local HUBS =', '-- Campaign defaults'):gsub('local ([%w_]+) =', '%1 =')))
    run(e, (section('local missionOptions =', 'local CAMPAIGN_COUNTS ='):gsub('local (%w+) =', '%1 =')))
    run(e, (section('local ASSIGNMENT_CAMP_KEYWORDS =', 'local function hubFromAssignment')
        :gsub('^local ', '', 1)))
    run(e, (section('local MAGUS_DESTINATIONS =', 'local function travelToCamp')
        :gsub('^local ', '', 1)))
    e.echo = function(message) e.messages[#e.messages + 1] = message end
    e.zoneId = function() return e.zone end
    e.zoneShortName = function()
        return ({ [30] = 'everfrost', [392] = 'nro', [393] = 'sro', [413] = 'innothule',
            [65] = 'guktop', [57] = 'lfaydark', [54] = 'gfaydark', [68] = 'butcher' })[e.zone] or 'bazaar'
    end
    e.assignmentState = function() return e.assigned, e.completed, e.dialogue, '' end
    e.saveSettings = function() e.saved = true; return true end
    e.stopSwarmPull = function() end
    e.breakInvisibilityForInteraction = function() return true end
    e.navToSpawn = function() return true end
    e.navToLocation = function(y, x, z, arrival, timeout, ignoreArrivalZ)
        e.points[#e.points + 1] = { y, x, z, arrival, timeout, ignoreArrivalZ }
        if e.navMovesDoor then e.doorDistance = 12 end
        if e.navDropsDoor then e.doorId = 0 end
        return not e.navFails
    end
    e.distanceTo = function() return e.cryptDistance or 30 end
    e.moveToRoutePoint = function(y, x, before)
        e.directPoint = { y, x, before }
        if e.directZone then e.zone = e.directZone end
        return not e.directFails
    end
    e.playRecordedPath = function() e.recordingUsed = true; return false end
    e.waitForZoneChange = function() return not e.noZoneChange end
    e.useMagus = function(destination)
        e.magusDestination = destination
        if e.magusFails then return false end
        for id, name in pairs(e.MAGUS_DESTINATIONS) do
            if name == destination then e.zone = id; break end
        end
        return true
    end
    e.configureGroupTravel = function() e.travelReady = true; return true end
    e.handleFailure = function(message) error(message) end
    local window = {
        Open = function() return e.open end,
    }
    window.Child = function(name)
        if name == 'AdvRqst_TypeCombobox' then
            return { List = function(index)
                return function()
                    if e.listErrorAt == index then error('list unavailable') end
                    return e.labels[index]
                end
            end }
        end
        return { Enabled = function() return true end }
    end
    local group = setmetatable({ Leader = { Name = function() return 'Tester' end } },
        { __call = function() return e.groupSize end })
    e.mq = {
        cmd = function(command)
            assert(not e.inStartCallback, 'Start callback must not execute game commands')
            e.commands[#e.commands + 1] = command
            if command == '/windowstate AdventureRequestWnd open' and not e.blockOpen then
                if e.deferWindowOpen then e.windowOpening = true else e.open = true end
            end
            if command:find('AdvRqst_AcceptButton leftmouseup', 1, true) then e.assigned = true end
        end,
        cmdf = function(format, ...) e.mq.cmd(string.format(format, ...)) end,
        doevents = function() end,
        delay = function()
            assert(not e.inStartCallback, 'Start callback must not delay')
            e.delayCount = (e.delayCount or 0) + 1
            if e.windowOpening then e.open, e.windowOpening = true, false end
        end,
        TLO = {
            Window = function() return window end,
            Group = group,
            Me = {
                CleanName = function() return 'Tester' end,
                AltAbility = function() return function() return true end end,
                Y = function() return 2697.71 end,
                X = function() return -4686.63 end,
            },
            Plugin = function() return { IsLoaded = function() return true end } end,
            Spawn = function() return { ID = function() return 1 end } end,
            DoorTarget = {
                ID = function() return e.doorId end,
                Distance = function() return e.doorDistance end,
                Name = function() return e.doorName end,
                Y = function() return 2774.88 end,
                X = function() return -4723.56 end,
            },
        },
    }
    definition(e, 'hubFromAssignment', 'local function campaignMissionType')
    definition(e, 'campaignLeg', 'local function nextCampaignLeg')
    definition(e, 'campaignMissionType', '-- Saved per-character settings')
    definition(e, 'nextCampaignLeg', '-- Lets the runner start')
    definition(e, 'selectHomeHub', '\nselectHomeHub()')
    definition(e, 'resolveHomeHub', 'local ASSIGNMENT_CAMP_KEYWORDS')
    definition(e, 'refreshMissionOptions', 'local function validateController')
    definition(e, 'requestTask', 'local MAGUS_NAMES_BY_ZONE')
    definition(e, 'travelToCamp', 'local function clickSwitch')
    definition(e, 'travelAcrossZones', 'local function clickDoor')
    definition(e, 'clickSwitch', 'local function enterTask')
    definition(e, 'enterTask', 'local function waitUntilSafeToExit')
    definition(e, 'validateTravelSetup', 'local function beginCampaign')
    definition(e, 'beginCampaign', '-- Starts the runner from any zone')
    definition(e, 'startRunner', '-- Walks or ports the group')
    definition(e, 'finishCampaign', 'local function recordCampaignCompletion')
    definition(e, 'returnToHub', '-- Adventure assignment detection')
    definition(e, 'command', "\nmq.unbind('/ldon')")
    run(e, (section('local groupRoles = {', 'local active = false'):gsub('^local ', '', 1)))
    run(e, (section('local function groupNames()', '-- MQ2Nav helpers'):gsub('^local function', 'function', 1)))
    if #source > 0 then definition(e, 'validateController', 'local function configureGroupTravel') end
    run(e, section('function groupRoles.sendGroupEntry(', '-- Validate required movement'))
    e.advPathLoaded = function() return true end
    run(e, (section('local ZONE_CAMPS =', 'local function waitForCondition'):gsub('^local ', '', 1)))
    return e
end

local count = 0
local function test(name, fn)
    fn(environment())
    count = count + 1
    print('PASS ' .. name)
end

local function shrinkEnvironment(e)
    assert(loadfile('ldon_shrink.lua'))
    e.mainAssistName = 'Tester'
    e.entryPositionZone = 0
    e.shrinkOnEntry, e.shrinkAttemptZone = false, 0
    e.active, e.zone = true, 238
    e.clock, e.height, e.ready, e.owned = 0, 6, true, {}
    e.mq.gettime = function() return e.clock end
    e.mq.doevents = function() end
    e.mq.delay = function() e.clock = e.clock + 250 end
    e.mq.TLO.Zone = { ID = function() return e.zone end }
    e.mq.TLO.Lua = { Script = function() return { Status = function() return e.triuneStatus or 'RUNNING' end } end }
    e.mq.TLO.MacroQuest = { GameState = function() return 'INGAME' end }
    e.mq.TLO.Me.Combat = function() return false end
    e.mq.TLO.Me.Dead = function() return false end
    e.mq.TLO.Me.Height = function() return e.height end
    e.mq.TLO.Me.Z = function() return 0 end
    e.mq.TLO.Me.Casting = function() return nil end
    e.mq.TLO.Me.ItemReady = function() return function() return e.ready end end
    e.targetId = 42
    e.mq.TLO.Me.ID = function() return 1 end
    e.mq.TLO.Target = { ID = function() return e.targetId end }
    e.mq.TLO.Group.Member = function()
        return { Name = function() return 'OtherBox' end }
    end
    e.mq.TLO.FindItem = function(name)
        return {
            ID = function() return e.owned[name] and 123 or 0 end,
            Name = function() return e.owned[name] end,
        }
    end
    local cmd = e.mq.cmd
    e.mq.cmd = function(command)
        cmd(command)
        if command == '/target myself' and not e.selfTargetFails then e.targetId = 1 end
        if command == '/target id 42' then e.targetId = 42 end
        if command:find('/useitem', 1, true) and not e.clickFails then e.height = 4 end
    end
    local chunk = assert(loadfile('ldon_shrink.lua'))
    local helperEnv = setmetatable({
        require = function(name) assert(name == 'mq'); return e.mq end,
        print = e.echo,
    }, { __index = _G })
    setfenv(chunk, helperEnv)
    e.shrink = chunk('ldon_shrink')
    e.require = function(name) assert(name == 'ldon_shrink'); return e.shrink end
    e.luaFileExists = function() return true end
    e.ensureTriune = function() return true end
    e.startLongBuffs = function() end
    e.startSwarmPull = function() end
    definition(e, 'validateController', 'local function configureGroupTravel')
    definition(e, 'shrinkGroupOnEntry', 'local function configureGroupCombat')
    definition(e, 'configureGroupCombat', 'local function monitorCombatPosture')
end

test('shrink option defaults off and leaves combat setup unchanged', function(e)
    shrinkEnvironment(e)
    assert(e.configureGroupCombat())
    assert(not contains(e.commands, '/useitem'))
    assert(not contains(e.commands, '/lua run ldon_shrink'))
    assert(contains(e.commands, '/ac run'))
end)

test('gukd clears both zone-in points before TAC and Swarm start, once per entry', function(e)
    shrinkEnvironment(e)
    e.zoneShortName = function() return 'gukd' end
    e.startSwarmPull = function()
        assert(#e.points == 2 and contains(e.commands, '/ac run'))
        e.swarmStarted = true
    end
    assert(e.configureGroupCombat())
    assert(e.points[1][1] == 140.38 and e.points[1][2] == -790.08 and e.points[1][3] == -25.96)
    assert(e.points[2][1] == 151.44 and e.points[2][2] == -754.05 and e.points[2][3] == -25.96)
    assert(e.swarmStarted and e.entryPositionZone == e.zone)
    assert(e.configureGroupCombat() and #e.points == 2)
    e.entryPositionZone = 0
    e.points = {}
    assert(e.configureGroupCombat() and #e.points == 2)
end)

test('gukd failed waypoint, cancellation or zoning never starts combat', function()
    for _, failure in ipairs({'nav', 'cancel', 'zone'}) do
        local e = environment()
        shrinkEnvironment(e)
        e.zoneShortName = function() return 'gukd' end
        e.navToLocation = function()
            if failure == 'cancel' then e.active = false end
            if failure == 'zone' then e.zone = 393 end
            return failure ~= 'nav'
        end
        assert(not e.configureGroupCombat())
        assert(not contains(e.commands, '/ac run'))
        assert(e.entryPositionZone == 0)
    end
end)

test('other dungeons and completed gukd missions skip zone-in repositioning', function(e)
    shrinkEnvironment(e)
    assert(e.configureGroupCombat() and #e.points == 0)
    e.zoneShortName = function() return 'gukd' end
    e.completed = true
    assert(e.configureGroupCombat() and #e.points == 0)
end)

test('regular and tiered shrink items each qualify for one self-targeted click', function(e)
    shrinkEnvironment(e)
    for _, name in ipairs({
        'Wand of Imperceptibility', 'Bracelet of the Shadow Hive',
        'Shimmering Bauble of Trickery',
    }) do
        for _, suffix in ipairs({ '', ' (Legendary)', ' (Epic)' }) do
            e.owned, e.commands, e.height = { [name] = name .. suffix }, {}, 6
            assert(e.shrink(238))
            assert(e.commands[1] == '/target myself')
            assert(e.commands[2] == '/useitem "' .. name .. suffix .. '"')
            assert(e.commands[3] == '/target id 42' and #e.commands == 3)
        end
    end
end)

test('group shrink runs before TAC and is not repeated on same-zone resume', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize = true, 1
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.configureGroupCombat())
    local click, runIndex
    for index, cmd in ipairs(e.commands) do
        if cmd:find('/useitem', 1, true) then click = index end
        if cmd == '/ac run' then runIndex = index end
    end
    assert(click and runIndex and click < runIndex and e.clock >= 27000)
    assert(contains(e.commands, '/ac net OtherBox /lua run ldon_shrink 238'))
    e.commands = {}
    assert(e.configureGroupCombat())
    assert(not contains(e.commands, '/useitem'))
    assert(not contains(e.commands, '/lua run ldon_shrink'))
    e.zone, e.height = 392, 6
    assert(e.configureGroupCombat())
    assert(contains(e.commands, '/useitem'))
end)

test('missing or unready shrink item reports and continues TAC', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry = true
    assert(e.configureGroupCombat())
    assert(contains(e.messages, 'No supported carried shrink item is ready'))
    assert(contains(e.commands, '/ac run'))
    e.owned['Wand of Imperceptibility'], e.ready = 'Wand of Imperceptibility', false
    assert(not e.shrink(238))
    assert(not contains(e.commands, '/useitem'))
end)

test('unconfirmed shrink stops after one bounded attempt and continues TAC', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.clickFails = true, true
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.configureGroupCombat())
    assert(e.clock == 10000)
    assert(contains(e.messages, 'No size decrease confirmed'))
    assert(contains(e.commands, '/ac run'))
end)

test('shrink refuses wrong zone and active casting even in completed adventure', function(e)
    shrinkEnvironment(e)
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(not e.shrink(999) and e.clock == 15000)
    e.mq.TLO.Me.Casting = function() return 'Spell' end
    assert(not e.shrink(238))
    e.shrinkOnEntry, e.completed = true, true
    assert(e.configureGroupCombat())
    assert(not contains(e.commands, '/useitem'))
end)

test('shrink covers camps, travel and dungeon zones once per entry while active', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize = true, 1
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    for _, zone in ipairs({392, 408, 393, 413, 65, 238, 393}) do
        e.zone, e.height, e.commands = zone, 6, {}
        assert(e.shrinkGroupOnEntry())
        assert(contains(e.commands, '/useitem'))
        assert(contains(e.commands, '/ac net OtherBox /lua run ldon_shrink ' .. zone))
        e.commands = {}
        assert(e.shrinkGroupOnEntry())
        assert(#e.commands == 0)
        e.active = false
        assert(not e.shrinkGroupOnEntry() and #e.commands == 0)
        e.active = true
        assert(e.shrinkGroupOnEntry() and #e.commands == 0)
    end
end)

test('new-zone navigation waits for shrink before issuing nav', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.zone = true, 392
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    definition(e, 'navToLocation', 'local function navToSpawn')
    e.waitForNavigation = function() return false end
    assert(not e.navToLocation(1, 2, 3))
    local click, nav
    for i, cmd in ipairs(e.commands) do
        if cmd:find('/useitem', 1, true) then click = i end
        if cmd:find('/nav loc', 1, true) then nav = i end
    end
    assert(click and nav and click < nav)
end)

test('remote helper waits for arrival and verifies a delayed shrink cast', function(e)
    shrinkEnvironment(e)
    e.zone, e.clickFails = 392, true
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    e.mq.TLO.Me.Casting = function()
        if contains(e.commands, '/useitem') and e.clock < 2000 then return 'Shrink' end
    end
    e.mq.delay = function()
        e.clock = e.clock + 250
        if e.clock >= 1000 then e.zone = 238 end
        if e.clock >= 2000 then e.height = 4 end
    end
    assert(e.shrink(238))
    assert(e.clock == 2000 and contains(e.commands, '/target id 42'))
end)

test('combat and dead characters never click shrink items', function(e)
    shrinkEnvironment(e)
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    e.mq.TLO.Me.Combat = function() return true end
    assert(not e.shrink(238))
    e.mq.TLO.Me.Combat = function() return false end
    e.mq.TLO.Me.Dead = function() return true end
    assert(not e.shrink(238))
    assert(not contains(e.commands, '/useitem'))
end)

test('shrink never uses an item when self targeting fails', function(e)
    shrinkEnvironment(e)
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    e.selfTargetFails = true
    assert(not e.shrink(238))
    assert(not contains(e.commands, '/useitem'))
    assert(contains(e.messages, 'Could not confirm self target'))
end)

test('missing helper reports the problem but still enables TAC', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry = true
    e.luaFileExists = function() return false end
    assert(e.configureGroupCombat())
    assert(contains(e.messages, 'is missing'))
    assert(contains(e.commands, '/ac run'))
end)

test('cancelling group preparation never enables TAC', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize = true, 1
    e.mq.doevents = function() e.active = false end
    assert(not e.configureGroupCombat())
    assert(not contains(e.commands, '/ac run'))
end)

test('shrink option loads only a saved boolean and persists with settings', function(e)
    shrinkEnvironment(e)
    definition(e, 'loadSettings', '\nloadSettings()')
    e.loadfile = function() return function() return { shrinkOnEntry = true } end end
    e.loadSettings()
    assert(e.shrinkOnEntry == true)
    e.loadfile = function() return function() return { shrinkOnEntry = 'false' } end end
    e.loadSettings()
    assert(e.shrinkOnEntry == true)
    e.loadfile = function() return function() return { shrinkOnEntry = false } end end
    e.loadSettings()
    assert(e.shrinkOnEntry == false)
    e.swarmPullCount, e.swarmPullRadius, e.retryLimit = 3, 150, 2
    e.settingsPath = 'mock-settings'
    local written
    e.io = { open = function()
        return { write = function(_, text) written = text end, close = function() end }
    end }
    definition(e, 'saveSettings', 'local function loadSettings')
    assert(e.saveSettings())
    assert(written:find('shrinkOnEntry = false', 1, true))
end)

test('camp comes from entrance wording when the theme is not named', function(e)
    assert(e.hubFromAssignment('Enter through a barricaded door in Upper Guk.') == 393)
    assert(e.hubFromAssignment('The entrance is in Innothule Swamp.') == 393)
    assert(e.hubFromAssignment('Keep an eye out for a crypt in Lesser Faydark, that will be your way in.') == 68)
    assert(e.hubFromAssignment('You can enter through a cave in Southern Ro.') == 408)
    assert(e.hubFromAssignment('Enter through a quicksand pit in Northern Ro.') == 392)
    assert(e.hubFromAssignment('through a snowy mine in Everfrost Peaks.') == 30)
    assert(e.hubFromAssignment('nothing useful here') == nil)
end)

test('all five choices exist before any interaction; mob count is default', function(e)
    assert(#e.missionOptions == 5 and e.missionTypeIndex == 3)
    for index, label in ipairs(e.labels) do
        assert(e.missionOptions[index].index == index and e.missionOptions[index].label == label)
    end
    assert(#e.commands == 0)
end)

test('each mission type selects its live index before requesting', function()
    for index = 1, 5 do
        local e = environment()
        assert(e.requestTask(e.HUBS[392], index))
        assert(contains(e.commands, 'AdvRqst_TypeCombobox listselect ' .. index))
        assert(contains(e.commands, 'AdvRqst_RequestButton leftmouseup'))
    end
end)

test('a longer client list still offers only the first five choices', function(e)
    for index = 6, 13 do e.labels[index] = 'Extra ' .. index end
    assert(e.refreshMissionOptions() and #e.missionOptions == 5)
    assert(not e.requestTask(e.HUBS[392], 7))
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('empty list retains choices and sends no request', function(e)
    local previous = e.missionOptions
    e.labels = {}
    assert(not e.requestTask(e.HUBS[392], 3))
    assert(e.missionOptions == previous)
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('partial list read error does not publish partial choices or request', function(e)
    local previous = e.missionOptions
    e.listErrorAt = 3
    assert(not e.requestTask(e.HUBS[392], 3))
    assert(e.missionOptions == previous)
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('missing selected type is rejected, not substituted', function(e)
    e.labels = { 'Random', 'Single Boss' }
    assert(not e.requestTask(e.HUBS[392], 5))
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('changed live index mapping is rejected', function(e)
    e.labels[2], e.labels[3] = e.labels[3], e.labels[2]
    assert(not e.requestTask(e.HUBS[392], 3))
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('closed request window refresh preserves startup choices', function(e)
    e.open = false
    assert(not e.refreshMissionOptions())
    assert(#e.missionOptions == 5)
end)

test('snowy mine follows exact approach and entrance then clicks expected door', function(e)
    e.zone, e.homeHubZone = 30, 30
    assert(e.enterTask(30, 'The safest entrance we could locate is through a snowy mine in Everfrost Peaks.'))
    assert(#e.points == 3)
    assert(e.points[1][1] == 2698.93 and e.points[1][2] == -4693.65 and e.points[1][3] == -95.64)
    assert(e.points[2][1] == 2751.72 and e.points[2][2] == -4645.75 and e.points[2][3] == -84.40)
    assert(e.points[3][1] == 2772.53 and e.points[3][2] == -4727.61 and e.points[3][3] == -97.37)
    assert(e.points[1][4] == 3 and e.points[2][4] == 3 and e.points[3][4] == 10)
    assert(not e.points[1][6] and not e.points[2][6] and not e.points[3][6])
    assert(contains(e.commands, '/doortarget id 7') and contains(e.commands, '/click left door'))
end)

test('portal remains a separate route', function(e)
    e.zone, e.homeHubZone = 30, 30
    e.doorName = 'MIRPORTAL700'
    assert(e.enterTask(30, 'Enter the glimmering portal in Everfrost Peaks.'))
    assert(#e.points == 2)
    assert(e.points[1][1] == -974.81 and e.points[1][2] == -5435.43 and e.points[1][3] == 153.51)
    assert(e.points[2][1] == -829.68 and e.points[2][2] == -5459.88 and e.points[2][3] == 192.99)
    assert(e.points[1][6] == true and not e.points[2][6])
    assert(contains(e.commands, '/click left door'))
end)

test('portal first waypoint accepts screenshot floor height using real arrival check', function(e)
    e.zone, e.homeHubZone = 30, 30
    definition(e, 'navToLocation', 'local function navToSpawn')
    local nav = e.navToLocation
    local calls = 0
    e.waitForNavigation = function() return true end
    e.navToLocation = function(y, x, z, ...)
        calls = calls + 1
        e.mq.TLO.Me.Y = function() return calls == 1 and -975.04 or y end
        e.mq.TLO.Me.X = function() return calls == 1 and -5435.57 or x end
        e.mq.TLO.Me.Z = function() return calls == 1 and 149.50 or z end
        return nav(y, x, z, ...)
    end
    assert(e.enterTask(30, 'glimmering portal'))
    assert(calls == 2 and contains(e.commands, '/click left door'))
    assert(not contains(e.commands, '/moveto loc'))
end)

test('portal first waypoint still rejects a horizontal miss using real arrival check', function(e)
    e.zone, e.homeHubZone = 30, 30
    definition(e, 'navToLocation', 'local function navToSpawn')
    e.mq.TLO.Me.Y = function() return -978.81 end
    e.mq.TLO.Me.X = function() return -5435.43 end
    e.mq.TLO.Me.Z = function() return 149.50 end
    e.waitForNavigation = function() return true end
    assert(not e.enterTask(30, 'glimmering portal'))
    assert(contains(e.messages, 'Nav stopped 4 units'))
    assert(not contains(e.commands, '/click left door'))
    assert(not contains(e.commands, '/moveto loc'))
end)

test('restored portal refuses missing or distant nearby objects without clicking', function()
    for _, door in ipairs({ {0, 0}, {7, 41}, {7, 20} }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorId, e.doorDistance = 30, 30, door[1], door[2]
        e.noZoneChange = true
        e.mq.TLO.Me.Z = function() return 192.99 end
        assert(not e.enterTask(30, 'glimmering portal'))
        assert(not contains(e.commands, '/click left door'))
        assert(contains(e.commands, '/moveto loc') == (door[2] == 20))
        assert(not e.recordingUsed)
    end
end)

test('mine walks from screenshot mesh stop and only clicks after verified arrival', function(e)
    e.zone, e.homeHubZone, e.active = 30, 30, true
    local distance = math.sqrt(9.44 ^ 2 + 14.53 ^ 2 + 21.18 ^ 2)
    e.distance3DTo = function() return distance end
    e.mq.doevents = function() end
    e.navToLocation = function(y) return y ~= 2772.53 end
    e.mq.delay = function() distance = 8 end
    assert(e.enterTask(30, 'snowy mine'))
    assert(contains(e.commands, '/moveto loc 2772.53 -4727.61'))
    assert(contains(e.commands, '/moveto off'))
    assert(contains(e.commands, '/click left door'))
end)

test('mine fallback cannot accept a stuck or distant mesh stop', function(e)
    e.zone, e.homeHubZone, e.active = 30, 30, true
    e.mq.doevents = function() end
    e.navToLocation = function(y) return y ~= 2772.53 end
    e.distance3DTo = function() return 27 end
    assert(not e.enterTask(30, 'snowy mine'))
    assert(contains(e.commands, '/moveto off') and not contains(e.commands, '/click left door'))
    e.commands = {}
    e.distance3DTo = function() return 36 end
    assert(not e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/moveto loc'))
end)

test('mine walking stops on cancellation or zoning without clicking', function()
    for _, cancel in ipairs({true, false}) do
        local e = environment()
        e.zone, e.homeHubZone, e.active = 30, 30, true
        e.navToLocation = function(y) return y ~= 2772.53 end
        e.distance3DTo = function() return 27 end
        e.mq.doevents = function()
            if cancel then e.active = false else e.zone = 232 end
        end
        assert(e.enterTask(30, 'snowy mine') == not cancel)
        assert(contains(e.commands, '/moveto off'))
        assert(not contains(e.commands, '/click left door'))
    end
end)

test('Everfrost portal restores nearby-door interaction without a named override', function(e)
    e.zone, e.homeHubZone, e.doorName = 30, 30, 'EFWALL1'
    assert(e.enterTask(30, 'glimmering portal of magic'))
    assert(contains(e.commands, '/doortarget id 7'))
    assert(not contains(e.commands, '/doortarget MIRPORTAL700'))
    assert(contains(e.commands, '/click left door'))
end)

test('North Ro targets verified quicksand portal without imported approach', function(e)
    e.zone, e.homeHubZone = 392, 392
    e.doorName = 'TAKPORTAL700'
    assert(e.enterTask(392, 'quicksand pit in Northern Ro'))
    assert(#e.points == 0)
    assert(contains(e.commands, '/doortarget TAKPORTAL700'))
    assert(contains(e.commands, '/click left door'))
    assert(not contains(e.commands, '/doortarget id 3'))
end)

test('Rujark restores Scout Miigle approach and targets local RUJPORTAL701', function(e)
    e.zone, e.homeHubZone, e.doorName = 393, 408, 'RUJPORTAL701'
    e.navToSpawn = function(name)
        assert(name == 'Scout_Miigle')
        e.scoutReached = true
        return true
    end
    assert(e.enterTask(393, 'Through a cave'))
    assert(e.scoutReached and #e.points == 0)
    assert(contains(e.commands, '/doortarget RUJPORTAL701'))
    assert(contains(e.commands, '/click left door'))
end)

test('Rujark crosses from Commonlands before approaching the Scout', function(e)
    e.zone, e.homeHubZone, e.doorName = 408, 408, 'RUJPORTAL701'
    e.navToSpawn = function(name)
        assert(e.zone == 393 and name == 'Scout_Miigle')
        return true
    end
    assert(e.enterTask(408, 'Through a cave in Southern Ro'))
    assert(e.magusDestination == 'South Ro' and #e.points == 0)
end)

test('Rujark fails safely if Scout approach or actual portal is unavailable', function(e)
    e.zone, e.homeHubZone, e.doorName = 393, 408, 'RUJPORTAL701'
    e.navToSpawn = function() return false end
    assert(not e.enterTask(393, 'Through a cave'))
    assert(not contains(e.commands, '/click left door'))
    e.navToSpawn = function() return true end
    e.doorName = 'OBJ_ZONEBOX'
    assert(not e.enterTask(393, 'Through a cave'))
    assert(not contains(e.commands, '/click left door'))
end)

test('Guktop barricaded door uses GKPORTAL701 and recorded approach', function(e)
    e.zone, e.homeHubZone, e.doorName = 65, 393, 'GKPORTAL701'
    assert(e.enterTask(65, 'barricaded door'))
    assert(#e.points == 1 and e.points[1][1] == 441.77)
    assert(e.points[1][2] == 228.63 and e.points[1][3] == -9.13)
    assert(contains(e.commands, '/doortarget GKPORTAL701'))
end)

test('Triune tree-trunk approach is retained instead of replacing it with live-server coordinates', function(e)
    e.zone, e.homeHubZone = 413, 393
    e.active = true
    e.distance3DTo = function() return 2 end
    e.doorName = 'GKPORTAL700'
    local cmd = e.mq.cmd
    e.mq.cmd = function(c) cmd(c); if c == '/click left door' then e.zone = 229 end end
    assert(e.enterTask(413, 'rotting tree trunk'))
    assert(#e.points == 1 and e.points[1][1] == 1389.12)
end)

test('Lesser Faydark restores original switch selection without approach overrides', function()
    for _, case in ipairs({
        { 'unearthed grave', 10 }, { 'Find a crypt', 7 },
        { 'Search the graveyard and find a crypt', 10 }, { 'other directions', 7 },
    }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorId = 57, 68, case[2]
        assert(e.enterTask(57, case[1]))
        assert(#e.points == 0)
        assert(contains(e.commands, '/doortarget id ' .. case[2]))
        assert(contains(e.commands, '/click left door'))
    end
end)

test('planar arrival still rejects horizontal misses and default arrival checks height', function(e)
    definition(e, 'navToLocation', 'local function navToSpawn')
    e.mq.TLO.Me.Y = function() return -756.27 end
    e.mq.TLO.Me.X = function() return 3838.85 end
    e.mq.TLO.Me.Z = function() return 7.20 end
    e.waitForNavigation = function() return true end
    assert(not e.navToLocation(-760.27, 3838.85, 0, 3, 60, true))
    e.mq.TLO.Me.Y = function() return -760.27 end
    assert(not e.navToLocation(-760.27, 3838.85, 0, 3, 60))
    assert(e.navToLocation(-760.27, 3838.85, 0, 3, 60, true))
end)

test('walking into the snowy mine must not click a door after zoning', function(e)
    e.zone, e.homeHubZone = 30, 30
    local nav = e.navToLocation
    e.navToLocation = function(...)
        nav(...)
        if #e.points == 3 then e.zone = 232; return false end
        return true
    end
    assert(e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/doortarget') and not contains(e.commands, '/click left door'))
end)

test('unexpected zoning during approach does not click or claim entrance success', function(e)
    e.zone, e.homeHubZone = 30, 30
    e.navToLocation = function() e.zone = 392; return true end
    assert(not e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/click left door'))
end)

test('entrance recording that zones does not click again in the dungeon', function(e)
    e.zone, e.homeHubZone, e.doorName = 392, 392, 'WrongDoor'
    e.playRecordedPath = function(key)
        assert(key == 'switch_nro_3')
        e.zone = 231
        return true
    end
    assert(e.enterTask(392, 'quicksand pit'))
    assert(not contains(e.commands, '/click left door'))
end)

test('unknown Guk directions do not guess an entrance', function()
    for _, hub in ipairs({ 393 }) do
        local e = environment()
        e.homeHubZone = hub
        assert(not e.enterTask(e.zone, 'unrecognized assignment directions'))
        assert(#e.points == 0 and #e.commands == 0)
    end
end)

test('North Ro refuses an unrelated door instead of clicking it', function(e)
    e.zone, e.homeHubZone, e.doorName = 392, 392, 'EKTOWER'
    assert(not e.enterTask(392, 'quicksand pit'))
    assert(#e.points == 0 and not contains(e.commands, '/click left door'))
end)

test('nearest-door approach limit accepts 40 units but rejects anything beyond it', function()
    for _, distance in ipairs({ 40, 40.01 }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorDistance, e.navMovesDoor = 30, 30, distance, true
        local nav = e.navToLocation
        e.navToLocation = function(...)
            e.navMovesDoor = #e.points >= 3
            return nav(...)
        end
        assert(e.enterTask(30, 'snowy mine') == (distance == 40))
        assert(contains(e.commands, '/click left door') == (distance == 40))
    end
end)

test('Lesser Faydark preserves original recording keys when door approach fails', function()
    for _, case in ipairs({ { 'grave', 10 }, { 'crypt', 7 } }) do
        local e = environment()
        e.zone, e.homeHubZone = 57, 68
        e.clickSwitch = function() return false end
        e.playRecordedPath = function(key)
            assert(key == 'switch_lfaydark_' .. case[2])
            e.recordingUsed = true
            return false
        end
        assert(not e.enterTask(57, case[1]))
        assert(e.recordingUsed)
    end
end)

test('route short-name aliases are normalized consistently with zone IDs', function(e)
    definition(e, 'zoneShortName', 'local function selectHomeHub')
    for alias, canonical in pairs({
        northro = 'nro', southro = 'sro', commonlands = 'commons', ecommons = 'commons',
        butcherblock = 'butcher', greaterfaydark = 'gfaydark', lesserfaydark = 'lfaydark',
    }) do
        e.mq.TLO.Zone = { ShortName = function() return alias end }
        assert(e.zoneShortName() == canonical)
    end
end)

test('Guk travel can resume in Innothule without trying to recross South Ro', function(e)
    e.zone = 413
    local crossings = {}
    e.runZoneCrossing = function(route)
        crossings[#crossings + 1] = route
        e.zone = 65
        return true
    end
    assert(e.travelAcrossZones({ 'innothule', 'guktop' }))
    assert(#crossings == 1 and crossings[1] == e.ZONE_CROSSINGS.innothule_to_guktop)
end)

test('unknown Everfrost directions warn and try each entrance in turn', function(e)
    e.zone, e.homeHubZone, e.doorName, e.doorId, e.doorDistance, e.active = 30, 30, 'X', 7, 12, true
    e.enterTask(30, 'Unknown entrance in Everfrost Peaks')
    assert(e.points[1][1] == 2698.93)
    assert(contains(e.messages, 'the snowy mine'))
    e.points = {}
    e.enterTask(30, 'Unknown entrance in Everfrost Peaks')
    assert(e.points[1][1] == -974.81)
end)

test('failed mine approach does not click', function(e)
    e.zone, e.homeHubZone, e.navFails = 30, 30, true
    assert(not e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/click left door'))
end)

test('failed middle mine waypoint does not walk or click', function(e)
    e.zone, e.homeHubZone, e.active = 30, 30, true
    e.navToLocation = function(y) return y ~= 2751.72 end
    e.distance3DTo = function() return 8 end
    assert(not e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/moveto loc'))
    assert(not contains(e.commands, '/doortarget') and not contains(e.commands, '/click left door'))
end)

test('distant or missing mine doors fail without chasing another entrance', function()
    for _, door in ipairs({ { 7, 100 }, { 0, 0 } }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorId, e.doorDistance = 30, 30, door[1], door[2]
        assert(not e.enterTask(30, 'snowy mine'))
        assert(not contains(e.commands, '/click left door'))
        assert(#e.points == 3)
    end
end)

test('mine click is not success unless a zone change occurs', function(e)
    e.zone, e.homeHubZone, e.noZoneChange = 30, 30, true
    assert(not e.enterTask(30, 'snowy mine'))
    assert(contains(e.commands, '/click left door'))
end)

test('switch navigation checks actual distance before clicking', function(e)
    e.doorDistance, e.navMovesDoor = 20, true
    assert(e.clickSwitch(7))
    assert(e.doorDistance <= 15 and contains(e.commands, '/click left door'))
end)

test('switch cannot be clicked when navigation and walking remain out of range', function(e)
    e.doorDistance = 20
    assert(not e.clickSwitch(7))
    assert(not contains(e.commands, '/click left door'))
end)

test('lost switch target after navigation cannot be clicked', function(e)
    e.doorDistance, e.navDropsDoor = 20, true
    assert(not e.clickSwitch(7))
    assert(not contains(e.commands, '/click left door'))
end)

local function entryTick(e)
    local code = section('        elseif ENTRY_ZONES[zone] then',
        "\n        else\n            local notice = 'Not in an LDoN zone")
    e.zone, e.assigned, e.completed = e.zoneId(), e.assigned, e.completed
    run(e, 'if false then\n' .. code .. '\nend')
end

test('finish then start in North Ro replaces stale Everfrost hub', function(e)
    e.campaignInitialized, e.active, e.homeHubZone = true, true, 30
    e.finishCampaign('finished')
    assert(e.startRunner())
    assert(e.homeHubZone == 392)
    e.requestTask = function(hub) e.requestedHub = hub end
    entryTick(e)
    assert(e.requestedHub == e.HUBS[392])
end)

test('restart from another camp travels to North Ro before requesting', function(e)
    e.zone, e.homeHubZone = 30, 30
    assert(e.startRunner())
    assert(e.homeHubZone == 392)
    entryTick(e)
    assert(e.zone == 392 and e.magusDestination == 'North Ro')
    assert(not contains(e.commands, 'AdvRqst_RequestButton'))
end)

test('already at target camp still updates stored hub', function(e)
    assert(e.travelToCamp(392))
    assert(e.homeHubZone == 392 and not e.magusDestination)
    assert(not e.travelToCamp(999))
end)

test('unfinished assignment owner wins over newly selected camp', function(e)
    e.assigned, e.dialogue = true, 'through a snowy mine in Everfrost Peaks'
    assert(e.startRunner())
    assert(e.homeHubZone == 30)
end)

test('unfinished assignment can infer owner from current dungeon', function(e)
    e.zone, e.assigned, e.dialogue = 232, true, 'unrecognized directions'
    assert(e.startRunner())
    assert(e.homeHubZone == 30)
end)

test('unknown unfinished assignment warns and uses the zone camp instead of stopping', function(e)
    e.assigned, e.dialogue = true, 'unrecognized directions'
    assert(e.startRunner())
    assert(contains(e.messages, 'names no known camp'))
end)

test('completed assignment does not retain previous campaign hub on fresh start', function(e)
    e.assigned, e.completed, e.dialogue = true, true, 'Miragul'
    assert(e.startRunner())
    assert(e.homeHubZone == 392)
end)

test('pause/resume preserves leg counters and assignment camp', function(e)
    e.campaignInitialized, e.homeHubZone, e.campaignCompleted[1] = true, 30, 2
    assert(e.startRunner())
    assert(e.homeHubZone == 30 and e.campaignCompleted[1] == 2)
end)

test('failed request-window opening cannot start a fresh campaign', function(e)
    e.open, e.blockOpen = false, true
    assert(not e.startRunner())
    assert(not e.active and not e.campaignInitialized)
end)

test('new campaign requires a selected camp', function(e)
    e.campaignPlan[1].count = 0
    assert(not e.startRunner())
    assert(not e.active)
end)

test('finishing a leg returns to its old hub before changing camps', function(e)
    e.zone, e.homeHubZone, e.campaignTravelPending = 392, 30, true
    entryTick(e)
    assert(e.zone == 30 and e.homeHubZone == 30)
    assert(e.campaignTravelPending)
    entryTick(e)
    assert(e.zone == 392 and not e.campaignTravelPending)
end)

test('transition-zone return uses existing crossing, not Magus camp travel', function(e)
    e.zone, e.homeHubZone = 413, 393
    e.moveThroughBoundary = function() return true end
    entryTick(e)
    assert(#e.points == 1 and e.points[1][1] == 2489.63)
    assert(not e.magusDestination)
end)

test('fresh start in a transition zone returns to its hub before traveling to North Ro', function(e)
    e.zone = 413
    assert(e.startRunner())
    assert(e.homeHubZone == 393 and e.campaignTravelPending)
    e.moveThroughBoundary = function() e.zone = 393; return true end
    entryTick(e)
    assert(e.zone == 393 and not e.magusDestination)
    entryTick(e)
    assert(e.zone == 392 and e.homeHubZone == 392 and not e.campaignTravelPending)
end)

local function clickStart(e)
    e.ImGui = { Button = function() return true end }
    e.inStartCallback = true
    run(e, section("        if ImGui.Button(active and 'Pause task runner' or 'Start campaign') then",
        "\n        ImGui.SameLine()\n        if ImGui.Button('Refresh task types')"))
    e.inStartCallback = false
end

local function processStart(e)
    run(e, section('    if runnerStartPending and not shuttingDown then', '\n    if active then'))
end

test('Start button queues startup without commands or delays inside ImGui', function(e)
    e.open, e.deferWindowOpen = false, true
    clickStart(e)
    assert(e.runnerStartPending and not e.active)
    assert(#e.commands == 0 and not e.delayCount)
    processStart(e)
    assert(e.active and e.open and not e.runnerStartPending)
    assert(e.delayCount == 1 and e.campaignInitialized)
end)

test('repeated Start clicks are consumed once by the main loop', function(e)
    e.open, e.deferWindowOpen = false, true
    clickStart(e)
    clickStart(e)
    processStart(e)
    local commands, delays = #e.commands, e.delayCount
    processStart(e)
    assert(#e.commands == commands and e.delayCount == delays)
end)

test('command start and resume also defer startup out of callbacks', function()
    for _, action in ipairs({ 'start', 'resume' }) do
        local e = environment()
        e.open, e.deferWindowOpen, e.inStartCallback = false, true, true
        e.command(action)
        e.inStartCallback = false
        assert(e.runnerStartPending and #e.commands == 0 and not e.delayCount)
        processStart(e)
        assert(e.active and e.open and e.delayCount == 1)
    end
end)

test('pause and exit cancel queued startup', function()
    for _, action in ipairs({ 'pause', 'stop', 'exit' }) do
        local e = environment()
        clickStart(e)
        e.command(action)
        processStart(e)
        assert(not e.runnerStartPending and not e.active and not e.campaignInitialized)
        assert(not e.delayCount)
    end
end)

test('closing the UI cancels queued startup', function(e)
    clickStart(e)
    e.open = false
    run(e, section('    if not open then\n        active = false', '\n    if visible then'))
    processStart(e)
    assert(e.shuttingDown and not e.runnerStartPending and not e.active)
end)

test('queued startup reports window failure without leaving a pending request', function(e)
    e.open, e.blockOpen = false, true
    clickStart(e)
    processStart(e)
    assert(not e.active and not e.runnerStartPending)
    assert(contains(e.messages, 'Adventure Request window did not open'))
end)

test('queued startup yields and resumes on a Lua coroutine, not the render stack', function(e)
    e.open, e.deferWindowOpen = false, true
    local finishDelay = e.mq.delay
    e.mq.delay = function(ms)
        coroutine.yield(ms)
        finishDelay()
    end
    clickStart(e)
    local runner = coroutine.create(function() processStart(e) end)
    local ok, ms = coroutine.resume(runner)
    assert(ok and ms == 500 and coroutine.status(runner) == 'suspended')
    assert(not e.active and not e.open)
    assert(coroutine.resume(runner))
    assert(coroutine.status(runner) == 'dead' and e.active and e.open)
end)

test('gukd pauses combat and stops Swarm first, then walks with its 5-unit, 60-second limits', function(e)
    shrinkEnvironment(e)
    e.zoneShortName = function() return 'gukd' end
    e.groupSize = 2
    local swarmStopped
    e.stopSwarmPull = function(resume) swarmStopped = resume == false end
    local nav = e.navToLocation
    e.navToLocation = function(...)
        assert(swarmStopped and contains(e.commands, '/ac pause') and contains(e.commands, '/ac net group pause'))
        return nav(...)
    end
    assert(e.configureGroupCombat())
    assert(#e.points == 2)
    for _, point in ipairs(e.points) do assert(point[4] == 5 and point[5] == 60) end
end)

test('a new zone clears the Mushroom Grove marker', function(e)
    local code = section('        if zone ~= lastZone then', '        if stopAfterMinutes > 0')
    e.zone, e.lastZone, e.entryPositionZone = 392, 244, 244
    run(e, code)
    assert(e.lastZone == 392 and e.entryPositionZone == 0)
end)

test('the main loop attempts shrink before any zone-specific action', function()
    local hook = assert(source:find('if active then shrinkGroupOnEntry() end', 1, true))
    assert(hook < assert(source:find('if zone ~= lastZone then', hook, true)))
end)

test('movement helpers stop before moving when the zone shrink step fails', function(e)
    local calls = 0
    e.shrinkOnZone = function() calls = calls + 1; return false end
    definition(e, 'navToLocation', 'local function navToSpawn')
    definition(e, 'navToSpawn', 'local function distanceTo')
    definition(e, 'navToRoutePoint', 'local function moveToRoutePoint')
    run(e, section('function useMagus(', 'local MAGUS_DESTINATIONS ='))
    assert(not e.navToLocation(1, 2, 3) and not e.navToSpawn('Somebody'))
    assert(not e.navToRoutePoint(1, 2, 3, e.zone) and not e.useMagus('North Ro'))
    assert(calls == 4 and #e.commands == 0)
end)

test('a zone crossing stops when the next zone shrink step fails', function(e)
    e.zone = 413
    e.runZoneCrossing = function() e.zone = 65; return true end
    e.shrinkOnZone = function() return false end
    assert(not e.travelAcrossZones({ 'innothule', 'guktop' }))
end)

test('a paused runner never clicks or records an attempt in a new zone', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.active, e.zone = true, false, 392
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(not e.shrinkGroupOnEntry())
    assert(#e.commands == 0 and e.shrinkAttemptZone == 0)
end)

test('a completed adventure still gets its one zone shrink', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.completed = true, true
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.configureGroupCombat())
    assert(contains(e.commands, '/useitem'))
end)

test('Rujark keeps its recording key when the door step fails', function(e)
    e.zone, e.homeHubZone = 393, 408
    e.clickSwitch = function() return false end
    e.playRecordedPath = function(key) e.recordingKey = key; return false end
    assert(not e.enterTask(393, 'Through a cave'))
    assert(e.recordingKey == 'switch_sro_1')
end)

test('shrink enabled where combat is already running never pauses TAC and waits for the next zone', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.combatZone = true, 1, e.zone
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.shrinkGroupOnEntry())
    assert(#e.commands == 0 and e.shrinkAttemptZone == e.zone)
    assert(contains(e.messages, 'shrink will start from the next zone'))
    e.zone = 392
    assert(e.shrinkGroupOnEntry())
    assert(contains(e.commands, '/ac pause') and contains(e.commands, '/useitem'))
end)

test('without Triune a travel zone clicks locally, sends no /ac and skips the group wait', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.zone, e.triuneStatus = true, 1, 392, 'STOPPED'
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.shrinkGroupOnEntry())
    assert(not contains(e.commands, '/ac ') and contains(e.commands, '/useitem'))
    assert(contains(e.messages, 'group boxes were not sent a shrink'))
    assert(not contains(e.messages, 'Shrink sent to group boxes'))
    assert(e.clock < 27000)
end)

test('a dungeon starts Triune before sending shrink to the group', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.triuneStatus = true, 1, 'STOPPED'
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    e.ensureTriune = function()
        assert(#e.commands == 0)
        e.triuneStatus, e.ensured = 'RUNNING', true
        return true
    end
    assert(e.shrinkGroupOnEntry())
    assert(e.ensured and contains(e.commands, '/ac pause'))
    assert(contains(e.commands, '/ac net OtherBox /lua run ldon_shrink ' .. e.zone))
end)

test('groupNames is declared before its first use and the box main loop stays idle', function()
    assert(source:find('local function groupNames(', 1, true) < source:find('local function groupMembersAtRecruiter(', 1, true))
    assert(source:find('if active and not remoteReturning then', 1, true))
end)

test('shrink enabled where combat is already running never pauses TAC and waits for the next zone', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.combatZone = true, 1, e.zone
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(e.shrinkGroupOnEntry())
    assert(#e.commands == 0 and e.shrinkAttemptZone == e.zone)
    assert(contains(e.messages, 'shrink will start from the next zone'))
    e.zone = 392
    assert(e.shrinkGroupOnEntry())
    assert(contains(e.commands, '/ac pause') and contains(e.commands, '/useitem'))
end)

test('without Triune a travel zone clicks locally, sends no /ac and skips the group wait', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.zone, e.triuneStatus = true, 1, 392, 'STOPPED'
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(not e.DUNGEONS[e.zone])
    assert(e.shrinkGroupOnEntry())
    assert(not contains(e.commands, '/ac ') and contains(e.commands, '/useitem'))
    assert(contains(e.messages, 'group boxes were not sent a shrink'))
    assert(not contains(e.messages, 'Shrink sent to group boxes'))
    assert(e.clock < 27000)
end)

test('a dungeon starts Triune before dispatching shrink to the group', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.triuneStatus = true, 1, 'STOPPED'
    for zone in pairs(e.DUNGEONS) do e.zone = zone; break end
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    e.ensureTriune = function()
        assert(#e.commands == 0)
        e.triuneStatus, e.ensured = 'RUNNING', true
        return true
    end
    assert(e.shrinkGroupOnEntry())
    assert(e.ensured and contains(e.commands, '/ac pause'))
    assert(contains(e.commands, '/ac net OtherBox /lua run ldon_shrink ' .. e.zone))
end)

test('remote-return never dispatches shrink, refuses overlap and restores state', function(e)
    shrinkEnvironment(e)
    e.shrinkOnEntry, e.groupSize, e.active = true, 1, false
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    local calls = 0
    e.returnToCampaignRecruiter = function(hub)
        calls = calls + 1
        assert(hub == 392 and e.active and e.remoteReturning)
        assert(e.shrinkGroupOnEntry())
        e.command('remote-return', '392')
        assert(e.remoteReturning)
        return true
    end
    e.command('remote-return', '392')
    assert(calls == 1 and contains(e.messages, 'Remote return already running'))
    assert(contains(e.messages, 'Remote group return reached the campaign recruiter'))
    assert(#e.commands == 0 and not e.remoteReturning and not e.active)
    e.active = true
    assert(e.shrinkGroupOnEntry() and contains(e.commands, '/useitem'))
end)

-- Group roles ---------------------------------------------------------------------------------

-- A group of Tester (this client), Tanky, Assisty, Pully and Healy, with no native leader at all.
local function roleGroup(e, classes)
    shrinkEnvironment(e)
    local members = { 'Tanky', 'Assisty', 'Pully', 'Healy' }
    classes = classes or { Healy = 'CLR', Tanky = 'WAR', Assisty = 'ROG', Pully = 'MNK', Tester = 'BRD' }
    e.groupSize = #members
    e.mq.TLO.Group.Member = function(key)
        local name = type(key) == 'number' and members[key] or key
        return {
            Name = function() return name end,
            Class = { ShortName = function() return classes[name] end },
        }
    end
    e.mq.TLO.Group.Leader = { Name = function() return nil end }
end

local function sent(e, text)
    return contains(e.commands, text)
end

local function roleRow(plan, name)
    for _, row in ipairs(plan) do
        if row.name == name then return row end
    end
end

test('no native leader: controller check and task request are not refused', function(e)
    roleGroup(e)
    assert(e.validateController())
    assert(not contains(e.messages, 'group leader'))
    assert(e.requestTask(e.HUBS[392], 3))
    assert(not contains(e.messages, 'group leader'))
end)

test('the script no longer reads native group leader data to decide anything', function()
    local uses = 0
    for line in source:gmatch('[^\n]+') do
        if line:find('Group.Leader', 1, true) then
            uses = uses + 1
            assert(line:find('local nativeLeader =', 1, true) or line:find('none', 1, true), line)
        end
    end
    assert(uses == 2)
end)

test('one character holding every role matches the old single-box setup', function(e)
    roleGroup(e)
    e.mainAssistName = 'Tester'
    e.groupRoles.apply(true)
    assert(sent(e, '/ac ma Tester') and sent(e, '/ac puller hunt'))
    for _, name in ipairs({ 'Tanky', 'Assisty', 'Pully', 'Healy' }) do
        assert(sent(e, '/ac net ' .. name .. ' ma Tester'))
        assert(sent(e, '/ac net ' .. name .. ' assist chase'))
    end
    assert(not sent(e, 'behind'))
end)

test('three different role holders form a chain that ends at the puller', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Tanky', 'Pully'
    local plan = e.groupRoles.plan()
    local puller, assist, tank = roleRow(plan, 'Pully'), roleRow(plan, 'Assisty'), roleRow(plan, 'Tanky')
    assert(puller.mode == 'puller hunt' and puller.assist == 'Tanky')
    assert(assist.mode == 'assist chase' and assist.assist == 'Pully')
    assert(tank.mode == 'assist chase' and tank.assist == 'Assisty')
    -- Healers point at the tank; everyone else assists the Main Assist.
    assert(roleRow(plan, 'Healy').assist == 'Tanky')
    assert(roleRow(plan, 'Tester').assist == 'Assisty' and roleRow(plan, 'Tester').mode == 'assist chase')
    local hunters = 0
    for _, row in ipairs(plan) do
        if row.mode == 'puller hunt' then hunters = hunters + 1 end
    end
    assert(hunters == 1)
end)

test('the controller is told by a local command and boxes by name', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Tanky', 'Pully'
    e.groupRoles.apply(true)
    assert(sent(e, '/ac ma Assisty') and sent(e, '/ac assist chase'))
    assert(sent(e, '/ac net Pully puller hunt') and sent(e, '/ac net Pully ma Tanky'))
    assert(sent(e, '/ac net Assisty ma Pully') and sent(e, '/ac net Healy ma Tanky'))
    assert(not sent(e, '/ac net group'))
end)

test('tank who is also the puller keeps its target and needs no behind change', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Pully', 'Pully'
    local plan = e.groupRoles.plan()
    assert(roleRow(plan, 'Pully').mode == 'puller hunt' and roleRow(plan, 'Pully').assist == 'Assisty')
    assert(roleRow(plan, 'Assisty').assist == 'Pully')
    e.groupRoles.apply(true)
    assert(not sent(e, 'behind'))
end)

test('Main Tank stops moving behind the mob, and a former tank gets it back', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Tanky', 'Pully'
    e.groupRoles.apply(true)
    assert(sent(e, '/ac net Tanky behind off') and e.groupRoles.behindOff == 'Tanky' and e.saved)
    e.commands = {}
    e.groupRoles.tank = 'Assisty'
    e.groupRoles.apply(true)
    assert(sent(e, '/ac net Tanky behind on') and sent(e, '/ac net Assisty behind off'))
    e.commands = {}
    e.groupRoles.apply(true)
    assert(not sent(e, 'behind'))
end)

test('unforced apply only resends what changed, including a late healer class', function(e)
    local classes = { Tanky = 'WAR', Assisty = 'ROG', Pully = 'MNK', Tester = 'BRD' }
    roleGroup(e, classes)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Tanky', 'Pully'
    e.groupRoles.apply(true)
    assert(sent(e, '/ac net Healy ma Assisty'))
    e.commands = {}
    e.groupRoles.apply(false)
    assert(#e.commands == 0)
    classes.Healy = 'SHM'
    e.groupRoles.apply(false)
    assert(sent(e, '/ac net Healy ma Tanky') and #e.commands == 2)
end)

test('a role holder outside the group stops the mission instead of guessing', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.puller = 'Assisty', 'Gone'
    assert(not e.validateController())
    assert(contains(e.messages, 'Puller Gone is not in this group'))
    e.messages = {}
    e.groupRoles.applyNow()
    assert(contains(e.messages, 'Roles were not sent') and not sent(e, '/ac'))
end)

test('roles are ignored when solo, even with stale saved names', function(e)
    shrinkEnvironment(e)
    e.groupSize = 0
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Gone', 'Gone', 'Gone'
    assert(e.validateController())
    local tank, assist, puller = e.groupRoles.names()
    assert(tank == 'Tester' and assist == 'Tester' and puller == 'Tester')
    e.groupRoles.apply(true)
    assert(sent(e, '/ac ma Tester') and sent(e, '/ac puller hunt') and not sent(e, 'behind'))
    assert(not sent(e, '/ac net'))
end)

test('role names typed in the wrong case use the group spelling', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'assisty', 'TANKY', 'pully'
    local tank, assist, puller = e.groupRoles.names()
    assert(tank == 'Tanky' and assist == 'Assisty' and puller == 'Pully')
end)

test('apply now waits for Triune and saves the roles', function(e)
    roleGroup(e)
    e.triuneStatus = 'STOPPED'
    e.groupRoles.applyNow()
    assert(contains(e.messages, 'Triune is not running') and #e.commands == 0 and e.saved)
    e.triuneStatus = 'RUNNING'
    e.groupRoles.applyNow()
    assert(sent(e, '/ac ma') and contains(e.messages, 'Roles sent'))
end)

test('/ldon commands set and report each role', function(e)
    roleGroup(e)
    e.command('ma', 'Assisty')
    e.command('mt', 'Tanky')
    e.command('puller', 'Pully')
    local tank, assist, puller = e.groupRoles.names()
    assert(tank == 'Tanky' and assist == 'Assisty' and puller == 'Pully')
    e.command('mt', 'same')
    assert(e.groupRoles.tank == '' and (e.groupRoles.names()) == 'Assisty')
    e.command('roles')
    assert(e.groupRoles.open)
    e.command('roles', 'apply')
    assert(e.groupRoles.applyPending and #e.commands == 0)
end)

test('commands go to every group member by name, including out of zone', function(e)
    roleGroup(e)
    e.groupRoles.sendToOthers('pause')
    assert(#e.commands == 4 and sent(e, '/ac net Healy pause') and sent(e, '/ac net Tanky pause'))
end)

test('only the untouched Mushroom Grove block still uses the zone-only group send', function()
    local uses = 0
    for line in source:gmatch('[^\n]+') do
        if line:find('/ac net group', 1, true) and not line:find('^%s*%-%-') then
            uses = uses + 1
            assert(line:find("/ac net group pause", 1, true), line)
        end
    end
    assert(uses == 1)
    local start = assert(source:find("if zoneShortName() == 'gukd'", 1, true))
    local finish = assert(source:find('entryPositionZone = zone', start, true))
    assert(source:sub(start, finish):find('/ac net group pause', 1, true))
end)

test('settings keep the new roles and tolerate older files', function(e)
    e.mq.configDir = 'config'
    definition(e, 'loadSettings', '\nloadSettings()')
    e.settingsPath = 'x'
    e.campaignPlan = {}
    e.swarmPullCount, e.swarmPullRadius, e.retryLimit = 1, 1, 1
    e.loadfile = function() return function() return { mainTankName = 'Tanky', pullerName = 'Pully', tankBehindOff = 'Tanky' } end end
    e.loadSettings()
    assert(e.groupRoles.tank == 'Tanky' and e.groupRoles.puller == 'Pully' and e.groupRoles.behindOff == 'Tanky')
    e.groupRoles.tank = 'Keep'
    e.loadfile = function() return function() return { mainTankName = 7 } end end
    e.loadSettings()
    assert(e.groupRoles.tank == 'Keep')
end)

-- Group Roles window, drawn through a strict ImGui mock.
local function drawWindow(e, script)
    script = script or {}
    local depth = { color = 0, var = 0, id = 0, table = 0, window = 0, disabled = 0 }
    local function count(field, by)
        return function() depth[field] = depth[field] + by end
    end
    local combos = {}
    e.ImGuiCond = { FirstUseEver = 4 }
    e.ImGuiCol = { Border = 5 }
    e.ImGuiStyleVar = { FramePadding = 11 }
    e.ImGuiTableFlags = { RowBg = 1, BordersInnerV = 2, SizingStretchProp = 4, ScrollY = 8 }
    e.ImGuiTableColumnFlags = { WidthFixed = 1, WidthStretch = 2 }
    e.bit32 = { bor = function(a, ...) for _, v in ipairs({ ... }) do a = a + v end return a end }
    e.boundedComboWidth = function(labels, width) assert(type(labels) == 'table' and #labels > 0); return width end
    e.ImGui = setmetatable({
        PushStyleColor = count('color', 1), PopStyleColor = count('color', -1),
        PushStyleVar = count('var', 1), PopStyleVar = count('var', -1),
        PushID = function(id) assert(type(id) == 'number'); depth.id = depth.id + 1 end,
        PopID = count('id', -1),
        BeginDisabled = function(flag) assert(type(flag) == 'boolean'); depth.disabled = depth.disabled + 1 end,
        EndDisabled = count('disabled', -1),
        Begin = function(title, open) depth.window = depth.window + 1; return open, script.visible ~= false end,
        End = count('window', -1),
        BeginTable = function() depth.table = depth.table + 1; return true end,
        EndTable = count('table', -1),
        Combo = function(label, current, items)
            assert(label == '##roleChoice' and items[current], 'combo index must point at a real item')
            combos[#combos + 1] = { current = current, items = items }
            local pick = script.combo and script.combo[#combos]
            if pick then return pick, true end
            return current, false
        end,
        Button = function(label) return script.button == label end,
    }, { __index = function() return function() end end })
    -- Any game command from the ImGui callback fails the test, as it does in the Start tests.
    e.inStartCallback = true
    e.groupRoles.draw()
    e.inStartCallback = false
    for field, value in pairs(depth) do assert(value == 0, 'unbalanced ImGui ' .. field) end
    return combos
end

local function loadWindow(e)
    run(e, section('function groupRoles.draw()', '-- Triune callback and /ldon command handling.'))
end

test('main window button opens Group Roles and the window balances every ImGui stack', function(e)
    roleGroup(e)
    loadWindow(e)
    e.groupRoles.open = false
    drawWindow(e)
    e.groupRoles.open = true
    local combos = drawWindow(e)
    assert(#combos == 3)
    assert(combos[1].items[1] == '(same as Main Assist)' and combos[3].items[1] == '(same as Main Assist)')
    assert(combos[2].items[1] == 'Tester')
    assert(source:find("if ImGui.Button('Group roles...') then groupRoles.open = true end", 1, true))
    assert(source:find("mq.imgui.init('LDONGroupRoles', groupRoles.draw)", 1, true))
    assert(source:find("mq.imgui.destroy('LDONGroupRoles')", 1, true))
    e.groupRoles.open = true
    drawWindow(e, { visible = false })
end)

test('window choices set roles, and only the main loop sends them', function(e)
    roleGroup(e)
    loadWindow(e)
    e.groupRoles.open = true
    -- Items: tank 1=(same) 2=Tester 3=Tanky; assist 1=Tester 2=Tanky 3=Assisty; puller 1=(same) ... 5=Pully.
    drawWindow(e, { combo = { 3, 3, 5 } })
    local tank, assist, puller = e.groupRoles.names()
    assert(tank == 'Tanky' and assist == 'Assisty' and puller == 'Pully')
    assert(#e.commands == 0)
    drawWindow(e, { button = 'Apply to group now' })
    assert(e.groupRoles.applyPending and #e.commands == 0)
    drawWindow(e, { combo = { 1 } })
    assert(e.groupRoles.tank == '' and (e.groupRoles.names()) == 'Assisty')
    drawWindow(e, { button = 'Close' })
    assert(not e.groupRoles.open)
end)

test('a saved role holder who left stays visible and blocks nothing silently', function(e)
    roleGroup(e)
    loadWindow(e)
    e.mainAssistName, e.groupRoles.puller, e.groupRoles.open = 'Gone', 'AlsoGone', true
    local combos = drawWindow(e)
    assert(combos[2].items[combos[2].current] == 'Gone')
    assert(combos[3].items[combos[3].current] == 'AlsoGone')
    assert(e.mainAssistName == 'Gone' and e.groupRoles.puller == 'AlsoGone')
    assert(#e.groupRoles.view.issues > 0)
end)

-- Group entry ---------------------------------------------------------------------------------

local function entryGroup(e)
    roleGroup(e)
    run(e, section('function groupRoles.sendGroupEntry(', '-- Validate required movement'))
end

test('leader sends the group to the entrance once, with cleaned directions', function(e)
    entryGroup(e)
    e.homeHubZone = 393
    e.groupRoles.sendGroupEntry("Find the Rotting Tree-Trunk, in Innothule's swamp!")
    assert(sent(e, '/ac net Healy /lua run LDON_Triune'))
    assert(sent(e, '/ac net Healy /lua run LDON_Triune remote-follow Tester 393 find the rotting tree trunk in innothule s swamp '))
    assert(sent(e, '/ac net Healy /ldon remote-follow Tester 393 find the rotting tree trunk in innothule s swamp '))
    e.commands = {}
    e.groupRoles.sendGroupEntry('again')
    assert(#e.commands == 0)
end)

test('box follows the leader, reissues after a zone or ID change, and stops in the dungeon', function(e)
    entryGroup(e)
    e.zone, e.active, e.clock = 392, false, 5000
    local id, following = 50, false
    e.mq.TLO.Spawn = function() return { ID = function() return id end } end
    e.mq.TLO.AdvPath = { Following = function() return following end }
    e.command('remote-follow', 'Leader', '392', 'quicksand')
    assert(contains(e.messages, 'Following Leader to the dungeon'))
    e.groupRoles.followTick()
    assert(sent(e, '/afollow spawn 50'))
    e.commands, following = {}, true
    e.clock = e.clock + 2000
    e.groupRoles.followTick()
    assert(#e.commands == 0)
    following = false
    e.clock = e.clock + 2000
    e.groupRoles.followTick()
    assert(sent(e, '/afollow spawn 50'))
    e.commands, following, id = {}, true, 77
    e.clock = e.clock + 2000
    e.groupRoles.followTick()
    assert(sent(e, '/afollow spawn 77'))
    for zone in pairs(e.DUNGEONS) do e.zone = zone; break end
    e.commands = {}
    e.clock = e.clock + 2000
    e.groupRoles.followTick()
    assert(sent(e, '/afollow off') and not e.groupRoles.followName and not e.groupRoles.enterHub)
end)

test('a box left behind takes the entrance route with the leader directions', function(e)
    entryGroup(e)
    e.zone, e.active, e.clock = 392, false, 5000
    e.mq.TLO.Spawn = function() return { ID = function() return 0 end } end
    e.command('remote-follow', 'Leader', '392', 'quicksand', 'pit')
    e.groupRoles.followTick()
    assert(not e.groupRoles.enterHub)
    e.clock = e.clock + 21000
    e.groupRoles.followTick()
    assert(e.groupRoles.enterHub == 392 and e.groupRoles.enterText == 'quicksand pit')
    assert(not e.groupRoles.followName and sent(e, '/afollow off'))
end)

test('follow without MQ2AdvPath uses the route, and off clears the order', function(e)
    entryGroup(e)
    e.active = false
    e.advPathLoaded = function() return false end
    e.command('remote-follow', 'Leader', '392', 'x')
    assert(e.groupRoles.enterHub == 392 and not e.groupRoles.followName)
    e.advPathLoaded = function() return true end
    e.groupRoles.enterHub = nil
    e.command('remote-follow', 'Leader', '392', 'x')
    assert(e.groupRoles.followName == 'Leader')
    e.command('remote-follow', 'off')
    assert(not e.groupRoles.followName and sent(e, '/afollow off'))
end)

test('solo sends no group entry', function(e)
    entryGroup(e)
    e.groupSize = 0
    e.groupRoles.sendGroupEntry('x')
    assert(#e.commands == 0 and not e.groupRoles.entrySent)
end)

test('box runs the unchanged route with the leader directions and stays out of the campaign loop', function(e)
    entryGroup(e)
    e.zone, e.active, e.assigned = 393, false, true
    e.dialogue = 'not useful'
    e.enterTask = function(_, text)
        assert(e.active and e.remoteReturning and e.homeHubZone == 393)
        assert(text == 'rotting tree trunk')
        return true
    end
    e.command('remote-enter', '393', 'rotting', 'tree', 'trunk')
    assert(e.groupRoles.enterHub == 393 and not e.remoteReturning)
    e.groupRoles.runRemoteEntry()
    assert(not e.active and not e.remoteReturning and not e.groupRoles.enterHub)
    assert(contains(e.messages, 'Remote entry reached the dungeon'))
end)

test('box entry retries, stops on pause, and skips with no adventure or inside a dungeon', function()
    local e = environment()
    entryGroup(e)
    e.zone, e.active, e.assigned = 392, false, true
    local calls = 0
    e.enterTask = function() calls = calls + 1; return false end
    e.groupRoles.enterHub = 392
    e.groupRoles.runRemoteEntry()
    assert(calls == 3 and contains(e.messages, 'Remote entry did not reach the dungeon'))
    calls = 0
    e.enterTask = function() calls = calls + 1; e.active = false; return false end
    e.groupRoles.enterHub = 392
    e.groupRoles.runRemoteEntry()
    assert(calls == 1)
    calls = 0
    e.assigned = false
    e.groupRoles.enterHub = 392
    e.groupRoles.runRemoteEntry()
    assert(calls == 0 and contains(e.messages, 'no active adventure'))
    e.assigned = true
    for zone in pairs(e.DUNGEONS) do e.zone = zone; break end
    e.groupRoles.enterHub = 392
    e.groupRoles.runRemoteEntry()
    assert(calls == 0)
end)

test('box already running its own campaign ignores remote entry', function(e)
    entryGroup(e)
    e.active = true
    e.command('remote-enter', '392')
    assert(not e.groupRoles.enterHub and contains(e.messages, 'running its own campaign'))
end)

test('leader waits for boxes once, and stops waiting in combat', function(e)
    entryGroup(e)
    e.mq.TLO.Spawn = function() return { ID = function() return 0 end } end
    e.mq.TLO.Me.Combat = function() return true end
    e.groupRoles.waitForGroupInZone(e.zone)
    assert(not contains(e.messages, 'Waiting up to two minutes'))
    e.groupRoles.entrySent = true
    local before = e.clock
    e.groupRoles.waitForGroupInZone(e.zone)
    assert(e.clock == before and contains(e.messages, 'Starting without: Tanky'))
    e.messages = {}
    e.groupRoles.waitForGroupInZone(e.zone)
    assert(#e.messages == 0)
    local f = environment()
    entryGroup(f)
    f.mq.TLO.Spawn = function() return { ID = function() return 5 end } end
    f.groupRoles.entrySent = true
    f.groupRoles.waitForGroupInZone(f.zone)
    assert(not contains(f.messages, 'Starting without'))
end)

test('a three-class box with any healer class assists the tank', function(e)
    roleGroup(e)
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Assisty', 'Tanky', 'Pully'
    e.groupRoles.classCache = { Tester = 'War/Rog/Shm', Healy = 'Wiz/Mag/Nec' }
    local plan = e.groupRoles.plan()
    assert(roleRow(plan, 'Tester').assist == 'Tanky')
    assert(roleRow(plan, 'Healy').assist == 'Assisty')
    assert(roleRow(plan, 'Tester').class == 'War/Rog/Shm')
end)

test('trio classes are read from saved loadout text without running it', function(e)
    roleGroup(e)
    e.mq.TLO.EverQuest = { ServerName = function() return '' end }
    e.mq.configDir = 'cfg'
    local opened = {}
    e.io = { open = function(path)
        opened[#opened + 1] = path
        if path ~= 'cfg/triune_loadout__Healy.lua' then return nil end
        return { read = function() return 'return { ["classes"]={\n [1]="Clr",\n [2]="Shm",\n [3]="Enc",\n }, }' end, close = function() end }
    end }
    assert(e.groupRoles.memberClass('Healy') == 'Clr/Shm/Enc')
    assert(e.groupRoles.memberClass('Tanky') == 'WAR')
end)

test('Start on a non-leader warns and continues', function(e)
    e.groupSize = 1
    e.mq.TLO.Group.Member = function() return { Name = function() return 'Box' end } end
    e.mq.TLO.Group.Leader = { Name = function() return 'Farbox' end }
    assert(e.startRunner())
    assert(contains(e.messages, 'Warning: Farbox is the group leader') and e.active)
end)

test('any class with heals counts as a healer', function(e)
    for _, classes in ipairs({ 'Pal/SK/Mnk', 'War/Rng/Rog', 'Bst/War/Rog', 'Clr', 'Wiz/Dru/Nec', 'Enc/Shm/Mag' }) do
        assert(e.groupRoles.canHeal(classes), classes)
    end
    assert(not e.groupRoles.canHeal('War/Mnk/Ber') and not e.groupRoles.canHeal(''))
end)


local function trunk(door, zones)
    local e = environment()
    e.zone, e.homeHubZone, e.doorName, e.doorDistance = 413, 393, door, 107
    e.distance3DTo = function() return 2 end
    e.mq.TLO.Me.Z = function() return -0.6 end
    e.active = true
    local cmd, nav = e.mq.cmd, e.navToLocation
    e.mq.cmd = function(c) cmd(c); if zones and c == '/click left door' then e.zone = 229 end end
    e.arrivals = {}
    e.navToLocation = function(y, x, z, arrival, ...) e.arrivals[#e.arrivals + 1] = arrival; return nav(y, x, z, arrival, ...) end
    return e
end
local function countOf(list, wanted)
    local n = 0
    for _, v in ipairs(list) do if v == wanted then n = n + 1 end end
    return n
end
test('rotting log navigates to the first point, walks in, and clicks from the spot', function()
    local e = trunk('GKPORTAL700', true)
    assert(e.enterTask(413, 'rotting tree trunk'))
    assert(#e.points == 1 and e.points[1][1] == 1389.12 and e.arrivals[1] == 12)
    assert(contains(e.commands, '/moveto loc 1253.06 1188.59'))
    assert(contains(e.commands, '/doortarget GKPORTAL700'))
    assert(countOf(e.commands, '/click left door') == 1)
end)
test('rotting log retries the walk from the first point and reports where it stopped', function()
    local e = trunk('GKPORTAL700', true)
    e.distance3DTo = function() return 50 end
    assert(e.enterTask(413, 'rotting tree trunk'))
    assert(#e.points == 2)
    assert(contains(e.messages, 'Did not get inside the log'))
    assert(contains(e.messages, 'Could not get inside the log'))
end)
test('rotting log refuses to click a different door', function()
    local e = trunk('EKTOWER', true)
    assert(not e.enterTask(413, 'rotting tree trunk'))
    assert(not contains(e.commands, '/click left door'))
end)
test('rotting log stops and reports after three clicks without zoning', function()
    local e = trunk('GKPORTAL700', false)
    assert(not e.enterTask(413, 'rotting tree trunk'))
    assert(countOf(e.commands, '/click left door') == 3)
    assert(contains(e.messages, 'Clicked "GKPORTAL700" three times without zoning.'))
end)
test('other entrances keep their 3-unit arrival', function()
    local e = environment()
    e.zone, e.homeHubZone, e.doorName = 65, 393, 'GKPORTAL701'
    local nav, seen = e.navToLocation, nil
    e.navToLocation = function(y, x, z, arrival, ...) seen = arrival; return nav(y, x, z, arrival, ...) end
    e.enterTask(65, 'barricaded door')
    assert(seen == 3)
end)

test('wrong-camp check knows each camp, and South Ro is right for Rujarkian', function(e)
    assert(e.groupRoles.wrongCamp(413, 392))
    assert(e.groupRoles.wrongCamp(30, 393))
    assert(not e.groupRoles.wrongCamp(413, 393))
    assert(not e.groupRoles.wrongCamp(57, 68))
    assert(not e.groupRoles.wrongCamp(393, 408))
    assert(not e.groupRoles.wrongCamp(151, 393))
end)
test('unknown Guk directions try the Guktop door, then the tree trunk', function(e)
    e.zone, e.homeHubZone, e.doorName, e.active = 65, 393, 'GKPORTAL701', true
    e.enterTask(65, 'somewhere in the swamp')
    assert(e.points[1][1] == 441.77)
    assert(contains(e.messages, 'the Guktop door'))
    e.returnToHub = function() e.zone = 413; return true end
    e.distance3DTo = function() return 2 end
    e.enterTask(65, 'somewhere in the swamp')
    assert(contains(e.messages, 'the Innothule tree trunk'))
end)
test('Guktop named in the directions goes to the Guktop door without guessing', function(e)
    e.zone, e.homeHubZone, e.doorName, e.active = 65, 393, 'GKPORTAL701', true
    assert(e.enterTask(65, 'The entrance is in Guktop.'))
    assert(not contains(e.messages, 'name no known entrance'))
end)
test('a failed point is retried, then walked to when close', function()
    local e = trunk('GKPORTAL700', true)
    local nav = e.navToLocation
    local near = 40
    e.navToLocation = function(y, ...)
        nav(y, ...)
        return false
    end
    e.distance3DTo = function() return near end
    e.mq.delay = function() near = 5 end
    assert(e.enterTask(413, 'rotting tree trunk'))
    assert(contains(e.messages, 'trying again'))
    assert(contains(e.commands, '/moveto loc 1389.12 1145.40'))
end)
test('a final point that stays out of reach fails without clicking', function()
    local e = trunk('GKPORTAL700', true)
    local nav = e.navToLocation
    e.navToLocation = function(y, ...)
        nav(y, ...)
        return false
    end
    e.distance3DTo = function() return 500 end
    assert(not e.enterTask(413, 'rotting tree trunk'))
    assert(not contains(e.commands, '/click left door'))
end)
test('a pause during an attempt is not counted as a failure', function()
    local at = assert(source:find('local function handleFailure', 1, true))
    assert(source:sub(at, at + 90):find('if not active then return false end', 1, true))
end)


test('the lesser-reward warning is filtered and the lost branch resets entry state', function()
    assert(source:find("find('lesser reward', 1, true)", 1, true))
    local at = assert(source:find("The adventure was lost", 1, true))
    local branch = source:sub(at, at + 900)
    assert(branch:find('groupRoles.entrySent, groupRoles.entryWaited = false, false', 1, true))
    assert(branch:find('recordCampaignCompletion()', 1, true))
end)
test('a guess that zoned in is kept for the same mission', function(e)
    e.groupRoles.guessText, e.groupRoles.guessCount, e.groupRoles.guessWon = nil, nil, nil
    assert(e.groupRoles.guessEntrance('x', { 'a', 'b' }) == 1)
    e.groupRoles.guessWon = true
    assert(e.groupRoles.guessEntrance('x', { 'a', 'b' }) == 1)
    e.groupRoles.guessWon = false
    assert(e.groupRoles.guessEntrance('x', { 'a', 'b' }) == 2)
    assert(e.groupRoles.guessEntrance('y', { 'a', 'b' }) == 1)
end)
-- Solo run and extra pullers.
local function withMembers(e, members)
    e.groupSize = #members
    e.mq.TLO.Group.Member = function(key)
        local name = type(key) == 'number' and members[key] or key
        return { Name = function() return name end, Class = { ShortName = function() return 'WAR' end } }
    end
end

local function hasRemoteCommand(e)
    for _, command in ipairs(e.commands) do
        if command:find('/ac net', 1, true) then return true end
    end
    return false
end

test('solo run while grouped lists only the controller and sends nothing to boxes', function(e)
    withMembers(e, { 'BoxOne', 'BoxTwo' })
    e.mainAssistName = 'BoxOne'
    assert(e.groupRoles.coordinated() and #e.groupNames() == 3)
    e.groupRoles.solo = true
    assert(not e.groupRoles.coordinated())
    local names = e.groupNames()
    assert(#names == 1 and names[1] == 'Tester')
    local tank, assist, puller = e.groupRoles.names()
    assert(tank == 'Tester' and assist == 'Tester' and puller == 'Tester')
    assert(#e.groupRoles.issues() == 0)
    e.groupRoles.sendToOthers('pause')
    e.groupRoles.sendGroupEntry('Enter through a quicksand pit in Northern Ro.')
    assert(#e.commands == 0 and not e.groupRoles.entrySent)
    assert(e.groupRoles.summary():find('Solo run', 1, true))
end)

test('solo combat setup runs Puller - Hunt on the controller and never waits for or messages boxes', function(e)
    shrinkEnvironment(e)
    withMembers(e, { 'BoxOne', 'BoxTwo' })
    e.groupRoles.solo = true
    assert(e.configureGroupCombat())
    assert(contains(e.commands, '/ac ma Tester') and contains(e.commands, '/ac puller hunt'))
    assert(contains(e.commands, '/ac run'))
    assert(not hasRemoteCommand(e))
    assert(not contains(e.messages, 'Waiting up to two minutes'))
    assert(contains(e.messages, 'Solo Triune Hunt mode set for Tester'))
end)

test('solo run in Mushroom Grove keeps its walk but does not pause the boxes', function(e)
    shrinkEnvironment(e)
    withMembers(e, { 'BoxOne' })
    e.zoneShortName = function() return 'gukd' end
    e.groupRoles.solo = true
    assert(e.configureGroupCombat() and #e.points == 2)
    assert(contains(e.commands, '/ac pause') and not hasRemoteCommand(e))
end)

test('switching solo on during a grouped entry stops the boxes following first', function(e)
    withMembers(e, { 'BoxOne' })
    e.groupRoles.entrySent = true
    e.groupRoles.setSolo(true)
    assert(contains(e.commands, '/ac net BoxOne /ldon remote-follow off'))
    assert(e.groupRoles.solo and not e.groupRoles.entrySent)
    local sent = #e.commands
    e.groupRoles.setSolo(false)
    assert(#e.commands == sent and not e.groupRoles.solo)
end)

test('solo exits, start travel and preflight use the solo paths', function()
    local exitAt = assert(source:find('local function exitTask', 1, true))
    assert(source:sub(exitAt, exitAt + 300):find('if not groupRoles.coordinated() then', 1, true))
    local startAt = assert(source:find('local function travelToStartHub', 1, true))
    assert(source:sub(startAt, startAt + 600):find('if groupRoles.coordinated() then return returnGroupToCampaignRecruiter() end', 1, true))
    local setupAt = assert(source:find('local function validateTravelSetup', 1, true))
    assert(source:sub(setupAt, setupAt + 700):find('if not groupRoles.coordinated() and not mq.TLO.Me.AltAbility(331)() then', 1, true))
    assert(source:find("local groupSize = groupRoles.coordinated() and (tonumber(mq.TLO.Group()) or 0) or 0", 1, true))
end)

test('extra pullers hunt and assist the Main Tank; tank and assist cannot be extra pullers', function(e)
    withMembers(e, { 'Tanky', 'BoxTwo', 'BoxThree' })
    e.mainAssistName, e.groupRoles.tank, e.groupRoles.puller = 'Tester', 'Tanky', ''
    e.groupRoles.setExtraPuller('boxtwo', true)
    e.groupRoles.setExtraPuller('Tanky', true)
    e.groupRoles.setExtraPuller('Tester', true)
    e.groupRoles.setExtraPuller('NotHere', true)
    local rows = {}
    for _, row in ipairs(e.groupRoles.plan()) do rows[row.name] = row end
    assert(rows.BoxTwo.isExtraPuller and rows.BoxTwo.mode == 'puller hunt' and rows.BoxTwo.assist == 'Tanky')
    assert(not rows.Tanky.isExtraPuller and rows.Tanky.mode == 'assist chase')
    assert(not rows.Tester.isExtraPuller and rows.Tester.mode == 'puller hunt')
    assert(not rows.BoxThree.isExtraPuller and rows.BoxThree.mode == 'assist chase')
    assert(#e.groupRoles.issues() == 0)
    assert(e.groupRoles.summary():find('Extra pullers: BoxTwo', 1, true))
    e.groupRoles.apply(true)
    assert(contains(e.commands, '/ac net BoxTwo puller hunt'))
    assert(contains(e.commands, '/ac net BoxThree assist chase'))
    e.groupRoles.setExtraPuller('BOXTWO', false)
    assert(#e.groupRoles.extraPullers == 3)
    e.commands = {}
    e.groupRoles.apply(false)
    assert(contains(e.commands, '/ac net BoxTwo assist chase'))
end)

local function swarmEnvironment(e)
    e.useSwarmPull, e.swarmActive, e.swarmPullCount, e.swarmPullRadius = true, false, 3, 150
    e.mainAssistName = 'Tester'
    e.swarmPullInstalled = function() return true end
    definition(e, 'startSwarmPull', 'local function stopSwarmPull')
    definition(e, 'stopSwarmPull', 'local function setSwarmPull')
end

test('Swarm Pull starts on the main puller, not an extra puller', function(e)
    withMembers(e, { 'BoxOne', 'BoxTwo' })
    swarmEnvironment(e)
    e.groupRoles.puller = 'BoxOne'
    e.groupRoles.setExtraPuller('BoxTwo', true)
    e.startSwarmPull()
    assert(contains(e.commands, '/ac net BoxOne swarm start 3 150'))
    assert(not contains(e.commands, '/ac net BoxTwo swarm'))
end)

test('solo switched on mid-dungeon stops a box Swarm Pull without restarting its combat', function(e)
    withMembers(e, { 'BoxOne' })
    swarmEnvironment(e)
    e.groupRoles.puller = 'BoxOne'
    e.startSwarmPull()
    e.groupRoles.setSolo(true)
    e.commands = {}
    e.stopSwarmPull(true)
    assert(contains(e.commands, '/ac net BoxOne swarm stop'))
    assert(not contains(e.commands, '/ac net BoxOne run'))
    e.swarmActive, e.groupRoles.swarmOwner, e.commands = true, 'Tester', {}
    e.stopSwarmPull(true)
    assert(contains(e.commands, '/ac swarm stop') and contains(e.commands, '/ac run'))
end)

test('grouped Swarm Pull stop still resumes the box combat', function(e)
    withMembers(e, { 'BoxOne' })
    swarmEnvironment(e)
    e.groupRoles.puller = 'BoxOne'
    e.startSwarmPull()
    e.stopSwarmPull(true)
    assert(contains(e.commands, '/ac net BoxOne run'))
end)

test('solo roles never send behind on to a box that was the grouped tank', function(e)
    withMembers(e, { 'BoxA' })
    e.mainAssistName = 'Tester'
    e.groupRoles.behindOff = 'BoxA'
    e.groupRoles.solo = true
    e.groupRoles.apply(true)
    assert(not hasRemoteCommand(e))
    assert(e.groupRoles.behindOff == 'BoxA')
    e.groupRoles.solo = false
    e.groupRoles.tank, e.commands = '', {}
    e.groupRoles.apply(true)
    assert(contains(e.commands, '/ac net BoxA behind on'))
end)

test('extra pullers and solo run load safely and persist with settings', function(e)
    shrinkEnvironment(e)
    definition(e, 'loadSettings', '\nloadSettings()')
    e.loadfile = function() return function()
        return { extraPullers = { 'BoxTwo', 'boxtwo', 5, '', 'BoxThree' }, soloRun = true }
    end end
    e.loadSettings()
    assert(#e.groupRoles.extraPullers == 2 and e.groupRoles.extraPullers[2] == 'BoxThree')
    assert(e.groupRoles.solo == true)
    e.loadfile = function() return function() return { extraPullers = 'BoxTwo', soloRun = 'yes' } end end
    e.loadSettings()
    assert(#e.groupRoles.extraPullers == 2 and e.groupRoles.solo == true)
    e.swarmPullCount, e.swarmPullRadius, e.retryLimit = 3, 150, 2
    e.settingsPath = 'mock-settings'
    local written
    e.io = { open = function()
        return { write = function(_, text) written = text end, close = function() end }
    end }
    definition(e, 'saveSettings', 'local function loadSettings')
    assert(e.saveSettings())
    assert(written:find('extraPullers = { "BoxTwo", "BoxThree" }', 1, true))
    assert(written:find('soloRun = true', 1, true))
    local reread = assert(loadstring(written))()
    assert(reread.extraPullers[1] == 'BoxTwo' and reread.soloRun == true)
end)

test('/ldon pullers and /ldon solo change the settings', function(e)
    withMembers(e, { 'BoxTwo' })
    e.command('pullers', 'add', 'BoxTwo')
    assert(e.groupRoles.isExtraPuller('boxtwo') and e.saved)
    e.command('pullers', 'add', 'Tester')
    assert(contains(e.messages, 'only becomes an extra puller if that changes'))
    e.command('pullers', 'remove', 'Tester')
    e.command('pullers', 'remove', 'boxtwo')
    assert(#e.groupRoles.extraPullers == 0)
    e.command('pullers', 'add', 'BoxTwo')
    e.command('pullers', 'clear')
    assert(#e.groupRoles.extraPullers == 0)
    e.command('solo', 'on')
    assert(e.groupRoles.solo and e.saved)
    e.command('solo')
    assert(contains(e.messages, 'Solo run is on'))
    e.command('solo', 'off')
    assert(not e.groupRoles.solo)
end)
print(string.format('%d regression tests passed; full script syntax checked.', count))
