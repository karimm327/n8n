# Projet n8n

## Prérequis
- Docker
- Docker Compose

## Installation

### 1. Cloner le projet
```bash
git clone https://github.com/karimm327/n8n.git
cd n8n
```

### 2. Configurer les variables d'environnement
```bash
cp .env.example .env
nano .env  # remplis les vraies valeurs
```

### 3. Lancer le projet
```bash
docker-compose up -d
```

### 4. Accéder à n8n
- n8n : http://localhost:5678
- Login avec N8N_BASIC_AUTH_USER et N8N_BASIC_AUTH_PASSWORD

### 5. Importer les workflows
- Aller dans n8n → Settings → Import workflow
- Importer les fichiers JSON du dossier `workflows/`

## Stack
- n8n
- PostgreSQL 15
- Nginx
