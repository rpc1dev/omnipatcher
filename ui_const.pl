##
# OmniPatcher for LiteOn DVD-Writers
# User Interface : Constants and initialization
#
# Modified: 2005/06/12, C64K
#

##
# Tabs
#
$UI_TABID_DRIVE   = 0;
$UI_TABID_MEDIA   = 1;
$UI_TABID_PATCHES = 2;

$UI_TABS[$UI_TABID_DRIVE  ] = "Drive ID";
$UI_TABS[$UI_TABID_MEDIA  ] = "DVD Media Support";
$UI_TABS[$UI_TABID_PATCHES] = "General Patches";

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

1;
