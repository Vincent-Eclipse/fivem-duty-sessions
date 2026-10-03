Duty = {}

function Duty.FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return ('%02d:%02d:%02d'):format(hours, minutes, secs)
end

function Duty.PrintInfo(source, message)
    if source == 0 then
        print(('[duty] %s'):format(message))
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'Duty', message } })
    end
end

local function notify(source, message)
    Duty.PrintInfo(source, message)
end

local function hasPermission(source, permission)
    return IsPlayerAceAllowed(source, permission) == true
end

RegisterCommand('duty', function(source)
    if source == 0 then
        print('[duty] /duty kann nicht ueber die Server-Konsole genutzt werden.')
        return
    end

    if not hasPermission(source, Config.Permissions.use) then
        Logger.warn('%s (%s) hat /duty ohne Berechtigung versucht.', GetPlayerName(source), source)
        notify(source, 'Du hast keine Berechtigung, den Dienst zu nutzen.')
        return
    end

    local identifier = Sessions.GetIdentifier(source)
    if not identifier then
        Logger.warn('Kein "%s"-Identifier fuer %s (%s) gefunden, Dienst kann nicht gestartet werden.', Config.Identifier, GetPlayerName(source), source)
        notify(source, 'Dein Account konnte nicht eindeutig identifiziert werden.')
        return
    end

    if Sessions.IsOnDuty(source) then
        local elapsed = Sessions.Stop(source)
        Logger.info('%s (%s) hat den Dienst beendet. Dauer: %ds.', GetPlayerName(source), identifier, elapsed)
        notify(source, ('Dienst beendet. Dauer: %s'):format(Duty.FormatDuration(elapsed)))
    else
        local name = GetPlayerName(source)
        Sessions.Start(source, identifier, name)
        Logger.info('%s (%s) hat den Dienst begonnen.', name, identifier)
        notify(source, 'Dienst gestartet.')
    end
end, false)

RegisterCommand('dutyinfo', function(source, args)
    if source ~= 0 and not hasPermission(source, Config.Permissions.admin) then
        Logger.warn('%s (%s) hat /dutyinfo ohne Berechtigung versucht.', GetPlayerName(source), source)
        notify(source, 'Keine Berechtigung fuer diesen Befehl.')
        return
    end

    local targetId = tonumber(args[1])
    if targetId then
        targetId = math.floor(targetId)
    end

    if not targetId then
        local found = false
        for src, session in pairs(Sessions.All()) do
            found = true
            local elapsed = os.time() - session.startedAt
            Duty.PrintInfo(source, ('#%s %s (%s) - im Dienst seit %s'):format(src, session.name, session.identifier, Duty.FormatDuration(elapsed)))
        end
        if not found then
            Duty.PrintInfo(source, 'Aktuell ist niemand im Dienst.')
        end
        return
    end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        Duty.PrintInfo(source, ('Spieler mit ID %d ist nicht online.'):format(targetId))
        return
    end

    local identifier = Sessions.GetIdentifier(targetId)
    if not identifier then
        Duty.PrintInfo(source, ('Kein Identifier fuer Spieler %d gefunden.'):format(targetId))
        return
    end

    local session = Sessions.Get(targetId)
    local total = Storage.GetTotalSeconds(identifier)

    Duty.PrintInfo(source, ('Spieler: %s (%s)'):format(targetName, identifier))
    if session then
        local elapsed = os.time() - session.startedAt
        Duty.PrintInfo(source, ('Status: im Dienst seit %s'):format(Duty.FormatDuration(elapsed)))
    else
        Duty.PrintInfo(source, 'Status: nicht im Dienst')
    end
    Duty.PrintInfo(source, ('Gesamte Dienstzeit: %s'):format(Duty.FormatDuration(total)))
end, false)
