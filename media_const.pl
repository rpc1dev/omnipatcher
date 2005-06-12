##
# OmniPatcher for LiteOn DVD-Writers
# Media : Constants and initialization
#
# Modified: 2005/06/08, C64K
#

##
# Media type IDs...
#
# Note that the speed limits encoded in %FW_PARAMS are done
# so in the order indicated by the IDs here.
#
$MEDIA_TYPE_DVD_PR  = 0x00;
$MEDIA_TYPE_DVD_PRW = 0x01;
$MEDIA_TYPE_DVD_PR9 = 0x02;
$MEDIA_TYPE_DVD_DR  = 0x03;
$MEDIA_TYPE_DVD_DRW = 0x04;
$MEDIA_TYPE_DVD_DR9 = 0x05;
$MEDIA_TYPE_DVD_P   = 0x06;
$MEDIA_TYPE_DVD_D   = 0x07;

$MEDIA_TYPES[$MEDIA_TYPE_DVD_P] = [ $MEDIA_TYPE_DVD_PR, $MEDIA_TYPE_DVD_PRW, $MEDIA_TYPE_DVD_PR9 ];
$MEDIA_TYPES[$MEDIA_TYPE_DVD_D] = [ $MEDIA_TYPE_DVD_DR, $MEDIA_TYPE_DVD_DRW, $MEDIA_TYPE_DVD_DR9 ];

$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_PR ] = '+R';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_PRW] = '+RW';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_PR9] = '+R9';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_DR ] = '-R';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_DRW] = '-RW';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_DR9] = '-R9';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_P  ] = '+';
$MEDIA_TYPE_NAME[$MEDIA_TYPE_DVD_D  ] = '-';

##
# Media data type IDs...
#
$MEDIA_DATA_STR = 0x00;
$MEDIA_DATA_INT = 0x01;

##
# Media code samples...
#
$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_PR] = join( '|', map { (quotemeta($_), quotemeta(str2unicode($_))) }
(
	"RICOHJPNR0",
	"YUDEN000T0",
	"OPTODISCOR",
	"PRODISC\x00R0",
) );

$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_PRW] = join( '|', map { (quotemeta($_), quotemeta(str2unicode($_))) }
(
	"MKM\x00\x00\x00\x00\x00A0",
	"RICOHJPNW",
) );

$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_PR9] = join( '|', map { (quotemeta($_), quotemeta(str2unicode($_))) }
(
	"RICOHJPND00",
) );

$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_DR] = join( '|', map { quotemeta }
(
	"RITEKG0",
	"FUJIFILM0",
	"TYG0",
) );

$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_DRW] = join( '|', 'TDK\d{3}saku', map { quotemeta }
(
	"RITEKW0",
) );

$MEDIA_SAMPLES[$MEDIA_TYPE_DVD_DR9] = join( '|', map { quotemeta }
(
	"MKM 01RD30",
) );

$MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_PR] = join( '|', map { (quotemeta($_), quotemeta(str2unicode($_))) }
(
	"RICOHJPNR00",
) );

$MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_DR] = join( '|', map { quotemeta }
(
	"RITEKG03",
) );

##
# Strategy patching info...
# Note that prior to OP-1.3.7, type 1 patches did not save a revision
# flag, so some type 0 firmwares are actually type 1 (the patches should
# be 100% identical except for the lack of the revision flag in bank 0)
#
# Also note that the various addresses used for type 5 patches can vary!
# The addresses are determined dynamically by the patching function.
#
# List of status/type flags, the insert address, and the table start address
#
# Type 0: [ 0x0000, 0x0000 ] Unpatched
# Type 1: [ 0xFF00, 0xFF30 ] Patched using patch_strat (Obsolete)
# Type 2: [ 0xFF00, 0xFF40 ] Patched using patch_strat2 (Obsolete)
# Type 3: [ 0xFF40, 0xFF70 ] Patched using patch_strat_TS0C (Obsolete)
# Type 4: [ 0xFF00, 0xFF40 ] Patched using patch_strat3 (Obsolete)
# Type 5: [ 0x0000, 0x0000 ] Patched using media_strat_p1s (Active)
# Type 6: [ 0xFF00, 0xFF40 ] Patched using media_strat_p3s (Active)
#
$MEDIA_STRAT_REVLOC = 0x0FFEF;

