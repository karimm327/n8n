# Documentation — Workflow Veille Cyber n8n

## Vue d'ensemble

Ce workflow automatise une **veille en cybersécurité** ciblée sur les infrastructures critiques françaises (eau, déchets, énergie, OT/SCADA). Il collecte des articles RSS, les filtre, les analyse via IA, les stocke en base de données et envoie des alertes par email.

---

## Architecture du workflow

```
Flux RSS → Nettoyage XML → Extraction articles → Déduplication/Filtrage
    → Insertion SQL brute → Analyse IA (Gemini) → Parsing réponse IA
        → Condition criticité → Upsert SQL enrichi → Envoi email (Brevo)
```

---

## Description des noeuds

### 1. Code in JavaScript — Initialisation
**Rôle :** Déclare en mémoire la liste des flux RSS à surveiller.

Sources configurées :
- 01net — `https://www.01net.com/rss/actualites/`
- Industrial Cyber — `https://industrialcyber.co/feed/`
- CERT-FR — `https://www.cert.ssi.gouv.fr/feed/`
- Security Affairs — `https://securityaffairs.com/feed`
- The Record — `https://therecord.media/feed`

---

### 2. Loop Over Items — Boucle RSS
**Rôle :** Parcourt les flux RSS par batch de 5 pour éviter la surcharge.

---

### 3. HTTP Request — Fetch RSS
**Rôle :** Effectue un GET HTTP sur chaque URL de flux RSS pour récupérer le contenu XML brut.

---

### 4. Code in JavaScript1 — Nettoyage XML
**Rôle :** Nettoie le XML brut en remplaçant les `&` par `&amp;` pour éviter les erreurs de parsing.

---

### 5. XML — Conversion XML → JSON
**Rôle :** Convertit le flux XML nettoyé en objet JSON exploitable par les noeuds suivants.

---

### 6. Code in JavaScript2 — Collecte et normalisation des articles
**Rôle :** Extrait les articles du flux JSON, gère les variantes de balises RSS (`item`, `entry`, `article`...) et génère un **hash unique** par titre pour la déduplication.

Champs extraits : `hash`, `titre`, `lien`, `date`, `auteur`, `description`, `categories`

---

### 7. Execute a SQL query — Récupération des hashs existants
**Rôle :** Interroge la table `articles` en PostgreSQL pour récupérer tous les hashs déjà présents.

```sql
SELECT hash FROM articles
```

---

### 8. Code in JavaScript3 — Pré-filtrage et déduplication
**Rôle :** Double filtrage des articles :
1. **Déduplication** — supprime les articles déjà en base via le hash
2. **Filtrage par mots-clés** — ne garde que les articles contenant à la fois :
   - Un mot-clé **cyber** (ex: attack, breach, ransomware, malware, exploit...)
   - Un mot-clé **secteur/techno cible** (ex: water, scada, azure, schneider, crowdstrike...)

---

### 9. Insert rows in a table — Insertion SQL brute
**Rôle :** Insère les articles filtrés en base de données avec les données brutes (avant analyse IA).

---

### 10. Edit Fields — Normalisation des champs
**Rôle :** Nettoie les champs texte (suppression des caractères spéciaux, retours à la ligne) pour préparer l'envoi à l'IA.

---

### 11. HTTP Request2 — Analyse IA (Eden AI / Gemini 2.5 Flash)
**Rôle :** Envoie la description de l'article à **Google Gemini 2.5 Flash** via l'API Eden AI avec un prompt d'analyse cybersécurité.

Le prompt demande à l'IA de retourner un JSON structuré contenant :
- `titre`, `resume`, `criticite` (0-10), `niveau`
- `secteur_cible`, `technologies_concernees`
- `attaquants`, `victimes`, `techniques_cyber`, `outils_utilises`
- `impact_potentiel_ou_reel`, `recommandation`

---

### 12. Code in JavaScript8 — Parsing réponse IA
**Rôle :** Extrait et parse le JSON retourné par l'IA. Gère les erreurs de format avec un fallback propre. Fusionne les données IA avec les métadonnées source.

---

### 13. If — Condition criticité
**Rôle :** Filtre les articles selon deux critères :
- `criticite > 5`
- `titre != "Hors-sujet"`

Seuls les articles pertinents et critiques passent à l'étape suivante.

---

### 14. Insert or update rows in a table — Upsert SQL enrichi
**Rôle :** Met à jour ou insère l'article enrichi par l'IA dans la table `articles` (upsert sur le hash).

---

### 15. Code in JavaScript4 — Génération et envoi email (Brevo)
**Rôle :** Génère un email HTML au design ANSSI (bleu #000091, rouge #E1000F) et l'envoie via l'API Brevo.

Fonctionnalités :
- Détection automatique de la langue (FR/EN)
- Niveaux de criticité colorés (Faible → Critique)
- Barre de progression de criticité
- Tags MITRE ATT&CK, outils, technologies
- Récupération de l'image og:image de l'article source
- Gestion des erreurs d'envoi sans bloquer la boucle

---

## Base de données PostgreSQL

### Table `articles`

| Colonne | Type | Description |
|---|---|---|
| `hash` | string | Identifiant unique basé sur le titre |
| `titre` | string | Titre original |
| `lien` | string | URL de l'article |
| `date` | string | Date de publication |
| `auteur` | string | Auteur |
| `description` | string | Description brute |
| `categories` | string | Catégories RSS |
| `resume` | string | Résumé généré par l'IA |
| `criticite` | number | Score 0-10 |
| `niveau` | string | Faible / Moyen / Élevé / Critique |
| `attaquants` | string | Acteurs de la menace |
| `victimes` | string | Cibles identifiées |
| `techniques` | array | Techniques MITRE ATT&CK |
| `outils_utilises` | array | Malwares / outils |
| `technologies_concernees` | array | Technologies exposées |
| `impact` | string | Impact technique et opérationnel |
| `recommandation_suez` | string | Recommandation adaptée |
| `secteur_cible` | string | Secteur visé |

---

## Variables d'environnement requises

| Variable | Description |
|---|---|
| `BREVO_API_KEY` | Clé API Brevo pour l'envoi des emails |
| `POSTGRES_USER` | Utilisateur PostgreSQL |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL |
| `POSTGRES_DB` | Nom de la base de données |
| `N8N_BASIC_AUTH_USER` | Login interface n8n |
| `N8N_BASIC_AUTH_PASSWORD` | Mot de passe interface n8n |

> ⚠️ Ne jamais commiter le fichier `.env`. Utiliser `.env.example` comme modèle.

---

## Credentials n8n à configurer

Après import du workflow, configurer dans n8n → Credentials :
- **Postgres account** — connexion à la base PostgreSQL
- **Eden AI** — token Bearer pour l'API Gemini (HTTP Request2)
- **Brevo** — clé API (dans le code JavaScript4 via `$env.BREVO_API_KEY`)

