# 🎯 RobloxESP Framework

> Framework ESP modulaire pour Roblox — Visualisation 2D/3D overlay complète, basé sur Linoria UI

![Lua](https://img.shields.io/badge/Lua-5.1-blue?logo=lua)
![Roblox](https://img.shields.io/badge/Roblox-Executor-red)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📁 Arborescence

```
RobloxESP/
├── Main.lua                  ← Point d'entrée + UI Linoria complète
├── linoria.lua               ← Librairie UI Linoria (copie locale)
├── Addons/
│   ├── SaveManager.lua       ← Gestion des profils de configuration
│   └── InterfaceManager.lua  ← Gestion des thèmes UI
├── Modules/
│   ├── Config.lua            ← Valeurs par défaut, save/load JSON
│   ├── Utils.lua             ← WorldToViewport, lerp, visibilité, logs
│   ├── ESP.lua               ← Orchestrateur principal
│   ├── Box.lua               ← Bounding Box 2D
│   ├── Skeleton.lua          ← Squelette R6 / R15
│   ├── Tracers.lua           ← Lignes de traçage
│   ├── Health.lua            ← Barre de santé dynamique
│   ├── Name.lua              ← Tag de nom
│   ├── Distance.lua          ← Tag de distance
│   └── PlayerList.lua        ← Liste overlay des joueurs
└── README.md
```

---

## ✨ Fonctionnalités

| Feature | Description |
|---------|-------------|
| **Box 2D** | Bounding box autour de chaque joueur, fill optionnel |
| **Skeleton** | Squelette R6 et R15 avec outline |
| **Tracers** | Ligne depuis bas/centre/haut de l'écran |
| **Health Bar** | Barre verte→rouge, positions Left/Right/Top/Bottom |
| **Name Tag** | Nom du joueur avec outline et offset |
| **Distance Tag** | Distance en studs, format configurable |
| **Player List** | Liste overlay temps réel avec focus & toggle |
| **Preview Mode** | Dummy de test sans autres joueurs |
| **Performance Mode** | Réduit les calculs lourds |
| **Profiler** | Temps d'exécution par module (ms) |
| **Debug Logs** | Buffer de logs avec affichage console |
| **Config JSON** | Sauvegarde/chargement automatique |

---

## 🚀 Installation

### 1. Fork / Clone ce repo

```bash
git clone https://github.com/TON_USERNAME/roblox-esp.git
```

### 2. Editer `Main.lua`

Remplace la ligne :
```lua
local REPO_URL = "https://raw.githubusercontent.com/TON_USERNAME/TON_REPO/main/"
```
Par ton URL GitHub RAW, par exemple :
```lua
local REPO_URL = "https://raw.githubusercontent.com/monpseudo/roblox-esp/main/"
```

### 3. Uploader les fichiers sur GitHub

Assure-toi que ton repository est **public** et contient :
- `linoria.lua` à la racine
- `Modules/` avec tous les modules
- `Addons/SaveManager.lua` et `Addons/InterfaceManager.lua`

### 4. Exécuter dans Roblox

Dans ton executor (Synapse X, Krnl, etc.) :

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TON_USERNAME/roblox-esp/main/Main.lua", true))()
```

---

## 🎮 Utilisation

| Touche | Action |
|--------|--------|
| `RightCtrl` | Ouvrir/fermer l'UI |
| Configurable via UI | Keybind custom |

### Onglets de l'UI

- **Visuals** — Box, Skeleton, Tracers avec couleurs et épaisseurs
- **ESP** — Master toggle, TeamCheck, VisibilityCheck, Health/Name/Distance
- **Player List** — Liste overlay, focus joueur, toggle ESP par joueur
- **Settings** — Sauvegarde config, debug, profiler, thème UI

---

## ⚙️ Configuration par défaut

```lua
Config.Defaults = {
    Enabled         = false,
    TeamCheck       = true,
    VisibilityCheck = true,
    PerformanceMode = false,
    DebugMode       = false,

    Box = {
        Enabled   = true,
        Color     = { R=255, G=255, B=255 },
        Thickness = 1,
        Filled    = false,
    },

    Skeleton = {
        Enabled   = true,
        Color     = { R=255, G=255, B=255 },
        Thickness = 1,
    },

    Tracers = {
        Enabled   = true,
        Position  = "Bottom",  -- "Bottom" | "Center" | "Top"
        Color     = { R=255, G=255, B=255 },
        Thickness = 1,
    },

    Health = {
        Enabled   = true,
        Position  = "Left",   -- "Left" | "Right" | "Top" | "Bottom"
        Width     = 3,
        ShowText  = false,
    },

    Name = {
        Enabled   = true,
        Color     = { R=255, G=255, B=255 },
        Size      = 13,
        OffsetY   = 5,
        Outline   = true,
    },

    Distance = {
        Enabled  = true,
        Color    = { R=200, G=200, B=200 },
        Size     = 11,
        Format   = "{dist}m",
        MaxDist  = 1000,
    },
}
```

---

## 🏗️ Architecture modulaire

Chaque module est **autonome** et suit ce pattern :

```lua
-- Module retourne une table
local Module = {}
Module.__index = Module

-- Injection des dépendances
function Module.SetDependencies(utils, config) ... end

-- Constructeur
function Module.Create(player) ... end

-- Mise à jour frame
function Module:Update(character, cfg) ... end

-- Cacher sans supprimer
function Module:Hide() ... end

-- Destruction
function Module:Remove() ... end

return Module
```

---

## 🔌 Ajouter un module custom

1. Crée `Modules/MonModule.lua` avec le pattern ci-dessus
2. Dans `Main.lua`, ajoute :
   ```lua
   local MonModule = include("Modules/MonModule.lua")
   ```
3. Injecte-le dans `ESP.Init(deps)` ou utilise-le indépendamment

---

## 📊 Profiling

Le profiler mesure le temps d'exécution de chaque module par frame :

```
Box: 0.012ms | Skel: 0.034ms | Tracer: 0.008ms
Health: 0.015ms | Name: 0.006ms | Dist: 0.005ms
```

Accès dans Settings → "⏱ Afficher profiling"

---

## 📝 Logs

```lua
-- Depuis n'importe quel module
Utils.Log("message", "INFO")   -- niveaux: INFO | WARN | ERROR
Utils.GetLogs()                -- retourne le buffer
Utils.ClearLogs()              -- vide le buffer
```

---

## 🎨 Thèmes UI (Linoria)

Les thèmes sont gérés par `InterfaceManager` (addon Linoria standard).
Accès dans Settings → "Thème UI".

---

## ⚠️ Disclaimer

Ce projet est fourni à des fins **éducatives** uniquement.
L'utilisation dans des jeux en ligne peut violer les CGU de Roblox.
L'auteur décline toute responsabilité.

---

## 📄 License

MIT — Libre d'utilisation avec attribution.
