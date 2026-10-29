-- LDoN task runner for MacroQuest and Triune AutoCombat.
-- Start with /lua run LDON_Triune. Solo runs are supported; grouped runs should
-- be started by the group leader. The Main Assist becomes Puller - Hunt.
--
-- Attribution: LDoN mission and travel reference details were adapted from the
-- user-provided LDON.lua by Cyfer. Camp/theme relationships, recruiter and
-- mission-request flow, and dungeon entrance/exit routing were reorganized for
-- MacroQuest Lua. The campaign scheduler, Triune integration, UI, and recovery
-- behavior are additions to this runner.
--
-- Optional Triune plugin integrations (each is off unless enabled in the window):
--   * Long-Duration Buffs (lua/tac/long_buffs.lua, tac_long_buffs_store.lua)
--     by Triune. The runner only sends /ac longbuff on and reads the roster file.
--   * Swarm Pull (lua/tac/Swarm_Pull_v2.0.lua) by matth, a Lua port of pull.mac.
--     The runner only sends /ac swarm start|stop; the plugin does the pulling.
--   * MQ2AdvPath (RedGuides) for optional recorded-route playback via /play and /record.
-- Those plugins are separate files and are not bundled with this runner.

local mq = require('mq')
local ImGui = require('ImGui')

local VERSION = '1.4.4'

-- Hub, zone-line, and dungeon metadata used by the travel state machine.
local HUBS = {
    [392] = { name = 'North Ro', recruiter = 'Escon Quickbow', family = 'takish' },
    [408] = { name = 'East Commonlands', recruiter = 'Periac Windfell', family = 'rujark' },
    [393] = { name = 'South Ro', recruiter = 'Kallei Ribblok', family = 'guk' },
    [68] = { name = 'Butcherblock', recruiter = 'Xyzelauna Tu`Valzir', family = 'mistmoore' },
    [30] = { name = 'Everfrost', recruiter = 'Mannis McGuyett', family = 'miragul' },
}

local ZONE_IDS_BY_SHORT_NAME = {
    nro = 392, northro = 392,
    sro = 393, southro = 393,
    commons = 408, commonlands = 408, ecommons = 408,
    butcher = 68, butcherblock = 68,
    everfrost = 30,
    gfaydark = 54, greaterfaydark = 54,
    lfaydark = 57, lesserfaydark = 57,
    innothule = 413,
    guktop = 65,
    bazaar = 151,
}

local ZONE_CROSSINGS = {
    sro_to_innothule = {
        start = 'sro', approachSpawn = 'Scout_Miigle', heading = 114.95, lastZ = -23.05,
        points = {
            {-3105.89, 1089.84}, {-3134.52, 1059.16}, {-3174.04, 1043.41},
            {-3204.04, 1070.45}, {-3197.69, 1113.27}, {-3200.11, 1134.10},
        },
    },
    innothule_to_guktop = {
        start = 'innothule', heading = 235.41, lastZ = -7.73,
        points = {
            {185.05, -714.98}, {176.92, -755.63}, {170.92, -797.48}, {138.19, -828.50},
        },
    },
    butcher_to_gfaydark = {
        start = 'butcher', heading = 246.08, lastZ = 3.75,
        points = {
            {-1151.15, -3056.88}, {-1183.39, -3083.84}, {-1225.25, -3082.91},
            {-1262.50, -3063.90}, {-1305.25, -3065.52}, {-1325.96, -3082.54},
        },
    },
    gfaydark_to_lfaydark = {
        start = 'gfaydark', heading = 169.77, lastZ = 3.75,
        points = {
            {-2475.47, -983.32}, {-2508.90, -1011.15}, {-2544.38, -1033.92},
            {-2577.02, -1061.64}, {-2595.93, -1098.98}, {-2626.51, -1109.55},
        },
    },
}

local DUNGEONS = {
    [231] = { family = 'takish', exit = 'THPRTL700E' },
    [236] = { family = 'takish', exit = 'THPRTL700E' },
    [241] = { family = 'takish', exit = 'THPRTL700E' },
    [246] = { family = 'takish', exit = 'THPRTL700E' },
    [251] = { family = 'takish', exit = 'THPRTL700E' },
    [256] = { family = 'takish', exit = 'THPRTL700E' },
    [261] = { family = 'takish', exit = 'THPRTL700E' },
    [266] = { family = 'takish', exit = 'THPRTL700E' },
    [270] = { family = 'takish', exit = 'THPRTL700E' },
    [274] = { family = 'takish', exit = 'THPRTL700E' },

    [230] = { family = 'rujark', exit = 'RUJPORTAL701E' },
    [235] = { family = 'rujark', exit = 'RUJPORTAL701E' },
    [240] = { family = 'rujark', exit = 'RUJPORTAL701E' },
    [245] = { family = 'rujark', exit = 'RUJPORTAL701E' },
    [260] = { family = 'rujark', exit = 'RUJPORTAL701E' },
    [250] = { family = 'rujark', exit = 'RUJPORTAL700BE' },
    [255] = { family = 'rujark', exit = 'RUJPORTAL700BE' },
    [265] = { family = 'rujark', exit = 'RUJPORTAL700BE' },
    [269] = { family = 'rujark', exit = 'RUJPORTAL700BE' },
    [273] = { family = 'rujark', exit = 'RUJPORTAL700BE' },

    [233] = { family = 'mistmoore', exit = 'MISTPORT701E', loc = {-338.14, -595.65, 4.72} },
    [248] = { family = 'mistmoore', exit = 'MISTPRTL700E', loc = {-641.12, -145.26, 4.30} },
    [253] = { family = 'mistmoore', exit = 'MISTPRTL700E', loc = {384, -606, 0.97} },
    [258] = { family = 'mistmoore', exit = 'MISTPRTL700E', loc = {380.43, -222.56, -7.91} },
    [263] = { family = 'mistmoore', exit = 'MISTPRTL701E', loc = {398.42, 407.86, 8.31} },
    [268] = { family = 'mistmoore', exit = 'MISTPRTL701E', loc = {-322.53, -367.08, 19.37} },
    [272] = { family = 'mistmoore', exit = 'MISTPRTL701E', loc = {-269, 589, 3.75} },
    [238] = { family = 'mistmoore', exit = '', loc = {1.69, -539, 22.94} },
    [243] = { family = 'mistmoore', exit = '', loc = {-85.70, -465.68, 4.78} },
    [276] = { family = 'mistmoore', exit = '', loc = {544.46, 268.48, 7.75} },

    [232] = { family = 'miragul', exit = 'MPORTAL700E' },
    [237] = { family = 'miragul', exit = 'MPORTAL700E' },
    [242] = { family = 'miragul', exit = 'MPORTAL700E' },
    [247] = { family = 'miragul', exit = 'MPORTAL700E' },
    [252] = { family = 'miragul', exit = 'MPORTAL700E' },
    [257] = { family = 'miragul', exit = 'MPORTAL700E' },
    [262] = { family = 'miragul', exit = 'MPORTAL700E' },
    [267] = { family = 'miragul', exit = 'MPORTAL700E' },
    [271] = { family = 'miragul', exit = 'MPORTAL700E' },
    [275] = { family = 'miragul', exit = 'MPORTAL700E' },

    [229] = { family = 'guk', exit = 'GKPORTAL701E' },
    [234] = { family = 'guk', exit = 'GKPORTAL701E' },
    [239] = { family = 'guk', exit = 'GKPORTAL701E' },
    [244] = { family = 'guk', exit = 'GKPORTAL701E' },
    [249] = { family = 'guk', exit = 'GKPORTAL701E' },
    [254] = { family = 'guk', exit = 'GKPORTAL701E' },
    [259] = { family = 'guk', exit = 'GKPORTAL701E' },
    [264] = { family = 'guk', exit = 'GKPORTAL701E' },
}

local ENTRY_ZONES = {
    [392] = true, [408] = true, [393] = true, [68] = true, [30] = true,
    [54] = true, [57] = true, [413] = true, [65] = true,
}

