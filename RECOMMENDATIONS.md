# Rapport d'Audit & Recommandations - Projet Gam-Jam

Ce document analyse la structure et le code du projet Godot `gam-jam` et propose des améliorations basées sur les bonnes pratiques officielles de Godot.

## 1. Organisation du Projet

### 📂 Structure des dossiers
- **Problème :** Présence des dossiers `exportV1` et `exportV2` à la racine du projet.
- **Recommandation :** Les builds (exécutables exportés) ne devraient pas être dans le dossier source du projet pour éviter de les importer comme ressources dans Godot et d'alourdir le repo Git.
- **Action :** 
  - Créez un dossier `builds/` à l'extérieur du dossier du projet (ou ignorez-le dans `.gitignore`).
  - Ajoutez `exportV*/` à votre fichier `.gitignore`.

### 📂 Gestion des Scripts
- **Observation :** Mélange entre l'approche "Script dossier" (`scripts/GameManager.gd`) et "Script co-localisé" (`scenes/fire_player/fire_player.gd`).
- **Bonne pratique :** Godot privilégie la **co-localisation**. Le script d'un nœud doit être à côté de sa scène (`.tscn`).
- **Action :** Continuez de placer les scripts spécifiques aux scènes (comme `fire_player.gd`) avec leurs fichiers `.tscn`. `GameManager.gd` est correct dans `scripts/` car c'est un Autoload global.

## 2. Architecture & Code (GDScript)

### 🔊 Gestion de l'Audio
- **Problème identifié :** Dans `main_menu.gd`, le nœud `MenuMusic` est déplacé (`reparent`) manuellement vers `root` pour persister entre les scènes. C'est une méthode fragile ("hacky") qui peut causer des erreurs si la hiérarchie change.
- **Recommandation :** Utilisez un **Autoload (Singleton)** dédié à l'audio (ex: `AudioManager`).
- **Action :** 
  - Créez une scène `AudioManager.tscn` avec vos `AudioStreamPlayers` pour la musique et les SFX globaux.
  - Ajoutez-la dans *Project Settings -> Globals (Autoload)*.
  - Appelez simplement `AudioManager.play_music("menu")` depuis n'importe où.

### 🔗 Couplage (Signals vs Get Node)
- **Point fort :** `main_layout_intro.gd` utilise correctement les signaux pour communiquer avec le `GameManager`. C'est excellent pour le découplage.
- **Point faible :** Dans `main_menu.gd`, l'utilisation de `$"../MenuMusic"` (chemins relatifs hardcodés) est risquée. Si vous changez la structure de la scène UI, le script cassera.
- **Recommandation :** Utilisez l'annotation `@export` pour référencer les nœuds, ou "Signal Up, Call Down" (Signaler vers le haut, Appeler vers le bas).

### 🛡️ Typage Statique
- **Observation :** Le typage est partiellement utilisé (`: float`, `: String`), mais pas partout (ex: variables non typées dans certaines fonctions).
- **Recommandation :** Utilisez le typage statique strict autant que possible pour gagner en performance et éviter les bugs.
- **Exemple :**
  ```gdscript
  # Au lieu de :
  var score = 0
  # Préférez :
  var score: int = 0
  # Ou l'inférence :
  var score := 0
  ```

### 🎮 Gestion des Inputs
- **Observation :** `fire_player.gd` utilise des exports de type String pour les actions (`p1_left`, etc.). C'est une bonne pratique pour permettre le remapping des touches !
- **Amélioration :** Assurez-vous d'utiliser `_unhandled_input(event)` pour les menus/UI afin que l'interface puisse consommer l'input avant le jeu (pause, etc.). Pour le joueur, `_physics_process` avec `Input.get_axis()` est la bonne approche pour les mouvements fluides.

## 3. Paramètres & Performance

### ⚙️ Engine
- **Mode de fenêtre :** Dans `project.godot`, `window/stretch/mode="canvas_items"` est activé. C'est parfait pour le Pixel Art. Assurez-vous que le **Filter** des textures est bien sur "Nearest" (dans les paramètres d'import par défaut) pour éviter le flou sur les sprites.

### 🔄 Delta Time
- **Vérification :** Assurez-vous que TOUS les mouvements dans `_process` ou `_physics_process` sont multipliés par `delta`.
- **Exemple :** `position.x += speed * delta`.
- Si vous utilisez `move_and_slide()` avec `CharacterBody2D`, `delta` est géré automatiquement pour la vélocité, mais pas pour l'accélération manuelle.

## 4. Résumé des Actions Prioritaires

1.  **Nettoyage :** Sortir les dossiers `export` de la racine.
2.  **Audio :** Remplacer la logique de déplacement de nœud `MenuMusic` par un Singleton `AudioManager`.
3.  **Typage :** Ajouter `:=` ou `: Type` sur toutes les variables et arguments de fonctions.
4.  **UI :** Uniformiser la navigation des menus (comme fait avec `commandes.gd` et `credits.gd`) pour éviter la duplication de code.

Ce projet a de bonnes bases (structure par feature, utilisation de `CharacterBody2D`), l'application de ces conseils le rendra plus robuste et facile à maintenir.
