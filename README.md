# PULSE – The Chase of the End

Garry's Mod Addon

Ein Horror-Spielmodus für Garry's Mod (Sandbox): Ein oder mehrere **Jäger** jagen die **Opfer**, die eine bestimmte Zeit überleben müssen.
Jäger haben Rollen mit Fähigkeiten, die Opfer haben eigene Tricks. Das ganze Menü ist auf Englisch, damit alle mitspielen können.

Du brauchst **keinen Injektor**. Es ist ein normales Addon, das auf dem Server installiert wird.
Deine Freunde laden den Client-Teil beim Joinen automatisch herunter.

## Installation

1. Kopiere den Ordner `pulse` nach `garrysmod/addons/` (einen alten Ordner `hunter_tools` vorher löschen).
   Richtig ist: `garrysmod/addons/pulse/lua/autorun/pulse_init.lua`.
2. Starte GMod, **Neues Spiel** (Sandbox, mehr als 1 Spieler) und hoste die Runde.
3. Nach dem Joinen kommt im Chat „PULSE loaded“. Mit **F4** öffnest du das Menü.

## Menü (F4)

| Tab | Wer | Inhalt |
|---|---|---|
| **Keybinds** | alle | Menü-Taste und die 4 Fähigkeiten-Slots belegen |
| **Hunter** | Jäger, Admin | Außerhalb der Runde: **Abilities** (ausführen, inkl. Menü-Fähigkeiten), **Roles** (Rolle wählen), **Default** (eigene Einstellungen und Slots). In der Runde nur die ausführbaren Fähigkeiten |
| **Victim** | alle | Fähigkeiten der Opfer |
| **Players** | Admin | „Next round“ für vorausgewählte Jäger, Zahnrad = Default-Einstellungen des Spielers |
| **Server** | Admin | Werte aller Fähigkeiten (Reichweite, Dauer, Abklingzeit …) |
| **Game** | Admin | Runde oder **Serie** starten/stoppen, Überlebenszeit, Versteckphase, Jäger-Anzahl und -Auswahl, Rollenvergabe, **Final phase & music**, **Items**, **Victim weapons**, **Role editor** |
| **Developer** | Admin | Versteckt: **Shift + Rechtsklick auf SERVER**. Ausgeblendete Funktionen (z. B. Aim Assist), Testmodus, Spieler sofort zum Jäger machen, Experimentelles, alle Sounds zum Anhören |

Links in jedem Tab ist eine Abschnittsliste; ein Klick springt direkt zum Abschnitt.

**Admins:** „Admin“ in den Tabellen oben heißt Host/Superadmin **oder** ein Spieler mit PULSE-Adminrechten.
Der Host bzw. ein Superadmin kann im Tab **Players** per Haken „Admin“ anderen Spielern PULSE-Adminrechte geben
(Tabs Players, Server und Game, Runden starten, Rollen bearbeiten). Das sind **keine** GMod-Superadmin-Rechte.
PULSE-Admins können selbst keine Adminrechte vergeben. Die Rechte werden gespeichert (`data/pulse/admins.json`).

## Tasten

| Taste | Standard |
|---|---|
| Menü | **F4** |
| Slot 1–4 | **1–4** |

Jäger und Opfer nutzen dieselben 4 Slot-Tasten. Was ein Slot macht, hängt von der Rolle ab.
Die Slot-Tasten wechseln keine Waffen mehr, Waffen und Items wählst du mit dem **Mausrad**. Wer vorher die alten Standardtasten (F5, Numpad) hatte, bekommt einmalig automatisch die neuen.

**Taste versehentlich falsch belegt?** In der Konsole (Taste `^`):
- `pulse_reset_keys` setzt alle Tasten zurück (Menü F4, Slots 1–4)
- `pulse_menu` öffnet das Menü ohne Taste
- Linke und rechte Maustaste lassen sich nicht mehr belegen

## Ablauf einer Runde

