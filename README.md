# labyrinth-arcade

Gioco arcade a labirinto in **Godot 4.7** (GDScript, 2D).

Raggiungi l'uscita verde il più in fretta possibile: ogni volta che ci arrivi
parte un nuovo labirinto, generato a caso e un po' più grande del precedente.
Undici regole speciali (buio, nemici, portali, ghiaccio...) rendono ogni
livello diverso, e dal menu iniziale scegli come giocare.

Questo README spiega anche **come è organizzato il progetto** e quali concetti
di Godot usa, file per file, così puoi studiarlo.

---

## Come provarlo

1. Scarica **Godot 4.7** (la versione "standard", non serve quella .NET) da
   <https://godotengine.org/download>.
2. Apri Godot. Nel **Project Manager** clicca **Importa** e scegli il file
   `project.godot` nella root di questa repo.
3. Premi **F5** (oppure il pulsante ▶ in alto a destra) per avviare il gioco:
   parte dal menu.

Al primo avvio Godot crea la cartella nascosta `.godot/` (cache, ignorata da
git) e importa le risorse: è normale.

### Comandi

| Dispositivo | Comando                                                         |
|-------------|-----------------------------------------------------------------|
| Tastiera    | Frecce oppure W A S D                                           |
| Gamepad     | Croce direzionale                                               |
| Touch       | Croce direzionale virtuale in basso a sinistra: tocca o trascina il dito |

Sui dispositivi con touch screen la croce virtuale è visibile da subito. Sugli
altri compare al primo clic del mouse e si può usare cliccando e trascinando (vedi
`emulate_touch_from_mouse` più sotto): così puoi provare i controlli touch
anche senza telefono.

Suggerimento: tenendo premute due direzioni (es. destra + su) il giocatore
svolta automaticamente alla prima apertura.

Per tornare al menu durante la partita: pulsante **Menu** in alto a sinistra,
oppure tasto **Esc**.

### Modalità (dal menu)

| Modalità | Come funziona |
|---|---|
| **Arcade** | Livello 1 normale, poi una regola a sorpresa a ogni livello; dal livello 5 spesso due insieme, dal 9 a volte tre. |
| **Classico** | Solo il labirinto, senza regole speciali. |
| **Caos** | Due o tre regole insieme fin dal primo livello. |
| **Sfida del giorno** | 5 livelli che oggi sono uguali per tutti (stessi labirinti, stesse regole). Alla fine vedi il tempo totale e il tuo record di oggi. |
| **Allenamento** | Un pulsante per ogni regola: la giochi da sola, a ogni livello. |

---

## Giocare sul telefono (versione web)

Il gioco è pubblicato come pagina web, all'indirizzo:

**<https://ricasino.github.io/labyrinth-arcade/>**

- Si apre dal browser di qualsiasi telefono, tablet o PC, senza installare
  niente. Sui telefoni compare da sola la croce direzionale touch.
- **Si aggiorna da solo:** ogni volta che fai un Push sul ramo `main`, GitHub
  esporta di nuovo il gioco e lo ripubblica. Ci vogliono 2-3 minuti;
  l'avanzamento si vede nella scheda **Actions** della repository su GitHub.
- **Come un'app:** dal browser puoi aggiungerlo alla schermata Home
  (Chrome: menu **⋮ → Aggiungi a schermata Home**; Samsung Internet: menu
  **≡ → Aggiungi pagina a → Schermata Home**). Si apre a schermo intero, in
  orizzontale, con la sua icona.
- **Non vedi le ultime modifiche?** Chiudi del tutto il gioco e riaprilo,
  a volte due volte: la versione installata tiene una copia del gioco per
  partire più in fretta e scarica quella nuova in sottofondo.

### Come funziona

- `export_presets.cfg` contiene il preset **Web**: le impostazioni che Godot
  usa per trasformare il progetto in una pagina web (lo trovi anche in
  *Progetto → Esporta…*).
