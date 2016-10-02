#!/usr/bin/env perl
#===============================================================================
#
#         FILE: make_top.pl
#
#        USAGE: ./make_top.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: LongXing (LX), lxing_1988@sina.com
# ORGANIZATION: FREE
#      CREATED: 11/09/2015 10:03:00 PM
#     REVISION: 
#               r1v01 @ 20151123 
#                   - 1. Fix Some Bugs
#                   - 2. Add WriteBackExcel function 
#                   - 3. Add Port/Wire width adjust
#                   - 4. Support execute script in windows
#               r1v02 @ 20160513
#                   - 1. Add user options
#                   - 2. Add help information
#               r1v03 @ 20160528
#                   - 1. Add function : User can manual define the module's instance name  
#                   - 2. Fix Bug      : The sub module name is not write out When writing back excel 
#               r1v04 @ 20160605
#                   - 1. Add report error for PortField, WireField, SubmodulePinField name redefine.
#                   - 2. Fix comment's printing out.
#                   - 3. Add $MaxCommentLength, $SubModulePinNameWidth, $SubModuleWireNameWidth variable
#               r1v05 @ 20160723
#                   - 1. Add auto add wire width to wire name.
#                   - 2. if output assignment is __invalid__ , wire name will auto added.
#                   - 3. Add parsing and write-back excel for multi pages.
#                   - 4. BugFix .
#                   - 5. Change use utf8 -> utf8::all .
#               r1v06 @ 20160812
#                   - 1. Support print comment in a seperate line.
#                   - 2. Support parse parameter.
#                   - 3. Support print submodules in fileheader. 
#                   - 4. Add Split comment line. 
#
#
#===============================================================================

use strict;
use warnings;
use utf8::all;
use Getopt::Long ;
use Spreadsheet::Read ;
use Spreadsheet::WriteExcel ;
use Spreadsheet::WriteExcel::Utility ;


#-------------------------------------------------------------------------------------
#
#  GetModule/CreateModule = {
#     IncludeInfo => [
#           'string' , 
#     ]
#     ParamsInfo => [
#         {
#             property => 'string' , 
#             pname  => 'string' , 
#             pvalue => 'string' , 
#             comment => 'string' , 
#         }
#     ]
#     ModuleName => 'string', 
#     Ports      => [
#         {
#             property  => 'string' ,   // comment/normal/condition
#             direction => 'string' , 
#             width => 'string' , 
#             name  => 'string' , 
#             type  => 'string' , 
#             assignwith => 'string' , 
#             comment => 'string' , 
#             autoadded => '0/1'
#         }
#         ...
#     ]
#     Wires => [
#         {
#             property  => 'string' ,   // comment/normal/condition
#             type  => 'string'
#             width => 'string' , 
#             name => 'string' , 
#             assignwith => 'string' , 
#             comment => 'string' , 
#             refoutputcnt => 'number'
#         }
#         ...
#     ]
#     SubModules => [
#         {
#             DecalareName => 'string'
#             InstName => 'string'
#             ParamsInfo => [
#                 {
#                     property => 'string' , 
#                     pname  => 'string' , 
#                     pvalue => 'string' , 
#                     comment => 'string' , 
#                 }
#                 ...
#             ]
#             PinsInfo => [
#                 {
#                     property  => 'string' ,   // comment/normal
#                     direction => 'string' , 
#                     width => 'string' , 
#                     name  => 'string' , 
#                     type  => 'string' , 
#                     assignwith => 'string' , 
#                     comment => 'string' ,                    
#                 }
#                 ...
#             ]
#         }
#         ...
#     ]
#  }
#
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
my $InputXlsFile           = "ModInfo_stage1.xls"            ;     
my $suffix                 = &GetTimeSuffix(1)               ;    
my $OutputXlsFile          = "TopMod_Report_${suffix}.xls"   ;    
my $OutputModulef          = "_NULL_"                        ;    
my $logdat                 = "./CodeGenReport_${suffix}.log" ;    
my $verbose                = 0                               ;    
my $JudgementCol           = 1                               ;    
my $ModuleNameCol          = 2                               ;    
my $ModuleInstCol          = 3                               ;    
my $DirectionCol           = 3                               ;    
my $WidthCol               = 4                               ;    
my $SigNameCol             = 5                               ;    
my $PortTypeCol            = 6                               ;    
my $AssignWithCol          = 7                               ;    
my $CommentCol             = 8                               ;    
my $MaxParseCol            = $CommentCol                     ;    
my $ParseChar              = '@'                             ;    
my $ParameterChar          = '$'                             ;    
my $CommentChar            = '#'                             ;    
my $CommentPrintChar       = '%'                             ;    
my $IncludeChar            = '&'                             ;
my $GenDumyModuleEnable    = 0                               ;    
my $WriteBackExcelEnable   = 0                               ;    
my $MaxCommentLength       = 120                             ;    
my $SubModulePinNameWidth  = 30                              ;    
my $SubModuleWireNameWidth = 40                              ;    
my $VersionName            = "v1.0.5"                        ;    
my $SheetRef                                                 ;    
my $SheetPage                                                ;    
my $PageLable                                                ;    
my $numOfSheets                                              ;    
my $rowmax                                                   ;    
my $colmax                                                   ;    
my $WriteBackExcelHD                                         ;
my %GetModule                                                ;    
my %CreateModule                                             ;    
my %SubModuleInfo                                            ;    
my @SubModulePortsInfo                                       ;    
my @SubModuleParamInfo                                       ;    
#-------------------------------------------------------------------------------------
my $BlankLineStyle         = ('-' x 37)                      ;
#-------------------------------------------------------------------------------------


GetOptions("xi=s"     => \$InputXlsFile, 
           "xo=s"     => \$OutputXlsFile,
           "gdmy"     => \$GenDumyModuleEnable, 
           "wbk"      => \$WriteBackExcelEnable, 
           "help"     => \&display_help, 
          ) or die("Error in Command Options! \n") ;



# ****************************************************************************
#      Script_Entry
# ****************************************************************************
$SheetRef = ReadData("$InputXlsFile") or die ("E000 : Cannot read <$InputXlsFile> !\n") ;
$numOfSheets = $SheetRef->[0]{sheets} ;
if($WriteBackExcelEnable) {
    $WriteBackExcelHD =  Spreadsheet::WriteExcel->new("$OutputXlsFile") 
}
foreach my $sht (1 .. $numOfSheets) {
    $SheetPage = $SheetRef->[$sht]     ;
    $PageLable = $SheetPage->{'label'} ;
    if( defined $PageLable ) {
        if(($PageLable =~ m/\w+_I$/)) {
            printf("\n# %s \n", ('-' x 80)) ;
            printf("#      Parsing Page < %s > ...  \n", $PageLable) ;
            printf("# %s \n\n", ('-' x 80)) ;
            $rowmax = $SheetPage->{'maxrow'} ;
            $colmax = $SheetPage->{'maxcol'} ;
            &ParseSheet() ;
            &CreateTopModule() ;
            &PrintCreatedModule($OutputModulef) ;
            if($GenDumyModuleEnable) {
                &PrintDumySubModules() ;
            }
            if($WriteBackExcelEnable) {
                &WriteBackExcel($WriteBackExcelHD, $PageLable) ;
            }
        } else {
            printf("I000 : Ignored Page [%s] \n", $PageLable);
        }
    } 
    undef %GetModule          ; 
    undef %CreateModule       ; 
    undef %SubModuleInfo      ; 
    undef @SubModulePortsInfo ;
    undef @SubModuleParamInfo ;
}
# ****************************************************************************



#-------------------------------------------------------------------------------------
#   Sub Functions 
#-------------------------------------------------------------------------------------

