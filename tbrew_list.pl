#!/usr/bin/env perl
use strict;
use warnings;
use NDBM_File;
use Fcntl ':DEFAULT';
my( $OS_Version,$CPU,%MAC_OS );

MAIN:{
 my $HOME = "$ENV{'HOME'}/.BREW_LIST";
 my $re  = { 'LEN1'=>1,'FOR'=>1,'ARR'=>[],'IN'=>0,'UP'=>0,'UNI'=>[],
             'CEL'=>'/usr/local/Cellar','BIN'=>'/usr/local/opt',
             'HOME'=>$HOME,'TXT'=>"$HOME/tiger.txt" };
 exit if $^O ne 'darwin';
 my @AR = @ARGV;
  Died_1() unless $AR[0];
 if( $AR[0] eq '-l' ){     $re->{'LIST'} = 1;
 }elsif( $AR[0] eq '-i' ){ $re->{'PRINT'}= 1;
 }elsif( $AR[0] eq '-lx' ){$re->{'LIST'} = 1; $re->{'LINK'} = 1;
 }elsif( $AR[0] eq '-lb' ){$re->{'LIST'} = 1; $re->{'LINK'} = 2;
 }elsif( $AR[0] eq '-co' ){$re->{'COM'}  = 1;
 }elsif( $AR[0] eq '-' ){  $re->{'BL'}   = 1;
 }elsif( $AR[0] eq '-s' ){ $re->{'S_OPT'}= 1;
 }else{  Died_1();
 }
 exit unless -d $re->{'CEL'};
 # $CPU = `uname -m` =~ /x86_64/ ? 'intel' : 'ppc'; # Power Macintosh
  $OS_Version = `sw_vers -productVersion`;
   $OS_Version =~ s/^(10\.1\d)\.?\d*\n/$1/;
    $OS_Version =~ s/^(10\.)([4-9])\.?\d*\n/${1}0$2/;
 %MAC_OS = ('el_capitan'=>'10.11','yosemite'=>'10.10','mavericks'=>'10.09',
            'mountain_lion'=>'10.08','lion'=>'10.07','snow_leopard'=>'10.06',
            'leopard'=>'10.05','tiger'=>'10.04');

 if( $AR[1] and $AR[1] =~ m!/.*(\\Q|\\E).*/!i ){
  $AR[1] !~ /.*\\Q.+\\E.*/ ? die" nothing in regex\n" :
   $AR[1] =~ s|/(.*)\\Q(.+)\\E(.*)/|/$1\Q$2\E$3/|;
 }
 if( $AR[1] and my( $reg )= $AR[1] =~ m|^/(.+)/$| ){
  die" nothing in regex\n" 
   if system "perl -e '$AR[1]=~/$reg/' 2>/dev/null" or
    $AR[1] =~ /\^[+*]+|\[\.\.\.]/;
 }

 if( $re->{'COM'} or $AR[1] and $re->{'LIST'} ){
   $AR[1] ? $re->{'STDI'} = lc $AR[1] : Died_1();
    $re->{'L_OPT'} = $re->{'STDI'} =~ s|^/(.+)/$|$1| ? $re->{'STDI'} : "\Q$re->{'STDI'}\E";
 }elsif( $re->{'S_OPT'} ){
  $AR[1] ? $re->{'STDI'} = lc $AR[1] : Died_1();
   $re->{'S_OPT'} =
    $re->{'STDI'} =~ s|^/(.+)/$|$1| ? $re->{'STDI'} : "\Q$re->{'STDI'}\E";
 }
 Init_1( $re );
}

sub Died_1{
 die "  tiger brew_list\n   Option
  -l\t:  formula list\n  -i\t:  instaled formula\n  -\t:  brew list command
  -lb\t:  bottled install formula\n  -lx\t:  can't install formula
  -s\t:  type search name\n  -co\t:  library display\n";
}

sub Init_1{
my( $re,$list ) = @_;
 DB_1( $re );
  DB_2( $re ) unless $re->{'BL'} or $re->{'S_OPT'} or $re->{'COM'};

 $list = ( $re->{'S_OPT'} or $re->{'BL'} or $re->{'TOP'} ) ?
  Dirs_1( $re->{'CEL'},1 ) : Dirs_1( $re->{'CEL'},0,$re );

 $re->{'COM'} ? Command_1( $re,$list ) : ( $re->{'BL'} or $re->{'USE'} ) ?
   Brew_1( $re,$list ) : $re->{'TOP'} ? Top_1( $re,$list ) : File_1( $re,$list );

Format_1( $re );
}

