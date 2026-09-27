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

## Wie es funktioniert

- Der Server entscheidet, wer Jäger ist. Nur der Jäger bekommt die Positionen der anderen Spieler hinter Wänden übertragen,
  und nur solange Radar oder ein Chaser-Puls aktiv ist.
- Der Chaser-Puls wird vom Server geprüft (Radius, Dauer, Abklingzeit). Man kann ihn also nicht über die Grenzen hinaus hochdrehen.
