$hWndMain = 0;


################################################################################
# BEGIN: Section: interface helper functions
{
	sub abort # ( message )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], "Error", MB_OK | MB_ICONWARNING);
		exit 1;
	}

	sub error # ( message, retcode )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], "Error", MB_OK | MB_ICONWARNING);
		return $_[1];
	}

	sub addpairs # ( pairs )
	{
		my(@pairs) = @_;
		my($ret) = [ 0, 0 ];

		foreach $pair (@pairs)
		{
			$ret->[0] += $pair->[0];
			$ret->[1] += $pair->[1];
		}

		return $ret;
	}

	sub getpos # ( obj )
	{
		return [ $_[0]->Left(), $_[0]->Top() ];
	}

	sub SetText # ( obj, str )
	{
		my($obj, $str) = @_;

		if ($obj->Text() ne $str)
		{
			$obj->Text($str);
		}
	}

	sub SetCheck # ( obj, check )
	{
		my($obj, $check) = @_;

		if ($obj->GetCheck() != $check)
		{
			$obj->SetCheck($check);
		}
	}

	sub SetEnable # ( obj )
	{
		my($obj) = @_;

		if (!$obj->IsEnabled())
		{
			$obj->Enable();
		}
	}

	sub SetDisable # ( obj )
	{
		my($obj) = @_;

		if ($obj->IsEnabled())
		{
			$obj->Disable();
		}
	}

} # END: Section: interface helper functions


################################################################################
# BEGIN: Section: initialize tool settings
{
	@MEDIA_SPEEDS = ( 1, 2, 4, 6, 8, 12, 16 );

	@PATCH_NAMES =
	(
		"Increase DVD�R/RW/DL reading speed to 8x",
		"Enable auto-bitsetting",
		"Earlier shift (faster burn) for 8x +R",
		"Utilize \"shift-fixing\" for 6x/8x burns",
		"Fix blinking orange light / Enable cross-flashing",
	);

	@CMD_NAMES =
	(
		"Load",
		"Save As",
		"About",
	);

	$MGROUP_NAME = "DVD Writing-Speed Limits";

} # END: Section: initialize tool settings


################################################################################
# BEGIN: Section: initialize fonts
{
	$FontTahoma = Win32::GUI::Font->new
	(
		-face		=> "Tahoma",
		-size		=> 8,
		-bold		=> 0,
		-italic	=>	0,

	) or abort("Initialization Error.");

	$FontTahomaBold = Win32::GUI::Font->new
	(
		-face		=> "Tahoma",
		-size		=> 8,
		-bold		=> 1,
		-italic	=>	0,

	) or abort("Initialization Error.");

	$FontCourierNew = Win32::GUI::Font->new
	(
		-face		=> "Courier New",
		-size		=> 10,
		-bold		=> 0,
		-italic	=>	0,

	) or abort("Initialization Error.");

	$FontWingdings = Win32::GUI::Font->new
	(
		-face		=> "Wingdings",
		-size		=> 13,
		-bold		=> 0,
		-italic	=>	0,

	) or abort("Initialization Error.");

	$FONTHEIGHT_TAHOMA = {$FontTahoma->GetMetrics()}->{'-height'};
	$FONTHEIGHT_CNEW = {$FontCourierNew->GetMetrics()}->{'-height'};
	$FONTHEIGHT_WINGDINGS = {$FontWingdings->GetMetrics()}->{'-height'};

} # END: Section: initialize fonts