sub DB_1{
my $re = shift;
  opendir my $dir,$re->{'BIN'} or die " DB_1 $!\n";
   for my $com(readdir $dir){
    my $hand = readlink "$re->{'BIN'}/$com";
     next if not $hand or $hand !~ m|^\.\./Cellar/|;
    my( $an,$bn ) = $hand =~ m|^\.\./Cellar/(.+)/(.+)|;
    $re->{'HASH'}{$an} = $bn;
   }
  closedir $dir;
}

sub DB_2{
my( $re,%NA ) = @_;
 tie my %tap,"NDBM_File","$re->{'HOME'}/DBM",O_RDONLY,0;
   %NA = %tap;
  untie %tap;
 $re->{'OS'} = %NA ? \%NA : die " Not read DBM\n";
}

sub Dirs_1{
my( $url,$ls,$re,$bn ) = @_;
 my $an = [];
 opendir my $dir_1,"$url" or die " Dirs_1 $!\n";
  for my $hand_1(readdir $dir_1){
   next if $hand_1 =~ /^\./;
   $re->{'FILE'} .= " File exists $url/$hand_1\n" if -f "$url/$hand_1" and not $ls;
    if( $ls != 2 ){
     next unless -d "$url/$hand_1";
    }
   $ls == 1 ? push @$an," $hand_1\n" : push @$an,$hand_1;
  }
 closedir $dir_1;
  @$an = sort{$a cmp $b}@$an;
   return $an if $ls;
 for( my $in=0;$in<@$an;$in++ ){
  push @$bn," $$an[$in]\n";
  opendir my $dir_2,"$url/$$an[$in]" or die " Dirs_2 $!\n";
   for my $hand_2(readdir $dir_2){
    next if $hand_2 =~ /^\./;
     push @$bn,"$hand_2\n";
   }
  closedir $dir_2;
 }
 $bn;
}

sub Brew_1{
my( $re,$list,%HA,@AN ) = @_;
 return unless @$list;
  for(my $i=0;$i<@$list;$i++){
   my( $tap ) = $list->[$i] =~ /^\s(.*)\n/ ? $1 : $list->[$i];
     Mine_1( $tap,$re,0 );
  }
}

sub File_1{
my( $re,$list,$file ) = @_;
 open my $dir,'<',$re->{'TXT'} or die" File2 $!\n";
  @$file = <$dir>;
 close $dir;
Search_1( $list,$file,0,$re );
}

sub Mine_1{
my( $name,$re,$ls ) = @_;
 $name = "$name (I)" if( $ls and -t STDOUT );
  $re->{'LEN'}{$name} = length $name;
   push @{$re->{'ARR'}},$name;
   $re->{'LEN1'} = $re->{'LEN'}{$name} if $re->{'LEN1'} < $re->{'LEN'}{$name};
}

sub Memo_1{
my( $re,$mem,$dir ) = @_;
 if( $dir ){
  my $file = Dirs_1( "$re->{'CEL'}/$dir",2 );
  if( @$file ){
     $re->{'ALL'} .= "     Check folder $re->{'CEL'} => $dir\n" unless $re->{'L_OPT'};
     $re->{'EXC'} .= "     Check folder $re->{'CEL'} => $dir\n" if $mem;
   for(my $i=0;$i<@$file;$i++){
     $re->{'ALL'} .= @$file-1 == $i ? "    $$file[$i]\n" : "     $$file[$i]" unless $re->{'L_OPT'};
     $re->{'EXC'} .= @$file-1 == $i ? "    $$file[$i]\n" : "     $$file[$i]" if $mem;
   }
  }else{
     $re->{'ALL'} .= "     Empty folder $re->{'CEL'} => $dir\n" unless $re->{'L_OPT'};
     $re->{'EXC'} .= "     Empty folder $re->{'CEL'} => $dir\n" if $mem;
  }
 }else{
    $re->{'ALL'} .= $re->{'MEM'} unless $re->{'L_OPT'};
    $re->{'EXC'} .= $re->{'MEM'} if $mem;
 }
}

