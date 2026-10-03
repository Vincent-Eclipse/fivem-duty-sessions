-- Persistenz ueber Resource-KVP. Kein Datenbank-Treiber noetig, siehe README
-- fuer die Grenzen dieses Ansatzes.

Storage = {}

local function activeKey(identifier)
    return Config.Kvp.activePrefix .. identifier
end

local function totalKey(identifier)
    return Config.Kvp.totalPrefix .. identifier
end

function Storage.GetTotalSeconds(identifier)
    local raw = GetResourceKvpString(totalKey(identifier))
    local total = tonumber(raw) or 0
    if total < 0 or total ~= total then
        return 0
    end
    return total
end

function Storage.AddSeconds(identifier, seconds)
    if seconds <= 0 then
        return Storage.GetTotalSeconds(identifier)
    end

    local total = Storage.GetTotalSeconds(identifier) + seconds
    SetResourceKvp(totalKey(identifier), tostring(total))
    return total
end

function Storage.SaveActiveSession(identifier, data)
    SetResourceKvp(activeKey(identifier), json.encode(data))
end

function Storage.GetActiveSession(identifier)
    local raw = GetResourceKvpString(activeKey(identifier))
    if not raw then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end

    if type(decoded.startedAt) ~= 'number' or decoded.startedAt <= 0 then
        return nil
    end

    if type(decoded.lastSeenAt) ~= 'number' or decoded.lastSeenAt < decoded.startedAt then
        return nil
    end

    if type(decoded.name) ~= 'string' then
        return nil
    end

    return decoded
end

function Storage.ClearActiveSession(identifier)
    DeleteResourceKvp(activeKey(identifier))
end
