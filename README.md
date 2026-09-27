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
3. Nach dem Joinen kommt im Chat „PULSE loaded“. Mit **F5** öffnest du das Menü.

## Menü (F5)

| Tab | Wer | Inhalt |
|---|---|---|
| **Keybinds** | alle | Menü-Taste und die 4 Fähigkeiten-Slots belegen |
| **Hunter** | Jäger, Admin | Außerhalb der Runde: **Abilities** (ausführen, inkl. Menü-Fähigkeiten), **Roles** (Rolle wählen), **Default** (eigene Einstellungen und Slots). In der Runde nur die ausführbaren Fähigkeiten |
| **Victim** | alle | Fähigkeiten der Opfer |
| **Players** | Admin | Jäger setzen (zum Testen), „Next round“ für vorausgewählte Jäger, Zahnrad = Default-Einstellungen des Spielers |
| **Server** | Admin | Werte aller Fähigkeiten (Reichweite, Dauer, Abklingzeit …) |
| **Game** | Admin | Runde starten/stoppen, Überlebenszeit, Versteckphase, Jäger-Anzahl und -Auswahl, Rollenvergabe, **Role editor** |

Links in jedem Tab ist eine Abschnittsliste; ein Klick springt direkt zum Abschnitt.

## Tasten

| Taste | Standard |
|---|---|
| Menü | **F5** |
| Slot 1–4 | **Numpad 1–4** |

Jäger und Opfer nutzen dieselben 4 Slot-Tasten. Was ein Slot macht, hängt von der Rolle ab.
Hinweis: F5 macht in GMod auch einen Screenshot. Wen das stört, legt das Menü im Tab Keybinds auf eine andere Taste.

## Ablauf einer Runde

1. Der Admin stellt im Tab **Game** alles ein und drückt **Start round**.
2. Jäger werden bestimmt (zufällig oder vorausgewählt). Alle respawnen, Jäger bekommen ihre Waffe (Standard: Brechstange), Opfer keine.
   Bauen, Noclip und Spawnen sind während der Runde aus.
3. **Versteckphase** (Standard 30 s, abschaltbar): Die Opfer verstecken sich, der Jäger ist eingefroren und sieht nichts.
   Bei „Player choice“ wählt der Jäger in dieser Zeit seine Rolle (wer nicht wählt, bekommt eine zufällige).
4. **Jagd**: Oben in der Mitte sehen alle den Timer und den Namen des Jägers.
5. **Ende**:
   - Alle Opfer tot → **der Jäger gewinnt**
   - Zeit abgelaufen und mindestens ein Opfer lebt → **die Opfer gewinnen**
   - Der Jäger stirbt (z. B. Fallschaden) → **die Opfer gewinnen**
6. Ein Fenster zeigt den Gewinner und ein Scoreboard (Rolle, Überlebenszeit, Ergebnis, gefangene Opfer).

Tote Opfer schauen bis zum Rundenende zu. Wer während einer Runde joint, schaut ebenfalls zu.
Opfer können dem Jäger keinen direkten Schaden machen.

## Rollen

Eine Rolle ist ein Jäger-Preset: ein Name und welche Fähigkeit auf welchem Slot liegt.
Jede Fähigkeit ist **Off**, auf **Slot 1–4** oder (bei An/Aus-Fähigkeiten) **Passive** = immer an.
Zusätzlich gibt es **Menu only**: Die Fähigkeit hat keine Taste und wird im Hunter-Menü mit „Use“ ausgelöst (beliebig viele pro Rolle).
Rollen bearbeitest du im Tab **Game → Role editor**. Sie werden auf dem Server gespeichert (`data/pulse/roles.json`).

Mitgelieferte Rollen:

| Rolle | Slots | Menü | Passiv |
|---|---|---|---|
| Stalker | 1 Behind You, 2 Scary Sounds, 3 Teleport, 4 Roar | Stalk | Footprints, Heartbeat Sensor |
| Tracker | 1 Chaser Pulse, 2 Roar, 3 Scary Sounds, 4 Stalk | – | Noise Radar, Footprints |
| Brute | 1 Roar, 2 Teleport, 3 Jump Scare, 4 Aim Assist | – | Heartbeat Sensor |
| Seer | 1 Radar, 2 Chaser Pulse, 3 Jump Scare, 4 Scary Sounds | Stalk | Heartbeat Sensor |

