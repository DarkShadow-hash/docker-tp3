# Étape 2 - Image PHP personnalisée avec extension mysqli
FROM php:8.2-fpm

# Installation de l’extension mysqli
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Dossier de travail par défaut
WORKDIR /app
