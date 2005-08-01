##
# OmniPatcher for Optical Drives
# Media : Recommended tweaks table
#
# Modified: 2005/07/15, C64K
#

$MEDIA_TWEAKS_REV = 'Revision 3-02 (2005/07/15)';

$MEDIA_TWEAKS{'lo'} =
[
	[ [ 'CMC MAG',  'R01', 0x00 ], [                         ], [ 0b00000110 ], sub { $_[0] >= 0x011 && $_[0] < 0x012 } ],
	[ [ 'CMC MAG',  'R01', 0x00 ], [                         ], [ 0b00011110 ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'CMC MAG',  'R01', 0x00 ], [ 'CMC MAG',  'M01', 0x00 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],
	[ [ 'CMC MAG',  'E01', 0x00 ], [ 'CMC MAG',  'M01', 0x00 ], [            ], sub { $_[0] >= 0x033 && $_[0] < 0x040 } ],
	[ [ 'MCC',      '002', 0x00 ], [                         ], [ 0b00011110 ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'MCC',      '002', 0x00 ], [ 'MCC',      '003', 0x00 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],
	[ [ 'OPTODISC', 'OR4', 0x00 ], [ 'PRODISC',  'R03', 0x00 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x040 } ],
	[ [ 'OPTODISC', 'OR8', 0x00 ], [ 'RICOHJPN', 'R01', 0x02 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'PRODISC',  'R02', 0x00 ], [ 'PRODISC',  'R03', 0x00 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x040 } ],
	[ [ 'RICOHJPN', 'R00', 0x00 ], [                         ], [ 0b00000110 ], sub { $_[0] >= 0x011 && $_[0] < 0x040 } ],
	[ [ 'RICOHJPN', 'R01', 0x02 ], [                         ], [ 0b00011110 ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'RICOHJPN', 'R01', 0x02 ], [ 'RICOHJPN', 'R02', 0x03 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],
	[ [ 'RITEK',    'R01', 0x00 ], [ 'RITEK',    'R02', 0x01 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x040 } ],
	[ [ 'RITEK',    'R02', 0x01 ], [ 'YUDEN000', 'T02', 0x00 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x030 } ],
	[ [ 'RITEK',    'R03', 0x01 ], [ 'YUDEN000', 'T02', 0x00 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x030 } ],
	[ [ 'RITEK',    'R03', 0x02 ], [ 'YUDEN000', 'T02', 0x00 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x030 } ],
	[ [ 'YUDEN000', 'T01', 0x00 ], [ 'YUDEN000', 'T01', 0x01 ], [            ], sub { $_[0] >= 0x011 && $_[0] < 0x030 } ],
	[ [ 'YUDEN000', 'T01', 0x00 ], [ 'YUDEN000', 'T02', 0x00 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],
	[ [ 'YUDEN000', 'T01', 0x01 ], [                         ], [ 0b00011110 ], sub { $_[0] >= 0x011 && $_[0] < 0x030 } ],
	[ [ 'YUDEN000', 'T01', 0x01 ], [ 'YUDEN000', 'T02', 0x00 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],

	[ [ 'FUJIFILM03',      0x52 ], [ 'TYG02',           0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'MCC 01RG20  ',    0x52 ], [ 'MCC 02RG20  ',    0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'OPTODISCR004',    0x52 ], [ 'AML',             0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'PRINCO',          0x52 ], [ 'PRINCO8X01',      0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x040 } ],
	[ [ 'ProdiscS03  ',    0x52 ], [ 'ProdiscS04  ',    0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'RITEKG04',        0x52 ], [ 'RITEKG05',        0x52 ], [            ], sub { $_[0] >= 0x031 && $_[0] < 0x040 } ],
	[ [ 'RITEKG05',        0x52 ], [ 'RITEKG06',        0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x030 } ],
	[ [ 'TYG01',           0x52 ], [ 'TYG02',           0x52 ], [            ], sub { $_[0] >= 0x012 && $_[0] < 0x040 } ],
];

###
# Revision History
# ================
#
# 3-02 (2005/07/15) - Removed YUDEN000T02->T03.  Added E01->M01 for CMC +R.
# 3-01 (2005/06/10) - Reformatted the table for OmniPatcher 2.
# 2-15 (2005/05/03) - Removed 1673S/1693S YUDEN000T02 to T03 startegy switch.
#                     Increased 1673S/1693S YUDEN000T02 burn speed to 16x.
# 2-14 (2005/04/15) - Added 1673S tweaks and YUDEN000T02 to T03 for 3S.
# 2-13 (2004/12/03) - Retired a number of the YUDEN000T02 switches.
# 2-12 (2004/11/11) - Added OPTODISCR004, MCC 01RG20, and FUJIFILM03 switches
#                     for the 2S.  Expanded the PRINCO switch.  Refined the
#                     YUDEN000T01-01 tweak for the 3S.
# 2-11 (2004/09/27) - Expanded the OPTODISCOR4 switch, modified the RITEKR01
#                     switch, and added a MCC002 switch for the 3S.
# 2-10 (2004/09/23) - Switched all Ritek +R codes to use YUDEN000T02.
# 2-09 (2004/09/20) - Added some OptoDisc +R, Prodisc -R, and Ritek -R switches.
#                     Modified tweaks for CMC MAGR01, RICOHJPNR00, and TYG01.
# 2-08 (2004/08/11) - Set YUDEN000T01-01 to 8x for the newer firmwares.
# 2-07 (2004/08/03) - Bumped CMC MAGR01 to 8x for the 2S drives.  Re-added
#                     RITEKG05->RITEKG06 for the 2S drives.  Added PRINCO-52->
#                     PRINCO8X01 for the 2S drives.
# 2-06 (2004/07/28) - Reverted the YUDEN000T01-00 tweak for the 1S/2S back to
#                     way it was in the earlier tweak revisions.
# 2-05 (2004/07/26) - Bumped MCC002 back to 8x (try using force-fallback).
#                     Expanded RITEKR03 and PRODISCR03 for the 3S.
# 2-04 (2004/07/23) - Edited RICOHJPNR00.  Slowed MCC002 from 8x to 6x.  Edited
#                     YUDEN000T01 for VS0A/US0Q.
# 2-03 (2004/07/17) - Removed CMC MAG +R swaps and RITEK -R due to reports of
#                     varying results.  Edited RICOHJPNR00.  Added RITEKR03->
#                     YUDEN000T02.  Extended YUDEN000T01 and PRODISCR02 for the
#                     3S drive family.
# 2-02 (2004/07/09) - Added PRODISCR03->YUDEN000T02, revised RITEKG05.
# 2-01 (2004/07/08) - Overhauled format for OmniPatcher 1.3.2 and added new
#                     tweaks.
# 1-01 (2004/07/05) - First revision.
#

1;
