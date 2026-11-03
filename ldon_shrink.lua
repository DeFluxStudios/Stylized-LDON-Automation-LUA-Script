-- Runs on each character so inventory and click readiness are checked locally.
local mq = require('mq')
local args = {...}
local ITEMS = {
    'Wand of Imperceptibility',
    'Bracelet of the Shadow Hive',
    'Shimmering Bauble of Trickery',
}

local function shrink(expectedZone, keepRunning)
    local function report(message) print('[LDoN Shrink] ' .. message) end
    if not expectedZone then
        report('Missing adventure zone ID; no item used.')
        return false
    end
    local function allowed()
        return not keepRunning or keepRunning()
    end
    for _ = 1, 60 do
        if not allowed() then return false end
        if tonumber(mq.TLO.Zone.ID()) == expectedZone
            and mq.TLO.MacroQuest.GameState() == 'INGAME' then break end
        mq.delay(250)
    end
    if tonumber(mq.TLO.Zone.ID()) ~= expectedZone or mq.TLO.MacroQuest.GameState() ~= 'INGAME' then
        report('Adventure zone not reached in 15 seconds; skipping shrink.')
        return false
    end
    if mq.TLO.Me.Combat() == true or mq.TLO.Me.Dead() == true then
        report('In combat or dead; skipping shrink.')
        return false
    end
    local name
    for _, baseName in ipairs(ITEMS) do
        -- Partial-name lookup includes regular and tier-suffixed versions.
        local item = mq.TLO.FindItem(baseName)
        if (tonumber(item.ID()) or 0) > 0 then
            local ownedName = tostring(item.Name() or '')
            if ownedName ~= '' and mq.TLO.Me.ItemReady(ownedName)() == true then
                name = ownedName
                break
            end
        end
    end
    if not name then
        report('No supported carried shrink item is ready; continuing without shrink.')
        return false
    end
    if mq.TLO.Me.Casting() then
        report('Already casting; skipping shrink rather than interrupting.')
        return false
    end
    local beforeHeight = tonumber(mq.TLO.Me.Height())
    if not beforeHeight then
        report('Cannot read character height to verify shrink; no item used.')
        return false
    end
    local targetId = tonumber(mq.TLO.Target.ID()) or 0
    local selfId = tonumber(mq.TLO.Me.ID()) or 0
    mq.cmd('/target myself')
    for _ = 1, 4 do
        if selfId > 0 and tonumber(mq.TLO.Target.ID()) == selfId then break end
        mq.delay(250)
    end
    if not allowed() or tonumber(mq.TLO.Zone.ID()) ~= expectedZone
        or selfId == 0 or tonumber(mq.TLO.Target.ID()) ~= selfId then
        report('Could not confirm self target in the adventure; no item used.')
        return false
    end
    mq.cmdf('/useitem "%s"', name)
    local success = false
    for _ = 1, 40 do
        mq.delay(250)
        if not allowed() or tonumber(mq.TLO.Zone.ID()) ~= expectedZone then break end
        local height = tonumber(mq.TLO.Me.Height())
        if height and height < beforeHeight and not mq.TLO.Me.Casting() then
            success = true
            break
        end
    end
    if tonumber(mq.TLO.Zone.ID()) == expectedZone and not mq.TLO.Me.Casting() then
        if targetId > 0 then mq.cmdf('/target id %d', targetId)
        else mq.cmd('/target clear') end
    end
    report(success and ('Shrank using ' .. name .. '.') or
        ('No size decrease confirmed after ' .. name .. '; may already be minimum size or the click failed.'))
    return success
end

if args[1] ~= 'ldon_shrink' then shrink(tonumber(args[1])) end
return shrink
