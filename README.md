# DonVie — Structure de Santé (Admin)

Application Flutter (Mobile + Web) destinée à l'administrateur unique d'une
structure de santé (hôpital, CSI, structure médico-légale) sur la
plateforme DonVie de mise en relation avec des donneurs de sang.

## Structure du projet

```
/lib
  /core
    /constants        constantes partagées (groupes sanguins, types de
                       structure, breakpoints, enums Urgence/Statuts)
    /providers         providers Riverpod transverses (structure courante)
    /router             configuration go_router (StatefulShellRoute)
    /theme              ThemeData centralisé (couleurs, typographie, radius)
    /widgets           widgets réutilisables : BloodTypeBadge, UrgencyBadge,
                       StatusDot, SkeletonLoader/SkeletonList,
                       EmptyStateView, AppShell (nav mobile/web), boutons,
                       champs de formulaire, stepper
  /features
    /auth               connexion admin (Firebase Auth email/mot de passe)
    /onboarding         assistant de configuration initiale (3 étapes)
    /dashboard          tableau de bord (stats, tension stock, activité)
    /donors             liste / détail / formulaire donneur
    /stock              banque de sang (jauges, mouvements, seuils)
    /requests           création de demande (wizard 4 étapes), suivi temps
                       réel, historique
    /settings           profil structure, compte admin, notifications
  main.dart             bootstrap Firebase + ProviderScope + MaterialApp.router
  firebase_options.dart généré par `flutterfire configure`
```

Chaque feature suit le même découpage `data/` (modèles + repository
Firestore/Storage) → `application/` (providers Riverpod + controllers) →
`presentation/` (écrans + widgets locaux).

## Modèle de données Firestore

| Collection | Champs clés | Notes |
|---|---|---|
| `structures/{uid}` | `nom`, `type`, `adresse`, `localisation` (GeoPoint), `documents[]`, `groupesSanguins[]`, `configurationTerminee`, `notifStockBas`, `notifResumeActivite` | Un document par admin — l'UID Firebase Auth sert directement d'identifiant de structure. |
| `donneurs/{id}` | `structureId`, `nom`, `prenom`, `age`, `telephone`, `groupeSanguin`, `identifiantDon`, `localisation`, `actif` | `identifiantDon` généré côté client (voir limitation ci-dessous). |
| `stock/{structureId}_{groupeSanguin}` | `structureId`, `groupeSanguin`, `quantite`, `seuilAlerte`, `objectif` | Une entrée par groupe sanguin et par structure. |
| `historique_dons/{id}` | `structureId`, `groupeSanguin`, `type` (`entree`/`sortie`), `quantite`, `motif`, `donneurId?`, `date` | Journal des mouvements de stock ; sert aussi d'historique des dons d'un donneur donné quand `donneurId` est renseigné. |
| `demandes/{id}` | `structureId`, `groupesSanguins[]`, `niveauUrgence`, `rayonKm`, `statut`, `nombreDonneursEstime`, `localisation`, `createdAt`, `closedAt` | |
| `reponses/{id}` | `demandeId`, `structureId`, `donneurId`, `donneurNom/Telephone/GroupeSanguin` (dénormalisés), `distanceKm`, `statut`, `notifiedAt`, `respondedAt` | Une entrée par donneur notifié pour une demande. |

### Index composites Firestore requis

Le mode développement Firestore proposera automatiquement la création de
ces index au premier lancement des requêtes concernées (lien dans l'erreur
console) ; à défaut, créez-les manuellement :

- `donneurs` : `structureId` (==) + `createdAt` (desc)
- `donneurs` : `structureId` (==) + `actif` (==) + `groupeSanguin` (in)
- `stock` : `structureId` (==)
- `historique_dons` : `structureId` (==) + `date` (desc)
- `historique_dons` : `structureId` (==) + `groupeSanguin` (==) + `date` (desc)
- `historique_dons` : `donneurId` (==) + `date` (desc)
- `demandes` : `structureId` (==) + `statut` (==) + `createdAt` (desc)
- `demandes` : `structureId` (==) + `createdAt` (desc)
- `reponses` : `demandeId` (==)
- `reponses` : `structureId` (==) + `statut` (in) + `respondedAt` (desc)

## Limitations connues / hors périmètre de ce dépôt

- **Cloud Functions** (génération d'ID donneur, diffusion des notifications
  push, déclenchement de l'appel Twilio pour les demandes Critiques) ne
  sont **pas incluses** dans ce dépôt Flutter : c'est un backend Node.js
  séparé (dossier `functions/` d'un projet Firebase), hors du périmètre
  `lib/`. Le client génère aujourd'hui l'identifiant donneur directement
  (avec vérification d'unicité par relecture Firestore) et écrit les
  documents `reponses` ; il reviendra à une Cloud Function déclenchée sur
  la création de ces documents d'effectuer l'envoi FCM réel et l'appel
  Twilio.
- **Firebase Cloud Messaging** : aucune intégration client (réception de
  notifications) n'est nécessaire côté admin — seule l'app donneur
  (hors périmètre) les reçoit.
- Le calcul de distance/rayon est effectué **côté client** (formule
  haversine via `geolocator`) après une requête Firestore filtrée par
  groupe sanguin. Convient pour le volume d'une structure ; à revoir
  (geohashing + Cloud Function) si le nombre de donneurs par structure
  devient très important.

## Configuration Firebase

1. Créez un projet Firebase et activez : Authentication (e-mail/mot de
   passe), Cloud Firestore, Cloud Storage.
2. Installez la CLI FlutterFire puis lancez, à la racine du projet :
   ```
   flutterfire configure
   ```
   Cela régénère `lib/firebase_options.dart` et place automatiquement :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - la config Web dans `firebase_options.dart` (utilisée par `main.dart`,
     aucun fichier séparé nécessaire pour Flutter Web).
3. Créez le premier compte administrateur dans Firebase Auth (email/mot
   de passe) — l'app n'a pas d'écran d'inscription, l'admin est
   provisionné manuellement.
4. Renseignez une clé Google Maps Platform (Maps SDK Android/iOS/JS +
   Geocoding API) dans :
   - `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
   - `ios/Runner/AppDelegate.swift`
   - `web/index.html` (script `maps.googleapis.com`)

## Commandes de lancement

```bash
flutter pub get

# Mobile (Android connecté ou émulateur)
flutter run

# Web
flutter run -d chrome

# Vérification statique
flutter analyze

# Tests
flutter test
```