1. Der Admin stellt im Tab **Game** alles ein und drückt **Start round**.
2. Jäger werden bestimmt (zufällig oder vorausgewählt). Alle respawnen, Jäger bekommen ihre Waffe (Standard: Brechstange), Opfer die Startwaffen aus **Game → Victim weapons** (Standard: keine). Dort auch: Schaden am Jäger und **Friendly fire** (beides Standard aus).
   **Eigenes Loadout:** Mit „Player's own loadout“ behalten Opfer die Waffen aus einem Loadout-Addon (zusätzlich zu den Startwaffen).
   **Voice chat:** Tote und Zuschauer können in der Runde nicht mit den Lebenden sprechen, hören aber alles (untereinander dürfen Tote reden; beides unter Game → Voice chat abschaltbar). Funktioniert auch mit VoiceActivity (Mikro immer an).
   Ob Opfer dem Jäger damit Schaden machen dürfen, ist dort einstellbar (Standard: aus).
   Wird der Jäger getroffen, kann er kurz nicht sprinten (Standard 1,5 s, Server-Tab).
   Bauen, Noclip und Spawnen sind während der Runde aus.
3. **Versteckphase** (Standard 30 s, abschaltbar): Die Opfer verstecken sich, der Jäger ist eingefroren und sieht nichts.
   Bei „Player choice“ wählt der Jäger in dieser Zeit seine Rolle (wer nicht wählt, bekommt eine zufällige).
4. **Jagd**: Oben in der Mitte sehen alle den Timer und den Namen des Jägers.
5. **Ende**:
   - Alle Opfer tot → **der Jäger gewinnt**
   - Zeit abgelaufen und mindestens ein Opfer lebt → **die Opfer gewinnen**
   - Der Jäger stirbt (z. B. Fallschaden) → **die Opfer gewinnen**
6. Ein Fenster zeigt den Gewinner und ein Scoreboard (Rolle, Überlebenszeit, Ergebnis, gefangene Opfer).

Tote Opfer schauen bis zum Rundenende zu (unsichtbar, nicht treffbar). **Links-/Rechtsklick** wechselt zwischen den
lebenden Spielern, **Leertaste** schaltet auf freie Kamera. Wer während einer Runde joint, schaut ebenfalls zu.
Hinweis: Mit nur einem Opfer endet die Runde sofort, wenn es stirbt, und alle respawnen.
Opfer können dem Jäger keinen direkten Schaden machen.

## Rollen

Eine Rolle ist ein Jäger-Preset: ein Name und welche Fähigkeit auf welchem Slot liegt.
Jede Fähigkeit ist **Off**, auf **Slot 1–4** oder (bei An/Aus-Fähigkeiten) **Passive** = immer an. Ausnahme: **Noise Radar** kann nicht passiv sein.
Zusätzlich gibt es **Menu only**: Die Fähigkeit hat keine Taste und wird im Hunter-Menü mit „Use“ ausgelöst (beliebig viele pro Rolle).
Rollen bearbeitest du im eigenen Tab **Role editor** (links neben Game). Sie werden auf dem Server gespeichert (`data/pulse/roles.json`).

**Default** ist das eigene Setup jedes Jägers (Hunter → Default) und die Standard-Rolle: Game → Role assignment steht standardmäßig auf **Fixed role = Default**, im Auswahlfenster steht Default ganz oben, und wer nicht rechtzeitig wählt, spielt Default. Mit Pill Pack wählt man bei Default zu Rundenbeginn seinen Charakter.
Startwert für alle Spieler: 1 Chaser Pulse, 2 Roar, 3 Stalk, 4 Night Vision, Heartbeat Sensor im Menü, Footprints passiv.

Mitgelieferte Rollen:

| Rolle | Slots | Menü | Passiv |
|---|---|---|---|
| Stalker | 1 Behind You, 2 Scary Sounds, 3 Teleport, 4 Roar | Stalk | Footprints, Heartbeat Sensor |
| Tracker | 1 Chaser Pulse, 2 Roar, 3 Noise Radar, 4 Scary Sounds | Stalk | Footprints |
| Brute | 1 Roar, 2 Teleport, 3 Jump Scare, 4 Chaser Pulse | – | Heartbeat Sensor |
| Seer | 1 Mark, 2 Chaser Pulse, 3 Jump Scare, 4 Scary Sounds | Stalk | Heartbeat Sensor |
| Phantom | 1 Mimic, 2 Blackout, 3 Trap, 4 Door Slam | Mark | Night Vision, Heartbeat Sensor |

Rollenvergabe (Game → Role assignment): **Fixed role**, **Player choice** (Auswahlfenster beim Start) oder **Random**.

## Fähigkeiten der Jäger

