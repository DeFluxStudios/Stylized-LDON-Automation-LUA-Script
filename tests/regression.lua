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
    e.shrinkOnEntry, e.shrinkAttemptZone = false, 0
    e.active, e.zone = true, 238
    e.clock, e.height, e.ready, e.owned = 0, 6, true, {}
    e.mq.gettime = function() return e.clock end
    e.mq.doevents = function() end
    e.mq.delay = function() e.clock = e.clock + 250 end
    e.mq.TLO.Zone = { ID = function() return e.zone end }
    e.mq.TLO.MacroQuest = { GameState = function() return 'INGAME' end }
    e.mq.TLO.Me.Combat = function() return false end
    e.mq.TLO.Me.Dead = function() return false end
    e.mq.TLO.Me.Height = function() return e.height end
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
    assert(contains(e.commands, '/ac net group /lua run ldon_shrink 238'))
    e.commands = {}
    assert(e.configureGroupCombat())
    assert(not contains(e.commands, '/useitem'))
    assert(not contains(e.commands, '/lua run ldon_shrink'))
    e.shrinkAttemptZone, e.height = 0, 6
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

test('shrink refuses wrong zone, active casting, and completed adventure', function(e)
    shrinkEnvironment(e)
    e.owned['Wand of Imperceptibility'] = 'Wand of Imperceptibility'
    assert(not e.shrink(999) and e.clock == 15000)
    e.mq.TLO.Me.Casting = function() return 'Spell' end
    assert(not e.shrink(238))
    e.shrinkOnEntry, e.completed = true, true
    assert(e.configureGroupCombat())
    assert(not contains(e.commands, '/useitem'))
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
    assert(#e.points == 2)
    assert(e.points[1][1] == 2697.18 and e.points[1][2] == -4694.15 and e.points[1][3] == -91.06)
    assert(e.points[2][1] == 2771.57 and e.points[2][2] == -4725.96 and e.points[2][3] == -104)
    assert(contains(e.commands, '/doortarget id 7') and contains(e.commands, '/click left door'))
end)

test('portal remains a separate route', function(e)
    e.zone, e.homeHubZone = 30, 30
    e.doorName = 'MIRPORTAL700'
    assert(e.enterTask(30, 'Enter the glimmering portal in Everfrost Peaks.'))
    assert(e.points[1][1] == -974.81 and e.points[2][1] == -829.68)
    assert(contains(e.commands, '/click left door'))
end)

test('mine walks from screenshot mesh stop and only clicks after verified arrival', function(e)
    e.zone, e.homeHubZone, e.active = 30, 30, true
    local distance = math.sqrt(9.44 ^ 2 + 14.53 ^ 2 + 21.18 ^ 2)
    e.distance3DTo = function() return distance end
    e.mq.doevents = function() end
    e.navToLocation = function(y) return y == 2697.18 end
    e.mq.delay = function() distance = 8 end
    assert(e.enterTask(30, 'snowy mine'))
    assert(contains(e.commands, '/moveto loc 2771.57 -4725.96'))
    assert(contains(e.commands, '/moveto off'))
    assert(contains(e.commands, '/click left door'))
end)

test('mine fallback cannot accept a stuck or distant mesh stop', function(e)
    e.zone, e.homeHubZone, e.active = 30, 30, true
    e.mq.doevents = function() end
    e.navToLocation = function(y) return y == 2697.18 end
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
        e.navToLocation = function(y) return y == 2697.18 end
        e.distance3DTo = function() return 27 end
        e.mq.doevents = function()
            if cancel then e.active = false else e.zone = 232 end
        end
        assert(e.enterTask(30, 'snowy mine') == not cancel)
        assert(contains(e.commands, '/moveto off'))
        assert(not contains(e.commands, '/click left door'))
    end
end)

test('Everfrost portal never clicks a wall door when the named portal is absent', function(e)
    e.zone, e.homeHubZone, e.doorName = 30, 30, 'EFWALL1'
    assert(not e.enterTask(30, 'glimmering portal of magic'))
    assert(contains(e.commands, '/doortarget MIRPORTAL700'))
    assert(not contains(e.commands, '/click left door'))
end)

test('North Ro reaches quicksand approach before targeting the nearest entrance', function(e)
    e.zone, e.homeHubZone = 392, 392
    assert(e.enterTask(392, 'quicksand pit in Northern Ro'))
    assert(#e.points == 1 and e.points[1][1] == 5562.44)
    assert(e.points[1][2] == -1183.15 and e.points[1][3] == 25.01)
    assert(contains(e.commands, '/doortarget id 7'))
    assert(not contains(e.commands, '/doortarget id 3'))
end)

test('Rujark approaches the cave in South Ro and targets OBJ_ZONEBOX', function(e)
    e.zone, e.homeHubZone, e.doorName = 393, 408, 'OBJ_ZONEBOX'
    assert(e.enterTask(393, 'Through a cave'))
    assert(#e.points == 1 and e.points[1][1] == 5 and e.points[1][2] == -222)
    assert(e.points[1][3] == 129.58)
    assert(contains(e.commands, '/doortarget OBJ_ZONEBOX'))
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
    assert(e.enterTask(413, 'rotting tree trunk'))
    assert(#e.points == 2 and e.points[1][1] == 1389.12 and e.points[2][1] == 1245.50)
end)

test('Mistmoore grave uses corrected map location and nearby door', function(e)
    e.zone, e.homeHubZone, e.doorName = 57, 68, 'MISTPORT701'
    e.zoneShortName = function() return 'lfaydark' end
    assert(e.enterTask(57, 'unearthed grave'))
    assert(e.points[1][1] == -67 and e.points[1][2] == 3843 and e.points[1][3] == nil)
    assert(contains(e.commands, '/doortarget id 7'))
end)

test('Mistmoore crypt follows both screenshot points and clicks the named door', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.doorName = 'MISTFCFN700'
    e.zoneShortName = function() return 'lfaydark' end
    e.moveThroughBoundary = function() error('must not use the old grave crossing') end
    assert(e.enterTask(57, 'Find a crypt'))
    assert(#e.points == 2)
    assert(e.points[1][1] == -739.37 and e.points[1][2] == 3793.22 and e.points[1][3] == 1.06)
    assert(e.points[2][1] == -760.27 and e.points[2][2] == 3838.85 and e.points[2][3] == 0)
    assert(e.points[1][6] == nil and e.points[2][6] == true)
    assert(contains(e.commands, '/doortarget MISTFCFN700'))
    assert(not e.directPoint and contains(e.commands, '/click left door'))
end)

test('crypt navigation rejects an unrelated zone change', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.zoneShortName = function() return 'lfaydark' end
    e.navToLocation = function() e.zone = 54; return true end
    assert(not e.enterTask(57, 'Find a crypt'))
    assert(not contains(e.commands, '/click left door'))
end)

test('crypt nav retains Z=0 but accepts the building floor by planar arrival', function(e)
    definition(e, 'navToLocation', 'local function navToSpawn')
    local y, x, z = -739.37, 3793.22, 1.06
    e.mq.TLO.Me.Y = function() return y end
    e.mq.TLO.Me.X = function() return x end
    e.mq.TLO.Me.Z = function() return z end
    e.waitForNavigation = function(_, reached)
        y, x, z = -760.27, 3838.85, 7.20
        assert(reached())
        return true
    end
    e.zone, e.homeHubZone, e.doorName = 57, 68, 'MISTFCFN700'
    assert(e.enterTask(57, 'Find a crypt'))
    assert(contains(e.commands, '/nav loc -760.27 3838.85 0.00'))
    assert(contains(e.commands, '/click left door'))
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
        if #e.points == 2 then e.zone = 232; return false end
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
    e.zone, e.homeHubZone, e.doorName = 30, 30, 'EFWALL1'
    e.playRecordedPath = function(key)
        assert(key == 'switch_everfrost_0')
        e.zone = 232
        return true
    end
    assert(e.enterTask(30, 'glimmering portal'))
    assert(not contains(e.commands, '/click left door'))
end)

test('unknown Guk and Mistmoore directions do not guess an entrance', function()
    for _, hub in ipairs({ 393, 68 }) do
        local e = environment()
        e.homeHubZone = hub
        assert(not e.enterTask(e.zone, 'unrecognized assignment directions'))
        assert(#e.points == 0 and #e.commands == 0)
    end
end)

test('North Ro approach rejects a distant nearest door instead of following it', function(e)
    e.zone, e.homeHubZone, e.doorDistance = 392, 392, 100
    assert(not e.enterTask(392, 'quicksand pit'))
    assert(#e.points == 1 and not contains(e.commands, '/click left door'))
end)

test('nearest-door approach limit accepts 40 units but rejects anything beyond it', function()
    for _, distance in ipairs({ 40, 40.01 }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorDistance, e.navMovesDoor = 392, 392, distance, true
        local nav = e.navToLocation
        e.navToLocation = function(...)
            e.navMovesDoor = #e.points > 0
            return nav(...)
        end
        assert(e.enterTask(392, 'quicksand pit') == (distance == 40))
        assert(contains(e.commands, '/click left door') == (distance == 40))
    end
end)

test('crypt directions mentioning a graveyard do not select the grave door', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.doorName = 'MISTFCFN700'
    e.moveThroughBoundary = function() e.zone = 238; return true end
    assert(e.enterTask(57, 'Search the graveyard and find a crypt'))
    assert(e.points[1][1] == -739.37 and contains(e.commands, '/doortarget MISTFCFN700'))
end)

test('crypt uses screenshot heights rather than the unmapped macro coordinate', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.doorName = 'MISTFCFN700'
    local point = 0
    e.navToLocation = function(y, x, z)
        point = point + 1
        if point == 1 then assert(y == -739.37 and x == 3793.22 and z == 1.06)
        else assert(y == -760.27 and x == 3838.85 and z == 0) end
        return true
    end
    e.moveThroughBoundary = function() e.zone = 238; return true end
    assert(e.enterTask(57, 'Find a crypt'))
end)

test('crypt refuses an unrelated door instead of clicking the nearest object', function(e)
    e.zone, e.homeHubZone, e.doorDistance = 57, 68, 50.01
    assert(not e.enterTask(57, 'Find a crypt'))
    assert(not e.directPoint and not contains(e.commands, '/click left door'))
end)

test('grave rejects a distant nearest door', function(e)
    e.zone, e.homeHubZone, e.doorDistance = 57, 68, 50
    assert(not e.enterTask(57, 'unearthed grave'))
    assert(not e.directPoint and not contains(e.commands, '/click left door'))
end)

test('crypt failed navigation stops before holding forward', function(e)
    e.zone, e.homeHubZone, e.navFails = 57, 68, true
    e.moveThroughBoundary = function() error('must not hold forward after failed approach') end
    assert(not e.enterTask(57, 'Find a crypt'))
end)

test('crypt approach zoning succeeds without another boundary movement', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.navToLocation = function() e.zone = 238; return true end
    e.moveThroughBoundary = function() error('must not move after instance zoning') end
    assert(e.enterTask(57, 'Find a crypt'))
end)

test('grave approach rejects unrelated zoning', function(e)
    e.zone, e.homeHubZone = 57, 68
    e.navToLocation = function() e.zone = 54; return true end
    assert(not e.enterTask(57, 'unearthed grave'))
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

test('unknown Everfrost directions fail without movement or clicks', function(e)
    e.zone, e.homeHubZone = 30, 30
    assert(not e.enterTask(30, 'Unknown entrance in Everfrost Peaks'))
    assert(#e.points == 0 and #e.commands == 0)
    assert(contains(e.messages, 'Unrecognized Everfrost'))
end)

test('failed mine approach does not click', function(e)
    e.zone, e.homeHubZone, e.navFails = 30, 30, true
    assert(not e.enterTask(30, 'snowy mine'))
    assert(not contains(e.commands, '/click left door'))
end)

test('distant or missing mine doors fail without chasing another entrance', function()
    for _, door in ipairs({ { 7, 100 }, { 0, 0 } }) do
        local e = environment()
        e.zone, e.homeHubZone, e.doorId, e.doorDistance = 30, 30, door[1], door[2]
        assert(not e.enterTask(30, 'snowy mine'))
        assert(not contains(e.commands, '/click left door'))
        assert(#e.points == 2)
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

test('unknown unfinished assignment cannot guess owner from an unrelated hub', function(e)
    e.assigned, e.dialogue = true, 'unrecognized directions'
    assert(not e.startRunner())
    assert(not e.active)
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

print(string.format('%d regression tests passed; full script syntax checked.', count))
