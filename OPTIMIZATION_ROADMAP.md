# 🗺️ Feuille de Route d'Optimisation - Gam-Jam

Ce document présente un plan d'action progressif pour optimiser le projet, basé sur les **bonnes pratiques officielles de Godot 4**. L'objectif est d'améliorer la maintenabilité, la performance et la robustesse du code sans casser les fonctionnalités existantes.

## 📋 Résumé des Étapes

| Priorité | Domaine | Action | Bénéfice |
| :---: | :--- | :--- | :--- |
| 1️⃣ | **Audio** | Créer un Autoload `AudioManager` | Musique fluide entre scènes, code plus propre. |
| 2️⃣ | **Code** | Typage Statique (`: Type`) | Performances accrues, moins de bugs, meilleure autocomplétion. |
| 3️⃣ | **Architecture** | Utiliser les "Unique Names" (`%Node`) | Scènes modifiables sans casser les chemins de scripts. |
| 4️⃣ | **Input** | Différencier `_input` et `_unhandled_input` | Meilleure gestion UI vs Gameplay (ex: clic traversant). |
| 5️⃣ | **Assets** | Structurer le dossier `assets/` | Projet plus navigable et professionnel. |

---

## 🚀 Détails des Actions

### 1. Centralisation de l'Audio (AudioManager)
**État actuel :** La musique est déplacée manuellement (`reparent`) vers la racine (`root`) pour persister. Code complexe et fragile dans les `_ready()` des menus.
**Action :**
1.  Créer une scène `AudioManager.tscn` avec des nœuds `AudioStreamPlayer`.
2.  Ajouter un script `AudioManager.gd` pour gérer les fonctions `play_music(track_name)`, `fade_out()`, etc.
3.  Ajouter cette scène dans **Project Settings > Autoload**.
4.  Remplacer la logique dans `commandes.gd`, `credits.gd`, `main_menu.gd` par de simples appels : `AudioManager.play_music("menu")`.

### 2. Typage Statique (Static Typing)
**État actuel :** Certaines variables sont typées (`var speed: float`), d'autres non.
**Pourquoi changer ?** GDScript dans Godot 4 est beaucoup plus rapide quand il est typé.
**Action :**
- Passer en revue les scripts principaux (`fire_player.gd`, `GameManager.gd`, etc.).
- Ajouter le type explicite ou inféré (`:=`).
```gdscript
# Avant
var health = 100
func take_damage(amount): ...

# Après (Recommandé)
var health: int = 100
func take_damage(amount: int) -> void: ...
```

### 3. Noms Uniques de Scène (Scene Unique Nodes)
**État actuel :** Utilisation de chemins relatifs ou absolus comme `$AudioControl/HSliderVolume`.
**Risque :** Si on déplace `HSliderVolume` dans un autre conteneur UI, le script plante.
**Action :**
1.  Dans l'éditeur, clic-droit sur les nœuds importants -> **Access as Unique Name**.
2.  Dans le code, remplacer `$` par `%` :
```gdscript
# Avant
@onready var slider = $AudioControl/HSliderVolume

# Après
@onready var slider = %HSliderVolume
```

### 4. Gestion des Inputs (Unhandled Input)
**État actuel :** Utilisation probable de `_input` ou `Input.is_action_pressed` partout.
**Problème potentiel :** Si un menu est ouvert par-dessus le jeu, appuyer sur "Espace" (sauter) pourrait aussi valider un bouton du menu.
**Action :**
- Utiliser `_unhandled_input(event)` pour les actions de gameplay (déplacements, tirs) qui ne doivent pas se déclencher si l'UI a "mangé" l'événement.

### 5. Organisation des Assets
**État actuel :** Dossier `assets/` contenant des mélanges de fichiers.
**Action :**
- Déplacer les fichiers importés (`.import`) et sources dans des sous-dossiers clairs : `assets/sprites`, `assets/audio`, `assets/fonts`.
- *Note : Godot gère bien les déplacements si faits depuis l'éditeur.*

---

## 🛠️ Comment procéder ?
Cette feuille de route est conçue pour être suivie point par point. Je recommande de commencer par le point **1 (AudioManager)** car c'est celui qui simplifiera le plus le code actuel des menus que nous venons de modifier.