################################################################################
# BEGIN: Section: initialize GUI dimensions
{
	$ObjTemp = new GUI::Window( -name => "Temp", -size => [ 64, 64 ], -style => WS_CAPTION | WS_SYSMENU ) or abort("Initialization Error.");
	$NC_WIDTH = $ObjTemp->Width() - $ObjTemp->ScaleWidth();
	$NC_HEIGHT = $ObjTemp->Height() - $ObjTemp->ScaleHeight();

	$MARGIN = 8;
	$MARGIN_CHECK = 4;
	$MARGIN_GROUP = 10;
	$MARGINS_GROUP = [ $MARGIN_GROUP, $MARGIN_GROUP + $FONTHEIGHT_TAHOMA ];

	@DIM_LIST = ( 192, $FONTHEIGHT_CNEW * 10 + 4 );
	@DIM_SPEED = ( 44, $FONTHEIGHT_TAHOMA );
	@DIM_SPDREP = ( $DIM_SPEED[0], 25 );
	@DIM_PATCH = ( $MARGIN + $DIM_LIST[0] + $DIM_SPEED[0], $FONTHEIGHT_TAHOMA );
	@DIM_CMD = ( ($DIM_PATCH[0] - $MARGIN * $#CMD_NAMES) / scalar(@CMD_NAMES), $DIM_SPDREP[1] );

	@DIM_MEDIAGRP = ( $MARGIN_GROUP * 2 + $DIM_PATCH[0], $MARGIN_GROUP * 2 + $FONTHEIGHT_TAHOMA + $DIM_LIST[1] );
	@DIM_PATCHGRP = ( $DIM_MEDIAGRP[0], $MARGIN_GROUP * 2 + $FONTHEIGHT_TAHOMA + ($DIM_PATCH[1] + $MARGIN_CHECK) * scalar(@PATCH_NAMES) - $MARGIN_CHECK );
	@DIM_CMDGRP = ( $DIM_MEDIAGRP[0], $MARGIN_GROUP * 2 + $FONTHEIGHT_TAHOMA + $DIM_CMD[1] );

	@DIM_WINDOW = ( $MARGIN * 2 + $DIM_MEDIAGRP[0] + $NC_WIDTH, $MARGIN * 4 + $DIM_MEDIAGRP[1] + $DIM_PATCHGRP[1] + $DIM_CMDGRP[1] + $NC_HEIGHT );

} # END: Section: initialize GUI dimensions


################################################################################
# BEGIN: Section: create window
{
	$unique_title = $PROGRAM_TITLE . (time() + 0);

	$ObjMain = new GUI::DialogBox
	(
		-name			=> "Main",
		-text			=> $unique_title,
		-pos			=> [ 64, 47 ],
		-size			=> \@DIM_WINDOW,
		-remexstyle	=> WS_EX_CONTEXTHELP,

	) or abort("Initialization Error.");

	$hWndMain = Win32::GUI::FindWindow('', $unique_title);
	$ObjMain->Change(-text => $PROGRAM_TITLE);

} # END: Section: create window


################################################################################
# BEGIN: Section: media codes
{
	$ObjMediaGroup = new Win32::GUI::Groupbox
	(
		$ObjMain,

		-name	=> "MediaGroup",
		-text	=> $MGROUP_NAME,
		-font	=> $FontTahomaBold,
		-pos	=> [ $MARGIN, $MARGIN ],
		-size	=> \@DIM_MEDIAGRP,

	) or abort("Initialization Error.");

	$ObjList = new Win32::GUI::Listbox
	(
		$ObjMain,

		-name			=> "List",
		-font			=> $FontCourierNew,
		-pos			=> addpairs($MARGINS_GROUP, getpos($ObjMediaGroup)),
		-size			=> \@DIM_LIST,
		-addstyle	=> WS_VSCROLL | WS_GROUP,
		-tabstop		=> 1,
		-disabled	=> 1,

	) or abort("Initialization Error.");

	foreach $i (0 .. $#MEDIA_SPEEDS)
	{
		$ObjSpeeds[$i] = new Win32::GUI::Checkbox
		(
			$ObjMain,

			-name			=> "Speeds$i",
			-text			=> "$MEDIA_SPEEDS[$i]x",
			-font			=> $FontTahoma,
			-pos			=> addpairs($MARGINS_GROUP, [ $MARGIN + $DIM_LIST[0], ($DIM_SPEED[1] + $MARGIN_CHECK) * $i ], getpos($ObjMediaGroup)),
			-size			=> \@DIM_SPEED,
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-tabstop		=> 1,
			-disabled	=> 1,

		) or abort("Initialization Error.");

	} # END: foreach

	$ObjSpdRep = new Win32::GUI::Button
	(
		$ObjMain,

		-name			=> "SpdRep",
		-text			=> '$',
		-font			=> $FontWingdings,
		-pos			=> addpairs($MARGINS_GROUP, [ $MARGIN + $DIM_LIST[0], ($DIM_LIST[1] - $DIM_SPDREP[1]) ], getpos($ObjMediaGroup)),
		-size			=> \@DIM_SPDREP,
		-addstyle	=> WS_GROUP,
		-tabstop		=> 1,
		-disabled	=> 1,

	) or abort("Initialization Error.");

} # END: Section: media codes


################################################################################
# BEGIN: Section: other patches
{
	$ObjPatchGroup = new Win32::GUI::Groupbox
	(
		$ObjMain,

		-name	=> "PatchGroup",
		-text	=> "Patches to Apply",
		-font	=> $FontTahomaBold,
		-pos	=> [ $MARGIN, $MARGIN * 2 + $DIM_MEDIAGRP[1] ],
		-size	=> \@DIM_PATCHGRP,

	) or abort("Initialization Error.");

	foreach $i (0 .. $#PATCH_NAMES)
	{
		$ObjPatches[$i] = new Win32::GUI::Checkbox
		(
			$ObjMain,

			-name			=> "Patches$i",
			-text			=> $PATCH_NAMES[$i],
			-font			=> $FontTahoma,
			-pos			=> addpairs($MARGINS_GROUP, [ 0, ($DIM_PATCH[1] + $MARGIN_CHECK) * $i ], getpos($ObjPatchGroup)),
			-size			=> \@DIM_PATCH,
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-disabled	=> 1,
			-tabstop		=> 1,

		) or abort("Initialization Error.");

	} # END: foreach

} # END: Section: other patches


################################################################################
# BEGIN: Section: command buttons
{
	$ObjCmdGroup = new Win32::GUI::Groupbox
	(
		$ObjMain,

		-name	=> "CmdGroup",
		-text	=> "No File Loaded",
		-font	=> $FontTahomaBold,
		-pos	=> [ $MARGIN, $MARGIN * 3 + $DIM_MEDIAGRP[1] + $DIM_PATCHGRP[1] ],
		-size	=> \@DIM_CMDGRP,

	) or abort("Initialization Error.");

	foreach $i (0 .. $#CMD_NAMES)
	{
		$ObjCmds[$i] = new Win32::GUI::Button
		(
			$ObjMain,

			-name			=> "Cmds$i",
			-text			=> $CMD_NAMES[$i],
			-font			=> $FontTahoma,
			-pos			=> addpairs($MARGINS_GROUP, [ ($DIM_CMD[0] + $MARGIN) * $i, 0 ], getpos($ObjCmdGroup)),
			-size			=> \@DIM_CMD,
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-tabstop		=> 1,
			-disabled	=> ($i == 1) ? 1 : 0,

		) or abort("Initialization Error.");

	} # END: foreach

} # END: Section: command buttons

1;