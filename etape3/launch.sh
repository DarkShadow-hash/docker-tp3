#!/bin/bash
# ============================================================
# Étape 3 : Lancement avec Docker Compose
# ------------------------------------------------------------
# Objectif du script :
#   1) Me placer dans le bon dossier (etape3) pour éviter les
#      erreurs de chemins relatifs dans docker-compose.yml
#   2) Choisir automatiquement la bonne commande "compose"
#      (docker compose v2 ou docker-compose v1, selon les PC)
#   3) Arrêter proprement ce qui tourne déjà (down), avec une
#      option --reset si je veux repartir d'une base vide
#      (down -v = supprime aussi les volumes => ré-exécution
#      de create.sql au prochain démarrage).
#   4) Re-construire l'image PHP si besoin (option --rebuild)
#      pour être sûre que l’extension mysqli est bien compilée.
#   5) Démarrer l’ensemble (up -d), afficher l’état (ps) et
#      rappeler les URLs de test (phpinfo + test.php).
#
# Pourquoi écrire ce script :
#   - J’ai tout en une seule commande au lieu de me souvenir
#     de 4–5 commandes docker compose.
#   - Je peux reproduire la même procédure sur un autre PC
#     (Windows Git Bash, macOS, Linux) sans réfléchir à nouveau.

# IMPORTANT : La page affichant PHP affichera une erreur au début 
# mais après quelques secondes et quelques refresh, elle marchera 
# correctement. Cela est du au fait que PHP démarre avant que MariaDB soit prêt.
# ============================================================

set -e  # Si une commande échoue, le script s’arrête (évite les demi-états bizarres)

# 1) Me placer dans le dossier du script (important car compose utilise des chemins relatifs)
#    "$(dirname "$0")" = répertoire où se trouve *ce* fichier
#    cd … = je me déplace dedans pour que ./src, ./config, ./php
#    dans docker-compose.yml pointent bien vers ce dossier.
cd "$(dirname "$0")"

# 2) Détecter la bonne commande "compose"
#    Sur les machines récentes c’est "docker compose".
#    Sur d’anciennes installations c’est "docker-compose".
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "[ERREUR] Docker Compose n'est pas installé ou pas dans le PATH."
  echo "         Installez Docker Desktop, puis réessayez."
  exit 1
fi

# 3) Aide rapide si on passe -h/--help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage : ./launch.sh [--reset] [--rebuild]"
  echo "  --reset   : arrêt + suppression volumes (réinitialise la BDD)"
  echo "  --rebuild : reconstruit l'image PHP sans cache (mysqli garanti)"
  exit 0
fi

# 4) Lire les options utilisateur
RESET=false    # si true => down -v (je veux réinitialiser la base)
REBUILD=false  # si true => build --no-cache (recompile PHP+mysqli)
[[ "${1:-}" == "--reset"   || "${2:-}" == "--reset"   ]] && RESET=true
[[ "${1:-}" == "--rebuild" || "${2:-}" == "--rebuild" ]] && REBUILD=true

# 5) Vérifs minimales avant de lancer quoi que ce soit
#    - docker-compose.yml doit exister (sinon compose ne sait pas quoi faire)
#    - .env doit exister (je stocke le mot de passe root de MariaDB ici)
if [[ ! -f "docker-compose.yml" ]]; then
  echo "[ERREUR] docker-compose.yml introuvable dans $(pwd)"
  echo "         Placez-vous dans le dossier etape3 (celui qui contient docker-compose.yml)."
  exit 1
fi

if [[ ! -f ".env" ]]; then
  echo "[ERREUR] Fichier .env introuvable."
  echo "         Créez-le avec par exemple :   echo 'MARIADB_ROOT_PASSWORD=root' > .env"
  exit 1
fi

# 6) Arrêt propre des services qui tournent déjà
#    --remove-orphans : au cas où des vieux services trainent (autres fichiers compose)
echo ">> Arrêt des services existants…"
if $RESET; then
  # down -v = supprime aussi les volumes => la base repart de zéro
  # Utile quand je veux être sûre que create.sql est rejoué.
  $COMPOSE down -v --remove-orphans
else
  $COMPOSE down --remove-orphans
fi

# 7) Construction des images
#    - Notre service "script" a un Dockerfile (php/Dockerfile) pour installer mysqli.
#    - --no-cache si je veux forcer une recompilation propre.
echo ">> Construction des images…"
if $REBUILD; then
  $COMPOSE build --no-cache
else
  $COMPOSE build
fi

# 8) Démarrage des services en arrière-plan
#    - data (MariaDB) va exécuter src/create.sql au premier démarrage
#    - script (PHP-FPM) a une commande 'sleep 15 && php-fpm' dans le compose
#      pour laisser quelques secondes à MariaDB avant que PHP s’y connecte.
#    - http (Nginx) expose le site sur http://localhost:8080
echo ">> Démarrage…"
$COMPOSE up -d

# 9) Afficher l’état (utile pour vérifier rapidement que tout est “Up”)
echo ">> État des containers :"
$COMPOSE ps

# 10) Rappels des URLs de test
#     - /  => index.php avec phpinfo() -> prouve que Nginx sert /app et parle à PHP-FPM
#     - /test.php => fait 1 INSERT + 1 SELECT -> prouve que PHP parle à MariaDB (mysqli OK)
echo
echo "Tests rapides :"
echo "  PHP info   : http://localhost:8080"
echo "  Test MySQL : http://localhost:8080/test.php"
echo
echo "Conseils d'usage :"
echo "  ./launch.sh --reset    # redémarre en supprimant la base (rejoue create.sql)"
echo "  $COMPOSE logs -f data  # suit l'initialisation MariaDB (pratique si lenteur)"
echo "  $COMPOSE logs -f http  # logs Nginx si page blanche"
echo "  $COMPOSE logs -f script# logs PHP-FPM si erreur PHP"
