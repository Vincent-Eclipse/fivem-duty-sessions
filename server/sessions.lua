-- Haelt den In-Memory-Status online Spieler. Die KVP-Werte in Storage bleiben
-- die eigentliche Quelle der Wahrheit, dieses Modul ist nur ein schneller
-- Zugriffscache waehrend ein Spieler verbunden ist.

Sessions = {}

local activeBySource = {}     -- source -> { identifier, name, startedAt }
local sourceByIdentifier = {} -- identifier -> source

function Sessions.GetIdentifier(source)
    local identifier = GetPlayerIdentifierByType(source, Config.Identifier)
    return identifier
end

function Sessions.IsOnDuty(source)
    return activeBySource[source] ~= nil
end

function Sessions.Get(source)
    return activeBySource[source]
end

function Sessions.GetByIdentifier(identifier)
    local source = sourceByIdentifier[identifier]
    if not source then
        return nil
    end
    return activeBySource[source], source
end

function Sessions.Start(source, identifier, name)
    local now = os.time()
    local session = {
        identifier = identifier,
        name = name,
        startedAt = now,
        lastSeenAt = now
    }

    activeBySource[source] = session
    sourceByIdentifier[identifier] = source

    Storage.SaveActiveSession(identifier, {
        startedAt = session.startedAt,
        lastSeenAt = session.lastSeenAt,
        name = session.name
    })

    return session
end

-- Beendet eine Session, schreibt die Dienstzeit fest und gibt die
-- vergangene Dauer in Sekunden zurueck (nie negativ, siehe Clock-Guard).
function Sessions.Stop(source)
    local session = activeBySource[source]
    if not session then
        return nil
    end

    local elapsed = math.max(0, os.time() - session.startedAt)
    Storage.AddSeconds(session.identifier, elapsed)
    Storage.ClearActiveSession(session.identifier)

    activeBySource[source] = nil
    sourceByIdentifier[session.identifier] = nil

    return elapsed, session
end

function Sessions.Touch(source)
    local session = activeBySource[source]
    if not session then
        return
    end

    session.lastSeenAt = os.time()
    Storage.SaveActiveSession(session.identifier, {
        startedAt = session.startedAt,
        lastSeenAt = session.lastSeenAt,
        name = session.name
    })
end

function Sessions.ClosePersisted(identifier, persistedSession)
    local elapsed = math.max(0, persistedSession.lastSeenAt - persistedSession.startedAt)
    Storage.AddSeconds(identifier, elapsed)
    Storage.ClearActiveSession(identifier)
    return elapsed
end

-- Haengt eine bereits persistierte Session (ungeaenderter Startzeitpunkt) an
-- einen aktuell verbundenen Spieler an, z.B. nach einem Resource-Neustart.
function Sessions.Resume(source, identifier, persistedSession)
    if activeBySource[source] then
        return
    end

    activeBySource[source] = {
        identifier = identifier,
        name = persistedSession.name,
        startedAt = persistedSession.startedAt,
        lastSeenAt = persistedSession.lastSeenAt
    }
    sourceByIdentifier[identifier] = source
    Sessions.Touch(source)
end

function Sessions.All()
    return activeBySource
end
