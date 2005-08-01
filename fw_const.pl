##
# OmniPatcher for Optical Drives
# Firmware : Constants and initialization
#
# Modified: 2005/08/01, C64K
#

##
# Drive ID stuff
#
$FW_CUSTOMID_CAPTION = 'Specify a custom drive ID below...';

##
# Config table for general patches
#
@FW_PATCH_KEYS = ('RPC', 'FBS', 'ABS', 'LED', 'IDE', 'ES', 'FS', 'FF', 'DL', 'CF', 'NSX', 'MTK');

%FW_PATCHES =
(
	# ID => [ caption(0), function to use(1), force patch(2) (always patch if enabled), relevancy test(3) ]
	#
	RPC => [ "Make this firmware \"region free\" (RPC I)",					\&fw_rpc_pat,	0, sub { fw_rpc_relevancy() } ],
	FBS => [ "Fix bitsetting support",												\&fw_pat_fbs,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && ($Current{'fw_fwrev'} =~ /^BYX|[CJK]Y/ || ($Current{'fw_family'} eq 'SOHW-812S/802S' && $Current{'fw_date_num'} < 20040414)) } ],
	ABS => [ "Enable auto-bitsetting",												\&fw_pat_abs,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x040 } ],
	LED => [ "Use a multi-color LED color scheme",								\&fw_pat_led,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x031 && $Current{'fw_gen'} < 0x033 || ($Current{'fw_gen'} < 0x100 && $Current{'fw_fwrev'} =~ /^[UV][YF]/) } ],
	IDE => [ "Disable the signal for the IDE activity indicator light",	\&fw_pat_ide,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x021 && $Current{'fw_gen'} < 0x040 && $Current{'fw_fwrev'} =~ /^.[YF]/ } ],
	ES  => [ "Earlier shift (faster burn) for 8x +R",							\&fw_pat_es,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x030 && $Current{'media_limits'}[$MEDIA_TYPE_DVD_PR] == 8 } ],
	FS  => [ "Utilize \"force-shifting\" for 6x/8x burns",					\&fw_pat_fs,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x012 && $Current{'fw_gen'} < 0x030 && $Current{'media_limits'}[$MEDIA_TYPE_DVD_PR] == 8 } ],
	FF  => [ "Utilize \"force-fallback\" for 8x +R",							\&fw_pat_ff,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x012 && $Current{'fw_gen'} < 0x030 && $Current{'media_limits'}[$MEDIA_TYPE_DVD_PR] == 8 } ],
	DL  => [ "Disable media learning",												\&fw_pat_dl,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x140 } ],
	CF  => [ "Fix the \"dead drive blink\" / Enable cross-flashing",		\&fw_pat_cf,	0, sub { $Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x140 && $Current{'fw_ebank'} > 0 } ],
	NSX => [ "Disable \"SMART-X\" for DVDs (not recommended)",				\&fw_pat_nsx,	0, sub { $Current{'fw_manuf'} eq 'lo' && ($Current{'fw_type'} eq 'combo' || $Current{'fw_type'} eq 'dvdrom') } ],
	MTK => [ "Enable MtkFlash support",												\&fw_pat_mtk,	0, sub { $Current{'fw_manuf'} eq 'lo' && $FW_ALLOW_ENABLE_MTKFLASH } ],
);

##
# Reading speed
#
$FW_RS_DVDROM = 0;
$FW_RS_DVD9   = 1;
$FW_RS_DVDR   = 2;
$FW_RS_DVDRW  = 3;
$FW_RS_DVDR9  = 4;

@FW_RS_IDX = ($FW_RS_DVDROM, $FW_RS_DVD9, $FW_RS_DVDR, $FW_RS_DVDRW, $FW_RS_DVDR9);

$FW_RS_NAME[$FW_RS_DVDROM] = 'DVD-ROM/5';
$FW_RS_NAME[$FW_RS_DVD9  ] = 'DVD-ROM/9';
$FW_RS_NAME[$FW_RS_DVDR  ] = 'DVD+/-R';
$FW_RS_NAME[$FW_RS_DVDRW ] = 'DVD+/-RW';
$FW_RS_NAME[$FW_RS_DVDR9 ] = 'DVD+/-R9';

##
# LiteOn DVDRW media ID to read speed type ID converter; uses capital hex format
#
%FW_RS_LODVDRWID2TYPE =
(
	'80' => $FW_RS_DVDROM,
	'82' => $FW_RS_DVD9,
	'83' => $FW_RS_DVD9,
	'90' => $FW_RS_DVDR,
	'91' => $FW_RS_DVDR,
	'92' => $FW_RS_DVDR,
	'93' => $FW_RS_DVDR9,
	'94' => $FW_RS_DVDR,
	'97' => $FW_RS_DVDR9,
	'88' => $FW_RS_DVDRW,
	'8C' => $FW_RS_DVDRW,
	'8D' => $FW_RS_DVDRW,
#	'A0' => $FW_RS_DVDRAM,
#	'A1' => $FW_RS_DVDRAM,
);

##
# Quick-n-Dirty speed/index converter, in the form of an array
#
$FW_RS_IDX2SPD_ = [ 4, 6, 8, 12, 16 ];
$FW_RS_SPD2IDX_ =
[
	0, 0, 0, 0, 0,	# 0-4
	1, 1,				# 5-6
	2, 2,				# 7-8
	3, 3, 3, 3,		# 9-12
	4, 4, 4,	4,		# 13-16
];

$FW_RS_IDX2SPD_10 = [ 4, 6, 8, 10, 12, 16 ];
$FW_RS_SPD2IDX_10 =
[
	0, 0, 0, 0, 0,	# 0-4
	1, 1,				# 5-6
	2, 2,				# 7-8
	3, 3,				# 9-10
	4, 4,				# 11-12
	5, 5, 5, 5,		# 13-16
];

$FW_RS_IDX2SPD_1014 = [ 4, 6, 8, 10, 12, 14, 16 ];
$FW_RS_SPD2IDX_1014 =
[
	0, 0, 0, 0, 0,	# 0-4
	1, 1,				# 5-6
	2, 2,				# 7-8
	3, 3,				# 9-10
	4, 4,				# 11-12
	5, 5,				# 13-14
	6, 6,				# 15-16
];

##
# Format of each entry of the read-speed table
#
# [ orig_speed (-1=invalid), new_speed, [ locations ] ]
#

##
# LED Stuff
#
$FW_LED_MINRATE = 5;
$FW_LED_MAXRATE = 40;

@FW_LED_LABELS = ("Select LED Behavior", "Blink Rate");

@FW_LED_BEHAVS =
(
	"Use blinking LED for write and solid LED for read (default)",
	"Use blinking LED for read and solid LED for write",
	"Use blinking LED for both read and write",
	"Use solid LED for both read and write",
);

1;
