#!/bin/bash
if [[ ! `uname` = Darwin ]];then
 exit
fi

VER=`sw_vers -productVersion|sed -E 's/(1[1-2]).*/\1.0/'|\
                             sed -E 's/(10\.)(1[0-5]).*/\1\2/'|\
                             sed -E 's/(10\.)([0-9])($|\.).*/\10\2/'`
[[ 10.04 > $VER ]] && echo ' Not supported' && exit
[[ $VER > 10.11 ]] && echo ' Use Home Brew' && exit

if [[ $1 && $1 = unlink ]];then
 rm -f /usr/local/bin/t_brew
  rm -rf ~/.BREW_LIST
   echo rm all cache
    exit
fi

if [[ ! $1 &&  -e /usr/local/bin/t_brew ]];then
 echo exist /usr/local/bin/t_brew 
  exit
fi

mkdir -p ~/.BREW_LIST
DIR=$(cd $(dirname $0); pwd)

cp $DIR/tbrew_list.pl /usr/local/bin/t_brew
cp $DIR/tied.pl ~/.BREW_LIST/tied.pl
cp $DIR/tiger.txt ~/.BREW_LIST/tiger.txt

perl ~/.BREW_LIST/tied.pl