sub display_help() {
    print("|=================================================================================== \n") ; 
    print("|                                                                                    \n") ; 
    print("|   ScriptName : TopMaker                                                            \n") ; 
    print("|   Version    : <$VersionName>                                                      \n") ; 
    print("|    User Options Description :                                                      \n") ; 
    print("|            -xi   ExcelFileInput  : Use User defined Excel fName to parise.         \n") ; 
    print("|            -xo   ExcelFileOutput : Use User defined Excel fName to Writeback.      \n") ; 
    print("|            -gdmy                 : Enable Generate Dumy Submodules.                \n") ; 
    print("|            -wbk                  : Enable Write Back Excel.                        \n") ; 
    print("|            -help                 : Print this Information.                         \n") ; 
    print("|                                                                                    \n") ; 
    print("|=================================================================================== \n") ; 
    exit 0 ;
} # display_help


sub ParseSheet() {
    my $ParsingGetModule = 0             ;
    my $ParsingWireField = 0             ;
    my $ParsingSubModule = 0             ;
    my $ParsingParameter = 0             ;
    my $SubModuleCounter = 0             ;
    my $InstModuleName   = '__invalid__' ;
    my $ParsingModuleName                ;
    my $PreviousSubModuleName            ;
_ROW_:
    foreach my $row (1 .. $rowmax) {
_COL_:
        foreach my $col (1 .. $colmax) {
            my $cell =  cr2cell($col, $row) ;
            my $info = &GetCell($row, $col, 0) ;
            my $ForceParseFlag = 0 ;
    
            if( $info ne '__invalid__' ) {
                if($col == 1) {
                    if($info =~ /^#/) {
                        next _ROW_ ;
                    } elsif ($info =~ m/^\@TopModulename/i) {
                        $info = &GetCell($row, $ModuleNameCol, 0) ;
                        if( $info ne '__invalid__' ) {
                            $GetModule{'ModuleName'} = $info ;
                            printf("I001 : Found TopModule name : %-30s at [ %-6s ]\n", $info, cr2cell($ModuleNameCol, $row)) ;
                        } else {
                            printf("E001 : GetModule name invalid at [%s]! \n", cr2cell($ModuleNameCol, $row)) ;
                        }
                        $ParsingGetModule = 1 ;
                        $ParsingWireField = 0 ;
                        $ParsingSubModule = 0 ;
                        $ParsingParameter = 0 ;
                        next _ROW_ ;
                    } elsif ($info =~ m/^\@wirefield/i) {
                        $ParsingGetModule = 0 ;
                        $ParsingWireField = 1 ;
                        $ParsingSubModule = 0 ;
                        $ParsingParameter = 0 ;
                        next _ROW_ ;
                    } elsif ($info =~ m/^\@submodulename/i) {
                        $info = &GetCell($row, $ModuleNameCol, 0) ;
                        if($info ne '__invalid__') {
                            $ParsingModuleName = $info ;
                            printf("I001 : Found SubModule name : %-30s at [ %-6s ]\n", $info, cr2cell($ModuleNameCol, $row)) ; 
                            if(defined $PreviousSubModuleName) {
                                $SubModuleInfo{'DecalareName'} = "$PreviousSubModuleName" ;
                                $SubModuleInfo{'InstName'}     = $InstModuleName ;
                                $SubModuleInfo{'ParamsInfo'}   = [@SubModuleParamInfo] ;
                                $SubModuleInfo{'PinsInfo'}     = [@SubModulePortsInfo] ;
                                push(@{$GetModule{SubModules}}, {%SubModuleInfo}) ;
                                undef %SubModuleInfo ;
                                undef @SubModulePortsInfo ;
                                undef @SubModuleParamInfo ;
                            }       
                            $PreviousSubModuleName = $ParsingModuleName ;
                            $InstModuleName        = &GetCell($row, $ModuleInstCol, 0) ;
                            if($InstModuleName eq '__invalid__') {
                                $InstModuleName = "u$PreviousSubModuleName" ;
                            } else {
                                #- print("I001 : Found user defined instance module name : u$ParsingModuleName -> $InstModuleName\n") ;
                            }
                        } else {
                            printf("E001 : SubModule name invalid at [%s]! \n", cr2cell($ModuleNameCol, $row)) ;
                        }
                        $ParsingGetModule  = 0 ;
                        $ParsingWireField  = 0 ;
                        $ParsingSubModule  = 1 ;
                        $ParsingParameter  = 0 ;
                        $SubModuleCounter += 1 ; 
                        next _ROW_ ;
                    } elsif($info =~ m/^%/) {
                        $ForceParseFlag = 1 ;
                    } elsif($info =~ m/^\$/) {
                        $ParsingParameter = 1 ;
                        if($ParsingGetModule) {
                            &ParseParameter($row, $col, $GetModule{'ModuleName'}, 'TOPMODULE') ;
                            #printf("Matched ParamsInfo @ %s\n", $row) ;
                        } elsif($ParsingSubModule) {
                            &ParseParameter($row, $col, $GetModule{'ModuleName'}, 'SUBMODULE') ;
                        } else {
                            printf("%s%s%s\n", 'E007 : ', "<ParseParameter> do not declare parameter in WireField ! @ ", $row) ;
                        }
                        next _ROW_ ;
                    }
                    # elsif ($info =~ m/^%/) {
                    #     $ParsingCommentLine = 1 ;
                    # elsif ($info =~ m/^\$/) {
                    #     $parsingParameterLine = 1 ;
                    # }
                }
                if(($col >= $DirectionCol) && ($col <= $MaxParseCol) || $ForceParseFlag) {
                    if($info ne '__invalid__') {
                        if($ParsingGetModule) {
                            &ParsePortInfo($row, $col, $GetModule{'ModuleName'}, 'TOPMODULE') ;
                            next _ROW_ ;
                        }
                        
                        if($ParsingWireField) {
                            &ParseWireInfo($row, $col, $GetModule{'ModuleName'}) ;
                            next _ROW_ ;
                        }
                        
                        if($ParsingSubModule) {
                            &ParsePortInfo($row, $col, $ParsingModuleName, 'SUBMODULE') ;
                            next _ROW_ ;
                        }
                    }
                }
                next _ROW_ ;
            }
        }
    }
    #--- Get the last sub module info
    $SubModuleInfo{'DecalareName'} = "$ParsingModuleName"  ;
    $SubModuleInfo{'InstName'}     = $InstModuleName       ;  
    $SubModuleInfo{'ParamsInfo'}   = [@SubModuleParamInfo] ;
    $SubModuleInfo{'PinsInfo'}     = [@SubModulePortsInfo] ;
    push(@{$GetModule{'SubModules'}}, {%SubModuleInfo})    ;
    #---
} # ParseSheet



#-------------------------------------------------------------------------------------
#

sub WriteBackExcel() {
    my $ShetHD        = shift(@_) ;
    my $PageName      = shift(@_) ;
    my $JudgementCol  = ($JudgementCol  - 1) ;
    my $ModuleNameCol = ($ModuleNameCol - 1) ;
    my $DirectionCol  = ($DirectionCol  - 1) ;
    my $WidthCol      = ($WidthCol      - 1) ;
    my $SigNameCol    = ($SigNameCol    - 1) ;
    my $SigTypeCol    = ($PortTypeCol   - 1) ;
    my $AssignWithCol = ($AssignWithCol - 1) ;
    my $CommentCol    = ($CommentCol    - 1) ;
    my $rowpc = 0 ;
    my $page = $ShetHD->add_worksheet("$PageName") ;

    #--- Create TopModule Declare Area
    $page->write(  $rowpc, $JudgementCol,  $CommentChar               ) ;
    $page->write(++$rowpc, $JudgementCol,  '@TopModuleName'           ) ;
    $page->write(  $rowpc, $ModuleNameCol, $CreateModule{'ModuleName'}) ;
    $page->write(++$rowpc, $JudgementCol,  $CommentChar               ) ;

    #--- Create Port Declare Area
    $rowpc = &WriteExcelPortsArea($page, $rowpc) ;

    #--- Create Wire Declare Area
    $rowpc = &WriteExcelWiresArea($page, $rowpc) ;

    #--- Create SubModules Declare Area
    $rowpc = &WriteExcelSubModulesArea($page, $rowpc) ;
} # WriteBackExcel