| Fähigkeit | Art | Wirkung |
|---|---|---|
| Chaser Pulse | Active | Opfer im Radius leuchten kurz als Wärmebild durch Wände |
| Roar | Active | Opfer in der Nähe werden langsamer, ihr Bildschirm wackelt |
| Teleport | Active | Teleport dorthin, wo du hinschaust |
| Scary Sounds | Active | Soundauswahl (Kinderlachen, Schreie …), abspielbar bei dir, hinter einem Opfer, wo du hinschaust oder überall |
| Aim Assist | Toggle | Zieht das Fadenkreuz auf sichtbare Opfer (Kreis zeigt den Winkel). **Standardmäßig ausgeblendet**, im Entwickler-Menü einschaltbar |
| Radar | Toggle | Alle Opfer rot umrandet durch Wände. **Standardmäßig ausgeblendet** (Entwickler-Menü) |
| Noise Radar | Toggle | Wer rennt, springt oder schießt, erscheint als Ping (pro Opfer höchstens alle 4 s). Nur an/aus, nicht passiv. Solange an, kannst du nicht sprinten |
| Footprints | Toggle | Leuchtende Fußspuren der Opfer |
| Heartbeat Sensor | Toggle | Herzschlag wird schneller, je näher ein Opfer ist |
| Stalk | Active | Ein paar Sekunden das nächste Opfer beobachten (Kamera hinter ihm), dein Körper bleibt eingefroren stehen |
| Behind You | Active | Direkt hinter das nächste Opfer teleportieren, eingefroren, kein Angriff. Das Opfer hört Atmen und Herzrasen. Dreht es sich um: leises Geräusch, du bleibst noch 1 s sichtbar und verschwindest dann zurück. Du schaust immer zum Opfer. Geht es weg: nichts passiert, du kehrst zurück |
| Jump Scare | Active | Alle Opfer im Radius sehen kurz dein Gesicht direkt vor sich |
| Blackout | Active | Opfer im Radius sehen kurz fast nichts, ihre Taschenlampe geht aus und lässt sich nicht einschalten. Schaltbare Map-Lampen gehen zusätzlich aus (experimentell, hängt von der Map ab) |
| Trap | Active | Falle auf den Boden legen (max. 3). Tritt ein Opfer hinein, hängt es fest, es klappert laut und du bekommst einen Ping |
| Mark | Active | Ein sichtbares Opfer anvisieren: Es leuchtet 10 s lila durch Wände |
| Mimic | Active | Du siehst aus wie ein zufälliges Opfer, bis du angreifst, getroffen wirst oder die Zeit abläuft. Namensanzeigen sind in Runden aus |
| Door Slam | Active | Türen in der Nähe knallen zu und sind kurz verschlossen (funktioniert nur auf Maps mit normalen Türen). Im Entwickler-Menü abschaltbar |
| Night Vision | Toggle | Grüne, verrauschte und leicht unscharfe Nachtsicht mit Scanlines. Licht nur in einem kleinen Radius (einstellbar) |

HUD des Jägers oben rechts: Slot 1–4 mit Status (READY, Abklingzeit, ACTIVE, ON/OFF) und Taste, darunter die Menü-Taste
und eine Zeile für die zuletzt benutzte Fähigkeit (läuft … / Abklingzeit …).

