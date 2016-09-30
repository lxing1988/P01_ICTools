#!/usr/bin/env perl
#===============================================================================
#
#         FILE: make_sheet.pl
#
#        USAGE: ./make_sheet.pl  
#
#  DESCRIPTION: 
#              Get verdi's "getModIO.log" then format print port's information 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: LongXing (Mr), lxing_1988@sina.com
# ORGANIZATION: FREE
#      VERSION: 1.0
#      CREATED: 11/05/2015 09:15:54 PM
#     REVISION: ---
#===============================================================================

use strict ;
use warnings ;
use utf8 ;
use Getopt::Long ;
use Spreadsheet::Read ;
use Spreadsheet::WriteExcel ;
use Spreadsheet::WriteExcel::Utility;


my @tagt_mlist = qw(LVDCTL_TOP BCLKSTOP_TOP BPORT_WRAP_TOP) ;


my $VerdiReportFile  = '../getModIO.log' ;
my $suffix           = &GetTimeSuffix(1) ;
my $logdat           = "./getinfo_${suffix}.txt" ;
my $verbose          = 0 ;

my $WrExcelName = "ModInfo_stage0.xls" ;


GetOptions("verdirpt=s"    => \$VerdiReportFile, 
           "logs=s"        => \$logdat, 
           "verbose"       => \$verbose, 
           "outputexcel=s" => \$WrExcelName, 
          ) or die("Error in command argument! \n") ;

open(my $VerdiReportFile_H, '<', $VerdiReportFile) or die ("Error in Open File : $VerdiReportFile \n$!") ;

my $verdi_rptf = [<$VerdiReportFile_H>] ;

close($VerdiReportFile_H) or die ("Error in Close File : $VerdiReportFile \n$!") ;

#========================================================================================================
#   Get module's information from verdi's log 
#========================================================================================================

#--------------------------------------------------------------------------------------------------------
#   Data structure of TargetModuleInfo : 
#   TargetModuleInfo
#   [
#     {
#          ModuleName  => '_string'
#          ModulePorts 
#          [
#              {
#               direction=>'_string', 
#               name=>'_string', 
#               width=>'_string', 
#              }
#              ...
#          ]
#     }
#     ...
#   ]
#
my @TargetModuleInfo ;


my $LinePC   = 0 ;
my $FindArea = 0 ;
my @PortList ;
my @ModuleList ;
my %ModuleInfo ;

foreach my $line (@{$verdi_rptf}) {
    $LinePC++ ;
    if($line =~ /^$|[\*=-]+/ ) { next ;} ;  # ignore character : */=/-/empty_line

    if($FindArea) {
        if($line =~ /\s+\d+\)\s+\w+\s*:\s+\w+\s+\(/) {
            my %PortInfo ;
            %PortInfo = &GetPortInfo($line) ;
            push(@PortList, {%PortInfo}) ;
            next ;
        } else {
            $FindArea = 0 ;
            $ModuleInfo{'ModulePorts'} = [@PortList] ;
            push(@TargetModuleInfo, {%ModuleInfo}) ;
            undef @PortList ;
            undef %ModuleInfo ;
        }
    }

    if($line =~ /\bModule\b:\W\w+\W\((\w+)\)/) {
        foreach my $module (@tagt_mlist) {
            if($module eq $1) {
                # printf("\n\n$line - $1 - $LinePC\n") ;
                $FindArea = 1 ;
                $ModuleInfo{'ModuleName'} = $module ;
            }
        }
    }

}


#--------------------------------------------------------------------------------------------------------
foreach my $minfo (@TargetModuleInfo) {
    printf("ModuleName : %10s \n", $minfo->{'ModuleName'}) ;
    foreach my $pinfo (@{$minfo->{'ModulePorts'}}) {
        #printf("\tDirection : %s - Name : %s - Width %s \n", 
        printf("\t %-8s -  %-20s -  %4s \n", 
               $pinfo->{'direction'}, $pinfo->{'name'}, $pinfo->{'width'}) ; 
    }
}

