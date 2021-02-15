#!/bin/bash
# -*- coding: utf-8 -*-

#==============================================================================
# Titre            : config.sh
# Description      : Script de configuration de Raspberry Pi 4b.
# Auteur           : MELONI Sébastien
# Date             : 02/01/2020
# Modification     : 04/02/2021
# Version          : 1.00 ALPHA
# Utilisation      : ./config.sh
# Notes            : Ce script est destiné à configurer un Raspberry Pi 4B/4B+
#                    avant son installation.
# Version de bash  : 5.0.17
#==============================================================================

# Mise à jour de firmware pour le support du boot USB
update_Bios()
{
  # Mise à jour du firmware du raspberrypi
  SKIP_WARNING=1 rpi-update

  # Installation du package permettant la mise à jour de l'EEPROM.
  apt install rpi-eeprom -y

  # Remplacement du status du firmware à mettre à jour.
  echo 'FIRMWARE_RELEASE_STATUS="stable"' > /etc/default/rpi-eeprom-update

  # Mise à jour du firmaware de l'EEPROM.
  rpi-eeprom-update -d -a
}

# Préparation de l'OS avant installation.
preparation_rpi()
{
  # Mise à jour de l'OS.
  apt-get update
  apt-get safe-upgrade -y

  # Installation d'aptitude pour gérer les packages
  apt-get install aptitude -y

  # Ajout des packages necessaire à l'installation.
  aptitude install -y python3 python3-pip git

  # Mise à jour et insallation de packages PIP3
  pip3 install pip setuptools wheel ansible ansible-base --upgrade

  # Configuration du wifi en utilisant les parametres système.
  langue=$(echo $LANG | cut -d '.' -f 1)
  langue=$(echo $langue | cut -d '_' -f 2)
  raspi-config nonint do_wifi_country $langue
}

change_passwd()
{
  # Déclaration de variables
  compte=$1
  retour="1"

  # Demande de confirmation de modification de mot de passe.
  echo -n "Voulez-vous modifier le mot de passe du compte "$compte "(o/n) ? "
  read -n 1 reponse
  echo ""

  # Passage de la réponse en minuscule.
  reponse=$(echo "${reponse,,}")

  # Modification du mot de passe du compte.
  if [ "$reponse" = "o" ]
  then
    while [ $retour != '0' ]
    do
      passwd $compte
      retour=$?
      if [ "$retour" = 10 ]
      then
        echo ""
        echo "Les 2 mots de passe ne sont pas identique."
        echo "Veuillez les ressaisir."
      elif [ "$retour" = 1 ]
      then
        echo "Vous n'avez pas les droits de modifier le mot de passe de ce compte."
        exit 1
      fi
    done
  else
    echo "Le mot de passe du compte "$compte "n'a pas été modifié."
    read -p "Appuyez sur une touche pour continuer." -n 1
 fi
}

change_hostname()
{
  # Déclarations de variables.
  reponse=""
  retour=1

  # Changement du nom d'hote.
  read -p "Voulez-vous modifier le nom d'hote de votre Raspberry Pi (o/n) ? " -n 1 reponse
  echo ""

  # Passage de la réponse en minuscule.
  reponse=$(echo "${reponse,,}")

  # Test de la réponse.
  if [ "$reponse" = "o" ]
  then
  # Récupération du nom de la machine
    read -p "Veuillez entrer le nouveau nom de votre Raspberry Pi : " reponse
    echo ""

  # Passage de la réponse en minuscule.
    reponse=$(echo "${reponse,,}")

  # Modification du nom de la amchine.
    hostnamectl set-hostname $reponse
    hostnamectl set-deployment production
    hostnamectl set-icon-name computer-desktop
    hostnamectl set-chassis desktop
    echo -n "Le nom de votre Raspberry Pi est maintenant : "$reponse
    read -p "Appuyez sur une touche pour continuer." -n 1
   else
     echo "Le nom d'hote de votre Raspberry Pi n'a pas été modifié."
     echo "Il s'appele toujours : "$(hostname)
     read -p "Appuyez sur une touche pour continuer." -n 1
   fi
}

