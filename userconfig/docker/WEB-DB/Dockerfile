# Usa la imagen base de PHP con Apache
FROM php:8.1-apache

# Instala las extensiones necesarias
RUN docker-php-ext-install mysqli

# Habilita mod_rewrite de Apache si es necesario
RUN a2enmod rewrite