**Eigene Gruselsounds:** `.wav`, `.mp3` oder `.ogg` nach `addons/pulse/sound/pulse/scary/` legen (z. B. `kinderlachen.mp3`),
Map neu starten. Sie erscheinen mit ★ in der Soundauswahl. Siehe auch [Eigene Sounds](#eigene-sounds).

## Fähigkeiten der Opfer

| Slot | Fähigkeit | Wirkung |
|---|---|---|
| 1 | Flashlight Blind | Blendet den Jäger, wenn du ihn anleuchtest und er dich ansieht |
| 2 | Stay Silent | Ein paar Sekunden unauffindbar: kein Radar, Chaser Pulse, Mark, Geräusch-Ping, Fußspuren oder Herzschlag |
| 3 | Decoy | Dose werfen, der Jäger bekommt dort einen falschen Ping |
| – | Adrenaline | Nach einem Treffer des Jägers kurz schneller |
| – | Hiding Bonus | Still in der Hocke bleiben → unsichtbar für Radar und Chaser Pulse |
| 4 | Heartbeat | Nur wenn der Admin es erlaubt (Server → Victim heartbeat): Herz schlägt schneller, wenn ein Jäger nah ist. Mit Slot 4 an/aus |

Alle Opfer-Fähigkeiten kann der Admin im Tab **Server** einzeln abschalten und einstellen.

## Charaktere aus Parakeet's Pill Pack (optional)

Ist **Parakeet's Pill Pack** mit Charakter-Packs (z. B. FNAF-Charaktere) installiert, bekommt der **Role editor** ein Feld
**„Character (Pill Pack)“** mit allen installierten Charakteren.

- In der Runde wird der Jäger beim Rollenstart automatisch zu diesem Charakter (bis zum Tod bzw. Rundenende) und bekommt keine Jäger-Waffe,
  weil der Charakter eigene Angriffe hat. Die PULSE-Fähigkeiten liegen weiter auf Numpad 1–4.
- Das HUD zeigt unter den Slots den Charakter und seine Tasten (LMB, RMB, R).
- Außerhalb von Runden wird ein Jäger beim Auswählen einer Rolle zum Ausprobieren verwandelt.
- Während einer Runde sind Pills aus dem Q-Menü gesperrt.
- Jump Scare und Halluzinationen zeigen das Charakter-Model. Mimic funktioniert als Charakter nicht.
- **Default mit eigenem Charakter:** Im Rollenfenster beim Rundenstart (Rollenvergabe „Player choice“) gibt es auch **Default**
  (dein eigenes Setup aus Hunter → Default). Wählst du es, öffnet sich ein **Charakter-Auswahlfenster mit Bildern wie im Q-Menü**
  (mit Suche). Die Wahl wird gespeichert; wer nicht rechtzeitig wählt, behält seinen gespeicherten Charakter.
  Vorab festlegen geht auch im Tab **Hunter → Default → Character**.
- **Choose:** Im Role editor kann bei „Character“ auch **„Choose (player picks with pictures)“** eingestellt werden.
  Bekommt ein Jäger so eine Rolle (selbst gewählt, fest oder zufällig), öffnet sich das Charakter-Auswahlfenster.
  Wer nicht rechtzeitig wählt, bekommt seinen zuletzt gewählten Charakter.
- **Filter:** Die eigenen Charaktere des Pill Packs (Gruppen „Half-Life 2“, „Fun“, „Jake“) sind standardmäßig ausgeblendet.
  Im Tab **Game → Characters** kann der Admin jede Gruppe einzeln ein- oder ausblenden.
- Ohne Pill Pack funktioniert PULSE ganz normal, das Feld ist dann ausgeblendet.

## Items (Opfer)

Beim Rundenstart werden Items auf der Map verteilt (Anzahl und Sorten im Tab **Game → Items**). Nur Opfer können sie aufheben,
indem sie darüberlaufen oder **E** drücken (außerhalb von Runden darf jeder aufheben, zum Testen). Sie landen im normalen Waffen-Inventar: **Mausrad** zum Auswählen, **Linksklick** zum Benutzen.

| Item | Wirkung |
|---|---|
| Calming Pills | Sanity +30 % |
| Glowstick | Werfen, leuchtet 60 s grün |
| Camera Flash | Blendet einen Jäger vor dir (einmalig, breiterer Winkel als die Taschenlampe) |

Am besten funktionieren Maps mit Navmesh. Sonst werden die Items rund um die Spawnpunkte verteilt.

## Finalphase, Musik und Atmosphäre

- **Finalphase**: Lebt nur noch ein Opfer, wird es kurz schneller, und der Jäger sowie das letzte Opfer hören Chase-Musik.
- **Chase-Musik** läuft außerdem für alle in den letzten Sekunden der Runde (Standard 60 s, einstellbar, 0 = aus).
- **Ambient**: leise Hintergrundgeräusche, die im Laufe der Runde lauter werden, dazu ab und zu ein Schreck-Geräusch.
- Eigene Dateien: `addons/pulse/sound/pulse/music/`, `.../ambient/` und `.../stingers/`. Sonst wird Half-Life-2-Musik benutzt.

## Eigene Sounds

**Jeder Sound hat einen eigenen Ordner** unter `addons/pulse/sound/pulse/`. Mehrere Dateien = jedes Mal zufällig eine,
leerer Ordner = Standard-Sound. Manche Ereignisse haben noch keinen Standard und bleiben stumm, bis eine Datei im Ordner liegt
(z. B. `round/hunt/`, `round/final/`, `round/caught/`, `hunter/stalk/`, `victim/exhausted/`, `items/pickup/`).
Die komplette Ordnerliste steht in `sound/pulse/LIESMICH.txt`, jeder Ordner hat eine kurze Erklärung.
Anhören: Entwickler-Menü → Sounds. Freunde laden eigene Dateien beim Joinen automatisch herunter.

## Rundenserie

Im Tab **Game → Game Series**: **Everyone is hunter once** (so viele Runden, bis jeder einmal Jäger war) oder **Fixed number of rounds**.
Jäger wird immer, wer bisher am seltensten Jäger war. Zwischen den Runden gibt es eine Pause mit Countdown.

Punkte: Opfer überlebt +3, +1 pro volle Minute am Leben. Jäger +2 pro gefangenem Opfer, +3 bei Sieg.
Nach jeder Runde zeigt das Ergebnisfenster den Zwischenstand, nach der letzten Runde den Gesamtsieger.

## Entwickler-Menü

Als Admin **Shift + Rechtsklick auf den Tab SERVER**:
- **Hidden features:** Funktionen ein- und ausblenden: Aim Assist (aus), Radar (aus), Door Slam (an). Ausgeblendet = nirgends sichtbar (Server-Tab, Role editor, Hunter-Menü, HUD) und ohne Funktion.
- **Test mode** (siehe unten)
- **Make hunter now:** Spieler außerhalb einer Runde sofort zum Jäger machen (zum Ausprobieren der Fähigkeiten)
- **Experimental:** Blackout schaltet Map-Lichter aus, Door-Slam-Werte, Aim Assist auch auf NPCs (nur wenn Aim Assist eingeschaltet ist)
- **Sounds:** jeden Sound von PULSE nach Gruppen einzeln abspielen, eigene Dateien sind mit ★ markiert.
  Bei **Scary Sounds** schaltet der Schalter links neben „Play“ einen Gruselsound aus der Auswahl des Jägers
  (standardmäßig aus: Squeaky teddy, Woman/Man screaming, Heavy breathing, Strange voices 2, Zombie murmur).

In den Tabs **Server** und **Game** hat jede Einstellung rechts einen **Reset**-Button (zurück zum Standardwert).

## Testmodus

Im **Entwickler-Menü → Test mode**:
- Bots hinzufügen und wieder kicken, Bots laufen lassen (sie rennen, springen und ducken sich zufällig)
- Testrunde starten: Du bist Jäger, 5 s Versteckphase
- Alle Items vor die Füße legen
- Eigene Sanity auf 0 (Halluzinationen) oder 100 setzen

## Sanity und Stamina (Opfer)

**Sanity** startet bei 100 % (Balken unten links). Sie sinkt durch Schaden, wenn man den Jäger sieht und durch Schreck-Fähigkeiten
(Roar, Jump Scare, Umdrehen bei Behind You, Gruselsound in der Nähe). Sie steigt nur langsam wieder, wenn man eine Weile mit anderen Opfern zusammen ist.

Je niedriger die Sanity, desto länger laden die eigenen Fähigkeiten und desto blasser wird das Bild.
Sanity beeinflusst **nicht** Stamina und Herzschlag. Beim Anblick des Jägers sinkt sie um 0,5 pro Sekunde (einstellbar).

Bei **0 %**: Halluzinationen (verzerrtes Bild, Flüstern, falsche Jäger-Schatten), der Jäger sieht einen ab und zu lila durch Wände,
Fußspuren bleiben doppelt so lange und schon normales Gehen erzeugt Pings im Geräusch-Radar.

**Stamina** (nur während einer Runde): Sprinten verbraucht Ausdauer. Ist sie leer, kann man nur gehen, bis sie wieder zu 30 % gefüllt ist.

Alle Werte stellt der Admin im Tab **Server** unter „Sanity“ und „Stamina“ ein.

## Speichern

- **Persönliche Einstellungen** (Hunter → Default: Slots, Aim-Hilfe, Charakter …) speichert der Server pro Spieler in
  `data/pulse/players.json`. Sie sind nach einem Neustart oder Absturz wieder da.
- **Werte aus dem Tab Server** stehen in `data/pulse/server.json`, **Rollen** und **Game-Einstellungen** in `roles.json` und `game.json`.
- **Tasten** speichert GMod bei jedem Spieler selbst. PULSE legt zusätzlich eine Sicherungskopie an.
