# Démineur 3D - Godot 4

Un jeu de démineur en 3D avec une ambiance désertique, jouable à la première personne dans Godot Engine.

## 📋 Description

Ce projet est une réinterprétation immersive du classique Démineur, où le joueur explore une grille de cases posées sur une pyramide au milieu d'un désert de dunes. Le jeu propose plusieurs niveaux de difficulté et une physique de mouvement inspirée des FPS modernes.

## ✨ Fonctionnalités

- **Jeu en 3D à la première personne** avec mouvements fluides (air-strafe, bunny hop)
- **4 niveaux de difficulté** : Facile (10×10), Moyen (18×18), Difficile (24×24), Extrême (50×50)
- **Génération procédurale** du terrain désertique avec dunes réalistes
- **Pyramide géante** servant de plateau de jeu
- **Effets visuels** : explosions avec particules, drapeaux animés
- **Système de couleurs classique** du démineur pour les chiffres
- **Ambiance** : musique d'ambiance, environnement avec brouillard et éclairage dynamique

## 🎮 Commandes

- **Z/Q/S/D** : Déplacements (ZQSD)
- **Espace** : Sauter
- **Souris** : Regarder autour
- **Clic gauche** : Révéler une case
- **Clic droit** : Placer/retirer un drapeau
- **Échap** : Quitter le jeu

## 🏗️ Structure du projet

```
├── background/          # Terrain désertique procédural
│   ├── background.gd
│   └── background.tscn
├── cell/               # Cases du démineur
│   ├── cell.gd
│   ├── cell.tscn
│   └── flag.tscn       # Drapeau animé avec shader
├── fx/                 # Effets visuels
│   └── explosion.tscn
├── main/               # Scène principale et logique de jeu
│   ├── checkerboard.gd
│   ├── minesweeper.tscn
│   └── proceduralGeneration.gd
├── main_menu/          # Menu principal
│   ├── main_menu.gd
│   └── main_menu.tscn
├── player/             # Contrôleur FPS
│   ├── player.gd
│   └── player.tscn
└── pyramid/            # Pyramide géante (base du jeu)
    ├── pyramid.gd
    └── pyramide.png
```

## 🔧 Architecture technique

### Génération du terrain (`background.gd`)
- Utilise **FastNoiseLite** avec deux couches de bruit (Simplex + Perlin)
- Vertex colors pour créer des variations de couleur sable
- Génération de collision avec `ConcavePolygonShape3D`

### Système de cellules (`cell.gd`)
- 3 états : cachée, révélée, drapeau
- Couleurs dynamiques selon le motif damier
- Intégration du système de flood-fill pour révéler les zones vides

### Génération du démineur (`proceduralGeneration.gd`)
- Algorithme de génération garantissant un premier clic sûr
- Zone de sécurité étendue autour du premier clic
- Mode classique (rapide) et mode solvable (contraintes strictes)
- Vérification de solvabilité avec logique de déduction

### Pyramide (`pyramid.gd`)
- Génération procédurale avec base large et sommet plat
- Texture triplanaire pour un mapping propre sur les pentes
- Collisions séparées (plateau + faces inclinées)

### Contrôleur joueur (`player.gd`)
- Physique de mouvement type Quake/Source Engine
- Air-strafe pour contrôle aérien précis
- RayCast pour interaction avec les cases

## 🎨 Particularités visuelles

- **Palette désertique** : dégradés de sable (doré clair, orange brûlé, terre cuite)
- **Shader de drapeau** : animation ondulante avec vertex displacement
- **Explosions** : système de particules triple (feu, débris, fumée)
- **Environnement** : ciel procédural, brouillard atmosphérique

## 🚀 Installation

1. Cloner le repository
2. Ouvrir le projet avec **Godot 4.x**
3. Lancer la scène `main_menu/main_menu.tscn`

## ⚙️ Configuration

Les paramètres de difficulté sont modifiables dans `main_menu/main_menu.gd` :

```gdscript
var difficulties: Dictionary = {
    0: {"rows": 10, "cols": 10, "mines": 10},    # Facile
    1: {"rows": 18, "cols": 18, "mines": 40},    # Moyen
    2: {"rows": 24, "cols": 24, "mines": 99},    # Difficile
    3: {"rows": 50, "cols": 50, "mines": 900}    # Extrême
}
```

## 📝 Notes techniques

- Le jeu utilise des **vertex colors** plutôt que des textures pour optimiser les performances
- La génération de grilles extrêmes (50×50) utilise un système de chargement progressif pour éviter les freezes
- Les collisions sont séparées en 2 layers (joueur + pyramide) pour optimiser les calculs physiques

## 🎵 Assets

- Musique d'ambiance : `song.mp3`
- Texture pyramide : `pyramid/pyramide.png`

## 📄 Licence

Projet éducatif - Libre d'utilisation et de modification

---

**Moteur** : Godot 4.5
**Langage** : GDScript  
**Genre** : Puzzle / FPS