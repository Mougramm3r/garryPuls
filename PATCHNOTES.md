# PULSE – Patch Notes

## Update: Balance & Fixes

- **Night Vision:** jetzt grün, verrauscht, leicht unscharf, mit Scanlines und dunklen Rändern. Licht nur noch in einem kleinen Radius (Standard 650, einstellbar unter Server → „Night vision: light radius“). Keine globale Aufhellung mehr.
- **Stay Silent:** Abklingzeit standardmäßig 10 s (statt 45 s).
- **Zuschauer:** sind jetzt tot im Zuschauermodus und können nicht mehr vom Jäger (z. B. Pill-Pack-Greifangriff) gepackt oder getötet werden. Schaden an Zuschauern ist komplett geblockt.
- **Noise Radar:**
  - Ping pro Opfer nur noch alle 4 s (einstellbar: „Noise radar: seconds between pings per victim“).
  - Nur noch an/aus (kein Passiv mehr). Gespeicherte „Passive“-Einstellungen werden zu „Menu only“.
  - Solange an, kann der Jäger nicht sprinten.
  - Rolle Tracker: Noise Radar jetzt auf Slot 3.
- **An/Aus-Fähigkeiten auf Slots** (z. B. Footprints) schalten jetzt zuverlässig: Der Client schickt den gewünschten Zustand statt „umschalten“, schnelle Doppeldrücke kommen nicht mehr durcheinander. Toggles gehen auch während Stalk/Behind You.
- **Behind You:**
  - Dreht sich das Opfer um, bleibt der Jäger 1 s sichtbar und verschwindet dann.
  - Der Jäger (auch als Pill-Charakter) schaut jetzt immer zum Opfer.
- **Startwaffen für Opfer:** neuer Bereich Game → „Victim weapons“. Mehrere HL2-Waffen ankreuzbar, eigene Waffen-Klassen per Textfeld (kommagetrennt). Opfer bekommen etwas Munition dazu.
- **Neu:** Schalter „Victims can hurt the hunter with their weapons“ (Standard: aus).
- **Medkit entfernt.**
- **Jäger getroffen:** Schaden unterbricht den Sprint des Jägers, er kann 1,5 s nur gehen (einstellbar unter Server → „Hunter hit: no sprint for“, 0 = aus). Gilt auch für Pill-Charaktere.
- **Eigene Behind-You-Sounds:** neue Ordner `sound/pulse/behindu/behind/` (während der Jäger hinter dem Opfer steht) und `sound/pulse/behindu/turn/` (wenn sich das Opfer umdreht). Mehrere Dateien = zufällige Auswahl, der nächste Sound startet erst nach dem vorigen.
- Eigene Musik/Ambient/Stinger werden jetzt auch an Freunde übertragen (vorher hörte sie nur der Host).

## Update: Entwickler-Menü

- **Entwickler-Menü:** als Admin mit **Shift + Rechtsklick auf den Tab SERVER**.
  - **Hidden features:** standardmäßig ausgeblendete Funktionen wieder einschalten.
  - **Test mode** ist aus dem Game-Tab hierher umgezogen.
  - **Sounds:** jeder Sound von PULSE nach Gruppen zum Anhören, eigene Dateien mit ★.
- **Aim Assist standardmäßig ausgeblendet:** nicht mehr im Server-Tab, Role editor, Hunter-Menü, Default-Einstellungen und HUD, und ohne Funktion, bis er im Entwickler-Menü eingeschaltet wird.
- Rolle Brute: Slot 4 ist jetzt Chaser Pulse statt Aim Assist.
- Aus Players- und Hunter-Tab ins Entwickler-Menü umgezogen: **„Make hunter now“** (Spieler sofort zum Jäger machen).
- Neuer Abschnitt **Experimental** im Entwickler-Menü: Blackout-Map-Lichter, Door-Slam-Werte, Aim Assist auf NPCs.