#--------------------------------------------------------------------------------------------------------
sub GetPortInfo() {
    my $GetLine = shift(@_) ;
    my %PortInfo;
    my $direction ;
    my $name ;
    my $width ;

    chomp($GetLine) ;
    if($GetLine =~ /\s+\d+\)\s+(\w+)\s*:\s+(\w+)\s+\(Size:\s+(\d+)\s*\)/) {
        $direction = $1 ;
        $name      = $2 ;
        $width     = $3 ;
        #printf("Debug-001 : $1 - $2 - $3 \n") ;  # - Debug line
    } else {
        printf("E001 - Error <%s> in line : %4d - Match Failed !\n", $VerdiReportFile, $LinePC) ;
    }
    $PortInfo{'direction'} = $direction ;
    $PortInfo{'name'}      = $name ;
    $PortInfo{'width'}     = $width ;

    return(%PortInfo) ;
}

#========================================================================================================
#   Write to Excel 
#========================================================================================================
#    ($row, $col)    = xl_cell_to_rowcol('C2');  # (1, 2)
#    $str            = xl_rowcol_to_cell(1, 2);  # C2
#
my $ParseChar   = '@' ;
my $CommentChar = '#' ;
my $PageName0   = 'SubModules' ;

my $ShetHD = Spreadsheet::WriteExcel->new("$WrExcelName") ;
my $page0 = $ShetHD->add_worksheet("$PageName0") ;

my $RowPC = 0 ;
my $ColPC = 0 ;

my $HeadRowOffset = 7 ;
my $HeadColOffset = 2 ;

my $JudgementCol = 0 ;
my $ModuleInsCol = 1 ;
my $DirectionCol = 2 ;
my $WidthCol     = 3 ;
my $SigNameCol   = 4 ;
my $SigTypeCol   = 5 ;
my $AssignCol    = 6 ;
my $CommentCol   = 7 ;


#--- Create TopModule Declare Area
$page0->write(  $RowPC, $JudgementCol, $CommentChar     ) ;
$page0->write(++$RowPC, $JudgementCol, '@TopModuleName' ) ;
$page0->write(  $RowPC, $ModuleInsCol, '_TopModuleName_') ;
$page0->write(++$RowPC, $JudgementCol, $CommentChar     ) ;

#--- Create Port Declare Area
$page0->write(++$RowPC, $JudgementCol, $CommentChar     ) ;
$page0->write(++$RowPC, $JudgementCol, '#PortDeclare' ) ;
$page0->write(  $RowPC, $DirectionCol, 'Direction'    ) ;
$page0->write(  $RowPC, $WidthCol,     'Width'        ) ;
$page0->write(  $RowPC, $SigNameCol,   'PortName'     ) ;
$page0->write(  $RowPC, $SigTypeCol,   'Type'         ) ;
$page0->write(  $RowPC, $AssignCol,    'AssignWith'   ) ;
$page0->write(  $RowPC, $CommentCol,   'Comment'      ) ;
$page0->write(++$RowPC, $JudgementCol, $CommentChar   ) ;
$RowPC += $HeadRowOffset ;

#--- Create Wire Declare Area
$page0->write(++$RowPC, $JudgementCol, $CommentChar   ) ;
$page0->write(++$RowPC, $JudgementCol, '@WireField'   ) ;
$page0->write(++$RowPC, $JudgementCol, $CommentChar   ) ;
$page0->write(  $RowPC, $WidthCol,     'Width'        ) ;
$page0->write(  $RowPC, $SigNameCol,   'WireName'     ) ;
$page0->write(  $RowPC, $AssignCol,    'AssignWith'   ) ;
$page0->write(  $RowPC, $CommentCol,   'Comment'      ) ;
$RowPC += $HeadRowOffset ;

#--- Write Module Template
&WrXlsModuleTemplate($page0, $RowPC, $HeadColOffset ) ;

$ShetHD->close() ;

#---------------------------------------------------------------------------

