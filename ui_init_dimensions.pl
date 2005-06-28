##
# OmniPatcher for LiteOn DVD-Writers
# User Interface : Initialization, part 1: Establishing dimensions
#
# Modified: 2005/06/27, C64K
#

################################################################################
# Initialize experimentally-determined dimensions and other basic dimensions
{
	use integer;

	# Font heights
	#
	$UI_FONTHEIGHT_TAHOMA = {Win32::GUI::Font->new(-face => "Tahoma", -size => 8)->GetMetrics()}->{'-height'};
	$UI_FONTHEIGHT_CNEW = {Win32::GUI::Font->new(-face => "Courier New", -size => 10)->GetMetrics()}->{'-height'};

	# Experimentally-determined dimensions
	#
	my($ObjTempWindow) = new GUI::Window( -name => "TempWindow", -size => [ 64, 64 ], -style => WS_CAPTION | WS_SYSMENU ) or ui_abort('Initialization Error.');
	my($ObjTempTabs) = new GUI::TabStrip( $ObjTempWindow, -name => "TempTabs", -size => [ 100, 100 ], -buttons => (!$UI_USE_TABS), -flat => (!$UI_USE_TABS), -font => Win32::GUI::Font->new(-face => "Tahoma", -size => 8) ) or ui_abort('Initialization Error.');
	$ObjTempTabs->InsertItem(-text => "Test");

	$UI_NC_WIDTH = $ObjTempWindow->Width() - $ObjTempWindow->ScaleWidth();
	$UI_NC_HEIGHT = $ObjTempWindow->Height() - $ObjTempWindow->ScaleHeight();

	$UI_MARGINS_TABSTRIP = [ $ObjTempTabs->DisplayArea() ];
	$UI_MARGINS_TABSTRIP->[2] = $ObjTempTabs->Width() - ($UI_MARGINS_TABSTRIP->[0] + $UI_MARGINS_TABSTRIP->[2]);
	$UI_MARGINS_TABSTRIP->[3] = $ObjTempTabs->Height() - ($UI_MARGINS_TABSTRIP->[1] + $UI_MARGINS_TABSTRIP->[3]);
	$UI_MARGINS_TABSTRIP->[1] += 2 if ($UI_USE_SUNKEN);
	$UI_MARGINS_TABSTRIP = [ map { $_ + (($UI_USE_TABS) ? 4 : -$UI_MARGINS_TABSTRIP->[0]) } @{$UI_MARGINS_TABSTRIP} ];

	# Some dimensions
	#
	$UI_HEIGHT_BUTTON = 25;
	$UI_HEIGHT_TEXTBOX = $UI_FONTHEIGHT_CNEW + 6;

	$UI_MARGINS_GENERAL = 8;
	$UI_MARGINS_GROUP = [ ($UI_MARGINS_GENERAL + 2) x 4 ];
	$UI_MARGINS_GROUP->[1] += $UI_FONTHEIGHT_TAHOMA;
	$UI_MARGINS_BLANKGROUP = [ ($UI_MARGINS_GENERAL + 2) x 4 ];
	$UI_MARGINS_BLANKGROUP->[1] += ($UI_FONTHEIGHT_TAHOMA / 2);
	$UI_MARGINS_BLANKGROUP = [ ($UI_MARGINS_GENERAL + 1) x 4 ] if ($UI_USE_SUNKEN);
}

