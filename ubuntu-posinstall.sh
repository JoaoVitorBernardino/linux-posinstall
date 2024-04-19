#!/usr/bin/env bash

set -e

#CORES

VERMELHO='\e[1;91m'
VERDE='\e[1;92m'
SEM_COR='\e[0m'

# URLS

URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

DIRETORIO_DOWNLOADS="$HOME/Downloads"

apt_update(){
    sudo apt update && sudo apt upgrade -y
}

testes_internet(){
    if ! ping -c 1 8.8.8.8 -q &> /dev/null; then
        echo -e "${VERMELHO}[ERROR] - Seu computador não tem conexão com a Internet. Verifique a rede.${SEM_COR}"
        exit 1
    else
        echo -e "${VERDE}[INFO] - Conexão com a Internet funcionando normalmente.${SEM_COR}"
    fi
}

just_apt_update(){
    sudo apt update -y
}

PROGRAMAS_PARA_INSTALAR=(
  snapd
  ca-certificates
  apt-transport-https
  wget
)

install_vscode(){
    echo -e "${VERDE}[INFO] - Instalando Visual Studio Code${SEM_COR}"
    
    sudo apt-get install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    
    sudo apt install code
}

install_debs() {
    echo -e "${VERDE}[INFO] - Baixando pacotes .deb${SEM_COR}"
    
    wget -c "$URL_GOOGLE_CHROME"       -P "$DIRETORIO_DOWNLOADS"
    
    echo -e "${VERDE}[INFO] - Instalando pacotes .deb baixados${SEM_COR}"
    sudo dpkg -i $DIRETORIO_DOWNLOADS/*.deb
    
    echo -e "${VERDE}[INFO] - Instalando pacotes apt do repositório${SEM_COR}"
    
    if ! dpkg -l | grep -q curl; then
        echo -e "${VERDE}[INFO] - Instalando Curl${SEM_COR}" 
        sudo apt install curl
    fi

    for nome_do_programa in ${PROGRAMAS_PARA_INSTALAR[@]}; do
        if ! dpkg -l | grep -q $nome_do_programa; then # Só instala se já não estiver instalado
            sudo apt install "$nome_do_programa" -y
        else
            echo "[INSTALADO] - $nome_do_programa"
        fi
    done
}


install_snaps(){
    echo -e "${VERDE}[INFO] - Instalando pacotes snap${SEM_COR}"
    sudo snap refresh
    sudo snap install slack telegram-desktop
}

system_clean(){
    apt_update -y
    sudo apt autoclean -y
    sudo apt autoremove -y
}

install_docker_packages(){
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
}

install_docker(){
    echo -e "${VERDE}[INFO] - Instalando o Docker e suas dependências${SEM_COR}"
    just_apt_update
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    just_apt_update
    install_docker_packages
}

testes_internet
apt_update
install_debs
just_apt_update
install_vscode
install_snaps
install_docker
apt_update
system_clean

echo -e "${VERDE}[INFO] - Script finalizado, instalação concluída! :)${SEM_COR}"
