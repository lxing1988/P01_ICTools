#!/usr/bin/env perl
#===============================================================================
#
#         FILE: encript.pl
#
#        USAGE: ./encript.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: LongXing (LX), lxing_1988@sina.com
# ORGANIZATION: FREE
#      VERSION: 1.0
#      CREATED: 04/25/2016 03:20:05 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

my $src_file  = "./make_top.pl" ;
my $dist_file = "./usermake_top.pl" ;

open(SRC_FH, "<", "$src_file") or die("Error : $!") ; 
open(DIST_FH, ">", "$dist_file") or die ("Error : $!") ;

my $SRC_INFO = [<SRC_FH>] ;

foreach my $line (@{$SRC_INFO}) {


    #-----------------------------------------------------------
    # a0000000000a
    #-----------------------------------------------------------
    $line =~ s/suffix/a0187928739721977a/g;
    $line =~ s/\$SheetRef/\$a0000a0b00sa/g ;
    $line =~ s/\$SheetPage/\$a0a00a0b00sa/g ;
    $line =~ s/\$PageLable/\$a0a00a0b0csa/g ;
    #$line =~ s/\$GetModule/\$a0a0ca1b0csa/g ;
    $line =~ s/\$GenDumyModuleEnable/\$a0a0ca1b4csa/g ;
    $line =~ s/\$numOfSheets/\$a0acca1c4csa/g ;


    #-----------------------------------------------------------
    # a1111111111a
    #-----------------------------------------------------------
    $line =~ s/\$JudgementCol/\$a1111011911a/g ;
    $line =~ s/\$ModuleNameCol/\$a1111811111a/g ;
    $line =~ s/\$DirectionCol/\$a1711111111a/g ;
    $line =~ s/\$WidthCol/\$a1111131161a/g ;
    $line =~ s/\$SigNameCol/\$a1115111111a/g ;
    $line =~ s/\$PortTypeCol/\$a4111111111a/g ;
    $line =~ s/\$AssignWithCol/\$a1111111131a/g ;
    $line =~ s/\$CommentCol/\$a1111111112a/g ;

    #-----------------------------------------------------------
    # b1111111111b
    #-----------------------------------------------------------
    $line =~ s/\$ParseChar/\$b1211111511b/g ;
    $line =~ s/\$CommentChar/\$b1211311111b/g ;
    $line =~ s/SubModuleInfo/b1211111111b/g ;
    $line =~ s/SubModulePortsInfo/b1111111211b/g ;


    #-----------------------------------------------------------
    # ca11111111ac
    #-----------------------------------------------------------
    $line =~ s/ParseSheet/ca21222222ac/g ;
    $line =~ s/\$ParsingGetModule/\$ca22222221ac/g ;
    $line =~ s/\$ParsingWireField/\$ca22222232ac/g ;
    $line =~ s/\$ParsingSubModule/\$ca22224222ac/g ;
    $line =~ s/\$SubModuleCounter/\$ca22532222ac/g ;
    $line =~ s/\$ParsingModuleName/\$ca22226222ac/g ;
    $line =~ s/\$PreviousSubModuleName/\$ca23252822ac/g ;

    #-----------------------------------------------------------
    # cb11111111bc
    #-----------------------------------------------------------
    $line =~ s/WriteBackExcel/cb11111111bc/g ;
    $line =~ s/\$WrExcelFName/\$cb21111111bc/g ;
    $line =~ s/\$PageName/\$cb31111111bc/g ;
    $line =~ s/\$JudgementCol/\$cb32111111bc/g ;
    $line =~ s/\$ModuleNameCol/\$cb32214111bc/g ;
    $line =~ s/\$ModuleInstCol/\$cb32211331bc/g ;
    $line =~ s/\$DirectionCol/\$cb32311111bc/g ;
    $line =~ s/\$WidthCol/\$cb32311112bc/g ;
    $line =~ s/\$SigNameCol/\$cb32311212bc/g ;
    $line =~ s/\$SigTypeCol/\$cb32331212bc/g ;
    $line =~ s/\$AssignWithCol/\$cb324531212bc/g ;
    $line =~ s/\$CommentCol/\$cb32741212bc/g ;
    $line =~ s/\$rowpc/\$cb3279786212bc/g ;
    $line =~ s/\$ShetHD/\$cb32797867642bc/g ;
    $line =~ s/\$page/\$cb32797899942bc/g ;


    #-----------------------------------------------------------
    # cd22222222222dc
    #-----------------------------------------------------------
    $line =~ s/GetCell/cd3279817263874981263874723423899942dc/g ;
    $line =~ s/WriteExcelPortsArea/cd3279789234322234232942dc/g ;
    $line =~ s/WriteExcelWiresArea/cd327978923432229asdas42dc/g ;
    $line =~ s/WriteExcelSubModulesArea/cd327908ask3d212402dc/g ;
    $line =~ s/CreateTopModule/cd327908asdfbkba65664i212402dc/g ;
    $line =~ s/PrintDumySubModules/cd327908asdfbkbai9212402dc/g ;
    $line =~ s/PrintCreatedModule/cd327908asd726fabdi912402dc/g ;
    $line =~ s/PrintFileHeader/cd327da2908asd726fabdi912402dc/g ;
    $line =~ s/PrintSubModuleField/cd3asdda8asd726fabdiasdldc/g ;
    $line =~ s/PrintWireField/cd3asdda8lakwpasd726fabdiasdldc/g ;
    $line =~ s/PrintPortField/cd3asdda8lak23kjsddbdi348asdldc/g ;
    $line =~ s/CreatePortsField/cd049759lk54asdflkertizlswldc/g ;
    $line =~ s/CreateWireField/cd934879akjlwoiori230984932ldc/g ;
    $line =~ s/CreateSubModuleField/cd9wqplsgakjlwoi309842ldc/g ;
    $line =~ s/ValidCell/cowi22038akjlwoi3owilklk234809842ldc/g ;
    $line =~ s/CheckDirectionCell/cow20akjlwoisadfwiklka42ldc/g ;
    $line =~ s/ParseWireInfo/cow20aw0woisadfwik023940lxdf2ldc/g ;
    $line =~ s/ParsePortInfo/cdw20saw0woi3pjlkasjdik023940ldc/g ;
    $line =~ s/CheckCommentCell/cdwwoizldiwoeoi3pja239k020ldc/g ;
    $line =~ s/GetTimeSuffix/cdwwoizliqowinzmcseiwu9293840ldc/g ;
    $line =~ s/GetUserName/cdww983947472zajdk3oiqowu929ads4dc/g ;


    #-----------------------------------------------------------
    # ce33333333333ec
    #-----------------------------------------------------------
    #$line =~ s/\$direction/\$ce327908asd726fa23abdi912402ec/g ;
    #$line =~ s/\$width/\$ce327908asd726f23423ab12di912402ec/g ;
    #$line =~ s/\$name/\$ce32745566767708asd726fabdi912402ec/g ;
    $line =~ s/\$type/\$ce327908aaasd72bbdde67fabdi912402ec/g ;
    $line =~ s/\$assignwith/\$ce327asd7a23a2645fabd912402ec/g ;
    $line =~ s/\$comment/\$ce27988asd726fabdi912407883sd2ec/g ;


    #-----------------------------------------------------------
    # cf44444444444fc
    #-----------------------------------------------------------
    $line =~ s/\$space4/\$cf8329489987293879s879028037fc/g ;
    $line =~ s/\$systype/\$cf8329489oqwieaa79879028037fc/g ;
    $line =~ s/\$UserName/\$cf83294899872387987lkajo37fc/g ;
    $line =~ s/\$format/\$cf8329489cccserttyuz7lkajo37fc/g ;
    #$line =~ s/\$time/\$cf8329489cccaserttasdioqkajo37fc/g ;
    $line =~ s/\$row/\$cf83eqwerqethaddiilxxxxxrkajo37fc/g ;
    $line =~ s/\$col/\$cf8389cccaseadrttawesdweokajo37fc/g ;
    $line =~ s/\$distf/\$cf89cccaseadrttawesdweokajo37fc/g ;
    $line =~ s/\$modulename/\$cf8389caseattaweweoajo37fc/g ;
    $line =~ s/\$datetime/\$cf889ccaseadttawesdokajo37fc/g ;
    $line =~ s/\$author/\$cf889ccaseadtweqacesdokajo37fc/g ;
    
    
    $line =~ s/^\s+//g ;

    unless($line =~ m/printf|print/) {
      $line =~ s/\s+/ /g ;
      $line .="\n" ;
    } 

    #print DIST_FH ("$line") ;
    if($line =~ /^$/) {
        #print DIST_FH ("$line") ;
    } else {
      print DIST_FH ("$line") ;
    }
}

close(SRC_FH) or die("Error : $!") ;
close(DIST_FH) or die("Error : $!") ;
