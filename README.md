# MLOps – TP Docker (Étapes 1 à 3)
## Ma démarche

J’ai avancé étape par étape, en testant à chaque fois dans le navigateur.
Objectif: séparer les rôles (HTTP, SCRIPT, DATA), comprendre les volumes, les réseaux Docker et finir avec Docker Compose.
Je garde les fichiers du professeur dans src/ et je monte ce dossier dans les containers pour éviter de reconstruire tout le temps.

## Arborescence

<img width="450" height="403" alt="image" src="https://github.com/user-attachments/assets/3a3ea9c4-1c27-420b-9f87-be40bddc32eb" />


## Étape 1 — Nginx + PHP-FPM (sans Compose)
But : avoir 2 containers qui se parlent.


HTTP : Nginx sur le port 8080.


SCRIPT : PHP-FPM qui exécute le PHP.


Les deux sont reliés par un réseau Docker (tp3-net).


Le code PHP (index.php avec phpinfo()) est monté en bind mount dans /app.


### Ce que j’ai compris :


Nginx ne “fait pas du PHP”. Il envoie les .php vers PHP-FPM via fastcgi_pass.


Les containers se voient par leur nom sur le réseau (ex: script:9000).


Le default.conf d’Nginx doit pointer sur root /app; et fastcgi_pass script:9000;.


### Test


http://localhost:8080 → page phpinfo().

<img width="1014" height="732" alt="image" src="https://github.com/user-attachments/assets/60de71b8-8119-4923-9d23-aaad5d98e574" />



## Étape 2 — + MariaDB et mysqli
But : ajouter un container DATA (MariaDB), et faire un CRUD minimal depuis test.php.


J’ai construit une image PHP perso avec l’extension mysqli (Dockerfile).


test.php fait un INSERT puis un SELECT et affiche un compteur.


### Ce que j’ai compris :


L’extension mysqli n’est pas toujours là. Il faut l’installer avec docker-php-ext-install.


Au tout premier run, la base peut être lente à démarrer. Si on tape trop vite l’URL, on peut avoir une erreur. Recharger après quelques secondes fonctionne.


### Tests


http://localhost:8080/ → phpinfo().


http://localhost:8080/test.php → “Count updated / Count : X” (X s’incrémente).

<img width="864" height="258" alt="image" src="https://github.com/user-attachments/assets/8300dc38-eb6f-4b6a-9779-d88cce746f22" />

Nous obtenons cette fois ci, en plus de la page affichant la version de php, un compteur qui s'incrémente à chaque fois que l'on rafraichit la page.




## Étape 3 — Conversion en Docker Compose
But : décrire les 3 services dans un seul fichier docker-compose.yml.


data (MariaDB), script (PHP-FPM + mysqli), http (Nginx).


Même réseau, mêmes volumes, même conf.


J’ai ajouté un petit sleep côté PHP pour laisser le temps à MariaDB de démarrer quand on n’utilise pas de healthcheck.


### Ce que j’ai compris :


Compose remplace plusieurs docker run par une description déclarative.


depends_on gère l’ordre de démarrage, mais pas “l’état prêt”.
Sans healthcheck, j’ai mis sleep 15 pour éviter l’erreur au premier chargement.


Les variables sensibles vont dans .env (je ne le publie pas). Je fournis .env.example.


### Tester :


http://localhost:8080/


http://localhost:8080/test.php


### Réinitialiser la base
./launch.sh --reset   # fait un down -v, rejoue create.sql au prochain up

Étapes 1 et 2 (sans Compose)


Aller dans etape1/ ou etape2/ et exécuter ./launch.sh.



## Points d’attention


Sous Windows, Git peut afficher des warnings de fins de lignes (CRLF/LF). Pas bloquant.


Si test.php affiche une erreur au tout premier chargement, attendre quelques secondes puis refresh.



## Outils utilisés


Docker Desktop, Docker CLI, Docker Compose


Nginx, PHP-FPM, MariaDB


Bind mounts, réseaux Docker


Git / GitHub



## Ce que j’ai appris (brièvement)


Séparer les rôles entre services rend la stack plus claire.


Monter le code comme volume est pratique pour itérer sans rebuild.


Initialiser une base avec docker-entrypoint-initdb.d est simple pour un TP.


Docker Compose simplifie le run multi-services et rend la configuration reproductible.

## Tests :

Même chose que pour l'étape 2



## Auteurs


Travail réalisé par une étudiante, dans le cadre du cours de MLOps.