################################################################################
# Initialize GUI dimensions for the main window
{
	use integer;

	$ui_dim_medialist = [ 206, $UI_FONTHEIGHT_CNEW * 12 + 4 ];
	$ui_dim_mediaspd = [ 40, $UI_FONTHEIGHT_TAHOMA ];
	$ui_dim_medialabel = [ $ui_dim_medialist->[0], $UI_FONTHEIGHT_TAHOMA * 2 + 4 ];
	$ui_dim_mediafield[0] = [ 158, $UI_HEIGHT_TEXTBOX ];
	$ui_dim_mediafield[1] = $ui_dim_mediafield[2] = [ 72, $UI_HEIGHT_TEXTBOX ];	# Warning, double-assignment of reference
	@ui_dim_mediafieldlabel = map { [ $_->[0], $UI_FONTHEIGHT_TAHOMA ] } @ui_dim_mediafield;
	$ui_pos_mediafieldlabel[0] = [ $UI_MARGINS_GENERAL + $ui_dim_mediaspd->[0], 0 ];
	$ui_pos_mediafieldlabel[1] = [ $UI_MARGINS_GENERAL + $ui_dim_mediaspd->[0], $ui_dim_mediafieldlabel[0][1] + $ui_dim_mediafield[0][1] + 4 ];
	$ui_pos_mediafieldlabel[2] = [ $ui_pos_mediafieldlabel[1][0] + $ui_dim_mediafieldlabel[1][0] + ($ui_dim_mediafield[0][0] - 2 * $ui_dim_mediafield[1][0]), $ui_pos_mediafieldlabel[1][1] ];
	$ui_dim_mediadiv[0] = [ $ui_dim_medialist->[0] + $ui_dim_mediaspd->[0] + $ui_dim_mediafieldlabel[0][0] + 2 * $UI_MARGINS_GENERAL, 2 ];
	$ui_dim_mediadiv[1] = [ $ui_dim_mediafieldlabel[0][0], 2 ];
	$ui_pos_mediadiv[0] = [ $UI_MARGINS_BLANKGROUP->[0], $ui_dim_medialist->[1] + $ui_dim_medialabel->[1] + 2 * $UI_MARGINS_GENERAL + $UI_MARGINS_BLANKGROUP->[1]];
	$ui_pos_mediadiv[1] = [ $ui_dim_medialist->[0] + $ui_pos_mediafieldlabel[0][0] + $UI_MARGINS_GENERAL + $UI_MARGINS_BLANKGROUP->[0], $ui_pos_mediafieldlabel[1][1] + $ui_dim_mediafieldlabel[1][1] + $ui_dim_mediafield[1][1] + $UI_MARGINS_GENERAL + $UI_MARGINS_BLANKGROUP->[1] + 1];
	$ui_dim_mediacmd = [ ($ui_dim_mediadiv[0][0] - $UI_MARGINS_GENERAL) / 2, $UI_HEIGHT_BUTTON ];
	$ui_dim_mediainfo = [ $ui_dim_mediadiv[1][0], $ui_pos_mediadiv[0][1] - ($ui_pos_mediadiv[1][1] + $ui_dim_mediadiv[1][1] + 2 * $UI_MARGINS_GENERAL) ];

	$ui_dim_tabstrip =
	[
		$ui_dim_mediadiv[0][0] + 2 * ($UI_MARGINS_TABSTRIP->[0] + $UI_MARGINS_BLANKGROUP->[0]),
		$ui_dim_medialist->[1] + $ui_dim_medialabel->[1] + $ui_dim_mediadiv[0][1] + $ui_dim_mediacmd->[1] + 3 * $UI_MARGINS_GENERAL + $UI_MARGINS_TABSTRIP->[1] + $UI_MARGINS_TABSTRIP->[3] + $UI_MARGINS_BLANKGROUP->[1] + $UI_MARGINS_BLANKGROUP->[3]
	];
	$ui_dim_frame = [ $ui_dim_tabstrip->[0] - ($UI_MARGINS_TABSTRIP->[0] + $UI_MARGINS_TABSTRIP->[2]), $ui_dim_tabstrip->[1] - ($UI_MARGINS_TABSTRIP->[1] + $UI_MARGINS_TABSTRIP->[3])];
	$ui_dim_cmdgrp = [ $ui_dim_tabstrip->[0], $UI_HEIGHT_BUTTON + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] ];
	$ui_dim_cmd = [ 80, $UI_HEIGHT_BUTTON ];

	$ui_dim_window = [ $ui_dim_tabstrip->[0] + 2 * $UI_MARGINS_GENERAL + $UI_NC_WIDTH, $ui_dim_tabstrip->[1] + $ui_dim_cmdgrp->[1] + 3 * $UI_MARGINS_GENERAL + $UI_NC_HEIGHT ];

	$ui_dim_drivespace = [ $ui_dim_frame->[0] - 2 * $UI_MARGINS_BLANKGROUP->[0] - 4 * $UI_MARGINS_GENERAL, $ui_dim_frame->[1] - $UI_MARGINS_BLANKGROUP->[1] - $UI_MARGINS_BLANKGROUP->[3] - 4 * $UI_MARGINS_GENERAL ];
	$ui_pos_driveupleft = [ ($ui_dim_frame->[0] - $ui_dim_drivespace->[0]) / 2, ($ui_dim_frame->[1] - $ui_dim_drivespace->[1]) / 2 ];

	$ui_dim_drivesel = [ $ui_dim_drivespace->[0] - 2 * $UI_MARGINS_GROUP->[0], 24 ];
	@ui_dim_field = map { [ $_->[1] * 8 + 40, $UI_FONTHEIGHT_TAHOMA ] } @UI_DRIVE_FIELDS;
	$ui_dim_field[1][0] += 8;
	@ui_left_field = (0, $ui_dim_field[0][0] + $UI_MARGINS_GENERAL, $ui_dim_field[0][0] + $ui_dim_field[1][0] + 2 * $UI_MARGINS_GENERAL);

	$ui_dim_drivefrchng = [ $ui_dim_drivespace->[0], $ui_dim_drivesel->[1] + $UI_FONTHEIGHT_TAHOMA + $UI_HEIGHT_TEXTBOX + 1 * $UI_MARGINS_GENERAL + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] + 1 ];
	$ui_dim_drivefrinfo = [ $ui_dim_drivespace->[0], $ui_dim_drivespace->[1] - $ui_dim_drivefrchng->[1] - 2 * $UI_MARGINS_GENERAL ];
	$ui_dim_driveinfo = [ $ui_dim_drivespace->[0] - 2 * $UI_MARGINS_GROUP->[0], $ui_dim_drivefrinfo->[1] - $UI_MARGINS_GROUP->[1] - $UI_MARGINS_GROUP->[3] ];

	$ui_margins_patchesframe = $UI_MARGINS_BLANKGROUP->[0] + $UI_MARGINS_GENERAL;
	$ui_width_patchesframe = $ui_dim_frame->[0] - 2 * $ui_margins_patchesframe;

	my($temp) = $ui_width_patchesframe - (2 * $UI_MARGINS_GROUP->[0] + $#FW_RS_NAME * $UI_MARGINS_GENERAL);

	$ui_dim_rsextra = $temp % ($#FW_RS_NAME + 1);
	$ui_dim_rsdrop = [ $temp / ($#FW_RS_NAME + 1), 21 ];
	$ui_dim_rsgroup = [ $ui_width_patchesframe, $UI_FONTHEIGHT_TAHOMA + $ui_dim_rsdrop->[1] + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] + 1 ];

	$ui_width_leddrop[1]= $ui_dim_rsdrop->[0] + ($ui_dim_rsextra > 0);
	$ui_width_leddrop[0] = $ui_width_patchesframe - ($ui_width_leddrop[1] + $UI_MARGINS_GENERAL + 2 * $UI_MARGINS_GROUP->[0]);
}

################################################################################
# Initialize GUI dimensions for the strategy box window
{
	use integer;

	$ui_dim_stb_list = [ 150, $UI_FONTHEIGHT_CNEW * 12 + 4 ];
	$ui_dim_stb_cmd = [ ($ui_dim_stb_list->[0] - $UI_MARGINS_GENERAL) / 2, $UI_HEIGHT_BUTTON ];
	$ui_dim_stb_group = [ $ui_dim_stb_list->[0] + $UI_MARGINS_GROUP->[0] * 2, $ui_dim_stb_list->[1] + $ui_dim_stb_cmd->[1] + $UI_MARGINS_GENERAL + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] ];

	$ui_dim_stb = [ $ui_dim_stb_group->[0] + $UI_MARGINS_GENERAL * 2 + $UI_NC_WIDTH, $ui_dim_stb_group->[1] + $UI_MARGINS_GENERAL * 2 + $UI_NC_HEIGHT ];
}

################################################################################
# Initialize GUI dimensions for the media code input window
{
	use integer;

	$ui_dim_mib_cmd = [ 96, $UI_HEIGHT_BUTTON ];

	$ui_dim_mib_edit = [ 80 * 7 + 6, 192 ];
	$ui_dim_mib_editgrp = [ $ui_dim_mib_edit->[0] + $UI_MARGINS_GROUP->[0] * 2, $ui_dim_mib_edit->[1] + $ui_dim_mib_cmd->[1] + $UI_MARGINS_GENERAL + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] ];

	$ui_dim_mib_instr = [ $ui_dim_mib_edit->[0], 84 ];
	$ui_dim_mib_instrgrp = [ $ui_dim_mib_editgrp->[0], $ui_dim_mib_instr->[1] + $UI_MARGINS_GROUP->[1] + $UI_MARGINS_GROUP->[3] ];

	$ui_dim_mib = [ $ui_dim_mib_editgrp->[0] + $UI_MARGINS_GENERAL * 2 + $UI_NC_WIDTH, $ui_dim_mib_editgrp->[1] + $ui_dim_mib_instrgrp->[1] + 3 * $UI_MARGINS_GENERAL + $UI_NC_HEIGHT ];
}

1;