- `.github/workflows/pubblica-web.yml` è un'automazione di **GitHub
  Actions**: a ogni Push un computer di GitHub scarica Godot, esporta il gioco
  con quel preset e lo pubblica su **GitHub Pages**, il servizio di GitHub per
  i siti web. Sulle pull request esporta il gioco senza pubblicarlo, per
  controllare che funzioni ancora.

GitHub Pages va attivato una volta sola, in **Settings → Pages → Source:
GitHub Actions**. Con un account gratuito funziona solo se la repository è
pubblica.

---

## Struttura delle cartelle

```
labyrinth-arcade/
├── project.godot              Configurazione del progetto (finestra, input, scena iniziale)
├── export_presets.cfg         Impostazioni per esportare il gioco come pagina web
├── .github/workflows/
│   └── pubblica-web.yml       Automazione: pubblica il gioco online a ogni Push
├── icon.svg                   Icona del gioco
├── scenes/                    Le scene (.tscn): "come sono fatti" gli oggetti
│   ├── menu.tscn              Il menu iniziale (è la prima scena che parte)
│   ├── ui_theme.tres          Il tema: l'aspetto dei pulsanti
│   ├── main.tscn              La scena del gioco: mette insieme tutte le altre
│   ├── player.tscn            Il giocatore (con la telecamera)
│   ├── exit.tscn              Il segnalino dell'uscita
│   ├── hud.tscn               Le scritte a schermo (livello, timer, messaggi)
│   └── touch_controls.tscn    La croce direzionale per il touch
├── scripts/                   Gli script GDScript (.gd): "cosa fanno" gli oggetti
│   ├── game_settings.gd       Autoload: modalità scelta e record
│   ├── menu.gd                Il menu: crea i pulsanti e avvia il gioco
│   ├── main.gd                Regista del gioco: livelli, varianti, timer
│   ├── maze_generator.gd      Algoritmo che genera il labirinto (solo dati)
│   ├── maze.gd                Contiene il labirinto e lo disegna
│   ├── player.gd              Movimento del giocatore sulla griglia
│   ├── exit.gd                Disegno e animazione dell'uscita
│   ├── hud.gd                 Aggiorna le scritte dell'HUD
│   └── touch_dpad.gd          Croce direzionale virtuale per il touch
├── modifiers/                 Le varianti: regole speciali, una per cartella
│   ├── level_modifier.gd      Base comune di tutte le varianti
│   ├── modifier_def.gd        La "scheda" di una variante (titolo, livello minimo...)
│   ├── modifier_catalog.gd    Il tipo del catalogo
│   ├── catalog.tres           Il catalogo: l'elenco di tutte le varianti
│   ├── common/enemy.gd        Il nemico che cammina sulla griglia (usato da più varianti)
│   └── memory/, keys/, ...    Una cartella per variante: scena, script e scheda .tres
└── tests/
    └── test_maze_generator.gd Test automatico del generatore
```

I file `*.gd.uid` e `icon.svg.import` sono generati da Godot: contengono
identificativi e impostazioni di importazione. Vanno tenuti nel repository ma
non serve modificarli a mano.

---

## Le idee base di Godot

### Nodi e scene

In Godot **tutto è un nodo**. Ogni nodo ha un tipo che decide cosa sa fare:
`Node2D` ha una posizione nel mondo 2D, `Camera2D` è una telecamera, `Label`
mostra un testo, `CanvasLayer` disegna su un livello separato, e così via.

I nodi si organizzano ad **albero** (padre → figli). Un albero di nodi salvato
su file è una **scena** (`.tscn`). Una scena può essere usata dentro un'altra
scena (si dice *istanziare*): `main.tscn` contiene un'istanza di
`player.tscn`, una di `hud.tscn`, ecc. In questo modo ogni pezzo del gioco
si apre e si modifica separatamente, e si può riusare.

Apri `scenes/main.tscn` nell'editor: nel pannello **Scena** (in alto a
sinistra) vedrai questo albero:

