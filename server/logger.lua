Logger = {}

local function timestamp()
    return os.date('%Y-%m-%d %H:%M:%S')
end

function Logger.info(msg, ...)
    print(('[duty] %s %s'):format(timestamp(), msg:format(...)))
end

function Logger.warn(msg, ...)
    print(('[duty] [WARN] %s %s'):format(timestamp(), msg:format(...)))
end
