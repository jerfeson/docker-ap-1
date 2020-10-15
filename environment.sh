#!/bin/bash
echo "##### Iniciando ambiente #####"

echo "##### Removendo arquivo de configuração residuais #####"
rm bin/webserver/.env bin/webserver/start.sh exec.sh start.sh sample.env README.md README.PROJECT.md docker-compose.yml
rm bin/webserver/.env.* bin/webserver/start.sh.* exec.sh.* start.sh.* sample.env.* README.md.* README.PROJECT.md.* docker-compose.yml.*

echo "##### Baixando arquivos essenciais #####"
wget https://raw.githubusercontent.com/p21sistemas/docker-ap/master/README.PROJECT.md
wget https://raw.githubusercontent.com/p21sistemas/docker-ap/master/docker-compose.yml
wget https://raw.githubusercontent.com/p21sistemas/docker-ap/master/exec.sh && chmod +x ambiente.sh
wget https://raw.githubusercontent.com/p21sistemas/docker-ap/master/start.sh && chmod +x start.sh

PHP_STRING='php'

if [ ! -f .env ]; then

  wget https://raw.githubusercontent.com/p21sistemas/docker-ap/master/sample.env

  echo "##### Por favor informa o nome do projeto com _ no final Ex. sdt21_df_ #####"
  read ENV_PROJECT

  echo "##### Por favor informa a porta em que o projeto vai estar externamente Ex. 8080 #####"
  read ENV_PORT

  echo "##### Por favor informa o ambiente do projeto Ex. desenvolvimento, teste ou producao #####"
  read ENV_APP

  sed -i "s/ENV_PROJECT/$ENV_PROJECT/g" sample.env
  sed -i "s/ENV_PORT/$ENV_PORT/g" sample.env
  sed -i "s/ENV_APP/$ENV_APP/g" sample.env
  cp sample.env .env

  echo "##### Criando pastas do projeto #####"
  mkdir -p bin/webserver
  mkdir -p config/apache2/sites-enabled
  mkdir -p config/php
  mkdir -p logs/apache2

  echo "##### criando primeiros arquivos do projeto #####"
  touch bin/webserver/Dockerfile
  touch logs/apache2/.gitkeep

  echo "##### Por favor informa a versão do ubuntu (18)"
  read ENV_UBUNTU

  echo "##### Por favor informa a versão do php (56, 72, 73)"
  read ENV_PHP

  sed -i "s/ENV_UBUNTU/$ENV_UBUNTU/g" sample.env
  sed -i "s/ENV_PHP/$ENV_PHP/g" sample.env

  echo "FROM p21sistemas/ap:u$ENV_UBUNTU$PHP_STRING$ENV_PHP" >> bin/webserver/Dockerfile

  echo "##### Baixando primeiros arquivos do projeto #####"
  wget -O config/apache2/sites-enabled/default.conf https://raw.githubusercontent.com/p21sistemas/docker-ap/master/config/apache2/sites-enabled/default.conf
  wget -O config/php/php.ini https://github.com/p21sistemas/docker-ap/blob/master/config/php/php.ini
  wget -O config/php/desenvolvimento.ini https://github.com/p21sistemas/docker-ap/blob/master/config/php/desenvolvimento.ini
  wget -O config/php/producao.ini https://github.com/p21sistemas/docker-ap/blob/master/config/php/producao.ini

fi

read_var() {
    VAR=$(grep $1 $2 | xargs)
    IFS="=" read -ra VAR <<< "$VAR"
    echo ${VAR[1]}
}

echo "##### Copiando arquivos de configuração #####"
cp .env bin/webserver/
cp start.sh bin/webserver/
cp README.PROJECT.md README.md

echo "##### Atualizando imagem #####"


docker pull p21sistemas/ap:u$(read_var UBUNTU_VERSION .env)$PHP_STRING$(read_var PHP_VERSION .env)

echo "##### Deseja ignorar o cache o fazer build? ? (N/y) #####"
read cache

if [ $cache == 'y' ]; then
    NOCACHE='--no-cache'
fi

echo "##### Realizando build #####"
docker-compose -f docker-compose.yml build $NOCACHE

echo "##### Iniciando container #####"

docker-compose -f docker-compose.yml up -d --force

echo "##### Removendo arquivo de configuração #####"

rm bin/webserver/.env bin/webserver/start.sh exec.sh start.sh sample.env README.md README.PROJECT.md. docker-compose.yml
rm bin/webserver/.env.* bin/webserver/start.sh.* exec.sh.* start.sh.* sample.env.* README.md.* README.PROJECT.md.* docker-compose.yml.*
rm environment.sh environment.sh.*

echo '##### Acessando o ambiente e executando primeiros comandos #####'

docker exec -it $(read_var PROJECT_NAME .env)webserver php /usr/share/apache2/www/composer.phar install -d /usr/share/apache2/www

# todo list
# - Utiliza migrations para criar tabelas do banco e também alimentar o banco com os principais dados, para limar o ambiente de testes.
# @see https://laravel.com/docs/8.x/migrations Exemplo: https://github.com/jerfeson/slim4-skeleton/blob/master/app/Console/MigrationsCommand.php