creation_compte()
{
  # Déclarations de variables.
  identifiant=""
  reponse=""
  groupe=""
  retour=1

  # Changement du nom d'hote.
  read -p "Veuillez saisir l'identifiant du compte à créer : " identifiant
  echo ""

  # Passage de la réponse en minuscule.
  identifiant=$(echo "${identifiant,,}")
  groupe=$identifiant

  echo -n "Voulez-vous que le compte "$identifiant "posséde des droits d'administrateur (o/n) ? "
  read -n 1 reponse
  echo ""

  if [ "$reponse" = "o" ]
  then

  # Création du compte avec les droits sudo
    useradd $identifiant -c $identifiant -d /home/$identifiant -m -s /bin/bash -G sudo
  else
  # Création du compte sans les droits sudo
    useradd $identifiant -c $identifiant -d /home/$identifiant -m -s /bin/bash
  fi

  # Initialisatyion du mot de passe
  change_passwd $identifiant
}

menu_outils()
{
  # Affichage du menu outils
  while [[ $CHOICE != $QUITTEOUTILS ]]
  do
    # Déclarations de variables
    HAUTEUR=15
    LARGEUR=60
    CHOICE_HEIGHT=4
    TITRE="Outils divers"
    MENU_OUTILS="Faites votre choix :"
    QUITTEOUTILS=5

    OPTIONS=(1 "Réinitialiser le mot de passe administrateur (root)."
             2 "Réinitialiser le mot de passe d'un compte."
             3 "Créer un compte."
    	       4 "Renommer mon Raspberry Pi."
             5 "Retour au menu principal.")

# Affectation à choice de la valeur de sortie car le bouton annuler n'affecte
# pas de valeur.
    CHOICE=$(dialog --clear \
                    --title "$TITRE" \
                    --menu "$MENU_OUTILS" \
                    $HAUTEUR $LARGEUR $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

    case $CHOICE in
      1)
          clear
          change_passwd root
          ;;
      2)
          clear
          change_passwd pi
          ;;
      3)
          clear
          creation_compte
          ;;
      4)
          clear
          change_hostname
          ;;
      5)
          clear
          CHOICE=$QUITTEOUTILS
          ;;
    esac
    if [ "$CHOICE" = "" ]
    then
      CHOICE=$QUITTEOUTILS
    fi
  done
}

# ************************ Programme Principal. ********************************

# Déclaration de constante
QUITTEPPAL=4
chemin_prep="/opt/prepa.ok"

# Installation des packages dialog
apt-get install -y dialog

# Message de bienvenu
dialog --clear --title "Bienvenu" \
--msgbox "Bonjour et bienvenu dans l'installation automatisée de votre Raspberry Pi.
          \nUne première phase de préparation va avoir lieu puis, après un redémarrage,
          \nune phase d'installation et de configuration aura lieu." \
          10 50

# Affichage du menu jusqu'a demande de sortie
while [[ $CHOICE != $QUITTEPPAL ]]
do
  # Déclarations de variables
  HEIGHT=15
  WIDTH=40
  CHOICE_HEIGHT=4
  TITLE="Installation du Raspberry Pi"
  MENU="Faites votre choix :"
  CHOICE=""

  # Création du menu
  OPTIONS=(1 "Configuration du Raspberry Pi."
           2 "Installation du Raspberry Pi."
           3 "Outils."
  	       4 "Quitter.")

# Affectation à choice de la valeur de sortie car le bouton annuler n'affecte
# pas de valeur.


# Affichage du menu principal
  CHOICE=$(dialog --clear \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >/dev/tty)

  case $CHOICE in
    1)
        if [ -f "$chemin_prep" ]
        then
          clear
          echo "La préparation de votre Raspberry Pi a déjà été effectuée."
          echo "Il est inutile de la relancer, vous pouvez lancer l'installation."
          read -p "Appuyez sur une touche pour continuer." -n 1
        else
          clear
          preparation_rpi
          touch $chemin_prep
        fi
        ;;
    2)
        if [ -f "$chemin_prep" ]
        then
          clear
          echo "Installation du Raspberry."
        else
          clear
          echo "La préparation de votre Raspberry Pi n'a pas été effectuée."
          echo "Veuillez d'abord lancer celle-ci avant de lancer l'installation."
          read -p "Appuyez sur une touche pour continuer." -n 1
        fi
        ;;
    3)
        menu_outils
        ;;
    4)
        clear
        CHOICE=$QUITTEPPAL
        ;;
  esac
  if [ "$CHOICE" = "" ]
  then
    CHOICE=$QUITTEPPAL
  fi
done
clear
