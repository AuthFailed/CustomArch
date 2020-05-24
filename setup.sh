#!/bin/bash

## Author: Aditya Shakya
## This script will download needed AUR pkgs, build them and automatically setup localrepo for this custom archlinux iso.

#colors
R='\033[1;31m'
B='\033[1;34m'
C='\033[0;36m'
G='\033[1;32m'
W='\033[1;37m'
Y='\033[1;33m'

DIR="$(pwd)"
PKG1="colorpicker"
PKG2="yay"
PKG3="plymouth"

## Banner
echo
echo -e $B"┌──────────────────────────────────┐"
echo -e $B"│   $R┏━┓┏━┓┏━╸╻ ╻   ╻  ╻┏┓╻╻ ╻╻ ╻   $B│"
echo -e $B"│   $R┣━┫┣┳┛┃  ┣━┫   ┃  ┃┃┗┫┃ ┃┏╋┛   $B│"
echo -e $B"│   $R╹ ╹╹┗╸┗━╸╹ ╹   ┗━╸╹╹ ╹┗━┛╹ ╹   $B│"
echo -e $B"└──────────────────────────────────┘"
echo

## Setting Things Up
echo
echo -e $Y"[*] Installing Dependencies - "$C
echo
sudo pacman -Sy git archiso --noconfirm
echo
echo -e $G"[*] Succesfully Installed."$C
echo
echo -e $Y"[*] Modifying /usr/bin/mkarchiso - "$C
sudo cp /usr/bin/mkarchiso{,.bak} && sudo sed -i -e 's/-c -G -M/-i -c -G -M/g' /usr/bin/mkarchiso
echo
echo -e $G"[*] Succesfully Modified."$C
echo

## Cloning AUR Packages
cd $DIR/pkgs

echo -e $Y"[*] Downloading AUR Packages - "$C
echo
echo -e $Y"[*] Cloning colorpicker - "$C
git clone https://aur.archlinux.org/colorpicker.git --depth 1 $PKG1
echo
echo -e $Y"[*] Cloning yay - "$C
git clone https://aur.archlinux.org/yay.git --depth 1 $PKG2
echo
echo -e $Y"[*] Cloning plymouth - "$C
git clone https://aur.archlinux.org/plymouth.git --depth 1 $PKG3
echo
echo -e $G"[*] Downloaded Successfully."$C
echo

## Building AUR Packages
mkdir -p ../localrepo/i686 ../localrepo/x86_64

echo -e $Y"[*] Building AUR Packages - "$C
echo

echo -e $Y"[*] Building $PKG1 - "$C
cd $PKG1 && makepkg -s
mv *.pkg.tar.xz ../../localrepo/x86_64
cd ..

echo -e $Y"[*] Building $PKG2 - "$C
cd $PKG2 && makepkg -si
mv *.pkg.tar.xz ../../localrepo/x86_64
cd ..

echo -e $Y"[*] Building $PKG3 - "$C
cd $PKG3
cp -r $DIR/pkgs/beat $DIR/pkgs/plymouth
sed -i '$d' PKGBUILD
cat >> PKGBUILD <<EOL
  sed -i -e 's/Theme=.*/Theme=beat/g' \$pkgdir/etc/plymouth/plymouthd.conf
  sed -i -e 's/ShowDelay=.*/ShowDelay=1/g' \$pkgdir/etc/plymouth/plymouthd.conf
  cp -r ../../beat \$pkgdir/usr/share/plymouth/themes
}
EOL 
sum1=$(md5sum sddm-plymouth.service |  awk -F ' ' '{print $1}')
cat > sddm-plymouth.service <<EOL
[Unit]
Description=Simple Desktop Display Manager
Documentation=man:sddm(1) man:sddm.conf(5)
Conflicts=getty@tty1.service
Wants=plymouth-deactivate.service
After=systemd-user-sessions.service getty@tty1.service plymouth-deactivate.service plymouth-quit.service systemd-logind.service

[Service]
ExecStart=/usr/bin/sddm
Restart=always

[Install]
Alias=display-manager.service
EOL
sum2=$(md5sum sddm-plymouth.service |  awk -F ' ' '{print $1}')
sed -i -e "s/$sum1/$sum2/g" PKGBUILD
makepkg -s
mv *.pkg.tar.xz ../../localrepo/x86_64
cd ..

echo
echo -e $G"[*] All Packages Builted Successfully."$C
echo

## Setting up LocalRepo
cd $DIR/localrepo/x86_64
echo -e $Y"[*] Setting Up Local Repository - "$C
echo
repo-add localrepo.db.tar.gz *
echo
echo -e $Y"[*] Appending Repo Config in Pacman file - "$C
echo
echo "[localrepo]" >> $DIR/customiso/pacman.conf
echo "SigLevel = Optional TrustAll" >> $DIR/customiso/pacman.conf
echo "Server = file://$DIR/localrepo/\$arch" >> $DIR/customiso/pacman.conf
echo

## Setting up oh-my-zsh
echo -e $Y"[*] Setting Up Oh-My-Zsh - "$C
echo
cd $DIR/customiso/airootfs/etc/skel && git clone https://github.com/robbyrussell/oh-my-zsh.git --depth 1 .oh-my-zsh
cp $DIR/customiso/airootfs/etc/skel/.oh-my-zsh/templates/zshrc.zsh-template $DIR/customiso/airootfs/etc/skel/.zshrc
cat >> $DIR/customiso/airootfs/etc/skel/.zshrc <<EOL
# omz
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"

# ls
alias l='ls -lh'
alias ll='ls -lah'
alias la='ls -A'
alias lm='ls -m'
alias lr='ls -R'
alias lg='ls -l --group-directories-first'

# git
alias gcl='git clone --depth 1'
alias gi='git init'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin master'
EOL
cp -r $DIR/customiso/airootfs/etc/skel/.oh-my-zsh $DIR/customiso/airootfs/root && cp $DIR/customiso/airootfs/etc/skel/.zshrc $DIR/customiso/airootfs/root
echo
echo -e $R"[*] Done."
echo

## Changing ownership to root to avoid false permissions error
echo -e $Y"[*] Making owner ROOT to avoid problems with false permissions."$C
sudo chown -R root:root $DIR/customiso/
echo

echo -e $Y"[*] Cleaning Up... "$C
cd $DIR/pkgs
rm -rf $PKG1 $PKG2 $PKG3
echo
echo -e $R"[*] Setup Completed."
echo
exit
