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
