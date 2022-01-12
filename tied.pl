use strict;
use warnings;
use NDBM_File;
use Fcntl ':DEFAULT';

my $IN = 0; my $KIN = 0;
# my $CPU = `uname -m` =~ /x86_64/ ? 'intel' : 'ppc'; # Power Macintosh
 my $Xcode = `xcodebuild -version 2>/dev/null` ?
             `xcodebuild -version|awk '/Xcode/{print \$NF}'` : 0;
 my $OS_Version = `sw_vers -productVersion`;
     $OS_Version =~ s/^(10.1\d)\.?\d*\n/$1/;
      $OS_Version =~ s/^(10\.)([4-9])\.?\d*\n/${1}0$2/;
 my %MAC_OS = ('el_capitan'=>'10.11','yosemite'=>'10.10','mavericks'=>'10.09',
               'mountain_lion'=>'10.08','lion'=>'10.07','snow_leopard'=>'10.06',
               'leopard'=>'10.05','tiger'=>'10.04');

 my @BREW = glob "/usr/local/Library/Formula/*";

tie my %tap,"NDBM_File","$ENV{'HOME'}/.BREW_LIST/TDB",O_RDWR|O_CREAT,0644 or die" tie $!\n";
 for my $dir1(@BREW){ chomp $dir1;
  my( $name ) = $dir1 =~ m|.+/(.+)\.rb|;
  # $tap{"${name}core"} = $dir1;
  open my $BREW,'<',$dir1 or die " tie Info_1 $!\n";
   while(my $data=<$BREW>){
     if( $data =~ /^\s*bottle\s+do/ ){
      $KIN = 1; next;
     }elsif( $data =~ /^\s*cellar\s:any|^\s*revision/ and $KIN == 1 ){
       next;
     }elsif( $data !~ /^\s*end/ and $KIN == 1 ){
       $tap{"$name$data"} =
       $data =~ s/.*:el_capitan.*\n/10.11/    ? 1 :
       $data =~ s/.*:yosemite.*\n/10.10/      ? 1 :
       $data =~ s/.*:mavericks.*\n/10.09/     ? 1 :
       $data =~ s/.*:mountain_lion.*\n/10.08/ ? 1 :
       $data =~ s/.*:lion.*\n/10.07/          ? 1 :
       $data =~ s/.*:snow_leopard.*\n/10.06/  ? 1 :
       $data =~ s/.*:leopard.*\n/10.05/       ? 1 :
       $data =~ s/.*:tiger.*\n/10.04/         ? 1 :
      next;
     }elsif( $data =~ /^\s*end/ and $KIN == 1 ){
      $KIN = 0; next;
     }
     if( $data =~ /^\s*head do/ ){ $IN = 1; next;
     }elsif( $data !~ /^\s*end/ and $IN == 1 ){ next;
     }elsif( $data =~ /^\s*end/ and $IN == 1){ $IN = 0; next;
     }
     if( $data =~ s/^\s*depends_on\s+:macos.+:([^\s]+).*\n/$1/ ){
      $tap{"${name}un_xcode"} = 1 if eval "$OS_Version < $MAC_OS{$data}";
     }elsif( $data =~ /^\s*depends_on\s+:xcode[^"]+:build/ ){
      $tap{"${name}un_xcode"} = 1 unless $Xcode;
      $tap{"${name}un_xcode"} = 0 if $tap{"$name$OS_Version"};
     }elsif( $data =~ s/^\s*depends_on\s+:xcode.+\["([^"]+)",\s+:build].*\n/$1/ ){
      $tap{"${name}un_xcode"} = 1 if eval "$Xcode lt $data";
      $tap{"${name}un_xcode"} = 0 if $tap{"$name$OS_Version"};
     }elsif( $data =~ s/^\s*depends_on\s+:xcode.+"([^"]+)".*\n/$1/ ){
      $tap{"${name}un_xcode"} = 1 if eval "$Xcode lt $data";
     }elsif( $data =~ /^\s*keg_only/ ){
      $tap{"${name}keg"} = 1;
     }
   }
  close $BREW;
 }
untie %tap;
