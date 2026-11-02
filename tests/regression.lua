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
        doorId = 7, doorDistance = 8, groupSize = 0,
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
        return ({ [30] = 'everfrost', [392] = 'nro', [393] = 'sro', [413] = 'innothule' })[e.zone] or 'bazaar'
    end
    e.assignmentState = function() return e.assigned, e.completed, e.dialogue, '' end
    e.saveSettings = function() e.saved = true; return true end
    e.stopSwarmPull = function() end
    e.breakInvisibilityForInteraction = function() return true end
    e.navToSpawn = function() return true end
    e.navToLocation = function(y, x, z, arrival)
        e.points[#e.points + 1] = { y, x, z, arrival }
        if e.navMovesDoor then e.doorDistance = 12 end
        if e.navDropsDoor then e.doorId = 0 end
        return not e.navFails
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
                Name = function() return 'MineDoor' end,
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
    assert(e.points[1][1] == 2697.71 and e.points[1][2] == -4686.63 and e.points[1][3] == -87.75)
    assert(e.points[2][1] == 2774.88 and e.points[2][2] == -4723.56 and e.points[2][3] == -93.31)
    assert(contains(e.commands, '/doortarget id 7') and contains(e.commands, '/click left door'))
end)

test('portal remains a separate route', function(e)
    e.zone, e.homeHubZone = 30, 30
    assert(e.enterTask(30, 'Enter the glimmering portal in Everfrost Peaks.'))
    assert(e.points[1][1] == -974.81 and e.points[2][1] == -829.68)
    assert(contains(e.commands, '/click left door'))
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
