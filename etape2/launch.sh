#!/bin/bash
# ==========================================================
# Étape 2 : HTTP + SCRIPT + DATA (MariaDB)
# Compatible Windows (Git Bash) / macOS / Linux
# ==========================================================

# ----------------------------------------------------------
# 1). Détermination du bon chemin de travail
# ----------------------------------------------------------
# Sous Windows, Git Bash nécessite la conversion du chemin pour Docker.
# Sous macOS/Linux, $(pwd) fonctionne directement.
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  WORKDIR=$(pwd -W)     # Format Windows (C:\Users\...)
else
  WORKDIR=$(pwd)        # Format Unix (/Users/...)
fi

echo "Répertoire détecté : $WORKDIR"
echo "----------------------------------------------------------"

# ----------------------------------------------------------
# 2). Nettoyage de l'environnement existant
# ----------------------------------------------------------
echo "Suppression d'anciens containers :"
docker stop http script data 2>/dev/null
docker rm http script data 2>/dev/null

# ----------------------------------------------------------
# 3). Création du réseau Docker
# ----------------------------------------------------------
echo "Vérification du réseau tp3-net"
docker network create tp3-net 2>/dev/null

# ----------------------------------------------------------
# 4). Construction de l'image PHP personnalisée avec mysqli
# ----------------------------------------------------------
echo "Construction de l'image PHP avec mysqli : "
docker build -t php:8.2-fpm-mysqli ./php

# ----------------------------------------------------------
# 5). Lancement du container DATA (MariaDB)
# ----------------------------------------------------------
echo "Lancement du container DATA (MariaDB) :"
docker run -d --name data --network tp3-net \
-e MARIADB_ROOT_PASSWORD=root \
-v "${WORKDIR}/src:/docker-entrypoint-initdb.d" \
mariadb:latest

# ----------------------------------------------------------
# 6). Lancement du container SCRIPT (PHP-FPM + mysqli)
# ----------------------------------------------------------
echo "Lancement du container SCRIPT (PHP-FPM + mysqli) :"
docker run -d --name script --network tp3-net \
-v "${WORKDIR}/src:/app" php:8.2-fpm-mysqli

# ----------------------------------------------------------
# 7). Lancement du container HTTP (Nginx)
# ----------------------------------------------------------
echo "Lancement du container HTTP (Nginx) :"
docker run -d --name http --network tp3-net -p 8080:80 \
-v "${WORKDIR}/src:/app" \
-v "${WORKDIR}/config/default.conf:/etc/nginx/conf.d/default.conf" \
nginx:1.27

# ----------------------------------------------------------
# 8). Vérification du déploiement
# ----------------------------------------------------------
echo "----------------------------------------------------------"
docker ps
echo "----------------------------------------------------------"
echo "Site PHP Info :   http://localhost:8080"
echo "Test MySQL :      http://localhost:8080/test.php"
echo "----------------------------------------------------------"
echo "Étape 2 initialisée avec succès."