```
Main (Node2D)                    scripts/main.gd
├── Maze (Node2D)                scripts/maze.gd
├── Exit (exit.tscn)             scripts/exit.gd
├── Modifiers (Node2D)           qui Main aggiunge le varianti del livello
├── Player (player.tscn)         scripts/player.gd
│   └── Camera2D                 segue il giocatore perché è sua figlia
├── HUD (hud.tscn)               scripts/hud.gd
│   └── Root (Control)
│       ├── TopBar → HBox → LevelLabel, TwistLabel, TimeLabel
│       └── MessageLabel
└── TouchControls (touch_controls.tscn)
    └── DPad (Control)           scripts/touch_dpad.gd
```

L'ordine conta: i nodi più in basso vengono disegnati sopra quelli più in alto
(per questo `Player` sta dopo `Maze`).

### Script

Uno script si "attacca" a un nodo ed **estende** il suo tipo: `player.gd`
inizia con `extends Node2D`, quindi il giocatore è un Node2D con in più il
codice che scriviamo noi. Con `class_name Player` diamo anche un nome globale
al nuovo tipo, utilizzabile in tutto il progetto (es. `var p: Player`).

Godot chiama automaticamente alcune funzioni "virtuali" (iniziano con `_`):

| Funzione             | Quando viene chiamata                              | Dove la usiamo |
|----------------------|----------------------------------------------------|----------------|
| `_ready()`           | Una volta, quando il nodo e i suoi figli sono pronti | `main.gd`, `exit.gd`, `touch_dpad.gd` |
| `_process(delta)`    | A ogni fotogramma; `delta` = secondi trascorsi     | `main.gd` (timer), `player.gd` (movimento) |
| `_draw()`            | Quando il nodo va disegnato (dopo `queue_redraw()`) | `maze.gd`, `player.gd`, `exit.gd`, `touch_dpad.gd` |
| `_input(event)`      | Per ogni evento di input, prima dell'interfaccia   | `touch_dpad.gd` |
| `_gui_input(event)`  | Eventi che cadono su un Control                    | `touch_dpad.gd` |
| `_unhandled_input(event)` | Eventi che l'interfaccia non ha usato         | `player.gd` |

### Altri strumenti usati (e dove trovarli)

- **`@export`** – rende una variabile modificabile dall'**Inspector**
  (pannello a destra). Prova: seleziona `Main` in `main.tscn` e cambia
  `First Cols` o `Cols Per Level`; seleziona `Player` e cambia `Speed`.
- **`@onready` e `$Nodo` / `%Nodo`** – trovano i nodi figli quando la scena è
  pronta (`main.gd`, `hud.gd`). `%` usa i *nomi unici* della scena.
- **Segnali** – eventi a cui altri nodi si collegano. `Player` emette
  `reached_cell` a ogni passo; `Main` lo ascolta e controlla se è l'uscita.
  Il giocatore così non deve sapere nulla di livelli e timer.
- **Mappa input** (*Progetto → Impostazioni progetto → Mappa input*) – le
  azioni `move_up`, `move_down`, `move_left`, `move_right` raccolgono tasti
  e pulsanti diversi sotto un unico nome. Il codice chiede "è premuto
  `move_up`?" e non "è premuto W o freccia su?".
- **Camera2D** – figlia del giocatore, quindi lo segue. I suoi *limiti*
  (calcolati in `main.gd`) le impediscono di mostrare il vuoto oltre il
  labirinto e lo tengono centrato quando è più piccolo dello schermo.
- **CanvasLayer** – l'HUD e la croce touch stanno su livelli separati che
  non si muovono con la telecamera.
- **Control e ancore** – i nodi dell'interfaccia si posizionano rispetto ai
  bordi dello schermo (la croce è "ancorata" in basso a sinistra), così si
  adattano a qualsiasi risoluzione.
- **Tween** – animano una proprietà nel tempo: la pulsazione dell'uscita
  (`exit.gd`) e la dissolvenza dei messaggi (`hud.gd`).
- **`await`** – mette in pausa una funzione senza bloccare il gioco: in
  `main.gd` aspettiamo 1,5 secondi prima del livello successivo.