Rollenvergabe (Game → Role assignment): **Fixed role**, **Player choice** (Auswahlfenster beim Start) oder **Random**.

## Fähigkeiten der Jäger

| Fähigkeit | Art | Wirkung |
|---|---|---|
| Chaser Pulse | Active | Opfer im Radius leuchten kurz als Wärmebild durch Wände |
| Roar | Active | Opfer in der Nähe werden langsamer, ihr Bildschirm wackelt |
| Teleport | Active | Teleport dorthin, wo du hinschaust |
| Scary Sounds | Active | Soundauswahl (Kinderlachen, Schreie …), abspielbar bei dir, hinter einem Opfer, wo du hinschaust oder überall |
| Aim Assist | Toggle | Zieht das Fadenkreuz auf sichtbare Opfer (Kreis zeigt den Winkel) |
| Radar | Toggle | Alle Opfer rot umrandet durch Wände |
| Noise Radar | Toggle | Wer rennt, springt oder schießt, erscheint als Ping |
| Footprints | Toggle | Leuchtende Fußspuren der Opfer |
| Heartbeat Sensor | Toggle | Herzschlag wird schneller, je näher ein Opfer ist |
| Stalk | Active | Ein paar Sekunden das nächste Opfer beobachten (Kamera hinter ihm), dein Körper bleibt eingefroren stehen |
| Behind You | Active | Direkt hinter das nächste Opfer teleportieren, eingefroren, kein Angriff. Das Opfer hört Atmen und Herzrasen. Dreht es sich um: leises Geräusch, du verschwindest zurück. Geht es weg: nichts passiert, du kehrst zurück |
| Jump Scare | Active | Alle Opfer im Radius sehen kurz dein Gesicht direkt vor sich |

HUD des Jägers oben rechts: Slot 1–4 mit Status (READY, Abklingzeit, ACTIVE, ON/OFF) und Taste, darunter die Menü-Taste
und eine Zeile für die zuletzt benutzte Fähigkeit (läuft … / Abklingzeit …).

**Eigene Sounds:** `.wav`, `.mp3` oder `.ogg` nach `addons/pulse/sound/pulse/` legen (z. B. `kinderlachen.mp3`),
Map neu starten. Sie erscheinen mit ★ in der Soundauswahl.

## Fähigkeiten der Opfer

| Slot | Fähigkeit | Wirkung |
|---|---|---|
| 1 | Flashlight Blind | Blendet den Jäger, wenn du ihn anleuchtest und er dich ansieht |
| 2 | Stay Silent | Kurz unsichtbar für Noise Radar, Footprints und Heartbeat |
| 3 | Decoy | Dose werfen, der Jäger bekommt dort einen falschen Ping |
| – | Adrenaline | Nach einem Treffer des Jägers kurz schneller |
| – | Hiding Bonus | Still in der Hocke bleiben → unsichtbar für Radar und Chaser Pulse |
| – | Heartbeat | Optional: Opfer hören ihr Herz, wenn ein Jäger nah ist |

Alle Opfer-Fähigkeiten kann der Admin im Tab **Server** einzeln abschalten und einstellen.

## Sanity und Stamina (Opfer)

**Sanity** startet bei 100 % (Balken unten links). Sie sinkt durch Schaden, wenn man den Jäger sieht und durch Schreck-Fähigkeiten
(Roar, Jump Scare, Umdrehen bei Behind You, Gruselsound in der Nähe). Sie steigt nur langsam wieder, wenn man eine Weile mit anderen Opfern zusammen ist.

Je niedriger die Sanity:
- desto lauter und schneller hört man generell den Herzschlag
- desto schneller sinkt die Ausdauer
- desto länger laden die eigenen Fähigkeiten

Bei **0 %**: Halluzinationen (verzerrtes Bild, Flüstern, falsche Jäger-Schatten), der Jäger sieht einen ab und zu lila durch Wände,
Fußspuren bleiben doppelt so lange und schon normales Gehen erzeugt Pings im Geräusch-Radar.

**Stamina** (nur während einer Runde): Sprinten verbraucht Ausdauer. Ist sie leer, kann man nur gehen, bis sie wieder zu 30 % gefüllt ist.

Alle Werte stellt der Admin im Tab **Server** unter „Sanity“ und „Stamina“ ein.
