#!/bin/bash
# ==========================================================
# Étape 1 : HTTP (Nginx) + SCRIPT (PHP-FPM)
# Compatible Windows (Git Bash) / macOS / Linux
# ==========================================================

# ----------------------------------------------------------
# 1). Détermination du chemin absolu
# ----------------------------------------------------------
# Sur mon ordinateur le fichier launch.sh ne s'executait pas correctement
# au début car il ne trouvait pas le bon fichier default.config, d'où cette étape
# que j'ai jugé bien de rajouter
# Sous Windows, on convertit le chemin pour Docker (C:\Users\...).
# Sous macOS/Linux, $(pwd) suffit.
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  WORKDIR=$(pwd -W)     # Windows : conversion automatique
else
  WORKDIR=$(pwd)        # macOS/Linux : chemin normal
fi

echo "Répertoire de travail détecté : $WORKDIR"


# ----------------------------------------------------------
# 2). Nettoyage des anciens containers
# ----------------------------------------------------------
# Ces commandes arrêtent et suppriment les anciens containers pour
# éviter les conflits de nom ou de port. 2>/dev/null masque les erreurs
# si les containers n'existent pas encore.
docker stop http script 2>/dev/null
docker rm http script 2>/dev/null

# ----------------------------------------------------------
# 3). Création du réseau Docker
# ----------------------------------------------------------
# Le réseau "tp3-net" permet la communication entre Nginx et PHP-FPM.
# Si le réseau existe déjà, Docker ignore la commande sans erreur.
docker network create tp3-net 2>/dev/null

# ----------------------------------------------------------
# 4). Lancement du container PHP-FPM (SCRIPT)
# ----------------------------------------------------------
# Ce container exécute les scripts PHP (notamment index.php).
# Il écoute sur le port 9000 et fait partie du réseau tp3-net.
docker run -d --name script --network tp3-net -v "${WORKDIR}/src:/app" php:8.2-fpm

# ----------------------------------------------------------
# 5). Lancement du container Nginx (HTTP)
# ----------------------------------------------------------
# Ce container sert le site sur localhost:8080 et redirige les fichiers 
# PHP vers le container "script" via FastCGI.
docker run -d --name http --network tp3-net -p 8080:80 \
-v "${WORKDIR}/src:/app" \
-v "${WORKDIR}/config/default.conf:/etc/nginx/conf.d/default.conf" \
nginx:1.27

# ----------------------------------------------------------
# 6). Vérification
# ----------------------------------------------------------
# Affiche les containers actifs pour confirmer que tout tourne.
docker ps

echo "----------------------------------------------------------"
echo "Serveur disponible sur : http://localhost:8080"
echo "----------------------------------------------------------"