sub WriteExcelPortsArea() {
    my $page     = shift(@_) ;
    my $StartRow = shift(@_) ;
    my $rowpc = $StartRow ;
    my $JudgementCol  = ($JudgementCol  - 1) ;
    my $ModuleNameCol = ($ModuleNameCol - 1) ;
    my $DirectionCol  = ($DirectionCol  - 1) ;
    my $WidthCol      = ($WidthCol      - 1) ;
    my $SigNameCol    = ($SigNameCol    - 1) ;
    my $SigTypeCol    = ($PortTypeCol   - 1) ;
    my $AssignWithCol = ($AssignWithCol - 1) ;
    my $CommentCol    = ($CommentCol    - 1) ;
    
    #--- Create Port Declare Area
    $page->write(++$rowpc, $JudgementCol,  $CommentChar  ) ;
    $page->write(++$rowpc, $JudgementCol,  '#PortDeclare') ;
    $page->write(  $rowpc, $DirectionCol,  'Direction'   ) ;
    $page->write(  $rowpc, $WidthCol,      'Width'       ) ;
    $page->write(  $rowpc, $SigNameCol,    'PortName'    ) ;
    $page->write(  $rowpc, $SigTypeCol,    'Type'        ) ;
    $page->write(  $rowpc, $AssignWithCol, 'AssignWith'  ) ;
    $page->write(  $rowpc, $CommentCol,    'Comment'     ) ;
    $page->write(++$rowpc, $JudgementCol,  $CommentChar  ) ;    
    foreach my $port (@{$CreateModule{'Ports'}}) {
        my $direction  = $port->{'direction'} ;
        my $width      = $port->{'width'} ;
        my $name       = $port->{'name'} ;
        my $type       = $port->{'type'} ;
        my $assignwith = $port->{'assignwith'} ;
        my $comment    = $port->{'comment'} ;
        if($assignwith eq '__invalid__') {
            $assignwith = " " ;
        }
        if($comment eq '__invalid__') {
            $comment = " " ;
        }
        $page->write(++$rowpc, $DirectionCol,  $direction  ) ;
        $page->write(  $rowpc, $WidthCol,      $width      ) ;
        $page->write(  $rowpc, $SigNameCol,    $name       ) ;
        $page->write(  $rowpc, $SigTypeCol,    'Port'      ) ;
        $page->write(  $rowpc, $AssignWithCol, $assignwith ) ;
        $page->write(  $rowpc, $CommentCol,    $comment    ) ;
    }
    return $rowpc ;
} # WriteExcelPortsArea


sub WriteExcelWiresArea() {
    my $page     = shift(@_) ;
    my $StartRow = shift(@_) ;
    my $rowpc = $StartRow ;
    my $JudgementCol  = ($JudgementCol  - 1) ;
    my $ModuleNameCol = ($ModuleNameCol - 1) ;
    my $DirectionCol  = ($DirectionCol  - 1) ;
    my $WidthCol      = ($WidthCol      - 1) ;
    my $SigNameCol    = ($SigNameCol    - 1) ;
    my $SigTypeCol    = ($PortTypeCol   - 1) ;
    my $AssignWithCol = ($AssignWithCol - 1) ;
    my $CommentCol    = ($CommentCol    - 1) ;

    #--- Create Wire Declare Area
    $page->write(++$rowpc, $JudgementCol,  $CommentChar ) ;
    $page->write(++$rowpc, $JudgementCol,  '@WireField' ) ;
    $page->write(++$rowpc, $JudgementCol,  $CommentChar ) ;
    $page->write(  $rowpc, $DirectionCol,  '---------'  ) ;
    $page->write(  $rowpc, $WidthCol,      'Width'      ) ;
    $page->write(  $rowpc, $SigNameCol,    'WireName'   ) ;
    $page->write(  $rowpc, $SigTypeCol,    '----'       ) ;
    $page->write(  $rowpc, $AssignWithCol, 'AssignWith' ) ;
    $page->write(  $rowpc, $CommentCol,    'Comment'    ) ;
    foreach my $wire (@{$CreateModule{'Wires'}}) {
        my $width      = $wire->{'width'} ;
        my $name       = $wire->{'name'} ;
        my $assignwith = " " ;
        if(exists $wire->{'assignwith'}) {
            $assignwith = $wire->{'assignwith'} ;
        }
        my $comment    = $wire->{'comment'} ;
        if($assignwith eq '__invalid__') {
            $assignwith = " " ;
        }
        if($comment eq '__invalid__') {
            $comment = " " ;
        }
        $page->write(++$rowpc, $WidthCol,      $width      ) ;
        $page->write(  $rowpc, $SigNameCol,    $name       ) ;
        $page->write(  $rowpc, $SigTypeCol,    ' '         ) ;
        $page->write(  $rowpc, $AssignWithCol, $assignwith ) ;
        $page->write(  $rowpc, $CommentCol,    $comment    ) ;
    }
    return $rowpc ;
} # WriteExcelWiresArea


sub WriteExcelSubModulesArea() {
    my $page     = shift(@_) ;
    my $StartRow = shift(@_) ;
    my $rowpc = $StartRow ;
    my $JudgementCol  = ($JudgementCol  - 1) ;
    my $ModuleNameCol = ($ModuleNameCol - 1) ;
    my $DirectionCol  = ($DirectionCol  - 1) ;
    my $WidthCol      = ($WidthCol      - 1) ;
    my $SigNameCol    = ($SigNameCol    - 1) ;
    my $SigTypeCol    = ($PortTypeCol   - 1) ;
    my $AssignWithCol = ($AssignWithCol - 1) ;
    my $CommentCol    = ($CommentCol    - 1) ;

    foreach my $module (@{$CreateModule{'SubModules'}}) {
        my $decalarename = $module->{'DecalareName'} ;
        my $instancename = $module->{'InstName'} ;
        #--- Create SubModule Declare Area
        $page->write(++$rowpc, $JudgementCol,  $CommentChar      ) ;
        $page->write(++$rowpc, $JudgementCol,  '@SubModuleName'  ) ;
        $page->write(  $rowpc, $ModuleNameCol, $decalarename     ) ;
        $page->write(  $rowpc, ($ModuleInstCol-1), $instancename ) ;
        $page->write(++$rowpc, $JudgementCol,  $CommentChar      ) ;
        $page->write(  $rowpc, $DirectionCol,  'Direction'       ) ;
        $page->write(  $rowpc, $WidthCol,      'Width'           ) ;
        $page->write(  $rowpc, $SigNameCol,    'PinName'         ) ;
        $page->write(  $rowpc, $SigTypeCol,    'Type'            ) ;
        $page->write(  $rowpc, $AssignWithCol, 'AssignWith'      ) ;
        $page->write(  $rowpc, $CommentCol,    'Comment'         ) ;
        foreach my $pin (@{$module->{'PinsInfo'}}) {
            my $direction  = $pin->{'direction'} ;
            my $width      = $pin->{'width'} ;
            my $name       = $pin->{'name'} ;
            my $type       = $pin->{'type'} ;
            my $assignwith = $pin->{'assignwith'} ;
            my $comment    = $pin->{'comment'} ;
            my $width_new = $width ;

            if($width > 1) {
                $width_new = '['.($width-1).':0]' ;
            } else {
                $width_new = " " ;
            }
            if($assignwith eq '__invalid__') {
                if( ($direction =~ m/output/i) or ($direction =~ m/inout/i) ) {
                    $assignwith = "$name"."$width_new" ;
                } elsif($width > 1) {
                    $assignwith = "$name"."$width_new" ;
                } 
            } 
            if($comment eq '__invalid__') {
                $comment = " " ;
            }
            $page->write(++$rowpc, $DirectionCol,  $direction  ) ;
            $page->write(  $rowpc, $WidthCol,      $width      ) ;
            $page->write(  $rowpc, $SigNameCol,    $name       ) ;
            $page->write(  $rowpc, $SigTypeCol,    $type       ) ;
            $page->write(  $rowpc, $AssignWithCol, $assignwith ) ;
            $page->write(  $rowpc, $CommentCol,    $comment    ) ;
        }
    }
    return $rowpc ;
} # WriteExcelSubModulesArea