sub Search_1{
my( $list,$file,$in,$re ) = @_;
 for(my $i=0;$i<@$file;$i++){ my $pop = 0;
  my( $brew_1,$brew_2,$brew_3 ) = split '\t',$file->[$i];
    my $mem = ( $re->{'L_OPT'} and $brew_1 =~ /$re->{'L_OPT'}/o ) ? 1 : 0;

  if( not $re->{'LINK'} or
      $re->{'LINK'} == 1 and $re->{'OS'}{"${brew_1}un_xcode"} or
      $re->{'LINK'} == 2 and $re->{'OS'}{"$brew_1$OS_Version"} ){

    if( $list->[$in] and " $brew_1\n" gt $list->[$in] ){
     Tap_1( $list,$re,\$in );
      $i--; next;
    }elsif( $list->[$in] and " $brew_1\n" eq $list->[$in] ){
     $re->{'HASH'}{$brew_1} ?
      Mine_1( $brew_1,$re,1 ) : Mine_1( $brew_1,$re,0 )
       if $re->{'S_OPT'} and $brew_1 =~ /$re->{'S_OPT'}/o;
        $in++; $re->{'IN'}++; $pop = 1;
    }else{
      Mine_1( $brew_1,$re,0 ) if $re->{'S_OPT'} and $brew_1 =~ /$re->{'S_OPT'}/o;
    }
   unless( $re->{'S_OPT'} ){
    $re->{'MEM'} = ( $re->{'OS'}{"$brew_1$OS_Version"} and $re->{'OS'}{"${brew_1}keg"} ) ?
       " b k     $brew_1\t" : $re->{'OS'}{"$brew_1$OS_Version"} ? " b       $brew_1\t" :
        ( $re->{'OS'}{"${brew_1}un_xcode"} and $re->{'OS'}{"${brew_1}keg"} ) ?
       " x k     $brew_1\t" : $re->{'OS'}{"${brew_1}un_xcode"} ? " x       $brew_1\t" :
       $re->{'OS'}{"${brew_1}keg"} ? "   k     $brew_1\t" : "         $brew_1\t";

    if( $pop ){
     if( not $list->[$in] or $list->[$in] =~ /^\s/ ){
       Memo_1( $re,$mem,$brew_1 );
         $i--; next;
     }elsif( $list->[$in + 1] and $list->[$in + 1] !~ /^\s/ ){
       Memo_1( $re,$mem,$brew_1 );
       while(1){ $in++;
        last if not $list->[$in + 1] or $list->[$in + 1] =~ /^\s/;
       }
     }
     if( not $re->{'HASH'}{$brew_1} ){
           $re->{'MEM'} =~ s/^.{9}$brew_1\t/      x  $brew_1\tNot Formula\n/;
            Memo_1( $re,$mem,0 );
             $in++; $i--; next;
     }else{
          $re->{'MEM'} =~ s/^(.{6}).(.+)/$1i$2/;
     }
     $in++;
    }
    $re->{'MEM'} .= $brew_3 ? "$brew_2\t$brew_3" : $brew_2;
     Memo_1( $re,$mem,0 ) if $re->{'LIST'} or $pop;
      $re->{'AN'}++;
   }
  }
 }
  if( $list->[$in] ){
   Tap_1( $list,$re,\$in ) while($list->[$in]);
  }
}

sub Tap_1{
my( $list,$re,$in ) = @_;
 my( $tap ) = $list->[$$in] =~ /^\s(.*)\n/;
  my $mem = ( $re->{'L_OPT'} and $tap =~ /$re->{'L_OPT'}/ ) ? 1 : 0;
  if( $list->[$$in + 1] and $list->[$$in + 1] !~ /^\s/ ){ $$in++;
    if( $list->[$$in + 1] and $list->[$$in + 1] !~ /^\s/ ){
     Memo_1( $re,0,$tap );
      while(1){ $$in++;
       last if not $list->[$$in + 1] or $list->[$$in + 1] =~ /^\s/;
      }
    }
    if( not $re->{'HASH'}{$tap} ){
     $re->{'MEM'} = "  x  $tap\tNot Formula\n";
      Memo_1( $re,0,0 );
    }
  }else{
    Memo_1( $re,0,$tap );
  }
 $$in++;
}

