#!/bin/bash
if [[ ! `uname` = Darwin ]];then
 exit
fi
 LINK="$1"
VER=`sw_vers -productVersion|\
sed -E 's/(1[1-2]).*/\1.0/;s/(10\.)(1[0-5]).*/\1\2/;s/(10\.)([0-9])($|\.).*/\10\2/'`
 [[ 10.04 > $VER ]] && echo ' Not supported' && exit
 [[ $VER > 10.11 ]] && echo ' Use Home Brew' && exit

if [[ "$LINK" = unlink ]];then
 rm -f /usr/local/bin/t_brew
  rm -rf ~/.BREW_LIST
   echo rm all cache
    exit
fi

if [[ ! "$LINK" &&  -e /usr/local/bin/t_brew ]];then
 echo exist /usr/local/bin/t_brew 
  exit
fi

if [[ ! "$LINK" || "$LINK" = JA ]];then
 mkdir -p ~/.BREW_LIST
 DIR=$(cd $(dirname $0); pwd)

 cp $DIR/tbrew_list.pl /usr/local/bin/t_brew || ${die:?copy error}
 Lang=$(printf $LC_ALL $LC_CTYPE $LANG 2>/dev/null)

 if [[ "$LINK" = JA && $Lang =~ [uU][tT][fF]-?8$ ]];then
  cp $DIR/ja_tiger.txt ~/.BREW_LIST/tiger.txt
 else
   cp $DIR/tiger.txt ~/.BREW_LIST/tiger.txt
 fi

 cp $DIR/tied.pl ~/.BREW_LIST/tied.pl
 perl ~/.BREW_LIST/tied.pl
fi
