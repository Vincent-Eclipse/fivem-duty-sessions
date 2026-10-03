Config = {}

-- ACE permissions, siehe README fuer add_ace/add_principal Beispiele
Config.Permissions = {
    use = 'duty.use',
    admin = 'duty.admin'
}

-- Identifier-Typ, ueber den Dienstzeiten zugeordnet werden (muss stabil sein)
Config.Identifier = 'license'

Config.Kvp = {
    activePrefix = 'duty_active:',
    totalPrefix = 'duty_total:'
}

Config.Session = {
    heartbeatSeconds = 60,
    resumeGraceSeconds = 120
}