sub Command_1{
my( $re,$list,$ls1,$ls2,%HA,%OP ) = @_;
 for(my $in=0;$in<@$list;$in++){
  if( $list->[$in] =~ s/^\s(.*)\n/$1/ and $list->[$in] =~ /^\Q$re->{'STDI'}\E$/o ){
   my $name = $list->[$in];
   exit unless my $num = $re->{'HASH'}{$name};
    for my $dir('bin','sbin'){
     if( -d "$re->{'CEL'}/$name/$num/$dir" ){
      my $com = Dirs_1( "$re->{'CEL'}/$name/$num/$dir",2 );
       print"$re->{'CEL'}/$name/$num/$dir/$_\n" for(@{$com});
     }
    }
    Dirs_2( "$re->{'CEL'}/$name/$num",$re );
     $re->{'CEL'} = "$re->{'CEL'}/\Q$name\E/$num";
    for $ls1(@{$re->{'ARR'}}){
     next if $ls1 =~ m|^$re->{'CEL'}/[^/]+$|o or $ls1 =~ m|^$re->{'CEL'}/s?bin/|o;
     if(not -l $ls1 and $ls1 =~ m|^$re->{'CEL'}/lib/[^/]+dylib$|o){
             print"$ls1\n"; $re->{'IN'} = 1;
     }else{ $ls2 = $ls1;
      $ls1 =~ s|^($re->{'CEL'}/[^/]+/[^/]+)/.+(/.+)|$1$2|o;
        $HA{$ls1}++ if $ls1 =~ s|(.+)/.+|$1|;
      $ls2 =~ s|^$re->{'CEL'}/[^/]+/[^/]+/(.+)|$1|o;
        $OP{$ls1} = $ls2;
     }
    }
    for my $key(sort keys %HA){
     if( $HA{$key} == 1 ){
      $OP{$key} =~ /^$re->{'CEL'}/o ? print"$OP{$key}\n" : print"$key/$OP{$key}\n";
     }else{
      ( $re->{'IN'} and  $key =~ m|^$re->{'CEL'}/lib$|o ) ?
      print"$key/ ($HA{$key} other file)\n" : print"$key/ ($HA{$key} file)\n";
     }
    }
   exit;
  }
 }
}

sub Dirs_2{
my( $an,$re ) = @_;
 opendir my $dir,$an or die " N_Dirs $!\n";
  for my $bn(readdir($dir)){
   next if $bn =~ /^\.{1,2}$/;
    ( -d "$an/$bn" and not -l "$an/$bn" ) ?
   Dirs_2( "$an/$bn",$re ) : push @{$re->{'ARR'}},"$an/$bn";
  }
 closedir $dir;
}

sub Format_1{
my( $re,$ls,$sl,$ss,$ze ) = @_;
 if( $re->{'LIST'} or $re->{'PRINT'} ){
  system " printf '\033[?7l' " if -t STDOUT;
   $re->{'L_OPT'} ? print"$re->{'EXC'}" : print"$re->{'ALL'}" if $re->{'ALL'} or $re->{'EXC'};
    print " item $re->{'AN'} : install $re->{'IN'}\n" if $re->{'ALL'} or $re->{'EXC'};
  system " printf '\033[?7h' " if -t STDOUT;
 }else{
  if( -t STDOUT ){
   my $leng = $re->{'LEN1'};
    my $tput = `tput cols`;
     my $size = int $tput/($leng+2);
      my $in = 1;
     for my $arr( @{$re->{'ARR'}} ){
      for(my $i=$re->{'LEN'}{$arr};$i<$leng+2;$i++){
       $arr .= ' ';
      }
      print"$arr";
      print"\n" unless $ze = eval "$in % $size";
      $in++;
     }
    print"\n" if $ze;
   }else{
    print"$_\n" for @{$re->{'ARR'}};
   }
 }
 print "\033[33m$re->{'FILE'}\033[00m" if $re->{'FILE'} and ( $re->{'ALL'} or $re->{'EXC'} );
}