##
# Pattern matching...
#
# Note that the dash pattern here is for slimline drives.
#
$MEDIA_PLUS_PATTERN = '(?:\x00{12}|\xFF{12}|(?:\w{2}.{6}[\w\x00]{3}.)|(?:[A-Z]\w{2}.{9})|(?:\x00{8}\w.{3}))[\x00-\x7F]';
$MEDIA_DASH_PATTERN = '.\xFF{13}|\x00{13}.|(?:\w[\w \-=\.,\xAD\x00\!\/\[\]]{11}..)';

##
# Speed type IDs...
#
# xxxxxxxx x0C86421 <- 1
# xxxxxxxx 0xC86421 <- 3, 4
# xxxxxxx0 xCx86421 <- 5, 6
#
# Type 3
# ----------
# 0 11111100
# 0 00111100
# 0 00011100
#
# Type 4
# ----------
# 0 10111000
# 0 00111000
# 0 00011000
#
# Type 5, 6
# ----------
# 1 11011100
# 0 01011100
# 0 00011100
#
$MEDIA_SPEED_TYPE[0] = "unknown";
$MEDIA_SPEED_TYPE[1] = "7 bits, standard";
$MEDIA_SPEED_TYPE[2] = "7 bits, slimtype";
$MEDIA_SPEED_TYPE[3] = "8 bits, with bit 6 set";
$MEDIA_SPEED_TYPE[4] = "8 bits, with bit 6 unset";
$MEDIA_SPEED_TYPE[5] = "9 bits";
$MEDIA_SPEED_TYPE[6] = "9 bits, with non-Unicode entries";

@MEDIA_SPEEDS_D = @MEDIA_SPEEDS_STD = ( 1, 2, 4, 6, 8, 12, 16 );
@MEDIA_SPEEDS_P = ( 0, 2.4, 4, 6, 8, 12, 16 );
$MEDIA_SPEEDS = sub { ($_[0] == $MEDIA_TYPE_DVD_P | $_[0] == $MEDIA_TYPE_DVD_PR | $_[0] == $MEDIA_TYPE_DVD_PRW | $_[0] == $MEDIA_TYPE_DVD_PR9) ? \@MEDIA_SPEEDS_P : \@MEDIA_SPEEDS_D };

##
# Media code entry format...
#
#[
#	$type_id(0),
#	$table_entry_id(1),
#	{ -> (2) (original)
#		field1 => [ $value(0), [ $datatype, $unicode ](1), $len(2), [ $addr, $addr2? ](3) ],
#		field2 => [ $value(0), [ $datatype, $unicode ](1), $len(2), [ $addr, $addr2? ](3) ],
#		...
#	},
#	$strat_id(3), (values can be changed by UI)
#	{ -> (4) (values can be changed by UI)
#		field1 => $value
#		field2 => $value
#	},
#	$disp(5),
#]
#
#$sample =
#[
#	$MEDIA_TYPE_DVD_PR,
#	0x01,
#	{
#		MID => [ 'RITEK', [ $MEDIA_DATA_STR, 1 ], 8, [ 0xC1234 ] ],
#		TID => [ 'R03', [ $MEDIA_DATA_STR, 1 ], 3, [ 0xC1234 ] ],
#		RID => [ 0x01, [ $MEDIA_DATA_INT, 1 ], 1, [ 0xC1234 ] ],
#		SPD => [ 0x0C, [ $MEDIA_DATA_INT, 1 ], 1, [ 0xC1234 ] ],
#	},
#	0x05,
#	{
#		MID => 'RITEK',
#		TID => 'R03',
#		RID => 0x01,
#		SPD => 0x0C,
#	},
#	"RITEK-R03-01",
#];
#

1;
