# Hunter Tools – Garry's Mod Addon

Ein Server-Addon, mit dem der **Jäger** in eurem Horror-Spiel stärker wird.
Du brauchst **keinen Injektor**. Es ist ein normales Addon, das auf dem Server installiert wird.
Deine Freunde laden den Client-Teil beim Joinen automatisch herunter.

## Installation

1. Kopiere den Ordner `hunter_tools` nach `garrysmod/addons/`
   - Wenn du selbst hostest (Listen-Server über „Neues Spiel“): in **deine** GMod-Installation
   - Bei einem gemieteten/dedizierten Server: in den `addons`-Ordner des Servers
2. Starte den Server bzw. die Map neu.
3. Drück im Spiel **F5**. Als Host bekommst du nach dem Joinen die Chat-Meldung „Hunter Tools geladen“.
   - Tab **Jäger**: „Mich zum Jäger machen“ und danach alle Fähigkeiten und Tasten
   - Tab **Spieler**: Haken setzen, wer Jäger ist. Über das **Zahnrad** neben jedem Namen änderst du dessen Jäger-Einstellungen (nur Host/Superadmin)
   - Tab **Server**: ein oder mehrere Jäger, Fähigkeiten erlauben/verbieten, Grenzen setzen (nur Host/Superadmin)

Alles läuft über das Menü, du brauchst keine Konsolenbefehle. Alle Spieler sehen im Chat, wer Jäger ist.

**Funktioniert nicht?**
- Kommt nach dem Joinen keine Meldung „Hunter Tools geladen“, liegt der Ordner falsch. Richtig ist
  `garrysmod/addons/hunter_tools/lua/autorun/hunter_tools_init.lua` (nicht `hunter_tools/hunter_tools/...`).
- Du musst die Runde **selbst hosten** (Neues Spiel → Spieleranzahl über 1). Auf dem Server eines anderen muss dieser das Addon installieren.

## Fähigkeiten

| Fähigkeit | Standard-Taste | Beschreibung |
|---|---|---|
| Menü | **F5** | Alle Einstellungen und Tasten ändern |
| Aim-Hilfe | **Numpad 1** | Zieht das Fadenkreuz auf den nächsten sichtbaren Spieler im Kreis. Der Kreis in der Bildschirmmitte zeigt den Winkel und wird grün, sobald ein Ziel erfasst ist. Optional auch auf NPCs/Nextbots (gut zum Testen). |
| Radar | **Numpad 2** | Alle Spieler rot umrandet durch Wände, mit Name und Entfernung |
| Chaser-Puls | **Numpad 3** | Schwächere Variante: Spieler im Radius erscheinen kurz als Wärmebild (Radius und Dauer einstellbar, Standard 1500 Units / 5 s) |
| Brüllen | **Numpad 4** | Schrei; Opfer im Radius werden kurz langsamer, ihr Bildschirm wackelt und färbt sich rot |
| Geräusch-Radar | **Numpad 5** | Wer sprintet, springt oder schießt, erscheint kurz als Ping. Wer geht oder schleicht, bleibt unsichtbar |
| Fußspuren | **Numpad 6** | Opfer hinterlassen leuchtende Fußabdrücke, die nur der Jäger sieht |
| Herzschlag | **Numpad 7** | Je näher das nächste Opfer, desto schneller und lauter der Herzschlag. Zeigt keine Richtung |
| Teleport | **Numpad 8** | Teleportiert dorthin, wo du hinschaust (kurze Reichweite, lange Abklingzeit) |
| Gruselsound-Auswahl | **Numpad 9** | Kleines Fenster mit allen Gruselsounds, anklicken spielt ab |
| Zufälliger Gruselsound | **Numpad 0** | Spielt einen zufälligen Gruselsound |

### Gruselsounds

Im Tab **Jäger** wählst du, **wo** der Sound abgespielt wird:

- **Bei mir**: kommt von deiner Position (verrät dich)
- **Hinter einem zufälligen Opfer**: ein paar Meter hinter einem Opfer, das nichts ahnt
- **Wo ich hinschaue**: an der Stelle, auf die du zielst (gut zum Weglocken)
- **Überall**: alle hören ihn direkt „im Kopf“ (kann der Admin verbieten)

Eingebaut sind Sounds aus Half-Life 2 (z. B. spielende/lachende Kinder, Kinderschrei, Schluchzen, Atmen, Schreie, seltsame Stimmen).
Es erscheinen nur die, die auf dem Server vorhanden sind.

**Eigene Sounds:** Leg `.wav`-, `.mp3`- oder `.ogg`-Dateien in `addons/hunter_tools/sound/hunter_tools/`
(z. B. `kinderlachen.mp3`). Nach einem Map-Neustart stehen sie mit ★ im Soundboard. Deine Freunde laden sie beim Joinen automatisch herunter.

### Fähigkeiten der Opfer (Tab „Opfer“, für alle Spieler)