- **Autoload** (*Progetto → Impostazioni progetto → Globali*) – un nodo che
  Godot crea all'avvio e che sopravvive ai cambi di scena. `GameSettings`
  porta la modalità scelta dal menu al gioco e salva i record nella cartella
  `user://`.
- **Cambiare scena** – `get_tree().change_scene_to_file(...)` sostituisce la
  scena attuale con un'altra (menu → gioco e ritorno).
- **Tema** (`scenes/ui_theme.tres`) – l'aspetto dei pulsanti (colori, bordi,
  angoli arrotondati) definito una volta sola e usato dal menu e dall'HUD.
- **Risorse personalizzate** – `ModifierDef` e `ModifierCatalog` sono "schede"
  di soli dati, salvate come file `.tres` e modificabili nell'Inspector.

---

## Cosa succede quando premi Play

1. Godot legge `project.godot`. Prima crea gli **Autoload** (qui
   `GameSettings`), poi carica la scena indicata in `run/main_scene`, cioè
   `scenes/menu.tscn`.
2. Il menu (`scripts/menu.gd`) crea un pulsante per ogni variante del
   catalogo. Quando scegli una modalità la scrive in `GameSettings.mode` e
   cambia scena con `get_tree().change_scene_to_file("res://scenes/main.tscn")`:
   il menu viene eliminato e parte il gioco.
3. Tutti i nodi del gioco entrano nell'albero e ricevono `_ready()`: **prima i
   figli, poi il padre**. Quindi quando arriva `Main._ready()` labirinto,
   giocatore e HUD sono già pronti.
4. `Main._ready()` legge la modalità da `GameSettings`, collega i segnali e
   chiama `_start_level(1)`, che:
   - chiede a `Maze` di generare un labirinto (`maze.generate`), il quale usa
     `MazeGenerator` e poi si ridisegna;
   - mette l'uscita e il giocatore nelle loro caselle;
   - aggiorna i limiti della telecamera e azzera il timer;
   - dal livello 2 pesca una variante, la aggiunge sotto `Modifiers` e
     mostra il suo nome (vedi "Le varianti" più sotto).
5. A ogni fotogramma:
   - `Main._process` aggiunge `delta` al tempo e aggiorna l'HUD;
   - `Player._process` fa avanzare il giocatore verso la casella successiva e,
     quando ci arriva, emette `reached_cell` e sceglie il passo seguente in
     base ai tasti premuti. Prima di ogni passo chiede a `Main.can_enter()`
     se la casella è libera.
6. Quando la casella raggiunta è l'uscita, `Main._complete_level()` ferma il
   timer, blocca il giocatore, mostra il tempo, aspetta un attimo e chiama
   `_start_level` con il livello successivo (più grande).

### Come arriva l'input al giocatore

```
Tastiera / gamepad ─────────────────────────────┐
                                                ├─► azioni move_* ─► Player
Touch ─► DPad (_gui_input) ─► InputEventAction ─┘
```

La croce touch non comanda direttamente il giocatore: crea un evento
`InputEventAction` e lo passa a `Input.parse_input_event()`, esattamente
come se fosse stato premuto un tasto. Il giocatore legge solo le azioni e
non sa (né gli interessa) da quale dispositivo arrivano.

---

## Il labirinto

Il labirinto è una **griglia di caselle**, ognuna muro o pavimento. Il
giocatore si muove di una casella alla volta e può entrare solo nelle caselle
libere (`Maze.is_walkable`): non serve il motore fisico.

`maze_generator.gd` usa l'algoritmo **recursive backtracker**:

1. si parte da una griglia tutta muro, divisa in "stanze" (le caselle con
   coordinate dispari);
2. si parte dalla prima stanza e si sceglie a caso una stanza vicina non
   ancora visitata, abbattendo il muro in mezzo;
3. se non ci sono vicini liberi si torna indietro (*backtracking*) finché se
   ne trova uno;
4. quando tutte le stanze sono visitate il labirinto è finito.

Il risultato è un labirinto **perfetto**: tutte le caselle sono raggiungibili
e tra due punti esiste un solo percorso. La partenza è in alto a sinistra,
l'uscita in basso a destra.

