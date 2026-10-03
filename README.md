# FiveM Duty Sessions

Kleines serverseitiges Duty-/Session-System fuer FiveM. Es gibt keine eigene
UI und keine Framework-Abhaengigkeit; die Dienstzeiten liegen in der
Resource-KVP.

## Installation

1. Ordner in `resources/` kopieren (Ordnername = Resource-Name, z.B. `duty-system`).
2. `ensure duty-system` in der `server.cfg` eintragen.
3. ACE-Permissions vergeben (siehe unten).

## ACE-Permissions

Die Resource prueft Berechtigungen ausschliesslich serverseitig ueber
`IsPlayerAceAllowed`. Beispielkonfiguration fuer die `server.cfg`:

```
add_ace group.staff duty.use allow
add_ace group.admin duty.admin allow

add_principal identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX group.staff
add_principal identifier.license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX group.admin
```

Admins brauchen beide Berechtigungen, wenn sie `/duty` ebenfalls nutzen sollen.

## Commands

- `/duty` — schaltet den eigenen Dienststatus um. Erfordert `duty.use`.
- `/dutyinfo [id]` — Admin-Befehl, erfordert `duty.admin`.
  - Ohne `id`: listet alle aktuell im Dienst befindlichen Spieler.
  - Mit `id`: zeigt Status und gesamte Dienstzeit des angegebenen (online)
    Spielers. Ausgabe erfolgt in den Chat des aufrufenden Spielers bzw. in
    die Server-Konsole, wenn der Befehl von der Konsole ausgefuehrt wird.

## Datenhaltung

Alle Daten liegen in der Resource-KVP (`GetResourceKvpString`/`SetResourceKvp`),
geordnet nach dem `license`-Identifier des Spielers (siehe `Config.Identifier`):

- `duty_total:<identifier>` — kumulierte Dienstzeit in Sekunden.
- `duty_active:<identifier>` — JSON mit Startzeitpunkt, Name und letztem
  serverseitigen Heartbeat. Der Eintrag existiert nur waehrend einer aktiven
  Session.

Beim Ausloggen, Disconnect oder erneutem `/duty` wird die vergangene Zeit
aus `duty_active` berechnet, zu `duty_total` addiert und der aktive Eintrag
geloescht.

## Restarts und Abstuerze

Der Beginn einer Session wird direkt gespeichert. Bei `restart duty-system`
wird eine Session eines weiterhin verbundenen Spielers wiederhergestellt.

Solange die Resource laeuft, aktualisiert sie alle 60 Sekunden einen
serverseitigen Heartbeat. Liegt der letzte Heartbeat beim erneuten Beitritt
mehr als 120 Sekunden zurueck, behandelt das System die Session als veraltet:
Es rechnet nur bis zum letzten Heartbeat ab und startet keinen neuen Duty-Status
automatisch. So wird Offline-Zeit nach einem Serverabsturz nicht als Dienstzeit
gezaehlt. Die beiden Werte stehen in `config.lua` und koennen bei Bedarf
angepasst werden.

## Bekannte Grenzen von KVP

- KVP ist an die Resource gebunden. Wird die Resource geloescht oder
  umbenannt, gehen die gespeicherten Daten verloren.
- Es gibt keine serverübergreifende Synchronisation; bei mehreren
  FXServer-Instanzen (z.B. Loadbalancing) hat jede ihre eigene KVP.
- Nach einem kompletten Absturz koennen maximal bis zu 60 Sekunden zwischen
  dem letzten Heartbeat und dem Absturz fehlen. Das verhindert im Gegenzug,
  dass laengere Offline-Zeit gutgeschrieben wird.
- KVP eignet sich fuer kleine, spielerbezogene Werte, nicht fuer grosse
  Datenmengen oder komplexe Abfragen — fuer produktive Frameworks mit
  vielen Spielern ist mittelfristig eine echte Datenbank sinnvoller.