sub PrintDumySubModules() {
    my @SubModules = @{$CreateModule{'SubModules'}} ;
    foreach my $module (@SubModules) {
        my $ModuleName = $module->{'DecalareName'} ;
        my $pinscnt = 0 ;
        my $space4 = (" " x 4) ;
        my @dumy ;
        open(my $FH, '>', "${ModuleName}.v") or die("Error : %!") ;

        &PrintFileHeader($FH, ${ModuleName}, \@dumy) ;
        printf $FH ("module %s ( \n", $ModuleName) ;
        
        SUBMODULE_LOOP:
        foreach my $pin (@{$module->{'PinsInfo'}}) {
            my $property  = $pin->{'property'} ;
            my $direction = $pin->{'direction'} ;
            my $name      = $pin->{'name'} ;
            my $width     = $pin->{'width'} ;
            my $comment   = $pin->{'comment'} ;
            if($property eq 'comment') {
                next SUBMODULE_LOOP ;
            }
            #printf("DEBUG : $ModuleName - $direction - $name - $width \n");
            $pinscnt++ ;
            if($pinscnt > 1) {
                printf $FH ("%s, ", $space4) ;
            } else {
                printf $FH ("%s  ", $space4) ;
            }
            if($width > 1) {
                $width = '['.($width-1).':0]' ;
            } else {
                $width = " " ;
            }
            printf $FH ("%-6s", lc($direction)) ;
            printf $FH ("%s%10s", $space4, $width) ;
            printf $FH ("%s%-30s", $space4, $name) ;
            if($comment ne '__invalid__') {
                printf $FH ("%s%s%s\n", $space4, '// ', $comment) ;
            }
            printf $FH ("%s\n", " ") ;
        }
        printf $FH (") ; \n") ;
        printf $FH ("\n") ;
        printf $FH ("// This is a dumy module") ;
        printf $FH ("\n\n") ;
        &PrintParameterField($FH, $module->{'ParamsInfo'}, 'TOPMODULE', '__invalid__') ;
        printf $FH ("endmodule // %s \n", $ModuleName) ;
        
        close($FH) or die("Error : $!") ; 
    }
} # PrintDumySubModules


sub PrintCreatedModule() {
    my $PutFile = shift(@_) ;
    my $TopModuleName = $CreateModule{'ModuleName'} ;
    my $PutFileName = "${TopModuleName}.v" ;
    my $distf ;
    my $FH ;

    if($PutFile ne '_NULL_') {
        $distf = $PutFile ;
    } else {
        $distf = $PutFileName ;
    }
    open($FH, '>', $distf) or die ("Error : $!");

    &PrintFileHeader($FH, $TopModuleName, $CreateModule{'SubModules'}) ;
    printf $FH ("\n") ;
    printf $FH ("module %s ( \n", $TopModuleName) ;
    &PrintPortField($FH, $CreateModule{'Ports'}) ;
    &PrintParameterField($FH, $CreateModule{'ParamsInfo'}, 'TOPMODULE', '__invalid__') ;
    &PrintWireField($FH, $CreateModule{'Wires'}) ;
    &PrintPortAssignment($FH, $CreateModule{'Ports'}, $CreateModule{'Wires'}) ;
    &PrintSubModuleField($FH, $CreateModule{'SubModules'}) ;
    printf $FH ("\nendmodule // %s\n", $TopModuleName) ;
    
    close($FH) or die ("Error : $!") ;
} # PrintCreatedModule


sub PrintPortAssignment() {
    my $FH        = shift(@_) ;
    my $portsref  = shift(@_) ;
    my $wiresref  = shift(@_) ;

    foreach my $port (@{$portsref}) {
        my $property   = $port->{'property'} ;
        my $assignwith = $port->{'assignwith'} ;
        my $pname      = $port->{'name'} ;
        my $pwidth     = $port->{'width'} ;
        if(($property ne 'comment') && ($assignwith ne '__invalid__')) {
            my $foundflag = 0 ;
            foreach my $wire (@{$wiresref}) {
                my $asname = $assignwith ;
                my $wname  = $wire->{'name'} ;
                $wname =~ s/\[.*\]//g ;
                $asname =~ s/\[.*\]//g ;
                if($asname eq $wname) {
                    $foundflag = 1
                }
            }
            if($foundflag == 1) {
                if($pwidth == 1) {
                    $pwidth = "" ;
                } else {
                    $pwidth = ('[' . ($pwidth-1) . ':' . '0' . ']') ;
                }
                printf $FH ("assign %-20s = %-30s ; \n", ($pname . $pwidth), $assignwith) ;
            } else {
                printf("E003 : Ports assigned a wire not in WireField!  [%s.%s] \n", $pname, $assignwith);
            }
        }

    }

    printf $FH ("\n") ;


} # PrintPortAssignment