| Fähigkeit | Standard-Taste | Beschreibung |
|---|---|---|
| Taschenlampen-Blitz | **Numpad 1** | Blendet den Jäger (weißer Bildschirm), wenn du ihn direkt anleuchtest und er dich gleichzeitig ansieht |
| Leise sein | **Numpad 2** | Ein paar Sekunden unsichtbar für Geräusch-Radar, Fußspuren und Herzschlag |
| Ablenkung | **Numpad 3** | Wirft eine Dose; wo sie aufschlägt, bekommt der Jäger einen falschen Ping |
| Adrenalin-Sprint | automatisch | Trifft dich der Jäger, bist du kurz schneller |
| Versteck-Bonus | automatisch | Bleibst du eine Weile still in der Hocke, sieht dich der Jäger nicht mehr mit Radar oder Chaser-Puls |

Die Opfer-Tasten sind getrennt von den Jäger-Tasten. Wer Jäger ist, benutzt automatisch die Jäger-Belegung.
Die Opfer-Anzeige steht unten links.

Alle Tasten kannst du im Menü neu belegen (auf das Feld klicken, dann die neue Taste drücken).

> **Hinweis F5:** In GMod macht F5 standardmäßig einen Screenshot. Das Menü geht trotzdem auf,
> aber wenn dich der Screenshot stört: `unbind f5` in die Konsole eingeben oder im Menü eine andere Taste wählen.

## Server-Einstellungen (Balancing)

Alle Werte kannst du im Menü im Tab **Server** ändern. Für einen dedizierten Server gehen sie auch in `server.cfg`.
Der Jäger kann im Menü nur bis zu diesen Grenzen einstellen.

| ConVar | Standard | Bedeutung |
|---|---|---|
| `ht_allow_aim` | 1 | Aim-Hilfe erlauben |
| `ht_allow_esp` | 1 | Radar erlauben (auf 0 setzen, wenn nur der Chaser-Modus erlaubt sein soll) |
| `ht_allow_chaser` | 1 | Chaser-Modus erlauben |
| `ht_multi_hunter` | 0 | Mehrere Jäger gleichzeitig erlauben (0 = nur einer) |
| `ht_aim_max_strength` | 0.8 | Maximale Aim-Hilfe-Stärke (0–1) |
| `ht_aim_max_fov` | 20 | Maximaler Aim-Hilfe-Winkel in Grad |
| `ht_chaser_max_radius` | 3000 | Maximaler Chaser-Radius |
| `ht_chaser_max_duration` | 10 | Maximale Chaser-Dauer in Sekunden |
| `ht_chaser_cooldown` | 15 | Abklingzeit nach einem Puls in Sekunden |
| `ht_admins_are_hunters` | 0 | Admins werden beim Joinen automatisch Jäger |
| `ht_allow_roar` / `ht_allow_noise` / `ht_allow_tracks` / `ht_allow_heart` / `ht_allow_teleport` | 1 | Neue Fähigkeiten einzeln erlauben |
| `ht_roar_radius` / `ht_roar_slow` / `ht_roar_duration` / `ht_roar_cooldown` | 600 / 0.5 / 3 / 30 | Brüllen: Radius, Tempo der Opfer, Dauer, Abklingzeit |
| `ht_noise_radius` | 2500 | Reichweite des Geräusch-Radars |
| `ht_tracks_radius` / `ht_tracks_time` | 3000 / 8 | Fußspuren: Reichweite und Sichtdauer |
| `ht_heart_range` | 1500 | Herzschlag ab dieser Entfernung hörbar |
| `ht_victim_heart` / `ht_victim_heart_range` | 0 / 1000 | Opfer hören Herzklopfen, sobald ein Jäger näher als diese Entfernung ist |
| `ht_teleport_range` / `ht_teleport_cooldown` | 800 / 45 | Teleport: Reichweite und Abklingzeit |
| `ht_allow_sounds` / `ht_sound_allow_global` | 1 / 1 | Gruselsounds erlauben / Modus „Überall“ erlauben |
| `ht_sound_cooldown` / `ht_sound_level` / `ht_sound_range` | 10 / 85 / 2000 | Gruselsounds: Abklingzeit, Lautstärke/Reichweite, max. Entfernung für „Wo ich hinschaue“ |
| `ht_allow_adrenaline` / `ht_adrenaline_speed` / `ht_adrenaline_time` / `ht_adrenaline_cooldown` | 1 / 1.5 / 3 / 20 | Opfer: Adrenalin-Sprint |
| `ht_allow_flash` / `ht_flash_range` / `ht_flash_time` / `ht_flash_cooldown` | 1 / 600 / 2.5 / 40 | Opfer: Taschenlampen-Blitz |
| `ht_allow_silent` / `ht_silent_time` / `ht_silent_cooldown` | 1 / 6 / 45 | Opfer: Leise sein |
| `ht_allow_decoy` / `ht_decoy_cooldown` | 1 / 25 | Opfer: Ablenkung |
| `ht_allow_hide` / `ht_hide_time` | 1 / 5 | Opfer: Versteck-Bonus |

## Wie es funktioniert

- Der Server entscheidet, wer Jäger ist. Nur der Jäger bekommt die Positionen der anderen Spieler hinter Wänden übertragen,
  und nur solange Radar oder ein Chaser-Puls aktiv ist.
- Der Chaser-Puls wird vom Server geprüft (Radius, Dauer, Abklingzeit). Man kann ihn also nicht über die Grenzen hinaus hochdrehen.
