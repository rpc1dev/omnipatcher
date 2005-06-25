##
# OmniPatcher for LiteOn DVD-Writers
# User Interface : Constants and initialization
#
# Modified: 2005/06/25, C64K
#

##
# Tabs
#
$UI_TABID_DRIVE   = 0;
$UI_TABID_MEDIA   = 1;
$UI_TABID_PATCHES = 2;
$UI_TABID_DEBUG   = 3;	# This must always be the last tab

$UI_TABS[$UI_TABID_DRIVE  ] = "Drive ID";
$UI_TABS[$UI_TABID_MEDIA  ] = "DVD Media Support";
$UI_TABS[$UI_TABID_PATCHES] = "General Patches";
$UI_TABS[$UI_TABID_DEBUG  ] = "Debug Log";

##
# Media Tab
#
$UI_STRATLABEL[0] = "Double-click on a +R or -R media\ncode to reassign its write strategy.";
$UI_STRATLABEL[1] = "Double-click on a +R media\ncode to reassign its write strategy.";
$UI_STRATLABEL[2] = "Double-click on a -R media\ncode to reassign its write strategy.";

$UI_MEDIA_TXTID_MID = 0;
$UI_MEDIA_TXTID_TID = 1;
$UI_MEDIA_TXTID_RID = 2;

$UI_MEDIA_TXT[$UI_MEDIA_TXTID_MID] = "Manufacturer ID:";
$UI_MEDIA_TXT[$UI_MEDIA_TXTID_TID] = "Type ID:";
$UI_MEDIA_TXT[$UI_MEDIA_TXTID_RID] = "Rev. ID:";

$UI_MAX_LEN[$UI_MEDIA_TXTID_MID] = 8;	# 12 for -R
$UI_MAX_LEN[$UI_MEDIA_TXTID_TID] = 3;
$UI_MAX_LEN[$UI_MEDIA_TXTID_RID] = 2;

$UI_FIELD_KEY[$UI_MEDIA_TXTID_MID] = 'MID';
$UI_FIELD_KEY[$UI_MEDIA_TXTID_TID] = 'TID';
$UI_FIELD_KEY[$UI_MEDIA_TXTID_RID] = 'RID';

##
# Drive ID
#
@UI_DRIVE_FIELDS =
(
	[ "Vendor ID:", 8 ],
	[ "Product ID:", 16 ],
	[ "Revision:", 4 ],
);

##
# Media Code Input
#
$UI_MIDBOX_INSTR = join("\r\n", (
	"This will rename an existing media code--the one you have just selected--using a media code block dump.", "",
	"Download a disc identification program capable of showing media code blocks (a sample media code block is shown below), such as DVD Identifier (dvdidentifier.cdfreaks.com) or CD-DVD Speed (cdspeed2000.com).  Use it to read the media code block of the disc whose media code you would like to use, and then copy the media code block into the text box below and click the \"Import\" button.",
) );

$UI_MIDBOX_SAMPLE = join("\r\n", (
	"Sample media code block:",
	"0000 : a1 0f 02 00 00 03 00 00  00 26 05 3f 00 00 00 00   .........&.?....",
	"0010 : 00 00 01 52 49 43 4f 48  4a 50 4e 52 30 31 02 38   ...RICOHJPNR01.8",
	"0020 : 23 54 37 09 00 3c 67 00  ac 62 16 18 0b 0b 0a 0b   #T7..<g..b......",
) );

1;