sub WrXlsModuleTemplate() {
    my $page  = shift(@_) ;
    my $rowpc = shift(@_) ;
    my $colpc = shift(@_) ;
    my $modname ;
    my $pincnt = 0 ;
    my $pinsum = 0 ;
    my $rowbegin = $rowpc ;
    my @pintype = qw(Port Wire) ;
    my $pinbegincell ; 
    my $pinendcell ; 
    my $pinsarea ;
    my $PinsCol ;

    $PinsCol = xl_rowcol_to_cell($rowbegin, ($colpc+2)) ;
    $PinsCol =~ s/\d+//g;
    foreach my $submod (@TargetModuleInfo) {
        $modname = $submod->{'ModuleName'} ;
        
        $rowpc = ($rowbegin + $pinsum);
        $page->write(  $rowpc, $JudgementCol, $CommentChar   ) ;
        $page->write(++$rowpc, $JudgementCol, '@SubModuleName') ;
        $page->write(  $rowpc, $ModuleInsCol, "${modname}"  ) ;
        $page->write(++$rowpc, $JudgementCol, $CommentChar   ) ;
        
        $page->write(  $rowpc, $DirectionCol, 'Direction' ) ;
        $page->write(  $rowpc, $WidthCol,     'Width'     ) ;
        $page->write(  $rowpc, $SigNameCol,   'PinName'   ) ;
        $page->write(  $rowpc, $SigTypeCol,   'Type'      ) ;
        $page->write(  $rowpc, $AssignCol,    'AssignWith') ;
        $page->write(  $rowpc, $CommentCol,   'Comment'   ) ;

        $rowpc++;
        $pinbegincell = xl_rowcol_to_cell(($rowpc+$pincnt), ($colpc+2)) ;
        foreach my $pininfo (@{$submod->{'ModulePorts'}}) {
            $page->write(($rowpc+$pincnt), $DirectionCol, $pininfo->{'direction'}) ;
            $page->write(($rowpc+$pincnt), $WidthCol,     $pininfo->{'width'}    ) ;
            $page->write(($rowpc+$pincnt), $SigNameCol,   $pininfo->{'name'}     ) ;
            $page->data_validation(($rowpc+$pincnt), $SigTypeCol, { validate => 'list', 
                                                                   source   => ['Port', 'Wire'], } ) ;
            $page->write(($rowpc+$pincnt), $SigTypeCol, 'Wire') ;
            #-$page->data_validation(($rowpc+$pincnt), $AssignCol, { validate => 'list', 
            #-                                                       source   => "$PinsCol:$PinsCol", } ) ;
            $page->write(($rowpc+$pincnt), $AssignCol, '') ;
            $pincnt += 1;
        }
        $pinendcell = xl_rowcol_to_cell(($rowpc+$pincnt), $SigNameCol) ;
        if(defined $pinsarea) {
            $pinsarea .= ",$pinbegincell:$pinendcell" ;
        } else {
            $pinsarea  = "$pinbegincell:$pinendcell" ;
        }
        $pinsum    += ($pincnt + 4) ;
        $pincnt     = 0 ;
    }
    printf("$pinsarea \n");
} # WrXlsModuleTemplate


sub GetTimeSuffix() {
    my $format = shift(@_) ;
    my $time = localtime() ;
    my @timechar = split(/\s+/, $time) ;
    my $suffix ;
    
    if($format == 1) {
        $suffix = "$timechar[4]"."$timechar[1]"."$timechar[2]" ;
    } else {
        $suffix = localtime() ;
    }
    return $suffix ;
} # GetTimeSuffix


sub GetUserName() {
    my $systype = "$^O" ;

    my $UserName ;
    if($systype =~ /mswin/i) {
        $UserName = $ENV{'USERNAME'} ;
    } elsif ($systype =~ /linux/i) {
        $UserName = $ENV{'USER'} ;
    } else {
        $UserName = 'UNKOWN' ;
    }
    return $UserName ;
} # GetUserName


