-- Beendet die Dienstzeit korrekt, wenn ein Spieler im Dienst die Verbindung
-- trennt (Crash, Disconnect, Kick, ...).
AddEventHandler('playerDropped', function(reason)
    local src = source

    if not Sessions.IsOnDuty(src) then
        return
    end

    local identifier = Sessions.Get(src).identifier
    local name = GetPlayerName(src) or identifier
    local elapsed = Sessions.Stop(src)

    Logger.info('%s (%s) wurde getrennt, Dienst automatisch beendet. Dauer: %ds. Grund: %s', name, identifier, elapsed, reason)
end)

local function restorePlayerSession(src, restoreReason)
    local identifier = Sessions.GetIdentifier(src)

    if not identifier or Sessions.IsOnDuty(src) then
        return
    end

    local persisted = Storage.GetActiveSession(identifier)
    if not persisted then
        return
    end

    local age = os.time() - persisted.lastSeenAt
    if age > Config.Session.resumeGraceSeconds then
        local elapsed = Sessions.ClosePersisted(identifier, persisted)
        Logger.warn('Veraltete Dienst-Session von %s (%s) beendet. Bestaetigte Dauer: %ds.', GetPlayerName(src), identifier, elapsed)
        return
    end

    Sessions.Resume(src, identifier, persisted)
    Logger.info('Dienst-Session von %s (%s) nach %s wiederhergestellt.', GetPlayerName(src), identifier, restoreReason)
end

-- playerJoining ist ein FiveM-Core-Event und braucht keine sessionmanager-Resource.
AddEventHandler('playerJoining', function()
    restorePlayerSession(source, 'Beitritt')
end)

-- Stellt Sessions von Spielern wieder her, die beim Resource-Start noch online sind.
local function restoreOnlinePlayers()
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        restorePlayerSession(src, 'Resource-Start')
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    restoreOnlinePlayers()
    Logger.info('Duty-System gestartet.')
end)

CreateThread(function()
    while true do
        Wait(Config.Session.heartbeatSeconds * 1000)

        for src in pairs(Sessions.All()) do
            Sessions.Touch(src)
        end
    end
end)

-- Der aktive Stand liegt bereits in der KVP und wird beim naechsten Start
-- anhand des letzten Heartbeats behandelt.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local count = 0
    for _ in pairs(Sessions.All()) do
        count = count + 1
    end

    if count > 0 then
        Logger.info('Duty-System stoppt mit %d aktiven Session(s).', count)
    else
        Logger.info('Duty-System gestoppt.')
    end
end)