-- Campaign defaults and the server's unlocked camp progression.
local missionOptions = {
    { label = 'Mob count (Slay / Kill / Ridding)', index = 3 },
}
local missionTypeIndex = 3
local CAMPAIGN_COUNTS = { 0 }
local CAMPAIGN_COUNT_LABELS = { 'Skip' }
for count = 1, 10 do
    CAMPAIGN_COUNTS[#CAMPAIGN_COUNTS + 1] = count
    CAMPAIGN_COUNT_LABELS[#CAMPAIGN_COUNT_LABELS + 1] =
        count == 1 and '1 dungeon' or (count .. ' dungeons')
end
local CAMP_ORDER = { 393, 30, 408, 392, 68 }
local CAMP_DISPLAY = {
    [408] = 'East Commonlands: Rujarkian Hills',
    [68] = 'Butcherblock: Mistmoore Catacombs',
    [30] = "Everfrost Peaks: Miragul's Menagerie",
    [393] = 'South Desert of Ro: Deepest Guk',
    [392] = 'North Desert of Ro: Takish-Hiz',
}
local mainAssistName = tostring(mq.TLO.Me.CleanName() or '')
local active = false
local shuttingDown = false
local hardMode = true
local lastNotice = ''
local lastZone = 0
local triuneReady = false
local combatZone = 0
local combatRunStartedAt = 0
local combatRunSends = 0
local travelReady = false
local homeHubZone = 0
local uiOpen = true
local missionWindowSized = false
local adventureCompleted = false
local meshRecoveryRequested = false
local meshRecoveryAwaitingManual = false
local meshFailureActive = false
local meshFailureKind = ''
local meshPopupOpen = false
local meshFailureLocation = nil
local meshRecoveryStatus = ''
local meshDiagnosticPathResults = {}
local meshDiagnosticLastCheck = 0
local meshDiagnosticCurrentPath = false
local meshRecoveryZone = 0
local meshRecoveryPoints = {}
local meshLastSample = nil
local lastStandAttemptAt = 0
local postureHoldNotice = false
local autoStandInCombat = true
local campaignPlan = {}
local campaignCompleted = {}
local campaignLegIndex = 1
local campaignLoop = false
local campaignTaskCounted = false
local campaignTravelPending = false
local campaignStopPending = false
local campaignInitialized = false
local useLongBuffs = false
local useAdvPath = false
local advPathFirst = false
local useSwarmPull = false
local swarmPullCount = 3
local swarmPullRadius = 200
local swarmActive = false
local retryLimit = 2
local failureStreak = 0
local stopAfterMinutes = 0
local lastFailure = ''
local preflightResults = {}
local stats = { startedAt = 0, dungeons = 0, failures = 0, retries = 0, dungeonSeconds = 0, dungeonStartedAt = 0 }
local stuckProgress = ''
local stuckSince = 0
local stuckWarned = false
local recentLog = {}
local LOG_LIMIT = 512 * 1024
local logPath = (tostring(mq.TLO.MacroQuest.Path('logs')() or 'logs')):gsub('\\', '/') .. '/LDON_Triune.log'

local function writeLog(line)
    recentLog[#recentLog + 1] = line
    if #recentLog > 60 then table.remove(recentLog, 1) end
    local file = io.open(logPath, 'a')
    if not file then return end
    if file:seek('end') > LOG_LIMIT then
        file:close()
        os.remove(logPath .. '.old')
        os.rename(logPath, logPath .. '.old')
        file = io.open(logPath, 'a')
        if not file then return end
    end
    file:write(line, '\n')
    file:close()
end

-- Shared status output and zone/campaign initialization.
local function echo(message)
    print('\ag[LDON]\ax ' .. message)
    writeLog(os.date('%Y-%m-%d %H:%M:%S ') .. message:gsub('\a.', ''))
end

-- Optional Triune plugin integrations. Both are skipped when their files are missing.
local function luaFileExists(relativePath)
    local base = tostring(mq.luaDir or (tostring(mq.TLO.MacroQuest.Path('lua')() or 'lua')))
    local file = io.open(base:gsub('\\', '/') .. '/' .. relativePath, 'r')
    if file then file:close() return true end
    return false
end

local function longBuffsInstalled()
    return luaFileExists('tac/long_buffs.lua')
end

local function swarmPullInstalled()
    return luaFileExists('tac/swarm_pull.lua') or luaFileExists('tac/Swarm_Pull_v2.0.lua')
end

local function longBuffRosterCount()
    local ok, store = pcall(require, 'tac_long_buffs_store')
    if not ok or type(store) ~= 'table' then return nil end
    local chunk = loadfile(store.path(mq))
    if not chunk then return 0 end
    local loaded, saved = pcall(chunk)
    if loaded and type(saved) == 'table' and type(saved.roster) == 'table' then return #saved.roster end
    return 0
end

local function startLongBuffs()
    if not useLongBuffs then return end
    if not longBuffsInstalled() then
        echo('Long-Duration Buffs is enabled but lua/tac/long_buffs.lua was not found; skipping.')
        return
    end
    mq.cmd('/ac longbuff on')
    if (tonumber(mq.TLO.Group()) or 0) > 0 then mq.cmd('/ac net group longbuff on') end
end

local function startSwarmPull()
    if not useSwarmPull or swarmActive then return end
    if not swarmPullInstalled() then
        echo('Swarm Pull is enabled but the plugin file was not found in lua/tac; skipping.')
        return
    end
    mq.cmdf('/ac swarm start %d %d', swarmPullCount, swarmPullRadius)
    swarmActive = true
    echo('Swarm Pull started. Turn off "Reset via Bazaar when idle" in its window so it never leaves the dungeon.')
end

local function stopSwarmPull(resumeCombat)
    if not swarmActive then return end
    swarmActive = false
    mq.cmd('/ac swarm stop')
    if resumeCombat then mq.cmd('/ac run') end
end

local function setSwarmPull(enabled)
    useSwarmPull = enabled
    if not enabled then stopSwarmPull(true) end
    echo('Swarm Pull ' .. (enabled and 'enabled; it starts when combat begins inside a dungeon.' or 'disabled.'))
end

mq.event('LDON_AdventureComplete', '#*#You have successfully completed your adventure#*#', function()
    if active then adventureCompleted = true end
end)

local function zoneId()
    local zone = mq.TLO.Zone
    local shortName = tostring(zone.ShortName() or ''):lower()
    return ZONE_IDS_BY_SHORT_NAME[shortName] or tonumber(zone.ID()) or 0
end

local function zoneShortName()
    local shortName = tostring(mq.TLO.Zone.ShortName() or ''):lower()
    if shortName == 'butcherblock' then return 'butcher' end
    if shortName == 'greaterfaydark' then return 'gfaydark' end
    if shortName == 'lesserfaydark' then return 'lfaydark' end
    return shortName
end

local function selectHomeHub()
    local zone = zoneId()
    if HUBS[zone] then
        homeHubZone = zone
    elseif zone == 54 or zone == 57 then
        homeHubZone = 68
    elseif zone == 413 or zone == 65 then
        homeHubZone = 393
    elseif DUNGEONS[zone] then
        local family = DUNGEONS[zone].family
        homeHubZone = ({ takish = 392, rujark = 408, mistmoore = 68, miragul = 30, guk = 393 })[family] or 0
    else
        homeHubZone = 0
    end
end

selectHomeHub()

local function initializeCampaignPlan()
    campaignPlan = {}
    campaignCompleted = {}
    for index = 1, 5 do
        campaignPlan[index] = {
            hubZone = CAMP_ORDER[index],
            count = CAMP_ORDER[index] == (homeHubZone ~= 0 and homeHubZone or CAMP_ORDER[1]) and 1 or 0,
            missionTypeIndex = 3,
        }
        campaignCompleted[index] = 0
    end
    campaignLegIndex = 1
    campaignTaskCounted = false
    campaignTravelPending = false
    campaignStopPending = false
    campaignInitialized = false
end

initializeCampaignPlan()

local function campaignLeg()
    return campaignPlan[campaignLegIndex]
end

local function nextCampaignLeg(startIndex)
    for index = startIndex, #campaignPlan do
        if (campaignPlan[index].count or 0) > 0 then return index end
    end
    return nil
end

-- Lets the runner start from any zone by defaulting to the first selected camp.
local function resolveHomeHub()
    if homeHubZone == 0 then selectHomeHub() end
    if homeHubZone == 0 then
        local first = nextCampaignLeg(1)
        if first then homeHubZone = campaignPlan[first].hubZone end
    end
    return homeHubZone ~= 0
end

local ASSIGNMENT_CAMP_KEYWORDS = {
    { 'deepest guk', 393 }, { 'takish', 392 }, { 'rujarkian', 408 },
    { 'mistmoore', 68 }, { 'miragul', 30 },
}

local function hubFromAssignment(dialogue)
    local text = tostring(dialogue or ''):lower()
    for _, entry in ipairs(ASSIGNMENT_CAMP_KEYWORDS) do
        if text:find(entry[1], 1, true) then return entry[2] end
    end
    return nil
end

local function campaignMissionType()
    local leg = campaignLeg()
    return leg and leg.missionTypeIndex or missionTypeIndex
end

-- Saved per-character settings and failure handling.
local settingsPath = tostring(mq.configDir or 'config'):gsub('\\', '/') ..
    '/ldon_triune__' .. tostring(mq.TLO.Me.CleanName() or 'unknown') .. '.lua'

local function saveSettings()
    local lines = {
        'return {',
        string.format('    mainAssistName = %q,', mainAssistName),
        string.format('    autoStandInCombat = %s,', tostring(autoStandInCombat)),
        string.format('    campaignLoop = %s,', tostring(campaignLoop)),
        string.format('    useLongBuffs = %s,', tostring(useLongBuffs)),
        string.format('    useAdvPath = %s,', tostring(useAdvPath)),
        string.format('    advPathFirst = %s,', tostring(advPathFirst)),
        string.format('    useSwarmPull = %s,', tostring(useSwarmPull)),
        string.format('    hardMode = %s,', tostring(hardMode)),
        string.format('    swarmPullCount = %d,', swarmPullCount),
        string.format('    swarmPullRadius = %d,', swarmPullRadius),
        string.format('    retryLimit = %d,', retryLimit),
        '    legs = {',
    }
    for _, leg in ipairs(campaignPlan) do
        lines[#lines + 1] = string.format('        [%d] = { count = %d, missionTypeIndex = %d },',
            leg.hubZone, leg.count or 0, leg.missionTypeIndex or 3)
    end
    lines[#lines + 1] = '    },'
    lines[#lines + 1] = '}'
    local file = io.open(settingsPath, 'w')
    if not file then return false end
    file:write(table.concat(lines, '\n'), '\n')
    file:close()
    return true
end

local function loadSettings()
    local chunk = loadfile(settingsPath)
    if not chunk then return end
    local ok, saved = pcall(chunk)
    if not ok or type(saved) ~= 'table' then return end
    local function number(value, low, high, default)
        value = tonumber(value)
        if not value then return default end
        return math.max(low, math.min(high, math.floor(value)))
    end
    if type(saved.mainAssistName) == 'string' and saved.mainAssistName ~= '' then
        mainAssistName = saved.mainAssistName
    end
    if type(saved.autoStandInCombat) == 'boolean' then autoStandInCombat = saved.autoStandInCombat end
    if type(saved.campaignLoop) == 'boolean' then campaignLoop = saved.campaignLoop end
    if type(saved.useLongBuffs) == 'boolean' then useLongBuffs = saved.useLongBuffs end
    if type(saved.useAdvPath) == 'boolean' then useAdvPath = saved.useAdvPath end
    if type(saved.advPathFirst) == 'boolean' then advPathFirst = saved.advPathFirst end
    if type(saved.useSwarmPull) == 'boolean' then useSwarmPull = saved.useSwarmPull end
    if type(saved.hardMode) == 'boolean' then hardMode = saved.hardMode end
    swarmPullCount = number(saved.swarmPullCount, 1, 20, swarmPullCount)
    swarmPullRadius = number(saved.swarmPullRadius, 20, 1000, swarmPullRadius)
    retryLimit = number(saved.retryLimit, 0, 5, retryLimit)
    if type(saved.legs) == 'table' then
        for _, leg in ipairs(campaignPlan) do
            local savedLeg = saved.legs[leg.hubZone]
            if type(savedLeg) == 'table' then
                leg.count = number(savedLeg.count, 0, 10, leg.count)
                leg.missionTypeIndex = number(savedLeg.missionTypeIndex, 1, 99, leg.missionTypeIndex)
            end
        end
    end
end

loadSettings()

-- Returns true when the caller should keep running (a retry was granted).
local function handleFailure(reason, retryable)
    stats.failures = stats.failures + 1
    lastFailure = reason
    failureStreak = failureStreak + 1
    if retryable and failureStreak <= retryLimit then
        local delaySeconds = 15 * failureStreak
        stats.retries = stats.retries + 1
        echo(string.format('%s Retrying in %d seconds (%d/%d).', reason, delaySeconds, failureStreak, retryLimit))
        for _ = 1, delaySeconds * 4 do
            mq.doevents()
            if not active then return false end
            mq.delay(250)
        end
        return true
    end
    active = false
    mq.cmd('/nav stop')
    stopSwarmPull(false)
    echo(reason .. ' Runner paused; resolve the issue, then use /ldon resume.')
    return false
end

local function windowText(windowName, childName)
    local value = mq.TLO.Window(windowName).Child(childName).Text()
    return tostring(value or '')
end

-- MQ2Nav helpers and saved pathable positions used for safe mesh recovery.
local function navigationActive()
    local activeNavigation = false
    local ok = pcall(function() activeNavigation = mq.TLO.Navigation.Active() == true end)
    return ok and activeNavigation
end

local function waitForNavigation(timeoutSeconds, destinationReached)
    local ticks = math.floor((timeoutSeconds or 120) * 4)
    local sawNavigation = false
    local idleTicks = 0
    for _ = 1, ticks do
        mq.doevents()
        if not active then
            mq.cmd('/nav stop')
            return false
        end
        if navigationActive() then
            sawNavigation = true
            idleTicks = 0
        else
            idleTicks = idleTicks + 1
            if destinationReached and destinationReached() then return true end
            if sawNavigation and idleTicks >= 8 then return true end
            if not sawNavigation and idleTicks >= 12 then
                echo('MQ2Nav did not start or stopped immediately; destination was not confirmed.')
                return false
            end
        end
        mq.delay(250)
    end
    mq.cmd('/nav stop')
    echo('Navigation timed out. I stopped MQ2Nav; check the navmesh and route before resuming.')
    return false
end

local function waitForZoneChange(previousZone, timeoutSeconds)
    local ticks = math.floor((timeoutSeconds or 90) * 4)
    for _ = 1, ticks do
        mq.doevents()
        if not active then return false end
        if zoneId() ~= previousZone then
            mq.delay(1500)
            echo('Zoned into ' .. tostring(mq.TLO.Zone.ShortName() or zoneId()) .. '.')
            return true
        end
        mq.delay(250)
    end
    echo('No zone change detected. I did not retry the door automatically.')
    return false
end

local function navToLocation(y, x, z, arrivalDistance, timeoutSeconds)
    local startY = tonumber(mq.TLO.Me.Y()) or 0
    local startX = tonumber(mq.TLO.Me.X()) or 0
    local startZ = tonumber(mq.TLO.Me.Z()) or 0
    local arrivalRange = arrivalDistance or 45
    local function reachedLocation()
        local currentY = tonumber(mq.TLO.Me.Y()) or startY
        local currentX = tonumber(mq.TLO.Me.X()) or startX
        local currentZ = tonumber(mq.TLO.Me.Z()) or startZ
        if z then
            local distance = math.sqrt((currentY - y) ^ 2 + (currentX - x) ^ 2 + (currentZ - z) ^ 2)
            return distance <= arrivalRange
        end
        return math.sqrt((currentY - y) ^ 2 + (currentX - x) ^ 2) <= arrivalRange
    end
    if reachedLocation() then return true end
    if z then
        mq.cmdf('/nav loc %.2f %.2f %.2f', y, x, z)
    else
        mq.cmdf('/nav locyx %.2f %.2f', y, x)
    end
    if not waitForNavigation(timeoutSeconds or 150, reachedLocation) then return false end
    if not reachedLocation() then
        local endY = tonumber(mq.TLO.Me.Y()) or startY
        local endX = tonumber(mq.TLO.Me.X()) or startX
        local endZ = tonumber(mq.TLO.Me.Z()) or startZ
        local distance
        if z then
            distance = math.sqrt((endY - y) ^ 2 + (endX - x) ^ 2 + (endZ - z) ^ 2)
        else
            distance = math.sqrt((endY - y) ^ 2 + (endX - x) ^ 2)
        end
        echo(string.format('Nav stopped %.0f units from the requested location; route not continued.', distance))
        return false
    end
    return true
end

local function navToSpawn(name, arrivalDistance)
    local range = arrivalDistance or 35
    local spawn = mq.TLO.Spawn('npc ' .. name)
    local id = tonumber(spawn.ID()) or 0
    if id == 0 then
        echo('Could not find NPC "' .. name .. '" in this zone.')
        return false
    end
    if (tonumber(mq.TLO.Spawn(id).Distance3D()) or math.huge) <= range then return true end
    mq.cmdf('/nav id %d', id)
    if not waitForNavigation(150, function()
        return (tonumber(mq.TLO.Spawn(id).Distance3D()) or math.huge) <= range
    end) then return false end
    local distance = tonumber(mq.TLO.Spawn(id).Distance3D()) or math.huge
    if distance > range then
        echo(string.format('Nav stopped %.0f units from %s; not interacting with the NPC.', distance, name))
        return false
    end
    return true
end

local function distanceTo(y, x)
    local currentY = tonumber(mq.TLO.Me.Y()) or 0
    local currentX = tonumber(mq.TLO.Me.X()) or 0
    return math.sqrt((currentY - y) ^ 2 + (currentX - x) ^ 2)
end

local function distance3DTo(y, x, z)
    local currentY = tonumber(mq.TLO.Me.Y()) or 0
    local currentX = tonumber(mq.TLO.Me.X()) or 0
    local currentZ = tonumber(mq.TLO.Me.Z()) or 0
    return math.sqrt((currentY - y) ^ 2 + (currentX - x) ^ 2 + (currentZ - z) ^ 2)
end

local function navPathExists(y, x, z)
    local exists = false
    local ok = pcall(function()
        exists = mq.TLO.Navigation.PathExists(string.format('loc %.2f %.2f %.2f', y, x, z))() == true
    end)
    return ok and exists
end

local function navigationMeshLoaded()
    local loaded = false
    local ok = pcall(function() loaded = mq.TLO.Navigation.MeshLoaded() == true end)
    return ok and loaded
end

local function pluginLoaded(name)
    local loaded = false
    local ok = pcall(function() loaded = mq.TLO.Plugin(name).IsLoaded() == true end)
    return ok and loaded
end

local function moveToActive()
    local moving = false
    local ok = pcall(function() moving = mq.TLO.MoveTo.Moving() == true end)
    return ok and moving
end

local function hasRouteFromSavedPoint(pointIndex)
    for index, candidate in ipairs(meshRecoveryPoints) do
        if index ~= pointIndex
            and distance3DTo(candidate.y, candidate.x, candidate.z) > 20
            and navPathExists(candidate.y, candidate.x, candidate.z) then
            return true
        end
    end
    return false
end

local meshLastSampleAt = 0

local function sampleMeshRecoveryPoint(zone)
    if meshRecoveryZone ~= zone then
        meshRecoveryZone = zone
        meshRecoveryPoints = {}
        meshLastSample = nil
    end
    local now = mq.gettime()
    if now - meshLastSampleAt < 2000 then return end
    meshLastSampleAt = now
    if not navigationMeshLoaded() then
        meshLastSample = nil
        return
    end

    local y = tonumber(mq.TLO.Me.Y())
    local x = tonumber(mq.TLO.Me.X())
    local z = tonumber(mq.TLO.Me.Z())
    if not y or not x or not z then return end
    if not navPathExists(y, x, z) then
        meshLastSample = nil
        return
    end
    if meshLastSample then
        local moved = math.sqrt((y - meshLastSample.y) ^ 2 + (x - meshLastSample.x) ^ 2)
        local latest = meshRecoveryPoints[1]
        local spaced = not latest or math.sqrt((y - latest.y) ^ 2 + (x - latest.x) ^ 2) >= 20
        if moved >= 5 and spaced then
            table.insert(meshRecoveryPoints, 1, { y = y, x = x, z = z })
            while #meshRecoveryPoints > 5 do table.remove(meshRecoveryPoints) end
        end
    end
    meshLastSample = { y = y, x = x, z = z }
end

local function navToRoutePoint(y, x, z, startZone)
    if z then
        mq.cmdf('/nav locyxz %.2f %.2f %.2f', y, x, z)
    else
        mq.cmdf('/nav locyx %.2f %.2f', y, x)
    end

    local sawNavigation = false
    local idleTicks = 0
    for _ = 1, 15 * 60 * 4 do
        mq.doevents()
        if not active then mq.cmd('/nav stop'); return false end
        if zoneId() ~= startZone then return true end
        if navigationActive() then
            sawNavigation = true
            idleTicks = 0
        else
            idleTicks = idleTicks + 1
            if distanceTo(y, x) <= 40 then return true end
            if sawNavigation or idleTicks >= 12 then return false end
        end
        mq.delay(250)
    end
    mq.cmd('/nav stop')
    return false
end

local function moveToRoutePoint(y, x, startZone)
    mq.cmdf('/moveto loc %.2f %.2f', y, x)
    for _ = 1, 30 * 4 do
        mq.doevents()
        if not active or zoneId() ~= startZone or distanceTo(y, x) <= 12 then break end
        mq.delay(250)
    end
    mq.cmd('/moveto off')
    return active and (zoneId() ~= startZone or distanceTo(y, x) <= 12)
end

-- Optional MQ2AdvPath recordings (RedGuides). Paths are named ldon_<key> and recorded
-- with /ldon record; the runner falls back to its own navigation when none is played.
local function advPathLoaded()
    return pluginLoaded('MQ2AdvPath')
end

local function playRecordedPath(key, startZone)
    if not useAdvPath or not advPathLoaded() then return false end
    local pathName = 'ldon_' .. key
    mq.cmd('/nav stop')
    mq.cmdf('/play %s noloop smart door', pathName)
    local started = false
    for tick = 1, 240 * 4 do
        mq.doevents()
        if not active then mq.cmd('/play off'); return false end
        if startZone and zoneId() ~= startZone then return true end
        local playing = mq.TLO.AdvPath.Playing() == true
        if playing then started = true end
        if not playing and (started or tick > 16) then break end
        mq.delay(250)
    end
    if not started then
        echo('No MQ2AdvPath recording named "' .. pathName .. '" was played; using built-in navigation.')
        return false
    end
    mq.cmd('/play off')
    return true
end

local function runZoneCrossing(route)
    if mq.TLO.Plugin('MQ2Nav').IsLoaded() ~= true then
        echo('MQ2Nav is required for recorded LDoN zone-line routes.')
        return false
    end
    if mq.TLO.Plugin('MQ2MoveUtils').IsLoaded() ~= true then
        echo('MQ2MoveUtils is required to walk the final zone-line route points.')
        return false
    end
    local startZone = zoneId()
    if route.approachSpawn and not navToSpawn(route.approachSpawn) then
        echo('Could not reach the recorded zone-line approach NPC "' .. route.approachSpawn .. '".')
        return false
    end
    if zoneId() ~= startZone then return true end
    local points = route.points
    local firstPoint = points[1]
    if not navToRoutePoint(firstPoint[1], firstPoint[2], nil, startZone) then
        echo('MQ2Nav could not reach the first recorded route waypoint; check the current zone mesh.')
        return false
    end
    if zoneId() ~= startZone then return true end
    for index = 2, #points do
        local point = points[index]
        if not moveToRoutePoint(point[1], point[2], startZone) then
            echo('MQ2MoveUtils could not reach a recorded zone-line point; check the route and mesh.')
            return false
        end
        if zoneId() ~= startZone then return true end
    end

    mq.cmd('/moveto off')
    mq.cmdf('/face fast heading %.2f', route.heading)
    mq.delay(300)
    mq.cmd('/keypress forward hold')
    local changed = waitForZoneChange(startZone, 20)
    mq.cmd('/keypress forward')
    if not changed then echo('Reached the recorded route end but did not zone.'); end
    return changed
end

-- Travel between hub/transition zones and return from an instance.
local function travelAcrossZones(path)
    for _, destination in ipairs(path) do
        local current = zoneShortName()
        if current ~= destination then
            local route = ZONE_CROSSINGS[current .. '_to_' .. destination]
            if not route then
                echo('No recorded zone-line route from ' .. current .. ' to ' .. destination .. '.')
                return false
            end
            local crossed = false
            local before = zoneId()
            local key = current .. '_to_' .. destination
            if advPathFirst then
                crossed = playRecordedPath(key, before) and (zoneId() ~= before or waitForZoneChange(before, 10))
            end
            if not crossed and zoneId() == before then
                crossed = runZoneCrossing(route)
                if not crossed and not advPathFirst and zoneId() == before then
                    crossed = playRecordedPath(key, before) and (zoneId() ~= before or waitForZoneChange(before, 10))
                end
            end
            if not crossed then return false end
            mq.delay(5000)
        end
    end
    return true
end

local function clickDoor(doorName)
    local before = zoneId()
    if doorName and doorName ~= '' then
        mq.cmd('/nav door ' .. doorName .. ' click')
        return waitForZoneChange(before, 90)
    else
        mq.cmd('/doortarget')
    end
    mq.delay(1500)
    mq.cmd('/click left door')
    return waitForZoneChange(before, 90)
end

local function moveThroughBoundary(heading, seconds)
    mq.cmdf('/face heading %d', heading)
    mq.delay(500)
    mq.cmd('/keypress forward hold')
    mq.delay((seconds or 3) * 1000, function() return not active end)
    mq.cmd('/keypress forward')
    return active
end

local useMagus

local function returnToHub()
    local zone = zoneId()
    if homeHubZone == 68 and zone == 57 then
        if not navToLocation(2152.63, -1198.00, 3.86) then return false end
        local before = zoneId()
        if not moveThroughBoundary(360, 3) or not waitForZoneChange(before, 30) then return false end
        zone = zoneId()
    end
    if homeHubZone == 68 and zone == 54 then
        if not navToLocation(-1642.97, 2650.98, 3.86) then return false end
        local before = zoneId()
        return moveThroughBoundary(115, 3) and waitForZoneChange(before, 30)
    elseif homeHubZone == 393 and zone == 65 then
        if not navToLocation(-65.48, 35.43, 3.76) then return false end
        local before = zoneId()
        return moveThroughBoundary(100, 3) and waitForZoneChange(before, 30)
    elseif homeHubZone == 393 and zone == 413 then
        if not navToLocation(2489.63, 1179.64, 3.35) then return false end
        local before = zoneId()
        return moveThroughBoundary(330, 3) and waitForZoneChange(before, 30)
    elseif homeHubZone == 408 and zone == 393 then
        return useMagus('commonlands', 'Magus Jerira')
    end
    return zoneId() == homeHubZone
end

-- Adventure assignment detection and Triune/group combat setup.
local function assignmentState()
    local dialogue = windowText('AdventureRequestWnd', 'AdvRqst_NPCText'):lower()
    local enterTimer = windowText('AdventureRequestWnd', 'AdvRqst_EnterTimeLeftLabel')
    local completeTimer = windowText('AdventureRequestWnd', 'AdvRqst_CompleteTimeLeftLabel')
    local progress = windowText('AdventureRequestWnd', 'AdvRqst_ProgressTextLabel')
    local unassigned = dialogue:find('not currently assigned', 1, true) ~= nil
    local assigned = not unassigned and (enterTimer ~= '' or completeTimer ~= '')
    local completed = adventureCompleted
    local current, total = progress:match('(%d+)%s*/%s*(%d+)')
    if not current then current, total = progress:lower():match('(%d+)%s+of%s+(%d+)') end
    if current and total and tonumber(total) > 0 and tonumber(current) >= tonumber(total) then
        completed = true
    end
    if progress:lower():find('complete', 1, true) or dialogue:lower():find('adventure is complete', 1, true) then
        completed = true
    end
    return assigned, completed, dialogue, progress
end

local function ensureTriune()
    if triuneReady then return true end
    local status = tostring(mq.TLO.Lua.Script('triune').Status() or '')
    if status ~= 'RUNNING' then
        mq.cmd('/lua run triune')
        for _ = 1, 120 do
            mq.delay(250)
            status = tostring(mq.TLO.Lua.Script('triune').Status() or '')
            if status == 'RUNNING' then break end
        end
    end
    if status ~= 'RUNNING' then
        echo('Triune is not running. Start it with /lua run triune, then use /ldon resume.')
        return false
    end
    triuneReady = true
    return true
end

local function refreshMissionOptions()
    local choices = {}
    if not mq.TLO.Window('AdventureRequestWnd').Open() then
        echo('Open the LDoN request window first to refresh the mission type dropdown.')
        return
    end
    local combo = mq.TLO.Window('AdventureRequestWnd').Child('AdvRqst_TypeCombobox')
    for index = 1, 10 do
        local ok, value = pcall(function() return combo.List(index)() end)
        if not ok then
            echo('Could not read the game mission-type list; retaining the verified mob-count option.')
            break
        end
        if value == nil or tostring(value) == '' then break end
        local label = tostring(value)
        local duplicate = false
        for _, choice in ipairs(choices) do
            if choice.label == label then duplicate = true; break end
        end
        if not duplicate then
            choices[#choices + 1] = { label = label, index = index }
        end
    end
    local mobCountFound = false
    for _, choice in ipairs(choices) do
        if choice.index == 3 then mobCountFound = true; break end
    end
    if not mobCountFound then
        choices[#choices + 1] = { label = 'Mob count (Slay / Kill / Ridding)', index = 3 }
    end
    missionOptions = choices
end

local function validateController(mainAssist)
    local me = tostring(mq.TLO.Me.CleanName() or '')
    local groupSize = tonumber(mq.TLO.Group()) or 0
    if groupSize > 0 and tostring(mq.TLO.Group.Leader.Name() or ''):lower() ~= me:lower() then
        echo('The local character must be group leader to run the mission controller.')
        return false
    end
    local selected = tostring(mainAssist or me):lower()
    local selectedFound = selected == me:lower()
    for index = 1, groupSize do
        local name = tostring(mq.TLO.Group.Member(index).Name() or '')
        if name:lower() == selected then selectedFound = true; break end
    end
    if not selectedFound then
        echo('The selected Main Assist is not a member of this group.')
        return false
    end
    return true
end

local function configureGroupTravel()
    local me = tostring(mq.TLO.Me.CleanName() or '')
    if not validateController(me) then return false end
    local grouped = (tonumber(mq.TLO.Group()) or 0) > 0
    if tostring(mq.TLO.Lua.Script('triune').Status() or '') == 'RUNNING' then
        mq.cmd('/ac pause')
        if grouped then mq.cmd('/ac net group pause') end
    end
    travelReady = true
    echo(grouped
        and 'Travel mode ready. Triune combat is disabled until the group enters the dungeon; keep group members with you.'
        or 'Solo travel mode ready. Triune combat is disabled until you enter the dungeon.')
    return true
end

local function configureGroupCombat()
    local me = tostring(mq.TLO.Me.CleanName() or '')
    local selected = mainAssistName ~= '' and mainAssistName or me
    if not validateController(selected) then return false end
    if not ensureTriune() then return false end

    mq.cmd('/ac ma ' .. selected)
    local grouped = (tonumber(mq.TLO.Group()) or 0) > 0
    if grouped then
        mq.cmd('/ac net group ma ' .. selected)
        mq.cmd('/ac net group assist chase')
    end
    mq.cmd('/ac puller hunt')
    if selected:lower() ~= me:lower() then
        mq.cmd('/ac net ' .. selected .. ' puller hunt')
    end
    mq.cmd('/ac run')
    if grouped then mq.cmd('/ac net group run') end
    combatRunStartedAt = mq.gettime()
    combatRunSends = 1
    combatZone = zoneId()
    startLongBuffs()
    startSwarmPull()
    echo(grouped and
        'Group leader set to Puller (Hunt); ' .. selected .. ' is the Main Assist' ..
            (selected:lower() ~= me:lower() and ' and also set to Puller (Hunt)' or '') ..
            '; remaining boxes set to Assist (Chase).' or
        'Solo Triune Hunt mode set for ' .. selected .. '.')
    return true
end

local function monitorCombatPosture()
    if not autoStandInCombat
        or mq.TLO.Me.Combat() ~= true
        or (mq.TLO.Me.Sitting() ~= true and mq.TLO.Me.Feigning() ~= true) then
        postureHoldNotice = false
        return
    end

    local function holdForHealth(hp, name)
        if hp == nil then
            return true, 'cannot confirm health for ' .. name
        end
        if hp <= 50 then
            return true, name .. ' is at or below 50% health'
        end
        return false
    end

    local hold, reason = holdForHealth(tonumber(mq.TLO.Me.PctHPs()), 'your')
    local groupSize = tonumber(mq.TLO.Group()) or 0
    if not hold then
        for index = 1, groupSize do
            local member = mq.TLO.Group.Member(index)
            local name = tostring(member.Name() or ('group member ' .. index))
            hold, reason = holdForHealth(tonumber(member.PctHPs()), name)
            if hold then break end
        end
    end
    if hold then
        if not postureHoldNotice then
            echo('Leaving sit/Feign Death unchanged: ' .. reason .. '.')
            postureHoldNotice = true
        end
        return
    end

    postureHoldNotice = false
    local now = mq.gettime()
    if now - lastStandAttemptAt < 2000 then return end
    mq.cmd('/stand')
    lastStandAttemptAt = now
    echo('Combat detected while sitting or Feign Death; you and any group members are above 50% HP, standing.')
end

local function recoverFromMeshIsolation()
    meshRecoveryRequested = false
    local zone = zoneId()
    if not active or not DUNGEONS[zone] then return true end
    if meshFailureKind == 'unmeshed' then
        meshRecoveryAwaitingManual = false
        meshRecoveryStatus = 'Your position is on connected mesh; the reported path failure is for an NPC. TAC remains active and will continue its bounded direct-approach attempts.'
        echo('Triune reports an NPC mesh-path issue, not a player isolation issue. Leaving TAC active so it can retry direct approach.')
        return true
    end
    if #meshRecoveryPoints > 1 and hasRouteFromSavedPoint(0) then
        meshRecoveryAwaitingManual = false
        meshRecoveryStatus = 'MQ2Nav confirms a path from your current position to a distinct saved position over 20 units away. This is not a player-isolation failure; no walkback or mesh reload is needed. TAC remains active to retry NPC targeting.'
        echo('MQ2Nav confirms connectivity from your current position to saved ground; skipping unnecessary walkback and mesh reload. TAC remains active.')
        return true
    end
    meshRecoveryAwaitingManual = false
    if mq.TLO.Me.Combat() == true or (tonumber(mq.TLO.Me.XTarget(1).ID()) or 0) > 0 then
        meshRecoveryRequested = true
        meshRecoveryStatus = 'Waiting for combat and XTargets to clear before moving.'
        mq.delay(1000)
        return true
    end
    local grouped = (tonumber(mq.TLO.Group()) or 0) > 0
    mq.cmd('/ac pause')
    if grouped then mq.cmd('/ac net group pause') end
    if mq.TLO.Plugin('MQ2Nav').IsLoaded() ~= true
        or mq.TLO.Plugin('MQ2MoveUtils').IsLoaded() ~= true then
        echo('Automatic mesh recovery requires both MQ2Nav and MQ2MoveUtils; TAC remains paused.')
        meshRecoveryStatus = 'Recovery unavailable: MQ2Nav or MQ2MoveUtils is not loaded.'
        active = false
        combatZone = 0
        return false
    end
    if #meshRecoveryPoints == 0 then
        echo('No recent confirmed MQ2Nav position is available. TAC is paused; move manually into pathable ground, then retry from the recovery window.')
        meshRecoveryStatus = 'No saved pathable position yet. TAC stays paused while the runner watches for a manually reached pathable location.'
        meshRecoveryAwaitingManual = true
        return true
    end

    local startZone = zone
    echo('Mesh recovery: TAC paused; walking back toward a recent confirmed navmesh position.')
    meshRecoveryStatus = 'Moving toward a recently confirmed MQ2Nav position.'
    mq.cmd('/nav stop')
    mq.cmd('/moveto off')

    local recovered = false
    local reloadAttempted = false
    for index, point in ipairs(meshRecoveryPoints) do
        meshRecoveryStatus = string.format(
            'Testing saved position %d/%d (Y %.1f, X %.1f, Z %.1f).',
            index, #meshRecoveryPoints, point.y, point.x, point.z)
        local reached = distance3DTo(point.y, point.x, point.z) <= 15
        if not reached then
            mq.cmdf('/moveto loc %.2f %.2f %.2f', point.y, point.x, point.z)
            local sawMovement = false
            for tick = 1, 12 * 4 do
                mq.doevents()
                if not active or zoneId() ~= startZone then
                    mq.cmd('/moveto off')
                    return false
                end
                if distance3DTo(point.y, point.x, point.z) <= 15 then
                    reached = true
                    break
                end
                if mq.TLO.MoveTo.Moving() == true then
                    sawMovement = true
                elseif sawMovement or tick >= 8 then
                    break
                end
                mq.delay(250)
            end
            mq.cmd('/moveto off')
        end
        if reached and not reloadAttempted then
            meshRecoveryStatus = 'Reloading the existing local MQ2Nav mesh, then checking path connectivity.'
            mq.cmd('/nav reload')
            reloadAttempted = true
            for _ = 1, 20 do
                mq.doevents()
                if not active or zoneId() ~= startZone then return false end
                if navigationMeshLoaded() and hasRouteFromSavedPoint(index) then
                    recovered = true
                    break
                end
                mq.delay(250)
            end
        elseif reached then
            recovered = navigationMeshLoaded() and hasRouteFromSavedPoint(index)
        end
        if recovered then break end
    end

    if not recovered then
        echo('Could not reach a recent confirmed navmesh position. TAC remains paused; manually reposition, then retry from the recovery window.')
        meshRecoveryStatus = 'Automatic recovery failed. TAC stays paused while the runner watches for a manually reached pathable location.'
        meshRecoveryAwaitingManual = true
        return true
    end

    echo('Reached a recent navmesh position; reconfiguring and resuming Triune.')
    meshRecoveryStatus = 'Path connectivity verified after reloading the existing local mesh; resuming Triune.'
    if not configureGroupCombat() then
        active = false
        combatZone = 0
        meshRecoveryStatus = 'Path restored, but Triune did not restart. TAC remains paused.'
        echo('Triune could not be restarted after mesh recovery. Reposition manually, then use /ldon resume.')
        return false
    end
    meshFailureActive = false
    return true
end

-- Recruiter interaction, including clearing invisibility before NPC actions.
local breakInvisibilityForInteraction

local function requestTask(hub, requestedMissionType)
    local me = tostring(mq.TLO.Me.CleanName() or '')
    local grouped = (tonumber(mq.TLO.Group()) or 0) > 0
    local leader = grouped and tostring(mq.TLO.Group.Leader.Name() or '') or me
    if grouped and (leader == '' or leader:lower() ~= me:lower()) then
        echo('You must be the group leader before requesting an LDoN task.')
        return false
    end
    if not breakInvisibilityForInteraction('the Adventure Recruiter') then return false end
    if not navToSpawn(hub.recruiter, 10) then return false end
    local recruiter = mq.TLO.Spawn('npc ' .. hub.recruiter)
    local recruiterId = tonumber(recruiter.ID()) or 0
    if recruiterId == 0 then return false end
    mq.cmdf('/target id %d', recruiterId)
    mq.delay(500)
    mq.cmd('/click right target')
    if not mq.TLO.Window('AdventureRequestWnd').Open() then
        mq.cmd('/windowstate AdventureRequestWnd open')
    end
    for _ = 1, 40 do
        if mq.TLO.Window('AdventureRequestWnd').Open() then break end
        mq.delay(250)
    end
    if not mq.TLO.Window('AdventureRequestWnd').Open() then
        echo('Adventure Request window did not open. No task was requested.')
        return false
    end
    refreshMissionOptions()
    missionTypeIndex = requestedMissionType or missionTypeIndex
    mq.delay(3000)
    mq.cmdf('/notify AdventureRequestWnd AdvRqst_RiskCombobox listselect %d', hardMode and 2 or 1)
    mq.cmdf('/notify AdventureRequestWnd AdvRqst_TypeCombobox listselect %d', missionTypeIndex)
    mq.delay(500)
    mq.cmd('/notify AdventureRequestWnd AdvRqst_RequestButton leftmouseup')
    for _ = 1, 80 do
        if mq.TLO.Window('AdventureRequestWnd').Child('AdvRqst_AcceptButton').Enabled() then break end
        mq.delay(250)
    end
    if not mq.TLO.Window('AdventureRequestWnd').Child('AdvRqst_AcceptButton').Enabled() then
        local message = windowText('AdventureRequestWnd', 'AdvRqst_NPCText')
        echo('No acceptable task appeared. Adventure NPC says: ' .. message)
        return false
    end
    adventureCompleted = false
    mq.cmd('/notify AdventureRequestWnd AdvRqst_AcceptButton leftmouseup')
    mq.delay(1500)
    mq.cmd('/target clear')
    local assigned = assignmentState()
    if not assigned then
        echo('The request was sent, but the task window does not show an active assignment.')
        return false
    end
    echo('Accepted a ' .. (hardMode and 'hard' or 'normal') .. ' LDoN task from ' .. hub.name .. '.')
    campaignTaskCounted = false
    return true
end

local MAGUS_NAMES_BY_ZONE = {
    [392] = 'Magus Arindri',
    [408] = 'Magus Zeir',
    [393] = 'Magus Jerira',
    [68] = 'Magus Tira',
    [30] = 'Magus Delin',
    [151] = 'Magus Alaria',
}

breakInvisibilityForInteraction = function(destination)
    local invisible = false
    local ok = pcall(function() invisible = mq.TLO.Me.Invis() == true end)
    if not ok then
        echo('Could not check invisibility before interacting with ' .. destination .. '.')
        return false
    end
    if not invisible then return true end
    if mq.TLO.Me.Combat() == true then
        echo('You are invisible and in combat; stopping before interacting with ' .. destination .. '.')
        return false
    end

    local selectedSpell
    local selectedSlot
    for slot = 1, 12 do
        local spellName = ''
        local spellReady = false
        local okSpell = pcall(function()
            spellName = tostring(mq.TLO.Me.Gem(slot).Name() or '')
            spellReady = mq.TLO.Me.SpellReady(slot)() == true
        end)
        if okSpell and spellName ~= '' and spellReady then
            local spell = mq.TLO.Spell(spellName)
            local beneficial = false
            local targetType = ''
            local okDetails = pcall(function()
                beneficial = spell.Beneficial() == true
                targetType = tostring(spell.TargetType() or ''):lower()
            end)
            local lowerName = spellName:lower()
            local invisibilitySpell = lowerName:find('invis', 1, true)
                or lowerName:find('shadow', 1, true)
                or lowerName:find('camouflage', 1, true)
                or lowerName:find('sneak', 1, true)
                or lowerName:find('hide', 1, true)
            if okDetails and beneficial and not invisibilitySpell
                and (targetType == 'self' or targetType == 'single') then
                selectedSpell = spellName
                selectedSlot = slot
                break
            end
        end
    end

    if not selectedSpell then
        echo('You are invisible, but no ready beneficial self/single-target spell is memorized to break invisibility. Remove invis manually or memorize a suitable spell, then resume.')
        return false
    end

    local previousTarget = tonumber(mq.TLO.Target.ID()) or 0
    local meId = tonumber(mq.TLO.Me.ID()) or 0
    if meId == 0 then
        echo('You are invisible, and MacroQuest could not identify your character to self-cast a spell.')
        return false
    end
    mq.cmdf('/target id %d', meId)
    mq.delay(250)
    echo('You are invisible; casting ' .. selectedSpell .. ' from gem ' .. selectedSlot .. ' on yourself before interacting with ' .. destination .. '.')
    mq.cmdf('/cast "%s"', selectedSpell)

    local invisibilityEnded = false
    local castFinished = false
    local sawCastStart = false
    for tick = 1, 240 do
        mq.doevents()
        local stateOk = pcall(function()
            invisibilityEnded = mq.TLO.Me.Invis() ~= true
            local casting = mq.TLO.Me.Casting()
            castFinished = casting == nil
            if not castFinished then sawCastStart = true end
        end)
        if not stateOk then
            echo('Could not verify that the invisibility-breaking spell finished.')
            return false
        end
        if invisibilityEnded and castFinished then break end
        if sawCastStart and castFinished then break end
        if not sawCastStart and tick >= 12 then break end
        mq.delay(250)
    end

    if not castFinished then
        echo('The invisibility-breaking spell did not finish; stopping before interacting with ' .. destination .. '.')
        return false
    end

    if invisibilityEnded then
        if previousTarget > 0 and previousTarget ~= meId then
            mq.cmdf('/target id %d', previousTarget)
        else
            mq.cmd('/target clear')
        end
        echo('Invisibility ended; continuing to ' .. destination .. '.')
        return true
    end

    echo('The spell finished, but invisibility is still active. Remove it manually before interacting with ' .. destination .. '.')
    return false
end

function useMagus(destination, magusName)
    local interactionRange = 10
    local startZone = zoneId()
    local magus = mq.TLO.Spawn('npc ' .. (magusName or MAGUS_NAMES_BY_ZONE[startZone] or 'Magus'))
    local magusId = tonumber(magus.ID()) or 0
    if magusId == 0 then
        magus = mq.TLO.Spawn('npc Magus')
        magusId = tonumber(magus.ID()) or 0
    end
    if magusId == 0 then
        echo('Could not find a Magus in ' .. zoneShortName() .. '.')
        return false
    end
    if not breakInvisibilityForInteraction('the Magus') then return false end
    local magusSpawn = mq.TLO.Spawn(magusId)
    if (tonumber(magusSpawn.Distance3D()) or math.huge) > interactionRange then
        local magusY = tonumber(magusSpawn.Y())
        local magusX = tonumber(magusSpawn.X())
        local currentY = tonumber(mq.TLO.Me.Y())
        local currentX = tonumber(mq.TLO.Me.X())
        if not magusY or not magusX or not currentY or not currentX then
            echo('Could not determine a reachable approach point for the Magus.')
            return false
        end

        local offsetY = currentY - magusY
        local offsetX = currentX - magusX
        local planarDistance = math.sqrt(offsetY ^ 2 + offsetX ^ 2)
        if planarDistance < 0.01 then
            offsetY = 1
            planarDistance = 1
        end
        local approachY = magusY + offsetY / planarDistance * 6
        local approachX = magusX + offsetX / planarDistance * 6
        -- The mesh often snaps the approach point a few units away; accept any
        -- spot that ends up in talking range, then fall back to walking at the NPC.
        navToLocation(approachY, approachX, nil, 5, 30)
        if (tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge) > interactionRange then
            mq.cmd('/nav stop')
            mq.cmdf('/nav id %d', magusId)
            waitForNavigation(30, function()
                return (tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge) <= interactionRange - 2
            end)
            mq.cmd('/nav stop')
        end
        if (tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge) > interactionRange then
            mq.cmdf('/moveto loc %.2f %.2f', magusY, magusX)
            for _ = 1, 24 do
                mq.delay(250)
                if (tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge) <= interactionRange - 2 then break end
            end
            mq.cmd('/moveto off')
        end
        if (tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge) > interactionRange then
            echo('Could not navigate to a close interaction point at the Magus.')
            return false
        end
    end
    local magusDistance = tonumber(mq.TLO.Spawn(magusId).Distance3D()) or math.huge
    if magusDistance > interactionRange then
        echo(string.format('Navigation stopped %.0f units from the Magus; not attempting dialogue.', magusDistance))
        return false
    end
    mq.cmdf('/target id %d', magusId)
    mq.delay(500)
    mq.cmd('/face fast')
    for attempt = 1, 2 do
        mq.cmdf('/say %s', destination)
        if waitForZoneChange(startZone, 30) then return true end
        if attempt == 1 then
            echo('Magus did not respond to "' .. destination .. '". Retrying once.')
            mq.cmd('/target id ' .. tostring(magusId))
            mq.cmd('/face fast')
        end
    end
    echo('Magus did not port to ' .. destination .. '.')
    return false
end

local MAGUS_DESTINATIONS = {
    [392] = 'North Ro',
    [408] = 'commonlands',
    [393] = 'South Ro',
    [68] = 'butcherblock',
    [30] = 'everfrost',
}

local function travelToCamp(targetHubZone)
    if zoneId() == targetHubZone then return true end
    local hub = HUBS[targetHubZone]
    local destination = MAGUS_DESTINATIONS[targetHubZone]
    if not hub or not destination then
        echo('No Magus destination is configured for the selected camp.')
        return false
    end
    echo('Switching camp to ' .. hub.name .. ' via Magus destination "' .. destination .. '".')
    if not useMagus(destination, MAGUS_NAMES_BY_ZONE[zoneId()]) then
        echo('Could not reach the selected camp. The campaign is paused; no mission will be requested at the wrong camp.')
        return false
    end
    if zoneId() ~= targetHubZone then
        echo('Magus travel completed in an unexpected zone; expected ' .. hub.name .. '.')
        return false
    end
    homeHubZone = targetHubZone
    echo('Arrived at the ' .. hub.name .. ' camp.')
    return true
end

local function clickSwitch(switchId)
    local before = zoneId()
    if switchId and switchId > 0 then
        mq.cmdf('/doortarget id %d', switchId)
    else
        mq.cmd('/doortarget')
    end
    for _ = 1, 20 do
        local targetId = tonumber(mq.TLO.DoorTarget.ID()) or 0
        if targetId ~= 0 and (not switchId or switchId == 0 or targetId == switchId) then break end
        mq.delay(250)
    end
    local doorId = tonumber(mq.TLO.DoorTarget.ID()) or 0
    if doorId == 0 or (switchId and switchId > 0 and doorId ~= switchId) then
        echo('Could not target the expected LDoN entrance switch.')
        return false
    end
    local distance = tonumber(mq.TLO.DoorTarget.Distance()) or math.huge
    if distance > 15 then
        local doorY = tonumber(mq.TLO.DoorTarget.Y())
        local doorX = tonumber(mq.TLO.DoorTarget.X())
        local currentY = tonumber(mq.TLO.Me.Y())
        local currentX = tonumber(mq.TLO.Me.X())
        if not doorY or not doorX or not currentY or not currentX then
            echo('Could not navigate within click range of the LDoN entrance switch.')
            return false
        end

        local offsetY = currentY - doorY
        local offsetX = currentX - doorX
        local planarDistance = math.sqrt(offsetY ^ 2 + offsetX ^ 2)
        if planarDistance < 0.01 then
            offsetY = 1
            planarDistance = 1
        end
        local directionY = offsetY / planarDistance
        local directionX = offsetX / planarDistance
        local approachAngles = { 0, 45, -45, 90, -90, 135, -135, 180 }
        local reachedClickRange = false
        for _, angle in ipairs(approachAngles) do
            local radians = math.rad(angle)
            local cosine = math.cos(radians)
            local sine = math.sin(radians)
            local approachY = doorY + (directionY * cosine - directionX * sine) * 10
            local approachX = doorX + (directionY * sine + directionX * cosine) * 10
            mq.cmd('/nav stop')
            -- The mesh snaps the point to another floor, so a "failed" nav can still
            -- leave the character in click range; judge by the door distance instead.
            navToLocation(approachY, approachX, nil, 4, 30)
            mq.cmdf('/doortarget id %d', doorId)
            mq.delay(250)
            local targetedId = tonumber(mq.TLO.DoorTarget.ID()) or 0
            distance = tonumber(mq.TLO.DoorTarget.Distance()) or math.huge
            if targetedId ~= 0 and targetedId == doorId and distance <= 15 then
                reachedClickRange = true
                break
            end
        end
        if not reachedClickRange then
            echo('Navmesh could not place me within click range; walking straight to the switch.')
            mq.cmd('/nav stop')
            mq.cmdf('/moveto loc %.2f %.2f', doorY, doorX)
            for _ = 1, 40 do
                mq.delay(250)
                mq.cmdf('/doortarget id %d', doorId)
                distance = tonumber(mq.TLO.DoorTarget.Distance()) or math.huge
                if distance <= 12 then break end
            end
            mq.cmd('/moveto off')
            mq.cmdf('/doortarget id %d', doorId)
            mq.delay(250)
            distance = tonumber(mq.TLO.DoorTarget.Distance()) or math.huge
            reachedClickRange = distance <= 15
        end
        if not reachedClickRange then
            echo('Could not navigate to a reachable point within click range of the LDoN entrance switch.')
            return false
        end

        local targetedId = tonumber(mq.TLO.DoorTarget.ID()) or 0
        if targetedId == 0 or targetedId ~= doorId then
            echo('The LDoN entrance switch was no longer targeted after moving.')
            return false
        end
        distance = tonumber(mq.TLO.DoorTarget.Distance()) or math.huge
        if distance > 15 then
            echo(string.format('Stopped %.0f units from the LDoN entrance switch; click range is 15.', distance))
            return false
        end
    end
    mq.cmd('/face fast door')
    mq.delay(300)
    mq.cmd('/click left door')
    return waitForZoneChange(before, 30)
end

local function enterTask(_, dialogue)
    local text = dialogue:lower()
    local entrance
    if homeHubZone == 392 then
        entrance = { zone = 'nro', switch = 3 }
    elseif homeHubZone == 408 then
        if zoneId() == 408 and not useMagus('South Ro') then return false end
        entrance = {
            zone = 'sro', approachSpawn = 'Scout_Miigle',
            switch = 1,
        }
    elseif homeHubZone == 393 then
        local function mentions(...)
            for _, phrase in ipairs({...}) do
                if text:find(phrase, 1, true) then return true end
            end
            return false
        end
        if mentions('barricaded door', 'guk portal', 'root garden') then
            entrance = { zone = 'guktop', switch = 0, path = {'innothule', 'guktop'} }
        elseif mentions('cauldron of lost souls', 'rotting tree trunk', 'tree trunk', 'innothule') then
            entrance = {
                zone = 'innothule', switch = 0, path = {'innothule'},
                waypoints = { { 1389.12, 1145.40, -15.62 }, { 1245.50, 1186.58, -10.49 } },
            }
        else
            entrance = { zone = 'guktop', switch = 0, path = {'innothule', 'guktop'} }
        end
    elseif homeHubZone == 68 then
        if text:find('grave', 1, true) then
            entrance = { zone = 'lfaydark', switch = 10, path = {'gfaydark', 'lfaydark'} }
        else
            entrance = { zone = 'lfaydark', switch = 7, path = {'gfaydark', 'lfaydark'} }
        end
    elseif homeHubZone == 30 then
        if text:find('hushed banquet', 1, true) or text:find('heart of the menagerie', 1, true) then
            entrance = { zone = 'everfrost', switch = 0 }
        else
            entrance = { zone = 'everfrost', switch = 0 }
        end
    end

    if not entrance then
        echo('No entrance route is configured for the selected camp.')
        return false
    end
    if entrance.path and zoneShortName() ~= entrance.zone and not travelAcrossZones(entrance.path) then return false end
    if zoneShortName() ~= entrance.zone then
        echo('Expected entrance zone ' .. entrance.zone .. ', but arrived in ' .. zoneShortName() .. '.')
        return false
    end
    if entrance.approachSpawn and not navToSpawn(entrance.approachSpawn) then
        echo('Could not reach the recorded zone-line approach NPC "' .. entrance.approachSpawn .. '".')
        return false
    end
    if entrance.waypoints then
        for _, point in ipairs(entrance.waypoints) do
            if not navToLocation(point[1], point[2], point[3], 3, 60) then
                echo('Could not reach the entrance approach point.')
                return false
            end
        end
    end
    if clickSwitch(entrance.switch) then return true end
    if zoneShortName() ~= entrance.zone then return false end
    local switchKey = 'switch_' .. entrance.zone .. '_' .. tostring(entrance.switch)
    return playRecordedPath(switchKey, zoneId()) and clickSwitch(entrance.switch)
end

local function waitUntilSafeToExit()
    for _ = 1, 1200 do
        if not active then return false end
        local xtarget = tonumber(mq.TLO.Me.XTarget(1).ID()) or 0
        local inCombat = mq.TLO.Me.Combat() == true
        if xtarget == 0 and not inCombat then return true end
        mq.doevents()
        mq.delay(250)
    end
    echo('Task is complete, but combat or an XTarget remained active for five minutes. Not clicking the exit.')
    return false
end

local function waitForCondition(timeoutMs, predicate)
    local ticks = math.floor(timeoutMs / 250)
    for _ = 1, ticks do
        mq.doevents()
        if not active then return false end
        if predicate() then return true end
        mq.delay(250)
    end
    return predicate()
end

local function windowOpen(name)
    return mq.TLO.Window(name).Open() == true
end

local function mapPortToEastCommonlands()
    local zone = zoneShortName()
    if zoneId() == 408 then return true end
    if zone ~= 'bazaar' then
        echo('The Bazaar waypoint map can only be used from the Bazaar or East Commonlands.')
        return false
    end

    if not navToLocation(-646.5, 2.9, 4.8) then return false end
    for _ = 1, 3 do
        mq.cmd('/doortarget id 146')
        if not waitForCondition(5000, function()
            return (tonumber(mq.TLO.DoorTarget.ID()) or 0) == 146
        end) then
            echo('Could not target the Bazaar waypoint map switch (146).')
            return false
        end
        mq.cmd('/face fast door')
        mq.delay(500)
        mq.cmd('/click left door')
        if waitForCondition(15000, function() return windowOpen('WaypointsWnd') end) then break end
    end
    if not windowOpen('WaypointsWnd') then
        echo('The Bazaar waypoint map window did not open.')
        return false
    end

    local child = function(name) return mq.TLO.Window('WaypointsWnd').Child(name) end
    mq.cmd('/notify WaypointsWnd ContinentsList listselect 1')
    if not waitForCondition(10000, function()
        return tonumber(child('ContinentsList').GetCurSel()) == 1
    end) then
        echo('The waypoint map did not select the continent list.')
        return false
    end
    if not waitForCondition(10000, function()
        return (tonumber(child('WaypointsList').Items()) or 0) > 0
    end) then
        echo('The waypoint map did not load its waypoint list.')
        return false
    end

    local waypointRow = tonumber(child('WaypointsList').List('=East Commonlands')()) or 0
    if waypointRow == 0 then
        echo('East Commonlands is not available in the Bazaar waypoint list.')
        return false
    end
    mq.cmdf('/notify WaypointsWnd WaypointsList listselect %d', waypointRow)
    if not waitForCondition(5000, function()
        return tonumber(child('WaypointsList').GetCurSel()) == waypointRow
    end) then
        echo('The waypoint list did not select East Commonlands.')
        return false
    end
    mq.cmd('/notify WaypointsWnd SelectedWaypointButton leftmouseup')
    waitForCondition(10000, function()
        return windowOpen('ConfirmationDialogBox') or windowOpen('LargeDialogWindow') or zoneShortName() ~= 'bazaar'
    end)
    if windowOpen('ConfirmationDialogBox') then
        mq.cmd('/notify ConfirmationDialogBox Yes_Button leftmouseup')
    end
    if windowOpen('LargeDialogWindow') then
        mq.cmd('/notify LargeDialogWindow LDW_YesButton leftmouseup')
    end
    if not waitForCondition(60000, function() return zoneId() == 408 end) then
        echo('The East Commonlands waypoint port did not complete.')
        return false
    end
    mq.cmd('/windowstate WaypointsWnd close')
    return true
end

local function returnViaBazaarAndMagus()
    if not mq.TLO.Me.AltAbility(331)() then
        echo('Bazaar and Back AA 331 is required for release-style return travel.')
        return false
    end
    if not waitForCondition(3 * 60 * 1000, function()
        return mq.TLO.Me.AltAbilityReady(331)() == true
    end) then
        echo('Bazaar and Back AA 331 is not ready; cannot use release-style return travel.')
        return false
    end
    mq.cmd('/alt activate 331')
    if not waitForCondition(60000, function()
        return zoneShortName() == 'bazaar' or zoneId() == 408
    end) then
        echo('Bazaar and Back did not transport to the Bazaar or East Commonlands.')
        return false
    end
    local returnedToBazaar = zoneShortName() == 'bazaar'
    if not returnedToBazaar and not mapPortToEastCommonlands() then return false end

    if returnedToBazaar or homeHubZone ~= 408 then
        local destination = MAGUS_DESTINATIONS[homeHubZone]
        if not destination then
            echo('No Magus destination is configured for the original camp.')
            return false
        end
        if not useMagus(destination, MAGUS_NAMES_BY_ZONE[zoneId()]) then return false end
    end
    if zoneId() ~= homeHubZone then
        echo('Return travel ended in the wrong hub zone.')
        return false
    end
    echo('Returned to the active campaign camp.')
    return true
end

local function returnToCampaignRecruiter(targetHubZone)
    local hub = HUBS[targetHubZone]
    if not hub then
        echo('No recruiter is configured for the selected campaign hub.')
        return false
    end

    homeHubZone = targetHubZone
    local hasBazaarAndBack = false
    local aaReady = false
    pcall(function()
        local ability = mq.TLO.Me.AltAbility(331)()
        hasBazaarAndBack = ability ~= nil and ability ~= false and ability ~= ''
        aaReady = mq.TLO.Me.AltAbilityReady(331)() == true
    end)

    local currentZone = zoneId()
    if DUNGEONS[currentZone] and not waitUntilSafeToExit() then return false end
    local returned = currentZone == targetHubZone
    local outsideLdon = not DUNGEONS[currentZone] and not ENTRY_ZONES[currentZone]
    if not returned and outsideLdon and zoneId() == 151 and MAGUS_DESTINATIONS[targetHubZone] then
        returned = useMagus(MAGUS_DESTINATIONS[targetHubZone], MAGUS_NAMES_BY_ZONE[151])
    elseif not returned and outsideLdon and hasBazaarAndBack then
        echo('Not in an LDoN zone; using Bazaar and Back to reach ' .. hub.name .. '.')
        returned = returnViaBazaarAndMagus()
    end
    if not returned and DUNGEONS[currentZone] and hasBazaarAndBack and aaReady then
        returned = returnViaBazaarAndMagus()
    end
    if not returned and DUNGEONS[zoneId()] then
        echo('Bazaar and Back is unavailable or not ready; using the dungeon exit and existing return route.')
        local route = DUNGEONS[zoneId()]
        if route.loc and not navToLocation(route.loc[1], route.loc[2], route.loc[3]) then return false end
        if not clickDoor(route.exit) then return false end
        if zoneId() ~= targetHubZone and not returnToHub() then return false end
        returned = zoneId() == targetHubZone
    end
    if not returned and ENTRY_ZONES[zoneId()] then
        returned = returnToHub() and zoneId() == targetHubZone
    end
    if not returned or zoneId() ~= targetHubZone then return false end
    if not navToSpawn(hub.recruiter, 10) then return false end
    return true
end

local function groupMembersAtRecruiter()
    local missing = {}
    local names = groupNames()
    for index = 2, #names do
        local name = names[index]
        local distance = math.huge
        pcall(function()
            local member = mq.TLO.Spawn('pc ' .. name)
            if member and member() then distance = tonumber(member.Distance3D()) or math.huge end
        end)
        if distance > 40 then missing[#missing + 1] = name end
    end
    return #missing == 0, missing
end

local function returnGroupToCampaignRecruiter()
    local hubZone = homeHubZone
    if hubZone == 0 or not HUBS[hubZone] then
        echo('Cannot coordinate group return: the active campaign hub is unknown.')
        return false
    end

    echo('Starting Bazaar and Back return for the group; BoxNet peers will meet at the campaign recruiter.')
    mq.cmd('/ac net group /lua run LDON_Triune')
    mq.delay(3000)
    mq.cmdf('/ac net group /ldon remote-return %d', hubZone)

    if not returnToCampaignRecruiter(hubZone) then
        echo('Could not return the controller to the campaign recruiter; runner paused.')
        return false
    end

    local arrived = waitForCondition(60000, function()
        local allArrived = groupMembersAtRecruiter()
        return allArrived
    end)
    if arrived then
        echo('All available group members arrived at the campaign recruiter.')
    else
        local _, missing = groupMembersAtRecruiter()
        echo('Group return wait reached one minute; continuing campaign processing. Not at the recruiter: ' ..
            (#missing > 0 and table.concat(missing, ', ') or 'BoxNet peers not visible'))
    end
    return true
end

local function exitTask(zone)
    local route = DUNGEONS[zone]
    if not route then return false end
    if not waitUntilSafeToExit() then return false end
    if (tonumber(mq.TLO.Group()) or 0) == 0 then
        mq.cmd('/ac pause')
        if returnViaBazaarAndMagus() then return true end
        if not DUNGEONS[zoneId()] then return false end
        echo('Bazaar and Back did not complete; using the dungeon exit and existing return route.')
        return returnToCampaignRecruiter(homeHubZone)
    end
    mq.cmd('/ac net group pause')
    return returnGroupToCampaignRecruiter()
end

-- Validate required movement support before starting or resuming a campaign.
local function validateTravelSetup()
    if mq.TLO.Plugin('MQ2Nav').IsLoaded() ~= true then
        echo('Load MQ2Nav before starting the LDoN runner.')
        return false
    end
    if mq.TLO.Plugin('MQ2MoveUtils').IsLoaded() ~= true then
        echo('Load MQ2MoveUtils before starting; recorded zone-line routes use /moveto.')
        return false
    end
    if (tonumber(mq.TLO.Group()) or 0) == 0 and not mq.TLO.Me.AltAbility(331)() then
        echo('Solo release-style return travel requires Bazaar and Back AA 331.')
        return false
    end
    return true
end

local function beginCampaign()
    if not campaignInitialized then
        local first = nextCampaignLeg(1)
        if not first then
            echo('Select at least one camp with a nonzero dungeon count before starting.')
            return false
        end
        campaignLegIndex = first
        campaignCompleted = {}
        for index = 1, #campaignPlan do campaignCompleted[index] = 0 end
        campaignTaskCounted = false
        campaignTravelPending = false
        campaignStopPending = false
        campaignInitialized = true
        stats.startedAt = 0
        stats.dungeons = 0
        stats.failures = 0
        stats.retries = 0
        stats.dungeonSeconds = 0
        stats.dungeonStartedAt = 0
        local activeLegCount = 0
        for _, leg in ipairs(campaignPlan) do
            if (leg.count or 0) > 0 then activeLegCount = activeLegCount + 1 end
        end
        echo(string.format('Campaign queued: %d camp leg(s), starting with %s.',
            activeLegCount, HUBS[campaignLeg().hubZone].name))
    end
    active = true
    if stats.startedAt == 0 then stats.startedAt = os.time() end
    failureStreak = 0
    saveSettings()
    if meshFailureActive then meshRecoveryRequested = true end
    return true
end

-- Starts the runner from any zone; the main loop travels to the first camp when needed.
local function startRunner()
    if not resolveHomeHub() then
        echo('Select at least one camp with a nonzero dungeon count, then press Start. You can start in any zone.')
        return false
    end
    if not validateTravelSetup() then return false end
    if not beginCampaign() then return false end
    local zone = zoneId()
    if not HUBS[zone] and not ENTRY_ZONES[zone] and not DUNGEONS[zone] then
        echo('You are not in an LDoN zone. The runner will travel to ' .. HUBS[homeHubZone].name ..
            ' first and request an adventure if you do not already have one.')
    end
    return true
end

-- Walks or ports the group to the camp that owns the current assignment, or the first camp.
local function travelToStartHub(dialogue, assigned, completed)
    local target = assigned and not completed and hubFromAssignment(dialogue) or nil
    if not target then
        local leg = campaignLeg()
        target = leg and leg.hubZone or homeHubZone
    end
    if not target or not HUBS[target] then return false end
    homeHubZone = target
    if (tonumber(mq.TLO.Group()) or 0) > 0 then return returnGroupToCampaignRecruiter() end
    return returnToCampaignRecruiter(target)
end

-- Presses Leave Adventure on a finished assignment so the window returns to its request state.
local function clearFinishedAssignment()
    if not mq.TLO.Window('AdventureRequestWnd').Open() then
        mq.cmd('/windowstate AdventureRequestWnd open')
        mq.delay(500)
    end
    mq.cmd('/notify AdventureRequestWnd AdvRqst_RequestButton leftmouseup')
    mq.delay(1000)
    if mq.TLO.Window('ConfirmationDialogBox').Open() then
        mq.cmd('/notify ConfirmationDialogBox Yes_Button leftmouseup')
    end
    if mq.TLO.Window('LargeDialogWindow').Open() then
        mq.cmd('/notify LargeDialogWindow LDW_YesButton leftmouseup')
    end
    mq.delay(1500)
    return not (assignmentState())
end

-- Returns the runner and window to the idle state so a new run can begin without a restart.
local function finishCampaign(message)
    active = false
    campaignInitialized = false
    campaignStopPending = false
    campaignTravelPending = false
    campaignTaskCounted = false
    campaignLegIndex = nextCampaignLeg(1) or 1
    for index = 1, #campaignPlan do campaignCompleted[index] = 0 end
    travelReady = false
    combatZone = 0
    combatRunSends = 0
    adventureCompleted = false
    failureStreak = 0
    lastNotice = ''
    stopSwarmPull(false)
    mq.cmd('/nav stop')
    mq.cmd('/ac pause')
    if (tonumber(mq.TLO.Group()) or 0) > 0 then mq.cmd('/ac net group pause') end
    saveSettings()
    echo(message)
end

local function recordCampaignCompletion()
    if campaignTaskCounted then return end
    campaignTaskCounted = true
    failureStreak = 0
    stats.dungeons = stats.dungeons + 1
    if stats.dungeonStartedAt > 0 then
        stats.dungeonSeconds = stats.dungeonSeconds + (os.time() - stats.dungeonStartedAt)
        stats.dungeonStartedAt = 0
    end
    local leg = campaignLeg()
    if not leg then
        campaignStopPending = true
        return
    end
    campaignCompleted[campaignLegIndex] = (campaignCompleted[campaignLegIndex] or 0) + 1
    local completedCount = campaignCompleted[campaignLegIndex]
    echo(string.format('Completed dungeon %d/%d for %s.',
        completedCount, leg.count, HUBS[leg.hubZone].name))
    if completedCount < leg.count then return end

    local nextIndex = nextCampaignLeg(campaignLegIndex + 1)
    if nextIndex then
        campaignLegIndex = nextIndex
        campaignTravelPending = true
        echo('Camp leg complete; the next camp is ' .. HUBS[campaignLeg().hubZone].name .. '.')
    elseif campaignLoop then
        campaignLegIndex = nextCampaignLeg(1)
        for index = 1, #campaignPlan do campaignCompleted[index] = 0 end
        campaignTravelPending = true
        echo('Campaign lap complete; starting the configured route again at ' ..
            HUBS[campaignLeg().hubZone].name .. '.')
    else
        campaignStopPending = true
        echo('All configured camp runs are complete; stopping after return travel and task cleanup.')
    end
end

-- Campaign completion accounting and command-line status reporting.
local function status()
    local zone = zoneId()
    local assigned, completed, _, progress = assignmentState()
    local zoneName = tostring(mq.TLO.Zone.ShortName() or zone)
    echo(string.format(
        'active=%s zone=%s task=%s complete=%s progress="%s" hardmode=%s campaignLeg=%d camp=%s completed=%d/%d',
        tostring(active), zoneName, tostring(assigned), tostring(completed), progress, tostring(hardMode),
        campaignLegIndex, campaignLeg() and HUBS[campaignLeg().hubZone].name or 'none',
        campaignCompleted[campaignLegIndex] or 0,
        campaignLeg() and campaignLeg().count or 0))
end

local function groupNames()
    local names = { tostring(mq.TLO.Me.CleanName() or '') }
    local count = tonumber(mq.TLO.Group()) or 0
    for index = 1, count do
        local name = tostring(mq.TLO.Group.Member(index).Name() or '')
        if name ~= '' then names[#names + 1] = name end
    end
    return names
end

local function selectedAssistIndex(names)
    for index, name in ipairs(names) do
        if name:lower() == mainAssistName:lower() then return index end
    end
    return 1
end

-- Preflight checklist, run summary, and diagnostics text for the window and /ldon commands.
local CAMP_MESH_ZONES = {
    [392] = { 'nro' },
    [408] = { 'commons' },
    [393] = { 'sro', 'innothule', 'guktop' },
    [68] = { 'butcher', 'gfaydark', 'lfaydark' },
    [30] = { 'everfrost' },
}

local function runPreflight()
    local results = {}
    local function check(passed, label, detail)
        results[#results + 1] = { passed = passed, text = label .. (detail and (': ' .. detail) or '') }
    end
    check(pluginLoaded('MQ2Nav'), 'MQ2Nav loaded')
    check(pluginLoaded('MQ2MoveUtils'), 'MQ2MoveUtils loaded')
    check(tostring(mq.TLO.Lua.Script('triune').Status() or '') == 'RUNNING', 'Triune running')
    local grouped = (tonumber(mq.TLO.Group()) or 0) > 0
    if grouped then
        check(pluginLoaded('MQ2EQBC') or pluginLoaded('MQ2DanNet'), 'BoxNet transport plugin loaded')
    else
        check(mq.TLO.Me.AltAbility(331)() and true or false, 'Bazaar and Back AA 331 trained')
    end
    local meshDirectory = tostring(mq.TLO.MacroQuest.Path('resources')() or 'resources'):gsub('\\', '/') .. '/MQ2Nav/'
    local seen = {}
    local missing = {}
    local function needMesh(shortName)
        if seen[shortName] then return end
        seen[shortName] = true
        local file = io.open(meshDirectory .. shortName .. '.navmesh', 'r')
        if file then file:close() else missing[#missing + 1] = shortName end
    end
    needMesh('bazaar')
    for _, leg in ipairs(campaignPlan) do
        if (leg.count or 0) > 0 then
            for _, shortName in ipairs(CAMP_MESH_ZONES[leg.hubZone] or {}) do needMesh(shortName) end
        end
    end
    check(#missing == 0, 'Navmeshes for the selected camps',
        #missing > 0 and ('missing ' .. table.concat(missing, ', ')) or nil)
    if useLongBuffs then
        local rosterCount = longBuffRosterCount()
        check(longBuffsInstalled() and (rosterCount or 0) > 0, 'Long-Duration Buffs',
            not longBuffsInstalled() and 'lua/tac/long_buffs.lua not found'
            or ((rosterCount or 0) == 0 and 'roster is empty; build it in Triune Settings > Plugins' or nil))
    end
    if useSwarmPull then
        check(swarmPullInstalled(), 'Swarm Pull plugin', not swarmPullInstalled() and 'plugin file not found in lua/tac' or nil)
    end
    if useAdvPath then
        check(advPathLoaded(), 'MQ2AdvPath loaded', not advPathLoaded() and 'use /plugin MQ2AdvPath' or nil)
    end
    preflightResults = results
    local failed = 0
    for _, result in ipairs(results) do
        if not result.passed then failed = failed + 1 end
        echo((result.passed and 'OK   ' or 'FAIL ') .. result.text)
    end
    echo(failed == 0 and 'Preflight passed.' or string.format('Preflight found %d problem(s).', failed))
    return failed == 0
end

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format('%d:%02d:%02d', math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
end

local function runSummary()
    local elapsed = stats.startedAt > 0 and (os.time() - stats.startedAt) or 0
    local average = stats.dungeons > 0 and math.floor(stats.dungeonSeconds / stats.dungeons) or 0
    return string.format('Elapsed %s | dungeons %d (avg %s) | failures %d | retries %d',
        formatDuration(elapsed), stats.dungeons, formatDuration(average), stats.failures, stats.retries)
end

local function diagnosticsText()
    local assigned, completed, _, progress = assignmentState()
    local lines = {
        'LDoN Triune Runner v' .. VERSION,
        string.format('zone=%s active=%s assigned=%s completed=%s progress="%s"',
            tostring(mq.TLO.Zone.ShortName() or '?'), tostring(active), tostring(assigned), tostring(completed), progress),
        string.format('leg=%d homeHub=%d grouped=%s mainAssist=%s', campaignLegIndex, homeHubZone,
            tostring((tonumber(mq.TLO.Group()) or 0) > 0), mainAssistName),
        string.format('longBuffs=%s swarmPull=%s swarmActive=%s retryLimit=%d', tostring(useLongBuffs),
            tostring(useSwarmPull), tostring(swarmActive), retryLimit),
        'lastFailure=' .. (lastFailure ~= '' and lastFailure or 'none'),
        runSummary(),
        '--- recent log ---',
    }
    for _, line in ipairs(recentLog) do lines[#lines + 1] = line end
    return table.concat(lines, '\n')
end

-- Zone-themed artwork and the main campaign window.
local ART_THEMES = {
    takish = {
        title = 'TAKISH-HIZ', subtitle = 'SUNLIT DESERT RUINS',
        asset = 'takish', file = 'takish.jpg',
        accent = { 0.70, 0.34, 0.15 },
    },
    rujark = {
        title = 'RUJARKIAN HILLS', subtitle = 'THE ORCISH STRONGHOLD',
        asset = 'rujark', file = 'rujark.jpg',
        accent = { 0.58, 0.25, 0.18 },
    },
    mistmoore = {
        title = 'MISTMOORE', subtitle = 'MOONLIT GOTHIC KEEP',
        asset = 'mistmoore', accent = { 0.28, 0.34, 0.58 },
    },
    miragul = {
        title = 'MIRAGUL', subtitle = 'FROSTBOUND NECROPOLIS',
        asset = 'miragul', file = 'miragul.jpg',
        accent = { 0.18, 0.48, 0.60 },
    },
    guk = {
        title = 'DEEPEST GUK', subtitle = "THE WIT'S END",
        asset = 'guk', accent = { 0.30, 0.45, 0.25 },
    },
}

local function missionArtTheme()
    local zone = zoneId()
    local dungeon = DUNGEONS[zone]
    if dungeon then return ART_THEMES[dungeon.family] end

    local currentHub = HUBS[zone]
    if currentHub then return ART_THEMES[currentHub.family] or ART_THEMES.takish end

    if zone == 54 or zone == 57 then return ART_THEMES.mistmoore end
    if zone == 413 or zone == 65 then return ART_THEMES.guk end

    local leg = campaignInitialized and campaignLeg() or nil
    if active and leg and leg.count > 0 then
        local plannedHub = HUBS[leg.hubZone]
        if plannedHub then return ART_THEMES[plannedHub.family] or ART_THEMES.takish end
    end

    if homeHubZone ~= 0 and HUBS[homeHubZone] then
        local family = HUBS[homeHubZone].family
        return ART_THEMES[family] or ART_THEMES.takish
    end
    return ART_THEMES.takish
end

-- Reads the real pixel size from a PNG or JPEG header; the texture size reported by
-- MacroQuest is the (possibly padded) GPU texture size, not the image size.
local function imageFileSize(path)
    local file = io.open(path, 'rb')
    if not file then return nil end
    local data = file:read('*a')
    file:close()
    if not data or #data < 24 then return nil end
    if data:sub(2, 4) == 'PNG' then
        local w1, w2, w3, w4, h1, h2, h3, h4 = data:byte(17, 24)
        return w1 * 16777216 + w2 * 65536 + w3 * 256 + w4, h1 * 16777216 + h2 * 65536 + h3 * 256 + h4
    end
    if data:byte(1) == 0xFF and data:byte(2) == 0xD8 then
        local pos = 3
        while pos + 9 <= #data do
            if data:byte(pos) ~= 0xFF then
                pos = pos + 1
            else
                local marker = data:byte(pos + 1)
                if marker == 0xFF then
                    pos = pos + 1
                elseif marker >= 0xC0 and marker <= 0xCF and marker ~= 0xC4 and marker ~= 0xC8 and marker ~= 0xCC then
                    local h1, h2, w1, w2 = data:byte(pos + 5, pos + 8)
                    return w1 * 256 + w2, h1 * 256 + h2
                else
                    local l1, l2 = data:byte(pos + 2, pos + 3)
                    pos = pos + 2 + l1 * 256 + l2
                end
            end
        end
    end
    return nil
end

local sourcePath = debug.getinfo(1, 'S').source:gsub('^@', '')
local scriptDirectory = sourcePath:match('^(.*)[/\\]') or '.'
local artTextures = {}
local artSourceSizes = {}
local unavailableArt = {}
for family in pairs(ART_THEMES) do
    local filename = ART_THEMES[family].file or (family .. '.png')
    local path = scriptDirectory .. '\\ldon_art\\' .. filename
    local file = io.open(path, 'rb')
    if file then
        file:close()
        local ok, texture = pcall(mq.CreateTexture, path)
        if ok and texture then
            artTextures[family] = texture
            local imageWidth, imageHeight = imageFileSize(path)
            if imageWidth and imageHeight then artSourceSizes[family] = { w = imageWidth, h = imageHeight } end
        else
            unavailableArt[#unavailableArt + 1] = filename
        end
    else
        unavailableArt[#unavailableArt + 1] = filename
    end
end
if #unavailableArt > 0 then
    echo('Optional artwork unavailable (' .. table.concat(unavailableArt, ', ') ..
        '); continuing with the runner UI without those images.')
end

-- Crops to cover the target area without stretching, sampling only the real image
-- region of a texture that may be padded to a larger size.
local function artUvRect(family, texture, areaWidth, areaHeight)
    local source = artSourceSizes[family]
    local size = texture.size
    local textureWidth = size and tonumber(size.x) or 0
    local textureHeight = size and tonumber(size.y) or 0
    if not source or areaWidth <= 0 or areaHeight <= 0 then return 0, 0, 1, 1 end
    local imageWidth, imageHeight = source.w, source.h
    local maxU, maxV = 1, 1
    if textureWidth >= imageWidth and textureHeight >= imageHeight then
        maxU = imageWidth / textureWidth
        maxV = imageHeight / textureHeight
    end
    local visibleU, visibleV = 1, 1
    if areaWidth / areaHeight > imageWidth / imageHeight then
        visibleV = (imageWidth / imageHeight) / (areaWidth / areaHeight)
    else
        visibleU = (areaWidth / areaHeight) / (imageWidth / imageHeight)
    end
    local startU = (1 - visibleU) / 2
    local startV = (1 - visibleV) / 2
    return startU * maxU, startV * maxV, (startU + visibleU) * maxU, (startV + visibleV) * maxV
end

local function drawMissionBackground()
    local theme = missionArtTheme()
    local texture = artTextures[theme.asset]
    if texture then
        local drawList = ImGui.GetWindowDrawList()
        local cursor = ImGui.GetCursorScreenPosVec()
        local windowPos = ImGui.GetWindowPosVec()
        local windowSize = ImGui.GetWindowSizeVec()
        local topLeft = ImVec2(windowPos.x + 1, cursor.y)
        local bottomRight = ImVec2(windowPos.x + windowSize.x - 1, windowPos.y + windowSize.y - 1)
        local u0, v0, u1, v1 = artUvRect(theme.asset, texture, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
        drawList:AddImage(texture:GetTextureID(), topLeft, bottomRight, ImVec2(u0, v0), ImVec2(u1, v1))
        drawList:AddRectFilled(topLeft, bottomRight, 0xA8000000)
    end

    local title = theme.title .. '  /  ' .. theme.subtitle
    local titlePosition = ImGui.GetCursorScreenPosVec()
    local drawList = ImGui.GetWindowDrawList()
    local outline = 0xE6000000
    for _, offset in ipairs({ {-1, 0}, {1, 0}, {0, -1}, {0, 1} }) do
        drawList:AddText(ImVec2(titlePosition.x + offset[1], titlePosition.y + offset[2]), outline, title)
    end
    ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.96, 0.82, 1.0)
    ImGui.TextWrapped(title)
    ImGui.PopStyleColor()
end

local function boundedComboWidth(labels, maxWidth)
    local textWidth = 0
    for _, label in ipairs(labels) do
        local labelWidth = ImGui.CalcTextSize(label)
        textWidth = math.max(textWidth, labelWidth)
    end
    local availableWidth = ImGui.GetContentRegionAvailVec().x
    return math.min(maxWidth, availableWidth, textWidth + 40)
end

local function drawUI()
    if not uiOpen then return end
    if not missionWindowSized then
        ImGui.SetNextWindowSize(1000, 620)
        missionWindowSized = true
    end
    ImGui.SetNextWindowSizeConstraints(ImVec2(700, 480), ImVec2(1280, 1024))
    local accent = missionArtTheme().accent
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.035, 0.043, 0.061, 0.98)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.48, 0.37, 0.20, 0.85)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.07, 0.08, 0.11, 1.0)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, accent[1] * 0.38, accent[2] * 0.38, accent[3] * 0.38, 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.09, 0.11, 0.15, 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, accent[1] * 0.36, accent[2] * 0.36, accent[3] * 0.36, 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, accent[1] * 0.52, accent[2] * 0.52, accent[3] * 0.52, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Button, accent[1] * 0.48, accent[2] * 0.48, accent[3] * 0.48, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, accent[1] * 0.68, accent[2] * 0.68, accent[3] * 0.68, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, accent[1] * 0.88, accent[2] * 0.88, accent[3] * 0.88, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Header, accent[1] * 0.38, accent[2] * 0.38, accent[3] * 0.38, 1.0)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, accent[1] * 0.58, accent[2] * 0.58, accent[3] * 0.58, 1.0)
    ImGui.PushStyleColor(ImGuiCol.HeaderActive, accent[1] * 0.78, accent[2] * 0.78, accent[3] * 0.78, 1.0)
    ImGui.PushStyleColor(ImGuiCol.CheckMark, 0.95, 0.78, 0.38, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.99, 0.98, 0.94, 1.0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 3)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 3)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 7, 5)
    local open, visible = ImGui.Begin('LDoN Triune Runner v' .. VERSION, uiOpen)
    uiOpen = open
    if not open then
        active = false
        shuttingDown = true
        mq.cmd('/nav stop')
    end
    if visible then
        ImGui.SetWindowFontScale(1.15)
        drawMissionBackground()
        ImGui.Separator()
        if ImGui.Button(active and 'Pause task runner' or 'Start campaign') then
            if active then
                active = false
                mq.cmd('/nav stop')
                stopSwarmPull(false)
                saveSettings()
            else
                startRunner()
            end
        end
        ImGui.SameLine()
        if ImGui.Button('Refresh task types') then refreshMissionOptions() end
        if meshFailureActive and not meshPopupOpen then
            if ImGui.Button('Open navigation diagnostics') then meshPopupOpen = true end
        end
        ImGui.Separator()
        ImGui.TextWrapped('Adventure difficulty')
        ImGui.SetNextItemWidth(160)
        local difficultyChoice = ImGui.Combo('##difficulty', hardMode and 2 or 1, { 'Normal', 'Hard' })
        if difficultyChoice then hardMode = difficultyChoice == 2 end
        if ImGui.IsItemHovered() then ImGui.SetTooltip('Risk level requested from the recruiter for every adventure. Applies to the next adventure request.') end
        local swarmToggle = ImGui.Checkbox('Use Swarm Pull (Triune AutoCombat plugin) inside dungeons', useSwarmPull)
        if swarmToggle ~= useSwarmPull then setSwarmPull(swarmToggle) end
        if ImGui.IsItemHovered() then ImGui.SetTooltip('Pulls groups of mobs at once. Best for kill or mob-count tasks. Pull count and radius are under Options.') end
        local names = groupNames()
        local assistIndex = selectedAssistIndex(names)
        ImGui.TextWrapped('Main Assist / puller')
        ImGui.SetNextItemWidth(boundedComboWidth(names, 300))
        local newAssist = ImGui.Combo('##mainAssist', assistIndex, names)
        if newAssist and names[newAssist] then mainAssistName = names[newAssist] end
        autoStandInCombat = ImGui.Checkbox('Auto-stand from sitting / Feign Death in combat', autoStandInCombat)
        ImGui.TextWrapped('Only when you and all group members are above 50% HP.')
        campaignLoop = ImGui.Checkbox('Repeat campaign after final camp', campaignLoop)
        ImGui.Separator()
        ImGui.TextWrapped(runSummary())
        if lastFailure ~= '' then ImGui.TextWrapped('Last failure: ' .. lastFailure) end
        if ImGui.Button('Stop after current dungeon') then
            campaignStopPending = true
            echo('The campaign will stop after the current dungeon is completed and the runner returns to camp.')
        end
        ImGui.SameLine()
        if ImGui.Button('Run preflight check') then runPreflight() end
        ImGui.SameLine()
        if ImGui.Button('Copy diagnostics') then ImGui.SetClipboardText(diagnosticsText()) end
        ImGui.SameLine()
        if ImGui.Button('Save settings') then
            echo(saveSettings() and 'Settings saved.' or 'Could not write the settings file.')
        end
        for _, result in ipairs(preflightResults) do
            if result.passed then
                ImGui.TextColored(0.45, 0.9, 0.55, 1.0, 'OK    ' .. result.text)
            else
                ImGui.TextColored(1.0, 0.45, 0.35, 1.0, 'FAIL  ' .. result.text)
            end
        end
        if not active and not campaignInitialized then
            ImGui.TextColored(0.95, 0.78, 0.38, 1.0, 'Quick start: 1) pick your Main Assist  2) choose runs and task type for each camp below  3) press Start campaign.')
        end
        if ImGui.CollapsingHeader('How to use this window') then
            ImGui.TextWrapped('1. Form your group (if grouped) and stand anywhere. In a supported LDoN camp the runner starts right there; from any other zone it travels to your first camp using Bazaar and Back and the Magus, and only requests an adventure if you do not already have one.')
            ImGui.TextWrapped('2. Click "Run preflight check". Anything marked FAIL tells you what to fix first.')
            ImGui.TextWrapped('3. Choose the Main Assist, then set runs and task type for each camp in the table.')
            ImGui.TextWrapped('4. Press "Start campaign". Use "Stop after current dungeon" for a clean stop, or Pause at any time.')
            ImGui.TextWrapped('Your choices are saved per character. The defaults are safe: you do not need the options below to run.')
            ImGui.TextWrapped('Commands: /ldon start | pause | finish | preflight | save')
        end
        if ImGui.CollapsingHeader('Options and optional plugins') then
            if ImGui.Button('Apply recommended settings') then
                retryLimit = 2
                stopAfterMinutes = 0
                useLongBuffs = longBuffsInstalled()
                useAdvPath = false
                advPathFirst = false
                useSwarmPull = false
                hardMode = true
                echo('Recommended settings applied.')
            end
            ImGui.TextWrapped('Recommended: auto-retry 2, Long-Duration Buffs on if installed, everything else off until you need it.')
            ImGui.Separator()
            ImGui.TextColored(0.95, 0.78, 0.38, 1.0, 'Basic')
            retryLimit = ImGui.SliderInt('Auto-retry limit', retryLimit, 0, 5)
            if ImGui.IsItemHovered() then ImGui.SetTooltip('How many times a failed step is retried before the runner pauses. Recommended: 2.') end
            stopAfterMinutes = ImGui.SliderInt('Stop after minutes (0 = off)', stopAfterMinutes, 0, 480)
            if ImGui.IsItemHovered() then ImGui.SetTooltip('Finish the current dungeon once this many minutes have passed, then stop. 0 means never.') end
            ImGui.Separator()
            ImGui.TextColored(0.95, 0.78, 0.38, 1.0, 'Advanced (optional plugins)')
            useLongBuffs = ImGui.Checkbox('Long-Duration Buffs (Triune plugin by Triune)', useLongBuffs)
            if longBuffsInstalled() then
                ImGui.TextColored(0.45, 0.9, 0.55, 1.0, 'Installed. Recommended: on. Build the roster once in Triune Settings > Plugins.')
            else
                ImGui.TextColored(1.0, 0.45, 0.35, 1.0, 'Not installed. Leave this off, or add tac\\long_buffs.lua.')
            end
            useAdvPath = ImGui.Checkbox('MQ2AdvPath recorded routes (for trouble spots)', useAdvPath)
            if advPathLoaded() then
                ImGui.TextColored(0.45, 0.9, 0.55, 1.0, 'Plugin loaded. Only helps where you have recorded a route; otherwise leave off.')
            else
                ImGui.TextColored(1.0, 0.45, 0.35, 1.0, 'MQ2AdvPath is not loaded. Run /plugin MQ2AdvPath first.')
            end
            if useAdvPath then
                advPathFirst = ImGui.Checkbox('Try recordings before built-in navigation', advPathFirst)
                if ImGui.IsItemHovered() then ImGui.SetTooltip('Off (recommended): built-in navigation first, recording only as a fallback.') end
                ImGui.TextWrapped('To record: stand at the start, type /ldon record start, walk the route, then /ldon record save <key>. Keys: sro_to_innothule, innothule_to_guktop, butcher_to_gfaydark, gfaydark_to_lfaydark, switch_guktop_0.')
            end
            ImGui.TextColored(0.95, 0.78, 0.38, 1.0, 'Swarm Pull (plugin by matth)')
            if swarmPullInstalled() then
                ImGui.TextColored(0.45, 0.9, 0.55, 1.0, 'Installed. Best for kill or mob-count tasks; skip it for rescue, recover or explore tasks.')
            else
                ImGui.TextColored(1.0, 0.45, 0.35, 1.0, 'Not installed. Leave this off, or add tac\\Swarm_Pull_v2.0.lua.')
            end
            if useSwarmPull then
                swarmPullCount = ImGui.SliderInt('Pull count', swarmPullCount, 1, 20)
                if ImGui.IsItemHovered() then ImGui.SetTooltip('Mobs pulled at once. Start low (3-5) and raise it if your group handles it.') end
                swarmPullRadius = ImGui.SliderInt('Pull radius', swarmPullRadius, 20, 1000)
                if ImGui.IsItemHovered() then ImGui.SetTooltip('How far to look for mobs. 150-300 is typical.') end
                ImGui.TextWrapped('Important: turn off "Reset via Bazaar when idle" in the Swarm Pull window, or it can pull you out of the dungeon.')
            end
        end
        ImGui.Separator()
        ImGui.TextWrapped("Camps follow this server's unlock order; skipped camps are left out.")
        if ImGui.BeginTable('##campaignPlan', 4, ImGuiTableFlags.SizingStretchProp) then
            ImGui.TableSetupColumn('Camp', ImGuiTableColumnFlags.WidthFixed, 270)
            ImGui.TableSetupColumn('Runs', ImGuiTableColumnFlags.WidthFixed, 120)
            ImGui.TableSetupColumn('Done', ImGuiTableColumnFlags.WidthFixed, 72)
            ImGui.TableSetupColumn('Task type', ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableHeadersRow()
            for index, leg in ipairs(campaignPlan) do
                local countChoice = 1
                for optionIndex, count in ipairs(CAMPAIGN_COUNTS) do
                    if count == leg.count then countChoice = optionIndex; break end
                end
                local missionChoice = 1
                for optionIndex, choice in ipairs(missionOptions) do
                    if choice.index == leg.missionTypeIndex then missionChoice = optionIndex; break end
                end
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextWrapped(CAMP_DISPLAY[leg.hubZone])
                ImGui.TableNextColumn()
                if campaignInitialized or active then
                    ImGui.TextWrapped(CAMPAIGN_COUNT_LABELS[countChoice])
                else
                    ImGui.SetNextItemWidth(boundedComboWidth(CAMPAIGN_COUNT_LABELS, 120))
                    local newCount = ImGui.Combo('##runs_' .. tostring(leg.hubZone), countChoice, CAMPAIGN_COUNT_LABELS)
                    if newCount and CAMPAIGN_COUNTS[newCount] ~= nil then
                        leg.count = CAMPAIGN_COUNTS[newCount]
                    end
                end
                ImGui.TableNextColumn()
                if campaignInitialized or active then
                    ImGui.Text(string.format('%d/%d', campaignCompleted[index] or 0, leg.count or 0))
                else
                    ImGui.TextDisabled('-')
                end
                ImGui.TableNextColumn()
                if campaignInitialized or active then
                    ImGui.TextWrapped(missionOptions[missionChoice].label)
                else
                    local missionLabels = {}
                    for optionIndex, choice in ipairs(missionOptions) do missionLabels[optionIndex] = choice.label end
                    ImGui.SetNextItemWidth(boundedComboWidth(missionLabels, 300))
                    local newMission = ImGui.Combo('##task_' .. tostring(leg.hubZone), missionChoice, missionLabels)
                    if newMission and missionOptions[newMission] then
                        leg.missionTypeIndex = missionOptions[newMission].index
                    end
                end
            end
            ImGui.EndTable()
        end
        if not campaignInitialized and not active then
            ImGui.TextWrapped(
                'Runs: Skip or 1 through 10. Refresh task types at an Adventure Recruiter. Complete and exit each dungeon to count it.')
        end
        ImGui.TextWrapped('Solo and group runs are supported. For groups, run on the leader and keep everyone together. Solo return needs Bazaar and Back AA 331.')
    end
    ImGui.End()
    ImGui.PopStyleVar(6)
    ImGui.PopStyleColor(15)
end

local function drawMeshDiagnosticsUI()
    if not meshPopupOpen then return end
    local open, visible = ImGui.Begin('LDoN Navigation Recovery', meshPopupOpen)
    meshPopupOpen = open
    if visible then
        local now = mq.gettime()
        if now - meshDiagnosticLastCheck >= 2000 then
            meshDiagnosticLastCheck = now
            meshDiagnosticPathResults = {}
            for index, point in ipairs(meshRecoveryPoints) do
                meshDiagnosticPathResults[index] = navPathExists(point.y, point.x, point.z)
            end
            local y = tonumber(mq.TLO.Me.Y()) or 0
            local x = tonumber(mq.TLO.Me.X()) or 0
            local z = tonumber(mq.TLO.Me.Z()) or 0
            meshDiagnosticCurrentPath = navPathExists(y, x, z)
        end
        ImGui.Text('Mesh isolation reported by Triune')
        ImGui.TextWrapped(meshRecoveryStatus ~= '' and meshRecoveryStatus or 'Failure detected; collecting navigation diagnostics.')
        ImGui.Separator()
        ImGui.Text('Zone: ' .. tostring(zoneShortName()))
        ImGui.Text('MQ2Nav loaded: ' .. tostring(pluginLoaded('MQ2Nav')))
        ImGui.Text('Navigation mesh loaded: ' .. tostring(navigationMeshLoaded()))
        ImGui.Text('MQ2Nav active: ' .. tostring(navigationActive()))
        ImGui.Text('MQ2MoveUtils loaded: ' .. tostring(pluginLoaded('MQ2MoveUtils')))
        ImGui.Text('MoveTo active: ' .. tostring(moveToActive()))
        ImGui.Text(string.format('Current position: Y %.1f, X %.1f, Z %.1f | path %s',
            tonumber(mq.TLO.Me.Y()) or 0, tonumber(mq.TLO.Me.X()) or 0,
            tonumber(mq.TLO.Me.Z()) or 0, tostring(meshDiagnosticCurrentPath)))
        ImGui.Text('Triune failure classification: ' ..
            (meshFailureKind ~= '' and meshFailureKind or 'unknown'))
        if meshFailureLocation then
            ImGui.Text(string.format('Failure point: Y %.1f, X %.1f, Z %.1f',
                meshFailureLocation.y, meshFailureLocation.x, meshFailureLocation.z))
        end
        ImGui.Text(string.format('Saved MQ2Nav positions: %d', #meshRecoveryPoints))
        for index, point in ipairs(meshRecoveryPoints) do
            ImGui.Text(string.format(
                '%d. Y %.1f, X %.1f, Z %.1f | distance %.1f | path %s',
                index, point.y, point.x, point.z,
                distance3DTo(point.y, point.x, point.z),
                tostring(meshDiagnosticPathResults[index])))
        end
        ImGui.Separator()
        if meshFailureKind == 'unmeshed' then
            ImGui.TextWrapped('Your position is pathable; Triune cannot find a navmesh route to the NPC. TAC remains active and will probe reachable approach points in any zone. From a nearby reachable point with line of sight and matching floor height, it may try up to four short MoveUtils steps toward the NPC (14 units total maximum). It stops on combat, lost line of sight, or no progress; the mesh file is never changed. Unknown or blocked geometry may still require manual relocation.')
        elseif ImGui.Button('Retry safe recovery') then
            active = true
            meshRecoveryAwaitingManual = false
            meshRecoveryRequested = true
            meshPopupOpen = true
        end
        ImGui.SameLine()
        if ImGui.Button('Pause runner and TAC') then
            active = false
            meshRecoveryRequested = false
            meshRecoveryAwaitingManual = false
            mq.cmd('/nav stop')
            mq.cmd('/moveto off')
            mq.cmd('/ac pause')
            if (tonumber(mq.TLO.Group()) or 0) > 0 then mq.cmd('/ac net group pause') end
            meshRecoveryStatus = 'Paused by user. Navigation diagnostics remain available.'
        end
    end
    ImGui.End()
end

-- Triune callback and /ldon command handling.
local function onMeshFailure(y, x, z, kind)
    if tonumber(y) == nil and type(y) == 'string' then
        local raw = table.concat({ y, x or '', z or '', kind or '' }, ' ')
        y, x, z, kind = raw:match('([%+%-]?%d+%.?%d*)%s+([%+%-]?%d+%.?%d*)%s+([%+%-]?%d+%.?%d*)%s*(%a*)')
    end
    meshFailureLocation = {
        y = tonumber(y) or (tonumber(mq.TLO.Me.Y()) or 0),
        x = tonumber(x) or (tonumber(mq.TLO.Me.X()) or 0),
        z = tonumber(z) or (tonumber(mq.TLO.Me.Z()) or 0),
    }
    meshFailureKind = tostring(kind or ''):lower()
    meshFailureActive = true
    meshPopupOpen = true
    meshRecoveryStatus = 'Triune reported mesh-isolation recovery failure (' ..
        (meshFailureKind ~= '' and meshFailureKind or 'type unavailable') .. ').'
    meshRecoveryRequested = active and DUNGEONS[zoneId()] ~= nil
    meshRecoveryAwaitingManual = false
    echo('Received Triune mesh-failure signal (' ..
        (meshFailureKind ~= '' and meshFailureKind or 'type unavailable') .. '). Opening navigation diagnostics.')
    if not meshRecoveryRequested then
        meshRecoveryStatus = 'Failure recorded. Start or resume the runner to inspect/recover.'
    end
end

local function command(...)
    local args = { ... }
    local action = tostring(args[1] or 'help'):lower()
    if action == 'meshfail' then
        onMeshFailure(args[2], args[3], args[4], args[5])
    elseif action == 'start' or action == 'resume' then
        if startRunner() then echo('Task runner resumed.') end
    elseif action == 'pause' or action == 'stop' then
        active = false
        mq.cmd('/nav stop')
        if useAdvPath and advPathLoaded() then mq.cmd('/play off') end
        stopSwarmPull(false)
        saveSettings()
        echo('Task runner paused. Triune combat was not changed.')
    elseif action == 'record' then
        local sub = tostring(args[2] or ''):lower()
        if not advPathLoaded() then
            echo('Load MQ2AdvPath first (/plugin MQ2AdvPath).')
        elseif sub == 'start' then
            mq.cmd('/record')
            echo('Recording started. Walk the route (finish at the zone line or switch), then /ldon record save <key>.')
        elseif sub == 'save' and args[3] and args[3] ~= '' then
            mq.cmdf('/record save ldon_%s 20', args[3])
            echo('Saved recording as ldon_' .. args[3] .. '. Enable MQ2AdvPath routes in the window to use it.')
        elseif sub == 'play' and args[3] and args[3] ~= '' then
            mq.cmdf('/play ldon_%s noloop smart door', args[3])
        else
            echo('/ldon record start | save <key> | play <key>')
        end
    elseif action == 'swarm' then
        local sub = tostring(args[2] or ''):lower()
        if sub == 'on' then
            setSwarmPull(true)
        elseif sub == 'off' then
            setSwarmPull(false)
        else
            echo('Swarm Pull is ' .. (useSwarmPull and 'on' or 'off') .. '. Use /ldon swarm on | off.')
        end
    elseif action == 'difficulty' then
        local sub = tostring(args[2] or ''):lower()
        if sub == 'hard' or sub == 'normal' then
            hardMode = sub == 'hard'
            echo('Adventure difficulty set to ' .. sub .. '.')
        else
            echo('Difficulty is ' .. (hardMode and 'hard' or 'normal') .. '. Use /ldon difficulty normal | hard.')
        end
    elseif action == 'preflight' then
        runPreflight()
    elseif action == 'save' then
        echo(saveSettings() and 'Settings saved to ' .. settingsPath or 'Could not write the settings file.')
    elseif action == 'finish' then
        campaignStopPending = true
        echo('The campaign will stop after the current dungeon is completed and the runner returns to camp.')
    elseif action == 'remote-return' then
        local targetHubZone = tonumber(args[2])
        if not targetHubZone or not HUBS[targetHubZone] then
            echo('Remote return requires a configured campaign hub zone ID.')
        else
            local wasActive = active
            active = true
            local returned = returnToCampaignRecruiter(targetHubZone)
            active = wasActive
            echo(returned and 'Remote group return reached the campaign recruiter.'
                or 'Remote group return did not reach the campaign recruiter.')
        end
    elseif action == 'exit' then
        active = false
        shuttingDown = true
        mq.cmd('/nav stop')
        stopSwarmPull(false)
    elseif action == 'status' then
        status()
        echo(runSummary())
    elseif action == 'ui' then
        uiOpen = true
    elseif action == 'diagnostics' then
        meshPopupOpen = true
        if not meshFailureActive then
            meshRecoveryStatus = 'No mesh-isolation failure has been reported in this run.'
        end
    elseif action == 'type' then
        local requested = tonumber(args[2])
        local found = false
        for _, choice in ipairs(missionOptions) do
            if choice.index == requested then
                missionTypeIndex = requested
                found = true
                break
            end
        end
        if found then
            echo('Mission request option set to ' .. tostring(requested) .. '.')
            local leg = campaignLeg()
            if leg then leg.missionTypeIndex = requested end
        else
            echo('That task option is not available. Use the in-game dropdown or /ldon help.')
        end
    elseif action == 'ma' then
        local requested = table.concat(args, ' ', 2)
        if requested == '' then
            echo('Main Assist / puller: ' .. mainAssistName)
        else
            mainAssistName = requested
            echo('Main Assist / puller set to ' .. mainAssistName .. '.')
        end
    elseif action == 'help' then
        echo('/ldon start | status | pause | resume | exit | finish | preflight | save | type <option> | ma <group name> | ui | diagnostics')
        echo('/ldon swarm on | off toggles Swarm Pull; /ldon difficulty normal | hard sets the adventure risk level.')
        echo('/ldon record start | save <key> | play <key> records and plays optional MQ2AdvPath routes.')
        echo('/ldon finish stops after the current dungeon; /ldon preflight checks plugins, meshes and optional integrations.')
        echo('Settings are saved per character in the MacroQuest config folder; the log is logs/LDON_Triune.log.')
        echo('Configure up to five sequential camp legs in the window; each leg has its own dungeon count and mission type.')
        echo('Requires MQ2Nav, MQ2MoveUtils and a route mesh. Solo return uses Bazaar and Back AA 331.')
        echo('Solo and grouped runs are supported; grouped runs require leadership and must stay together.')
        echo('The selected Main Assist uses Puller - Hunt; other group boxes use Assist - Chase.')
        echo('During combat, sit/Feign Death is ended only when you and all group members are above 50% HP.')
        echo('Mesh recovery uses recent navmesh positions, then reloads and tests the existing local mesh; it never downloads meshes.')
        echo('Use the LDoN Navigation Recovery window for live mesh/path diagnostics and a manual retry.')
        echo('BoxNet must be available for automatic remote-box setup. Check peers with /ac net peers.')
    else
        echo('Unknown command. Use /ldon help.')
    end
end

mq.unbind('/ldon')
mq.bind('/ldon', command)
mq.unbind('/ldonmeshfail')
mq.bind('/ldonmeshfail', onMeshFailure)
mq.imgui.init('LDONTriuneRunner', drawUI)
mq.imgui.init('LDONMeshDiagnostics', drawMeshDiagnosticsUI)

echo('LDoN Triune Runner v' .. VERSION .. ' loaded; Leg 1 defaults to one hard mob-count dungeon at the current camp. Configure the campaign, select Main Assist, then press Start.')

-- Main campaign loop: recover, fight, exit, return, change camps, and request.
while not shuttingDown do
    mq.doevents()
    if active then
        local zone = zoneId()
        if zone ~= lastZone then
            lastZone = zone
            lastNotice = ''
            if not DUNGEONS[zone] then
                meshRecoveryRequested = false
                swarmActive = false
            elseif stats.dungeonStartedAt == 0 then
                stats.dungeonStartedAt = os.time()
                stuckProgress = ''
            end
        end
        if stopAfterMinutes > 0 and not campaignStopPending and stats.startedAt > 0
            and os.time() - stats.startedAt >= stopAfterMinutes * 60 then
            campaignStopPending = true
            echo('Scheduled stop reached; finishing the current dungeon and then stopping.')
        end
        if not mq.TLO.Window('AdventureRequestWnd').Open() then
            mq.cmd('/windowstate AdventureRequestWnd open')
        end
        local assigned, completed, dialogue, progress = assignmentState()
        local dungeon = DUNGEONS[zone]
        if dungeon then
            sampleMeshRecoveryPoint(zone)
            if not triuneReady and not ensureTriune() then
                active = false
            elseif meshRecoveryRequested and not completed then
                monitorCombatPosture()
                recoverFromMeshIsolation()
            elseif meshRecoveryAwaitingManual and not completed then
                meshRecoveryRequested = false
                if #meshRecoveryPoints > 0 then
                    meshRecoveryStatus = string.format(
                        'Found %d pathable position(s). Review diagnostics, then choose the appropriate resume/retry action.',
                        #meshRecoveryPoints)
                end
                mq.delay(1000)
            elseif combatZone ~= zone and not configureGroupCombat() then
                active = false
            else
                monitorCombatPosture()
                if completed then
                    meshRecoveryRequested = false
                    local notice = 'Task objective complete; waiting for combat to clear before exiting.'
                    if lastNotice ~= notice then echo(notice); lastNotice = notice end
                    stopSwarmPull(true)
                    if exitTask(zone) then
                        recordCampaignCompletion()
                        lastNotice = ''
                        combatZone = 0
                        combatRunSends = 0
                        adventureCompleted = false
                        travelReady = false
                        mq.cmd('/ac pause')
                        if (tonumber(mq.TLO.Group()) or 0) > 0 then
                            mq.cmd('/ac net group pause')
                        end
                    else
                        handleFailure('Exit route failed.', true)
                    end
                else
                    if not swarmActive and combatRunSends < 4
                        and mq.gettime() - combatRunStartedAt >= combatRunSends * 10000 then
                        mq.cmd('/ac run')
                        if (tonumber(mq.TLO.Group()) or 0) > 0 then
                            mq.cmd('/ac net group run')
                        end
                        combatRunSends = combatRunSends + 1
                    end
                    if progress ~= stuckProgress then
                        stuckProgress = progress
                        stuckSince = os.time()
                        stuckWarned = false
                    elseif not stuckWarned and os.time() - stuckSince >= 15 * 60 then
                        stuckWarned = true
                        lastFailure = 'No task progress for 15 minutes.'
                        echo('No task progress for 15 minutes; check the character or use /ldon diagnostics.')
                    end
                    lastNotice = ''
                    mq.delay(1000)
                end
            end
        elseif ENTRY_ZONES[zone] then
            if assigned and not completed then
                if not travelReady and not configureGroupTravel() then
                    active = false
                elseif enterTask(zone, dialogue) then
                    lastNotice = ''
                    failureStreak = 0
                else
                    handleFailure('Entrance route failed.', true)
                end
            elseif homeHubZone ~= 0 and zone ~= homeHubZone then
                if not travelReady and not configureGroupTravel() then
                    active = false
                elseif returnToHub() then
                    lastNotice = ''
                    failureStreak = 0
                else
                    handleFailure('Could not reach the configured task hub.', true)
                end
            elseif campaignStopPending and (not assigned or completed) then
                if assigned and completed then clearFinishedAssignment() end
                finishCampaign('Campaign finished. The configured completed-dungeon counts have been reached. The window is ready for a new run.')
            elseif campaignTravelPending and not assigned then
                local leg = campaignLeg()
                if not leg or not travelToCamp(leg.hubZone) then
                    handleFailure('Camp change failed.', true)
                else
                    campaignTravelPending = false
                    lastNotice = ''
                    failureStreak = 0
                end
            elseif assigned and completed then
                local notice = 'The task is complete and you are outside the instance. Clearing the finished assignment.'
                if lastNotice ~= notice then echo(notice); lastNotice = notice end
                mq.delay(3000)
                if not clearFinishedAssignment() then mq.delay(10000) end
            else
                local hub = HUBS[zone]
                if hub then
                    if not travelReady and not configureGroupTravel() then
                        active = false
                    else
                        local leg = campaignLeg()
                        if leg and leg.hubZone ~= zone then
                            if travelToCamp(leg.hubZone) then
                                lastNotice = ''
                                failureStreak = 0
                            else
                                handleFailure('Camp travel failed.', true)
                            end
                        elseif requestTask(hub, campaignMissionType()) then
                            lastNotice = ''
                            failureStreak = 0
                        else
                            mq.delay(10000)
                        end
                    end
                else
                    local notice = 'No task is active in this transition zone. Travel to your camp hub to request the next mission.'
                    if lastNotice ~= notice then echo(notice); lastNotice = notice end
                    mq.delay(5000)
                end
            end
        else
            local notice = 'Not in an LDoN zone (' .. tostring(mq.TLO.Zone.ShortName() or zone) ..
                '). Traveling to the starting camp.'
            if lastNotice ~= notice then echo(notice); lastNotice = notice end
            if not travelReady and not configureGroupTravel() then
                active = false
            elseif travelToStartHub(dialogue, assigned, completed) then
                lastNotice = ''
                failureStreak = 0
            else
                handleFailure('Could not travel to the starting camp.', true)
            end
        end
    else
        mq.delay(250)
    end
end

-- Stop movement and unregister script-owned callbacks and windows on shutdown.
mq.unbind('/ldon')
mq.unbind('/ldonmeshfail')
mq.imgui.destroy('LDONTriuneRunner')
mq.imgui.destroy('LDONMeshDiagnostics')
mq.cmd('/nav stop')
stopSwarmPull(false)
saveSettings()
echo('Task runner exited.')