sub PrintSubModuleField() {
    my $FH            = shift(@_) ;
    my $SubModuleInfo = shift(@_) ;
    my $space4    = (" " x 4) ;
    my $space2    = (" " x 2) ;
    my $pincnt    = 0 ; 
    printf $FH ("\n") ;
    foreach my $module (@{$SubModuleInfo}) {
        my $DecalareName = $module->{'DecalareName'} ;
        my $InstName     = $module->{'InstName'} ;

        print  $FH ("\n\n\n") ;
        printf $FH ("// %s \n", ('*' x 100)) ;
        printf $FH ("// Inst [ %s ] -> < %s > \n", $DecalareName, $InstName) ;
        printf $FH ("// %s \n", ('*' x 100)) ;

        &PrintParameterField($FH, $module->{'ParamsInfo'}, 'SUBMODULE', $InstName) ;
        printf $FH ("\n%s %s (\n", $DecalareName, $InstName) ;
        foreach my $pin (@{$module->{'PinsInfo'}}) {
            my $property   = $pin->{'property'} ;
            my $direction  = $pin->{'direction'} ;
            my $width      = $pin->{'width'} ;
            my $name       = $pin->{'name'} ;
            my $type       = $pin->{'type'} ;
            my $assignwith = $pin->{'assignwith'} ;
            my $comment    = $pin->{'comment'} ;
            my $widthorg   = $width ;
            my $partwireflag = 0 ;

            if($property eq 'normal') {
                if($assignwith =~ m/(\[.*\])|(\d+'[bhd]\w+)|(\{.*\})/) {
                    $partwireflag = 1 ;
                }
                if($assignwith =~ m/([\+\-\*\\><])|(==)/) {
                    printf("E003 : Illegal Wire Connection(Glue Logic) : %s.%s.%s!\n", $InstName, $name, "[$assignwith]") ;
                }
                if($direction =~ /input/i) {
                    $direction = 'I' ;
                } elsif ($direction =~ /output/i) {
                    $direction = 'O' ;
                } elsif ($direction =~ /inout/i) {
                    $direction = 'IO' ;
                } else {
                    printf("E003 : Pin direction [%s.%s-%s] is illegal！\n", $InstName, $name, $direction) ;
                }
                $pincnt++ ;
                if($width > 1) {
                    $width = '['.($width-1).':0]' ;
                } else {
                    $width = " " ;
                }
                if($pincnt > 1) {
                    printf $FH ("%s, ", $space4) ;
                } else {
                    printf $FH ("%s  ", $space4) ;
                }
                printf $FH (".%-${SubModulePinNameWidth}s", $name) ;
                if($type =~ /wire/i) {
                    if(($assignwith eq '__invalid__') and (($direction eq 'O') or ($direction eq 'IO'))) {
                        $assignwith = "$name"."$width" ;
                    } elsif(!($assignwith eq '__invalid__') and (!$partwireflag) and ($pin->{'width'} > 1) ) {
                        $assignwith = "$assignwith"."$width" ;
                    } elsif( $assignwith eq '__invalid__'  ) {
                        $assignwith = "/* Floating */" ;
                    }
                    printf $FH ("%s( %-${SubModuleWireNameWidth}s )", $space4, $assignwith) ;
                } elsif ($type =~ /port/i) {
                    printf $FH ("%s( %-${SubModuleWireNameWidth}s )", $space4, "${name}"."${width}") ;
                } else {
                    printf("E003 ： [%s.%s-%s] type is illegal.\n", $InstName, $name, $type) ;
                }
                printf $FH ("%s // %-4s %s", $space4, "${direction}_${widthorg}", $space2) ;
                if($comment ne '__invalid__') {
                    $comment =~ s/\R/ /g ;   # replace enter to space
                    if(length($comment) > $MaxCommentLength) {
                        print $FH ("\n") ;
                    } else {
                        printf $FH (" - %-s \n", $comment) ;
                    }
                } else {
                    print $FH ("\n") ;
                }
            } elsif($property eq 'comment') {
                if($comment eq '__invalid__') {
                    printf $FH ("%s %s\n", '//', $BlankLineStyle) ;
                } else {
                    printf $FH ("%s %s\n", '//', $comment) ;
                }
            } else {
                printf("%s%s\n", 'E007 : ', "<PrintSubModuleField.property> illegal variable");
            }
        }
        printf $FH (") ; // %s\n", $InstName);
        $pincnt = 0 ;
    }
} # PrintSubModuleField


sub PrintWireField() {
    my $FH        = shift(@_) ;
    my $WireInfo  = shift(@_) ;
    my $space4    = (" " x 4) ;
    my %WireNames ;

    print  $FH ("\n" ) ;
    printf $FH ("// %s \n", ('-' x 100)) ;
    printf $FH ("// %s \n", "Local WireField") ;
    printf $FH ("// %s \n", ('-' x 100)) ;
    foreach my $wire (@{$WireInfo}) {
        my $property = $wire->{'property'} ;
        my $width    = $wire->{'width'} ;
        my $name     = $wire->{'name'} ;
        my $comment  = $wire->{'comment'} ;
        my $partwireflag = 0 ;

        if($property eq 'normal') {
            if($name =~ m/(\[.*\])|(\d+'[bhd]\w+)|(\{.*\})/) {
                $partwireflag = 1 ;
            }
            $name =~ s/\[.*\]//g ;
            $WireNames{"$name"}++ ;

            if($width > 1) {
                $width = '['.($width-1).':0]' ;
            } else {
                $width  = " ";
            }
            if($WireNames{"$name"} == 1) {
                printf $FH ("wire") ;
                printf $FH ("%s%10s", $space4, $width) ;
                printf $FH ("%s%-30s ;", $space4, $name) ;
                if($comment ne '__invalid__') {
                    printf $FH ("%s%s\n", $space4, "// $comment") ;
                } else {
                    printf $FH ("%s%s\n", $space4, "// ") ;
                }
            }
        } elsif ($property eq 'comment') {
            if($comment eq '__invalid__') {
                printf $FH ("%s %s\n", '//', $BlankLineStyle) ;
            } else {
                printf $FH ("%s%s\n", '// ', $comment) ;
            }
        } else {
           printf("%s%s\n", 'E007 : ', "<PrintWireField.property> illegal variable")
        }
    }
    printf $FH ("\n\n") ;
    foreach my $wire (@{$WireInfo}) {
        if(exists $wire->{'assignwith'}) {
            my $name       = $wire->{'name'} ;
            my $assignwith = $wire->{'assignwith'} ;
            my $comment    = $wire->{'comment'} ;
            if($comment eq '__invalid__') {
                $comment = "" ;
            }
            if($assignwith ne '__invalid__') {
                printf $FH ("assign ") ;
                printf $FH ("%30s = ", $name) ;
                printf $FH ("%-40s ;", $assignwith) ;
                printf $FH (" // %s\n", $comment) ;
            }
        }
    }
} # PrintWireField

sub PrintParameterField() {
    my $FH        = shift(@_) ;
    my $ParamInfo = shift(@_) ;
    my $type      = shift(@_) ;
    my $instname  = shift(@_) ;
    if(@{$ParamInfo} > 0) {
        if($type eq "TOPMODULE") {
            printf $FH ("\n\n// %s\n", ('-' x 80)) ;
            printf $FH ("// %s\n", "Parameter Field") ;
            printf $FH ("// %s\n", ('-' x 80)) ;
            foreach my $param (@{$ParamInfo}) {
                my $pname   = $param->{'pname'} ;
                my $pvalue  = $param->{'pvalue'} ;
                my $comment = $param->{'comment'} ;
                unless(($pname eq '__invalid__') || ($pvalue eq '__invalid__')) {
                    printf $FH ("parameter %${SubModulePinNameWidth}s = %${SubModuleWireNameWidth}s ;", $pname, $pvalue) ;
                    unless($comment eq '__invalid__') {
                        printf $FH (" // %s\n", $comment) ;
                    } else {
                        printf $FH (" %s \n", '// ') ;
                    }
                } else {
                    printf("%s<%s>%s\n", 'E007 : ', "TopModule", "- parameters defines error") ;
                }
            }
            printf $FH ("// %s\n\n\n", ('-' x 80)) ;
        } elsif($type eq "SUBMODULE") {
            printf $FH ("\n// %s\n", ('-' x 50)) ;
            printf $FH ("//       < %s > Parameters \n", "$instname") ;
            printf $FH ("// %s\n", ('-' x 50)) ;
            foreach my $param (@{$ParamInfo}) {
                my $pname   = $param->{'pname'} ;
                my $pvalue  = $param->{'pvalue'} ;
                my $comment = $param->{'comment'} ;
                unless(($pname eq '__invalid__') || ($pvalue eq '__invalid__')) {
                    printf $FH ("defparam %${SubModulePinNameWidth}s = %${SubModuleWireNameWidth}s ;", "${instname}.${pname}", $pvalue) ;
                } else {
                    printf("%s<%s>%s\n", 'E007 : ', "$instname", "- parameters defines error") ;
                }
                unless($comment eq '__invalid__') {
                    printf $FH (" // %s\n", $comment) ;
                } else {
                    printf $FH (" %s \n", '// ') ;
                } 
            }
        } else {
            printf("%s%s\n", "E007 : ", "<PrintParameterField.type> variable illegal!") ;
        }
    }
} # PrintParameterField

sub PrintPortField() {
    my $FH       = shift(@_) ;
    my $PortInfo = shift(@_) ;
    my $portcnt  = 0 ;
    my $space4   = (" " x 4) ;
    my %PortNames ;

    foreach my $port (@{$PortInfo}) {
        my $property   = $port->{'property'} ;
        my $direction  = $port->{'direction'} ;
        my $width      = $port->{'width'} ;
        my $name       = $port->{'name'} ;
        my $comment    = $port->{'comment'} ;

        if($property eq 'normal') {
            if( $PortNames{"$name"}++ > 1) {
                printf("E003 : PortField - Port Name Redefined <%s> !\n", $name);
            } 
            $portcnt++ ;
            if($width > 1) {
                $width = '['.($width-1).':0]' ;
            } else {
                $width  = " ";
            }
            if($portcnt > 1) {
                printf $FH ("%s, ", $space4);
            } else {
                printf $FH ("%s  ", $space4);
            }
            printf $FH ("%-6s", lc($direction)) ;
            printf $FH ("%10s", $width) ;
            printf $FH ("%s%-40s", $space4, $name) ;
            if($comment ne '__invalid__') {
                printf $FH ("%s%s", $space4, "// $comment") ;
            } else {
                printf $FH ("%s%s", $space4, "// ") ;
            }
            printf $FH ("\n") ;
        } elsif($property eq 'comment') {
            if($comment eq '__invalid__') {
                printf $FH ("%s %s\n", '//', $BlankLineStyle) ;
            } else {
                printf $FH ("%s %s\n", '// ', "$comment") ;
            }
        } else {
            printf ("%s%s\n", 'E007 : ', "<PrintPortField.property> illegal variable") ;
        }

    }
    printf $FH (") ; \n") ;
} # PrintPortField


sub PrintFileHeader() {
    my $distf      = shift(@_) ;
    my $modulename = shift(@_) ;
    my $submodules = shift(@_) ;
    my $linewidth  = 80 ;
    my $author     = &GetUserName() ;
    my $datetime   = &GetTimeSuffix(0) ;
    
    printf $distf ("// %s\n", ('=' x $linewidth)) ;
    printf $distf ("//  Module Name      : %s \n", $modulename ) ;
    printf $distf ("//  Generated By     : %s \n", $author     ) ;
    printf $distf ("//  TopMaker Version : %s \n", $VersionName) ;
    printf $distf ("//  Environment OS   : %s \n", "$^O"       ) ;
    printf $distf ("//  Date             : %s \n", $datetime   ) ;
    if(@{$submodules} > 0) {
        printf $distf ("// %s\n", ('-' x $linewidth)) ;
        printf $distf ("// %s\n", "SubModule Informations") ;
        printf $distf ("// %s\n", ('-' x $linewidth)) ;
        &PrintSubModuleInfo($distf, $submodules) ;
    }
    printf $distf ("// %s\n", ('=' x $linewidth)) ;
    printf $distf ("\n") ;
} # PrintFileHeader

sub PrintSubModuleInfo() {
    my $FH         = shift(@_) ;
    my $submodules = shift(@_) ;
    my $NameWidth  = 36  ;
    my $InstWidth  = 30  ;
    my $counter    = 0   ;
    if(@{$submodules} > 0) {
        foreach my $module (@{$submodules}) {
            $counter++ ;
            my $decname = $module->{'DecalareName'} ;
            my $insname = $module->{'InstName'};
            printf $FH ("// [%4d] %${NameWidth}s -> %${InstWidth}s\n", $counter, $decname, $insname) ;
        }
    }
}

sub CreateTopModule() {
    $CreateModule{'ModuleName'} = $GetModule{'ModuleName'} ;
    $CreateModule{'ParamsInfo'} = &CreateParamsField()     ;
    $CreateModule{'Ports'}      = &CreatePortsField()      ;
    $CreateModule{'Wires'}      = &CreateWireField()       ;
    $CreateModule{'SubModules'} = &CreateSubModuleField()  ;
} # CreateTopModule


sub CreateParamsField() {
    if(exists $GetModule{'ParamsInfo'}) {
        return [@{$GetModule{'ParamsInfo'}}] ;
    } else {
        return [] ;
    }
}

sub CreatePortsField() {
    my @PortsInfo ;
    foreach my $port (@{$GetModule{'Ports'}}) {
        push(@PortsInfo, $port) ;
    }
    foreach my $module (@{$GetModule{'SubModules'}}) {
        foreach my $pin (@{$module->{'PinsInfo'}}) {
            if(($pin->{'type'} =~ /port/i) && ($pin->{'property'} eq 'normal')) {
                my $sameportname = 0 ;
                my $portwidth = $pin->{'width'} ;
                foreach my $port (@PortsInfo) {
                    if($port->{'name'} eq $pin->{'name'}) {
                        $sameportname = 1 ;
                    }
                }
                if($pin->{'assignwith'} ne '__invalid__') {
                    printf("E001 : CreatePortsField decalared port should not be assigned with wire <%s.%s>\n", 
                        $module->{'InstName'}, $pin->{'name'}) ;
                }
                foreach my $chkmod (@{$GetModule{'SubModules'}}) {
                    foreach my $chkpin (@{$chkmod->{'PinsInfo'}}) {
                        if($chkpin->{'name'} eq $pin->{'name'}) {
                            # Adjust port width
                            if($chkpin->{'width'} > $portwidth) {
                                printf("I001 : Adjust PortWidth <%s> %4d->%-4d\n", 
                                    $pin->{'name'}, $portwidth, $chkpin->{'width'}) ;
                                $portwidth = $chkpin->{'width'} ;
                            }
                            # check [output]<->[output]
                            if(($chkpin->{'type'} =~ /port/i) & ($chkmod->{'InstName'} ne $module->{'InstName'})) {
                                if(($chkpin->{'direction'} =~ /output/i) & ($pin->{'direction'} =~ /output/i)) {
                                    printf("E001 : Error Port [output]<->[output] - %s.%s<->%s.%s\n", 
                                        $module->{'InstName'}, $pin->{'name'}, $chkmod->{'InstName'}, $chkpin->{'name'}) ;
                                }
                            }
                        }
                    }
                }
                unless($sameportname) {
                    my %PortInfo ;
                    $PortInfo{'autoadded'}  = 1 ;
                    $PortInfo{'property'}   = 'normal' ;
                    $PortInfo{'direction'}  = $pin->{'direction'} ;
                    $PortInfo{'width'}      = $portwidth ;
                    $PortInfo{'name'}       = $pin->{'name'} ;
                    $PortInfo{'type'}       = $pin->{'type'} ;
                    $PortInfo{'assignwith'} = '__invalid__' ;
                    $PortInfo{'comment'}    = $pin->{'comment'} ;
                    push(@PortsInfo, {%PortInfo}) ;
                }
            }
        }
    }
    return [@PortsInfo] ;
} # CreatePortsField


sub CreateWireField() {
    my @WireInfo ;

    foreach my $wire (@{$GetModule{'Wires'}}) {
        push(@WireInfo, $wire) ;
    }

    foreach my $module (@{$GetModule{'SubModules'}}) {
        foreach my $pin (@{$module->{'PinsInfo'}}) {
            if(($pin->{'type'} =~ m/wire/i) && ($pin->{'property'} eq 'normal')) {
                my %SubmWireInfo ;
                my $assignwith = $pin->{'assignwith'} ;
                my $partwireflag = 0 ;
                if($assignwith =~ m/(\[.*\])|(\d+'[bhd]\w+)|(\{.*\})/) {
                    $partwireflag = 1 ;
                }
                $assignwith =~ s/\[.*\]//g ;
                if($assignwith ne '__invalid__') {
                    my $connectedport = 0 ;
                    my $samewirename  = 0 ;
                    my $wirewidth     = $pin->{'width'} ;
                    foreach my $wire (@WireInfo) {
                        if($assignwith eq $wire->{'name'}) {
                            $samewirename = 1 ;
                        }
                    }
                    foreach my $port (@{$CreateModule{'Ports'}}) {
                        if($port->{'name'} eq $assignwith) {
                            $connectedport = 1 ;
                            if($pin->{'direction'} =~ /output/i) {
                                if ($port->{'direction'} =~ /input/i) {
                                    printf("E001 : [Sub_output]<->[Top_input] %s.%s-%s\n", 
                                        $module->{'InstName'}, $pin->{'name'}, $assignwith) ;
                                }
                                if($port->{'autoadded'}) {
                                    printf("E001 : Connected by multi driver at port <%s>.\n", $port->{'name'}) ;
                                }
                            }
                        }
                    }
                    foreach my $chkmod (@{$GetModule{'SubModules'}}) {
                        foreach my $chkpin (@{$chkmod->{'PinsInfo'}}) {
                            if($chkmod->{'InstName'} ne $module->{'InstName'}) {
                                if($chkpin->{'name'} eq $assignwith) {
                                    # Adjust wire width
                                    if(($chkpin->{'width'} > $wirewidth) and (!$samewirename) and (!$partwireflag)) {
                                        printf("I001 : Adjust WireWidth <%s> %4d->%-4d\n", 
                                            $assignwith, $wirewidth, $chkpin->{'width'}) ;
                                        $wirewidth = $chkpin->{'width'} ;
                                    }
                                }
                                # check [output]<->[output]
                                my $assignwith_chk = $chkpin->{'assignwith'} ;
                                my $type_chk       = $chkpin->{'type'} ;
                                $assignwith_chk    =~ s/\[.*\]//g ;
                                if($assignwith_chk eq $assignwith) {
                                    if(($chkpin->{'direction'} =~ m/output/i) and ($pin->{'direction'} =~ m/output/i)) {
                                        printf("E001 : [output]<->[output] - %s.%s<->%s.%s\n", 
                                            $module->{'InstName'}, $pin->{'name'}, $chkmod->{'InstName'}, $chkpin->{'name'}) ;
                                    }
                                }
                            }
                        }
                    }
                    unless( ($connectedport||$samewirename) ) {
                        if($assignwith =~ /^\w+$/) {
                            $SubmWireInfo{'property'} = 'normal' ;
                            $SubmWireInfo{'width'}    = $wirewidth ;
                            $SubmWireInfo{'name'}     = $assignwith ;
                            $SubmWireInfo{'comment'}  = $pin->{'comment'} ;
                            push(@WireInfo, {%SubmWireInfo}) ;
                        }
                    }
                } elsif( (($pin->{'direction'} =~ /output/i) or ($pin->{'direction'} =~ /inout/i)) and ($assignwith eq '__invalid__') ) {
                    # check [output]<->[output]
                    foreach my $chkmod (@{$GetModule{'SubModules'}}) {
                        foreach my $chkpin (@{$chkmod->{'PinsInfo'}}) {
                            if($chkmod->{'InstName'} ne $module->{'InstName'}) {
                                my $assignwith_chk = $chkpin->{'assignwith'} ;
                                my $direction_chk  = $chkpin->{'direction'} ;
                                $assignwith_chk    =~ s/\[.*\]//g ;
                                if(($assignwith_chk eq '__invalid__') or ($assignwith_chk eq $pin->{'name'})) {
                                    if(($chkpin->{'name'} eq $pin->{'name'}) and ($direction_chk =~ m/output/i) and ($pin->{'direction'} =~ m/output/i)) {
                                        printf("E001 : [output]<->[output] - %s.%s<->%s.%s\n", 
                                            $module->{'InstName'}, $pin->{'name'}, $chkmod->{'InstName'}, $chkpin->{'name'}) ;
                                    }

                                }
                            }
                        }
                    }
                    $SubmWireInfo{'property'} = 'normal' ;
                    $SubmWireInfo{'width'}   = $pin->{'width'} ;
                    $SubmWireInfo{'name'}    = $pin->{'name'} ;
                    $SubmWireInfo{'comment'} = $pin->{'comment'} ;
                    push(@WireInfo, {%SubmWireInfo}) ;
                } elsif($pin->{'direction'} =~ /input/i) {
                    printf("E003 : <%s.%s> Input is floating! \n", $module->{'DecalareName'}, $pin->{'name'}) ;
                }
            }
        }
    }
    return [@WireInfo] ;
} # CreateWireField


sub CreateSubModuleField() {
    my @SubModules ;
    foreach my $module (@{$GetModule{'SubModules'}}) {
        push(@SubModules, $module) ;
    }
    return [@SubModules] ;
} # CreateSubModuleField


sub GetCell() {
    my $getrow     = shift(@_) ;
    my $getcol     = shift(@_) ;
    my $keepformat = shift(@_) ;
    my $gcell = cr2cell($getcol, $getrow) ;
    my $getinfo ;
    if( &ValidCell($gcell) ) {
        $getinfo = $SheetPage->{$gcell} ;
        unless($keepformat) {
            chomp($getinfo) ;
            $getinfo =~ s/\R+|\s+//g ;
        }
        return $getinfo
    } else {
        return '__invalid__' ;
    }
} # GetCell


sub ValidCell() {
    my $cell = shift(@_) ;
    if(defined $SheetPage->{$cell}) {
        if($SheetPage->{$cell} =~ /^\s*$/) {
            return 0
        } else {
            return 1 ;
        }
    } else {
        return 0 ;
    }
} # ValidCell


sub CheckDirectionCell() {
    my $info = shift(@_) ;
    unless($info =~ /^\binput\b|\boutput\b|\binout\b$/i) {
        return 0 ;
    } else {
        return 1 ;
    }
} # CheckDirectionCell


sub CheckWidthCell() {
    my $info = shift(@_) ;
    unless($info =~ /^\b\d+\b$/i) {
        return 0 ;
    } else {
        return 1 ;
    }
} # CheckWidthCell


sub CheckPNameCell() {
    my $info = shift(@_) ;
    unless($info =~ /^\w+$/) {
        return 0 ;
    } else {
        return 1 ;
    }
} # CheckPNameCell


sub CheckPTypeCell() {
    my $info = shift(@_) ;
    unless($info =~ /^\bport\b|\bwire\b$/i) {
        return 0 ;
    } else {
        return 1 ;
    }
} # CheckPTypeCell


sub CheckAssignCell() {
    my $assignwith = shift(@_) ;
    my $address    = shift(@_) ;
    #if($assignwith =~ m/[\+\-\*\\]/i) {
    #    printf("W001 : Comment string length extends %d words, will be ignored ! at [%s] \n", $MaxCommentLength, $address) ;
    #    return 0 ;
    #}
    #  T.B.D 
    return 1 ;
} # CheckAssignCell


sub CheckCommentCell() {
    my $comment = shift(@_) ;
    my $address = shift(@_) ;
    if(length($comment) > $MaxCommentLength) {
        printf("W001 : Comment string length extends %d words, will be ignored ! at [%s] \n", $MaxCommentLength, $address) ;
    }
    return 1 ;
} # CheckCommentCell


sub CheckRedeclare() {
    my $CheckArray = shift(@_) ;
    my $CheckName  = shift(@_) ;
    my %CheckerH               ;
    my $CheckerFlag = 0        ;
    foreach my $info (@{$CheckArray}) {
        my $name = $info->{'name'} ;
        $CheckerH{"$name"} += 1 ;
        if("$name" eq "$CheckName") {
            $CheckerFlag = 1 ;
        }
    }
    return $CheckerFlag ;
} # CheckRedeclare


sub ParseWireInfo() {
    my $row        = shift(@_) ;
    my $col        = shift(@_) ;
    my $modulename = shift(@_) ;
    my $width ;
    my $name ;
    my $assignwith ;
    my $comment ;
    my %WireInfo ;
    my $errcnt = 0 ;
    my $judgement ;
    my $property ;

    $judgement = &GetCell($row,  $JudgementCol, 0) ;
    if($judgement =~ m/^%/) {
        $property = "comment" ;
    } else {
        $property = "normal" ;
    }
    
    if($property eq "normal") {
        $width = &GetCell($row, $WidthCol, 0) ;
        unless( &CheckWidthCell($width) ) {
            printf("E002 : Illegal Wire width <%s> - [integer(dec)] at |%s|.\n", 
                      $width, cr2cell($WidthCol, $row)) ;
            $errcnt++ ;
        }
        $name = &GetCell($row, $SigNameCol, 0) ;
        unless( &CheckPNameCell($name) ) {
            printf("E002 : Illegal Wire name <%s> - [string] at |%s|.\n", 
                      $name, cr2cell($SigNameCol, $row)) ;
            $errcnt++ ;
        }
        $assignwith = &GetCell($row, $AssignWithCol, 1) ;
        unless( &CheckAssignCell($assignwith, cr2cell($SigNameCol, $row)) ) {
            printf("E002 : Illegal Wire assign <%s> - [string] at |%s|.\n", 
                             $assignwith, cr2cell($AssignWithCol, $row)) ;
            $errcnt++ ;
        }
        $comment = &GetCell($row, $CommentCol, 1) ;
        unless( &CheckCommentCell($comment, cr2cell($CommentCol, $row)) ) {
            printf("E002 : Illegal Comment <%s> - [string] at |%s|.\n", 
                             $comment, cr2cell($CommentCol, $row)) ;
            $errcnt++ ;
        }
    } elsif ($property eq "comment") {
        $comment = &GetCell($row, $CommentCol, 1) ;
        unless( &CheckCommentCell($comment, cr2cell($CommentCol, $row)) ) {
            printf("E002 : Illegal Comment <%s> - [string] at |%s|.\n", 
                             $comment, cr2cell($CommentCol, $row)) ;
            $errcnt++ ;
        }
    }

    if (($errcnt == 0) && ($property eq "normal")){
        $WireInfo{'property'}   = "normal" ;
        $WireInfo{'width'}      = $width ;
        $WireInfo{'name'}       = $name ;
        $WireInfo{'assignwith'} = $assignwith ;
        $WireInfo{'comment'}    = $comment ;
        push(@{$GetModule{'Wires'}}, {%WireInfo}) ;
    } elsif(($errcnt == 0) && ($property eq "comment")) {
        $WireInfo{'property'}   = "comment"     ;
        $WireInfo{'width'}      = '__invalid__' ;
        $WireInfo{'name'}       = '__invalid__' ;
        $WireInfo{'assignwith'} = '__invalid__' ;
        $WireInfo{'comment'}    = $comment      ;
        push(@{$GetModule{'Wires'}}, {%WireInfo}) ;
    } else {
        printf("E002 : Illegal Wire Information at line : %4d \n", $row) ;
    }
} # ParseWireInfo

sub ParsePortInfo() {
    my $row    = shift(@_) ;
    my $col    = shift(@_) ;
    my $Mdname = shift(@_) ;
    my $HierTp = shift(@_) ;
    my $info ;
    my $direction ;
    my $width ;
    my $name ;
    my $type ;
    my $assignwith ;
    my $comment ;
    my $errcnt = 0 ;
    my %PortInfo ;
    my $judgement ;
    my $property ; # comment/normal

    $judgement = &GetCell($row,  $JudgementCol, 0) ;

    if($judgement =~ m/^%/) {
        $property = "comment" ;
    } else {
        $property = "normal" ;
    }

    if($property eq "normal") {
        $direction = &GetCell($row, $DirectionCol, 0) ;
        unless( &CheckDirectionCell($direction) ) {
            printf("E002 : Illegal Port Direction <%s> - [input,output,inout] at |%s|.\n", 
                      $direction, cr2cell($DirectionCol, $row)) ;
            $errcnt++ ;
        }
        $width = &GetCell($row, $WidthCol, 0) ;
        unless( &CheckWidthCell($width) ) {
            printf("E002 : Illegal Port width <%s> - [integer(dec)] at |%s|.\n", 
                      $width, cr2cell($WidthCol, $row)) ;
            $errcnt++ ;
        }
        $name = &GetCell($row, $SigNameCol, 0) ;
        unless( &CheckPNameCell($name) ) {
            printf("E002 : Illegal Port name <%s> - [string] at |%s|.\n", 
                      $name, cr2cell($SigNameCol, $row)) ;
            $errcnt++ ;
        }
        unless($HierTp eq 'TopModuleName') {
            $type = &GetCell($row, $PortTypeCol, 0) ;
            unless( &CheckPTypeCell($type) ) {
                printf("E002 : Illegal Port type <%s> - [string] at |%s|.\n", 
                          $type, cr2cell($PortTypeCol, $row)) ;
                $errcnt++ ;
            }
        }
        $assignwith = &GetCell($row, $AssignWithCol, 1) ;
        unless( &CheckAssignCell($assignwith, cr2cell($AssignWithCol, $row)) ) {
            printf("E002 : Illegal Port assign <%s> - [string] at |%s|.\n", 
                      $assignwith, cr2cell($AssignWithCol, $row)) ;
            $errcnt++ ;
        }
        $comment = &GetCell($row, $CommentCol, 1) ;
        unless( &CheckCommentCell($comment, cr2cell($CommentCol, $row)) ) {
            printf("E002 : Illegal Comment <%s> - [string] at |%s|.\n", 
                      $comment, cr2cell($AssignWithCol, $row)) ;
            $errcnt++ ;
        }

        if($HierTp eq 'TOPMODULE') {
            if( &CheckRedeclare(\@{$GetModule{'Ports'}}, $name) ) {
                printf("E002 : Port Name Redefine <%s> @ |%s|.\n", $name, $row) ;
            }
        } elsif($HierTp eq 'SUBMODULE') {
            if( &CheckRedeclare(\@SubModulePortsInfo, $name) ) {
                printf("E002 : Port Name Redefine <%s> @ |%s|.\n", $name, $row) ;
            }
        }
    } elsif($property eq "comment") {
        $comment = &GetCell($row, $CommentCol, 1) ;
        unless( &CheckCommentCell($comment, cr2cell($CommentCol, $row)) ) {
            printf("E002 : Illegal Comment <%s> - [string] at |%s|.\n", 
                      $comment, cr2cell($AssignWithCol, $row)) ;
            $errcnt++ ;
        }
    } else {
        printf("%s %s [%s]\n", 'E007 : ', "<ParsePortInfo.property> illegal Variable @ ", cr2cell($JudgementCol, $row)) ;
        $errcnt++ ;
        exit ;
    }

    if(($errcnt == 0) && ($property eq "normal")) {
        $PortInfo{'property'}   = "normal" ;
        $PortInfo{'direction'}  = $direction ;
        $PortInfo{'width'}      = $width ;
        $PortInfo{'name'}       = $name ;
        $PortInfo{'type'}       = $type ;
        $PortInfo{'assignwith'} = $assignwith ;
        $PortInfo{'comment'}    = $comment ;
        if($HierTp eq 'TOPMODULE') {
            push(@{$GetModule{'Ports'}}, {%PortInfo}) ;
        } elsif($HierTp eq 'SUBMODULE') {
            push(@SubModulePortsInfo, {%PortInfo}) ;
        }
    } elsif(($errcnt == 0) && ($property eq "comment")) {
        $PortInfo{'property'}   = "comment"     ;
        $PortInfo{'direction'}  = "__invalid__" ;
        $PortInfo{'width'}      = "__invalid__" ;
        $PortInfo{'name'}       = "__invalid__" ;
        $PortInfo{'type'}       = "__invalid__" ;
        $PortInfo{'assignwith'} = "__invalid__" ;
        $PortInfo{'comment'}    = $comment ;
        if($HierTp eq 'TOPMODULE') {
            push(@{$GetModule{'Ports'}}, {%PortInfo}) ;
        } elsif($HierTp eq 'SUBMODULE') {
            push(@SubModulePortsInfo, {%PortInfo}) ;
        }
    } else {
        printf("E002 : Illegal Port Information at line : %4d \n", $row) ;
    }
} # ParsePortInfo

sub ParseParameter() {
    my $row    = shift(@_) ;
    my $col    = shift(@_) ;
    my $Mdname = shift(@_) ;
    my $HierTp = shift(@_) ;
    my $errcnt = 0 ;
    my $pname      ;
    my $pvalue     ;
    my $comment    ;
    my %ParamInfo  ;

    $pname = &GetCell($row, $SigNameCol, 0) ;
    unless( &CheckPNameCell($pname) ) {
        printf("E002 : Illegal parameter name <%s> - [string] at |%s|.\n", 
                  $pname, cr2cell($SigNameCol, $row)) ;
        $errcnt++ ;
    }
    $pvalue = &GetCell($row, $AssignWithCol, 0) ;
    unless( &CheckAssignCell($pvalue, cr2cell($AssignWithCol, $row)) ) {
        printf("E002 : Illegal parameter value <%s> - [string] at |%s|.\n", 
                  $pvalue, cr2cell($AssignWithCol, $row)) ;
        $errcnt++ ;
    }
    $comment = &GetCell($row, $CommentCol, 1) ;
    unless( &CheckCommentCell($comment, cr2cell($CommentCol, $row)) ) {
        printf("E002 : Illegal Comment <%s> - [string] at |%s|.\n", 
                  $comment, cr2cell($AssignWithCol, $row)) ;
        $errcnt++ ;
    }
    
    if($errcnt == 0) {
        $ParamInfo{'pname'}   = $pname   ;
        $ParamInfo{'pvalue'}  = $pvalue  ;
        $ParamInfo{'comment'} = $comment ;
        if($HierTp eq 'TOPMODULE') {
            push(@{$GetModule{'ParamsInfo'}}, {%ParamInfo}) ;
        } elsif($HierTp eq 'SUBMODULE') {
            push(@SubModuleParamInfo, {%ParamInfo}) ;
        }
    } else {
        printf("E002 : <ParseParameter> at line : %4d \n", $row) ;
    }
} # ParseParameter

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
