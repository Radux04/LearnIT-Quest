# LearnIT Quest - Level 1: Binary Search Tree Network

Un edugame interattivo sviluppato in Godot Engine che insegna i **Binary Search Tree (BST)** attraverso un'esperienza pratica di 5 minuti.

## 🎮 Panoramica del Gioco

Il giocatore impersona un tecnico di rete che deve ripristinare una rete di router danneggiata da un hacker, imparando nel contempo il funzionamento dei Binary Search Tree. Il gioco è diviso in **4 fasi consecutive** senza schermate di caricamento.

## 📋 Fasi del Gioco

### 🟦 Introduzione
- Schermata di tutorial che spiega i concetti base del BST
- Regola principale: valori minori a sinistra, maggiori a destra
- Benefici: ricerca veloce nella struttura

### ⚙️ Fase 1: Ricostruzione della Rete (Drag & Drop)
**Durata**: ~1 minuto

- Un router radice (50) è già posizionato al centro
- 6 router aggiuntivi (30, 70, 20, 40, 60, 80) da trascinare
- Il giocatore deve posizionare ogni router nella posizione corretta rispetto al BST
- **Validazione in tempo reale**: posizionamento corretto = feedback verde, errato = messaggio d'errore
- Completamento: quando tutti i router sono posizionati

### 📡 Fase 2: Instradamento dei Pacchetti (Decision Tree)
**Durata**: ~1 minuto

- 5 pacchetti di rete con destinazioni diverse da consegnare
- Al nodo radice, il giocatore sceglie SINISTRA o DESTRA per raggiungere la destinazione
- Percorso corretto = pacchetto consegnato
- Percorso errato = -10 secondi di tempo
- Insegna la ricerca nel BST attraverso il gameplay

### 🔍 Fase 3: Scansione della Rete (Tree Traversals)
**Durata**: ~1.5 minuti

- L'antivirus deve esaminare la rete in un ordine specifico
- 4 tipi di visita casuali:
  - **Preorder** (radice → sinistro → destro)
  - **Inorder** (sinistro → radice → destro)
  - **Postorder** (sinistro → destro → radice)
  - **BFS** (livello per livello)
- Il giocatore clicca i router nell'ordine corretto
- Visual feedback: verde = corretto, rosso = errore (-10 sec)

### ⚡ Fase 4: Attacco Finale (45 secondi)
**Durata**: 45 secondi

L'hacker attacca continuamente. Tre tipi di sfide casuali:
- **Inserisci**: Digita il valore del router da inserire
- **Elimina**: Scegli quale router è compromesso (3 opzioni)
- **Ricerca**: Scegli la direzione corretta per trovare un valore

Penalità: -15 secondi per risposta errata. Il giocatore deve completare quante più sfide possibili in 45 secondi.

## ⏱️ Sistema Timer

- **Durata totale**: 5 minuti (300 secondi)
- **Timer visibile** in alto a destra
- **Colore dinamico**: verde (>60s), rosso (<60s)
- **Game Over**: scadenza tempo prima del completamento

## 🎨 Estetica Visiva

- **Stile**: Cyberpunk moderno con tema blu/verde/rosso
- **Router**: Sprite futuristici con design moderno
- **Cavi**: Linee luminose che collegano i nodi
- **Feedback**: 
  - Verde per azioni corrette
  - Rosso per errori
  - Animazioni di fade e scale per feedback visivo
- **Effetti**: Glow, flash, shake quando necessario

## 🛠️ Tecnologie Utilizzate

- **Engine**: Godot 4.5+
- **Linguaggio**: GDScript
- **Struttura dati**: Binary Search Tree (implementato in GDScript)
- **Generazione asset**: AI per sprite e animazioni

## 📁 Struttura del Progetto

```
learn-it-quest/
├── scenes/
│   ├── introduction.tscn       # Schermata di introduzione
│   ├── level.tscn              # Scene principale del livello
│   └── main.tscn               # Scena root con GameManager
├── scripts/
│   ├── global/
│   │   └── GameManager.gd      # Gestione globale del gioco e BST
│   ├── scenes/
│   │   ├── IntroductionScreen.gd  # UI introduzione
│   │   └── Level.gd              # Logica principale del livello
│   ├── phases/
│   │   ├── Phase1Manager.gd    # Drag & drop ricostruzione
│   │   ├── Phase2Manager.gd    # Routing dei pacchetti
│   │   ├── Phase3Manager.gd    # Tree traversals
│   │   └── Phase4Manager.gd    # Sfide finali
│   └── utils/
│       └── VisualEffects.gd    # Effetti visivi e animazioni
└── assets/
    └── generated/              # Asset generati con AI
        ├── router_node_frame_0.png
        ├── network_packet_frame_0.png
        ├── packet_glow.png (animation)
        └── error_flash.png (animation)
```

## 📊 Valori del BST Utilizzati

```
        50 (radice)
       /  \
      30   70
     / \   / \
    20 40 60 80
```

**Inorder**: 20, 30, 40, 50, 60, 70, 80
**Preorder**: 50, 30, 20, 40, 70, 60, 80
**Postorder**: 20, 40, 30, 60, 80, 70, 50
**BFS**: 50, 30, 70, 20, 40, 60, 80

## 🎯 Obiettivi di Apprendimento

✅ Comprendere la struttura di un Binary Search Tree
✅ Imparare le regole di inserimento (minori a sinistra, maggiori a destra)
✅ Praticare la ricerca in un BST
✅ Visualizzare le visite dell'albero (preorder, inorder, postorder, BFS)
✅ Applicare i concetti in scenari pratici (instradamento, ricerca, scansione)

## 🚀 Come Giocare

1. Avvia il gioco
2. Leggi l'introduzione e premi **"Avanti"**
3. **Fase 1**: Trascina i 6 router nelle posizioni corrette
4. **Fase 2**: Instrada 5 pacchetti scegliendo le direzioni giuste
5. **Fase 3**: Clicca i router negli ordini di visita corretti
6. **Fase 4**: Completa le sfide casuali in 45 secondi
7. Se completi tutte le fasi in tempo, **HAI VINTO!**

## ⚠️ Game Over

Se il timer raggiunge zero:
- Schermare "Tempo Scaduto!"
- Opzioni: Ricomincia il livello o Torna al Menu

## 📝 Note di Sviluppo

### Commit History
- ✅ Struttura di base e GameManager
- ✅ Schermata Introduzione
- ✅ Fase 1 - Drag & Drop
- ✅ Fase 2 - Packet Routing
- ✅ Fase 3 - Tree Traversals
- ✅ Fase 4 - Final Attack
- ✅ Visual Effects e Animazioni

### Sviluppi Futuri
- [ ] Menu principale
- [ ] Leaderboard
- [ ] Più livelli (Sorting, Graphs, Dynamic Programming)
- [ ] Audio e SFX
- [ ] Spiegazioni in-game per concetti avanzati
- [ ] Difficoltà progressive
- [ ] Multiplayer competitivo (con upgrade Ziva)

## 👨‍💻 Autore

Sviluppato come progetto educativo su Godot Engine

## 📄 Licenza

Educational Project - Godot Engine

---

**Buon divertimento imparando i Binary Search Tree!** 🎮💻