Dimensioni: il livello 1 ha 7×4 stanze, ogni livello aggiunge 2 colonne e 1
riga (modificabile dall'Inspector del nodo `Main`).

Il disegno è fatto da codice in `Maze._draw()`: un rettangolo per ogni muro
più una linea "neon" sui lati che toccano il pavimento.

---

## Le varianti

Le **varianti** sono le regole speciali dei livelli. In modalità Arcade sono
pescate a caso, mai le stesse del livello appena giocato, e due varianti che
non vanno d'accordo (per esempio due tipi di nemici) non escono mai insieme.
Il loro nome compare in alto al centro; sotto, una riga di stato come
"Stelle 2/5".

| Variante (cartella in `modifiers/`) | Cosa succede | Cosa insegna di Godot |
|---|---|---|
| **A memoria** (`memory`) | Il labirinto si vede per 3 secondi, poi i muri spariscono. | Animare una proprietà con un `Tween` |
| **Labirinto vivo** (`living_maze`) | È buio: si vede solo attorno a te, e fuori dalla luce i muri si spostano. | Luci 2D (`CanvasModulate`, `PointLight2D`), `Timer`, segnali collegati nell'editor |
| **Caccia alle stelle** (`stars`) | L'uscita vale solo dopo aver raccolto tutte le stelle. | Disegnare poligoni con `_draw()` |
| **Chiavi e porte** (`keys`) | Porte colorate sulla strada: serve la chiave dello stesso colore. | Visita in ampiezza per mettere le chiavi dove si possono raggiungere |
| **Portali** (`portals`) | Entri in un portale ed esci da quello dello stesso colore. | Spostare il giocatore da codice |
| **Specchio** (`mirror`) | Comandi invertiti. | Effetti sul giocatore che il gioco azzera a ogni livello |
| **Ghiaccio** (`ice`) | Scivoli finché non trovi un muro o un incrocio. | Cambiare un colore del labirinto a runtime |
| **A ritmo** (`rhythm`) | Cancelli che si aprono e chiudono a tempo di metronomo. | Creare un suono da codice (`AudioStreamWAV`, `AudioStreamPlayer`) |
| **Ronda** (`patrol`) | Guardie che vanno avanti e indietro in corridoi laterali. | Nemici creati da codice (`Enemy.new()`), funzioni salvate in variabili (lambda) |
| **Inseguitore** (`chaser`) | Un mostro più lento di te ti insegue quando ti sente. | Ricalcolare il percorso più breve a ogni passo |
| **Il tuo fantasma** (`ghost`) | Un fantasma rifà la tua strada qualche secondo dopo. | Registrare e "riprodurre" posizioni nel tempo |

Se un nemico ti tocca torni alla partenza e il tempo aumenta di 3 secondi.

### Come è fatta una variante

Ogni variante è una cartella dentro `modifiers/` con tre file:

- **una scena** (`.tscn`), il cui nodo principale ha uno script che estende
  `LevelModifier`. Può avere nodi figli: luci, timer, sprite...;
- **lo script** (`.gd`), che ridefinisce solo le funzioni che gli servono:
  - `level_started()`: il labirinto è pronto, la variante può iniziare;
  - `player_stepped(cell)`: il giocatore è arrivato in una casella;
  - `blocks_cell(cell)`: risponde `true` per impedire al giocatore di
    entrare in una casella (porte, trappole...);
  - `allows_exit()`: risponde `false` se l'uscita non deve ancora valere;
  - `player_caught()`: un nemico ti ha preso e sei tornato alla partenza;
  - `status_text()`: il testo della riga di stato nell'HUD;
- **la scheda** (`.tres`, una risorsa `ModifierDef`), con titolo,
  descrizione, livello minimo, "peso" (quanto spesso esce) ed etichette
  (`tags`: due varianti con un'etichetta in comune non escono insieme).

Dallo script la variante raggiunge tutto il gioco tramite `game`:
`game.maze`, `game.player`, `game.hud`, `game.exit_marker`, `game.rng`,
`game.level`, e funzioni utili come `game.pick_rooms()` (stanze libere dove
mettere oggetti) e `game.catch_player()` (il giocatore è stato preso). `Main` la crea a inizio livello e la elimina alla fine, quindi
tutto quello che la variante crea sparisce con lei.

### Creare una nuova variante (passo passo)

1. Nel pannello **FileSystem** crea una cartella in `modifiers/`, per esempio
   `modifiers/veloce/`.
2. Crea una nuova scena con un nodo **Node2D** e salvala lì (`veloce.tscn`).
3. Attacca al nodo un nuovo script (`veloce.gd`) e cambia la prima riga in
   `extends LevelModifier`. Per esempio:
   ```gdscript
   extends LevelModifier

   func level_started() -> void:
   	game.player.speed = 14.0  # Il giocatore corre!
   ```
   (Attenzione: questa modifica resterebbe anche nei livelli dopo. Per
   annullarla, ridefinisci `_exit_tree()` e rimetti la velocità di prima.)
4. Clic destro sulla cartella → **Crea nuovo → Risorsa…** → **ModifierDef**:
   salvala come `veloce.tres`, poi nell'Inspector compila titolo e
   descrizione e trascina `veloce.tscn` nel campo **Scene**.
5. Fai doppio clic su `modifiers/catalog.tres` (il catalogo di tutte le
   varianti) e trascina `veloce.tres` nella lista **Modifiers**
   dell'Inspector. Fatto: la variante esce in Arcade e ha il suo pulsante
   nell'Allenamento del menu.

---

## Impostazioni del progetto

Si trovano in *Progetto → Impostazioni progetto* (salvate in `project.godot`).
Quelle scelte per questo gioco:

| Impostazione | Valore | Perché |
|---|---|---|
| Display → Window → Viewport Width/Height | 1280 × 720 | Risoluzione "di riferimento" |
| Display → Window → Stretch → Mode | `canvas_items` | Il gioco si scala su qualsiasi schermo |
| Display → Window → Stretch → Aspect | `expand` | Su schermi più larghi o più alti si vede più labirinto, senza bande nere |
| Display → Window → Handheld → Orientation | Sensor Landscape | Sui telefoni gioca in orizzontale (in entrambi i versi) |
| Input Devices → Pointing → Emulate Touch From Mouse | attivo | Il mouse genera eventi touch: provi la croce sul PC |
| Rendering → Renderer | Compatibility | Il più leggero: va bene per il 2D, per i telefoni e per il web |

---

## Test

Il generatore ha un test che controlla bordi chiusi, raggiungibilità di
tutte le caselle e assenza di anelli, anche dopo centinaia di spostamenti di
muri (quelli del "Labirinto vivo"). Si lancia da terminale, senza finestra:

```
godot --headless --path . -s tests/test_maze_generator.gd
```

(`godot` è il percorso dell'eseguibile di Godot sul tuo computer.) Deve
stampare `OK: tutti i labirinti sono validi.`

---

## Idee per continuare

Piccoli esercizi, in ordine di difficoltà, per prendere confidenza:

1. **Cambia i parametri** dall'Inspector: velocità del giocatore, colori dei
   muri, dimensione delle caselle (`Maze → Tile Size`), crescita dei livelli.
2. **Record**: salva il miglior tempo di ogni livello con `ConfigFile` in
   `user://` e mostralo nell'HUD.
3. **Suoni**: aggiungi un nodo `AudioStreamPlayer` e riproduci un suono quando
   si trova l'uscita.
4. **Conto alla rovescia**: invece di contare il tempo in avanti, dai un tempo
   limite per livello e aggiungi una schermata di game over.
5. **Grafica con le tile**: sostituisci il disegno da codice con un nodo
   `TileMapLayer` e un `TileSet` disegnato da te.
6. **App Android**: esporta il gioco anche come app da installare
   (*Progetto → Esporta… → Aggiungi… → Android*; servono gli strumenti di
   Android sul PC).
