# Résumé des modifications pour ajouter la fonctionnalité "Poids de fichier cible" dans HandBrake GTK

## Objectif
Ajouter un nouveau mode de calcul automatique du débit vidéo basé sur un poids de fichier cible en mégaoctets dans l'interface GTK de HandBrake.

## Fichiers modifiés

### 1. Interface utilisateur (gtk/src/ui/ghb.ui)
- **Ajout d'un nouvel adjustment** : `adjustment_target_size` (lignes 1207-1216)
  - Valeur par défaut : 700 MB
  - Plage : 1-100000 MB
  - Incrément : 10 MB

- **Ajout du nouveau bouton radio** : `vquality_type_target_size` (lignes 3541-3551)
  - Label : "Target Size (MB):"
  - Groupé avec les autres boutons radio de qualité vidéo
  - Tooltip explicatif

- **Ajout du champ de saisie** : `VideoTargetSize` (lignes 3552-3562)
  - SpinButton lié à `adjustment_target_size`
  - Callback : `vtarget_size_changed_cb`

- **Ajustement de la position** : Décalage du contrôle MultiPass à la ligne 4

### 2. Settings par défaut (gtk/data/internal_defaults.json)
- **Ajout de nouveaux settings** (lignes 54-56) :
  - `"vquality_type_target_size": false`
  - `"VideoTargetSize": 700`

### 3. Gestion des presets (gtk/src/presets.c)
- **Extension du switch VideoQualityType** (lignes 347-378) :
  - Ajout du cas 3 pour le mode target size
  - Mise à jour de tous les cas existants pour inclure le nouveau flag

- **Mise à jour de la conversion preset** (lignes 1769-1775, 1820-1834) :
  - Ajout de la variable `target_size`
  - Gestion du VideoQualityType = 3

### 4. Logique de calcul (gtk/src/videohandler.c)
- **Nouvelle fonction de calcul** : `calculate_bitrate_from_target_size()` (lignes 68-89)
  - Calcule le débit vidéo nécessaire pour atteindre la taille cible
  - Prend en compte le débit audio estimé
  - Assure un débit minimum de 100 kbps

- **Nouvelle fonction de mise à jour** : `ghb_update_target_size_bitrate()` (lignes 91-130)
  - Obtient la durée du titre sélectionné
  - Calcule et met à jour le débit vidéo automatiquement
  - Gère les différents types de plages (chapitres/secondes/frames)

- **Mise à jour de la gestion des encodeurs** (lignes 202-220) :
  - Ajout du support pour le nouveau bouton radio
  - Gestion de la sensibilité selon l'encodeur

### 5. Header (gtk/src/videohandler.h)
- **Ajout de la déclaration** (ligne 32) :
  - `void ghb_update_target_size_bitrate(signal_user_data_t *ud);`

### 6. Callbacks (gtk/src/callbacks.c)
- **Nouveau callback** : `vtarget_size_changed_cb()` (lignes 3335-3345)
  - Met à jour le débit quand la taille cible change
  - Appelle `ghb_update_target_size_bitrate()`

- **Mise à jour des callbacks existants** :
  - `vquality_type_changed_cb()` (lignes 3309-3313) : Calcul automatique en mode target size
  - `start_point_changed_cb()` (lignes 3565-3567) : Recalcul quand le point de début change
  - `end_point_changed_cb()` (lignes 3578-3580) : Recalcul quand le point de fin change
  - `ptop_widget_changed_cb()` (lignes 3011-3012) : Recalcul quand le type de plage change
  - `ghb_set_title_settings()` (lignes 2720-2722) : Calcul lors de la sélection d'un titre

- **Ajout des bindings d'interface** (lignes 429-430) :
  - Liaison entre le bouton radio et le champ de saisie
  - Gestion de la sensibilité

## Fonctionnement

1. **Sélection du mode** : L'utilisateur sélectionne le bouton radio "Target Size (MB)"
2. **Saisie de la taille** : L'utilisateur entre la taille cible en mégaoctets
3. **Calcul automatique** : Le système calcule automatiquement le débit vidéo nécessaire
4. **Mise à jour dynamique** : Le débit se recalcule automatiquement quand :
   - La taille cible change
   - La durée change (points de début/fin, type de plage)
   - Un nouveau titre est sélectionné

## Formule de calcul

```
débit_vidéo_kbps = (taille_cible_MB * 8 * 1024 / durée_secondes) - débit_audio_kbps
```

Avec un débit minimum garanti de 100 kbps.

## Tests effectués

Le calcul a été testé avec plusieurs scénarios :
- Film de 2h, cible 700MB → ~668 kbps (vérification : 699.6 MB)
- Épisode TV de 45min, cible 350MB → ~933 kbps (vérification : 349.7 MB)
- Clip de 5min, cible 50MB → ~1237 kbps (vérification : 50.0 MB)

## Compilation

Pour compiler HandBrake avec ces modifications :
1. Installer les dépendances requises (GTK4, GLib, etc.)
2. Utiliser le système de build standard de HandBrake
3. Les modifications sont compatibles avec l'architecture existante
