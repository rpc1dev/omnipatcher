##
# OmniPatcher for Optical Drives
# User Interface : Initialization, part 2: Object creation
#
# Modified: 2005/07/25, C64K
#

################################################################################
# Get the Windows version
{
	my(undef, $major, $minor) = Win32::GetOSVersion();
	$UI_OS_VERSION = sprintf("%d.%d", $major, $minor) + 0;
}

################################################################################
# Initialize fonts
{
	$FontTahoma = Win32::GUI::Font->new
	(
		-charset	=> 0,	# ANSI_CHARSET
		-face		=> "Tahoma",
		-size		=> 8,
		-bold		=> 0,
		-italic	=>	0,

	) or ui_abort('Initialization Error.');

	$FontTahomaBold = Win32::GUI::Font->new
	(
		-charset	=> 0,	# ANSI_CHARSET
		-face		=> "Tahoma",
		-size		=> 8,
		-bold		=> 1,
		-italic	=>	0,

	) or ui_abort('Initialization Error.');

	$FontTahomaItalic = Win32::GUI::Font->new
	(
		-charset	=> 0,	# ANSI_CHARSET
		-face		=> "Tahoma",
		-size		=> 8,
		-bold		=> 0,
		-italic	=>	1,

	) or ui_abort('Initialization Error.');

	$FontCourierNew = Win32::GUI::Font->new
	(
		-charset	=> 0,	# ANSI_CHARSET
		-face		=> "Courier New",
		-size		=> 10,
		-bold		=> 0,
		-italic	=>	0,

	) or ui_abort('Initialization Error.');

	$FontCourierNewSmall = Win32::GUI::Font->new
	(
		-charset	=> 0,	# ANSI_CHARSET
		-face		=> "Courier New",
		-size		=> 8,
		-bold		=> 0,
		-italic	=>	0,

	) or ui_abort('Initialization Error.');
}

################################################################################
# Initialize icons
{
	$OPIconLg = new		Win32::GUI::Icon($ICO_ID);
	$OPIconSm = new_sm	Win32::GUI::Icon($ICO_ID);
}

################################################################################
# Main window
{
	my($unique_title) = $PROGRAM_TITLE . (time() + 0);

	$ObjMain = new GUI::DialogBox
	(
		-name			=> 'Main',
		-text			=> $unique_title,
		-pos			=> [ 64, 47 ],
		-size			=> $ui_dim_window,
		-addstyle	=> WS_MINIMIZEBOX,
		-addexstyle	=> WS_EX_ACCEPTFILES,
		-remexstyle	=> WS_EX_CONTEXTHELP,

	) or ui_abort('Initialization Error.');

	$hWndMain = Win32::GUI::FindWindow('', $unique_title);
	$ObjMain->Text($PROGRAM_TITLE);
	$ObjMain->ChangeIcon($OPIconLg);
	$ObjMain->ChangeSmallIcon($OPIconSm);

	#$ObjMainMaintenanceTimer = new Win32::GUI::Timer($ObjMain, "MainMaintenanceTimer", 1000) or ui_abort('Initialization Error.');
}

################################################################################
# Main window containers
{
	$ObjMainTabstrip = new Win32::GUI::TabStrip
	(
		$ObjMain,

		-name			=> 'MainTabstrip',
		-pos			=> [ $UI_MARGINS_GENERAL, $UI_MARGINS_GENERAL ],
		-size			=> $ui_dim_tabstrip,
		-addstyle	=> WS_GROUP,
		-buttons		=> (!$UI_USE_TABS),
		-flat			=> (!$UI_USE_TABS),
		-font			=> $FontTahoma,
		-hottrack	=> 1,

	) or ui_abort('Initialization Error.');

	foreach my $i (0 .. $#UI_TABS)
	{
		$ObjMainTabstrip->InsertItem(-text => $UI_TABS[$i]) if ($i != $UI_TABID_DEBUG || $COM_PRINT_DEBUGGING_MESSAGES);

		if ($UI_USE_ROOT && $i)
		{
			# Use only one frame and have all the rest reference it
			# to reduce flicker when switching.
			#
			$ObjMainTabs[$i]{'Frame'} = $ObjMainTabs[$i - 1]{'Frame'};
		}
		else
		{
			if ($UI_USE_SUNKEN)
			{
				$ObjMainTabs[$i]{'Frame'} = new Win32::GUI::Label
				(
					$ObjMain,

					-name			=> "MainTabs$i" . 'Frame',
					-pos			=> ui_addpairs([ $UI_MARGINS_TABSTRIP->[0], $UI_MARGINS_TABSTRIP->[1] ], ui_getpos($ObjMainTabstrip)),
					-size			=> $ui_dim_frame,
					-disabled	=> ($UI_USE_ROOT) ? 1 : 0,
					-sunken		=> 1,
					-visible		=> 0,

				) or ui_abort('Initialization Error.');
			}
			else
			{
				$ObjMainTabs[$i]{'Frame'} = new Win32::GUI::Groupbox
				(
					$ObjMain,

					-name		=> "MainTabs$i" . 'Frame',
					-pos		=> ui_addpairs([ $UI_MARGINS_TABSTRIP->[0], $UI_MARGINS_TABSTRIP->[1] ], ui_getpos($ObjMainTabstrip)),
					-size		=> $ui_dim_frame,
					-font		=> $FontTahomaBold,
					-visible	=> 0,

				) or ui_abort('Initialization Error.');
			}
		}
	}

	$ObjMainDisabledTabText = new Win32::GUI::Label
	(
		$ObjMain,

		-name		=> 'MainDisabledTabText',
		-text		=> 'The contents of this tab are not available for this firmware.',
		-pos		=> ui_addpairs($ui_pos_disabledtab, ui_getpos($ObjMainTabs[0]{'Frame'})),
		-size		=> $ui_dim_disabledtab,
		-align	=> center,
		-font		=> $FontTahoma,
		-visible	=> 0,

	) or ui_abort('Initialization Error.');

	$ObjMainCmdGrp = new Win32::GUI::Groupbox
	(
		$ObjMain,

		-name	=> 'MainCmdGrp',
		-text	=> 'No File Loaded',
		-pos	=> ui_addpairs([ 0, $ui_dim_tabstrip->[1] + $UI_MARGINS_GENERAL ], ui_getpos($ObjMainTabstrip)),
		-size	=> $ui_dim_cmdgrp,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');
}

################################################################################
# General command buttons
{
	$ObjMainCmd->{'Load'} = new Win32::GUI::Button
	(
		($UI_USE_ROOT) ? $ObjMain : $ObjMainCmdGrp,

		-name			=> "MainCmdLoad",
		-text			=> "&Load...",
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($ObjMainCmdGrp)),
		-size			=> $ui_dim_cmd,
		-font			=> $FontTahoma,
		-addstyle	=> WS_GROUP,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$ObjMainCmd->{'Save'} = new Win32::GUI::Button
	(
		($UI_USE_ROOT) ? $ObjMain : $ObjMainCmdGrp,

		-name			=> "MainCmdSave",
		-text			=> "&Save As...",
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], [ $ui_dim_cmd->[0] + $UI_MARGINS_GENERAL, 0 ], ui_getpos_cond($ObjMainCmdGrp)),
		-size			=> $ui_dim_cmd,
		-disabled	=> 1,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$ObjMainCmd->{'About'} = new Win32::GUI::Button
	(
		($UI_USE_ROOT) ? $ObjMain : $ObjMainCmdGrp,

		-name			=> "MainCmdAbout",
		-text			=> "&About",
		-pos			=> ui_addpairs([ $ui_dim_cmdgrp->[0] - $ui_dim_cmd->[0] - $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($ObjMainCmdGrp)),
		-size			=> $ui_dim_cmd,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');
}

################################################################################
# Tab contents: drive ID
{
	my($tid) = $UI_TABID_DRIVE;
	my($namepre) = "MainTabs$tid";
	my($group) = $ObjMainTabs[$tid];

	$FlagTabEnabledStatus[$tid] = 1;

	$group->{'InfoFrame'} = new Win32::GUI::Groupbox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name	=> $namepre . "InfoFrame",
		-text	=> 'General Drive Information for this Firmware',
		-pos	=> ui_addpairs($ui_pos_driveupleft, ui_getpos_cond($group->{'Frame'})),
		-size	=> $ui_dim_drivefrinfo,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	$group->{'InfoBox'} = new Win32::GUI::Textfield
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'InfoFrame'},

		-name			=> $namepre . 'InfoBox',
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($group->{'InfoFrame'})),
		-size			=> $ui_dim_driveinfo,
		-addstyle	=> WS_VSCROLL | ES_READONLY,
		-font			=> $FontCourierNewSmall,
		-multiline	=> 1,
		-remstyle	=> WS_BORDER,

	) or ui_abort('Initialization Error.');

	$group->{'ChangeFrame'} = new Win32::GUI::Groupbox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name	=> $namepre . "ChangeFrame",
		-text	=> 'Change the Drive ID for this Firmware',
		-pos	=> ui_addpairs([ 0, $ui_dim_drivefrinfo->[1] + 2 * $UI_MARGINS_GENERAL ], ui_getpos($group->{'InfoFrame'})),
		-size	=> $ui_dim_drivefrchng,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	$group->{'Selector'} = new Win32::GUI::Combobox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'ChangeFrame'},

		-name			=> $namepre . "Selector",
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($group->{'ChangeFrame'})),
		-size			=> [ $ui_dim_drivesel->[0], $ui_dim_drivesel->[1] + 6 + $UI_FONTHEIGHT_CNEW * 7 ],
		-addstyle	=> WS_VSCROLL | WS_GROUP | 0x03,
		-disabled	=> 1,
		-font			=> $FontCourierNew,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	foreach my $i (0 .. $#UI_DRIVE_FIELDS)
	{
		$group->{'FieldLabels'}[$i] = new Win32::GUI::Label
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'ChangeFrame'},

			-name			=> $namepre . "FieldLabels$i",
			-text			=> $UI_DRIVE_FIELDS[$i][0],
			-pos			=> ui_addpairs([ $ui_left_field[$i], $ui_dim_drivesel->[1] + $UI_MARGINS_GENERAL ], ui_getpos($group->{'Selector'})),
			-size			=> $ui_dim_field[$i],
			-disabled	=> 1,
			-font			=> $FontTahoma,

		) or ui_abort('Initialization Error.');

		$group->{'Fields'}[$i] = new Win32::GUI::Textfield
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'ChangeFrame'},

			-name			=> $namepre . "Fields$i",
			-pos			=> ui_addpairs([ 0, $ui_dim_mediafieldlabel[$i][1] + 1 ], ui_getpos($group->{'FieldLabels'}[$i])),
			-size			=> [ $ui_dim_field[$i][0], $UI_HEIGHT_TEXTBOX ],
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-font			=> $FontCourierNew,
			-disabled	=> 1,
			-readonly	=> 1,
			-remstyle	=> WS_BORDER,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');

		$group->{'Fields'}[$i]->MaxLength($UI_DRIVE_FIELDS[$i][1]);
	}
}

################################################################################
# Tab contents: DVD media support
{
	my($tid) = $UI_TABID_MEDIA;
	my($namepre) = "MainTabs$tid";
	my($group) = $ObjMainTabs[$tid];

	$FlagTabEnabledStatus[$tid] = 0;

	$group->{'List'} = new Win32::GUI::Listbox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name			=> $namepre . 'List',
		-pos			=> ui_addpairs([ $UI_MARGINS_BLANKGROUP->[0], $UI_MARGINS_BLANKGROUP->[1] ], ui_getpos_cond($group->{'Frame'})),
		-size			=> $ui_dim_medialist,
		-addstyle	=> WS_VSCROLL | WS_GROUP,
		-disabled	=> 1,
		-font			=> $FontCourierNew,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	foreach my $i (0 .. $#MEDIA_SPEEDS_STD)
	{
		$group->{'Speeds'}[$i] = new Win32::GUI::Checkbox
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

			-name			=> $namepre . "Speeds$i",
			-text			=> "$MEDIA_SPEEDS_STD[$i]x",
			-pos			=> ui_addpairs([ $UI_MARGINS_GENERAL + $ui_dim_medialist->[0], ($ui_dim_mediaspd->[1] + 4) * $i ], ui_getpos($group->{'List'})),
			-size			=> $ui_dim_mediaspd,
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-disabled	=> 1,
			-font			=> $FontTahoma,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');
	}

	foreach my $i (0 .. $#UI_MEDIA_TXT)
	{
		$group->{'FieldLabels'}[$i] = new Win32::GUI::Label
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

			-name			=> $namepre . "FieldLabels$i",
			-text			=> $UI_MEDIA_TXT[$i],
			-pos			=> ui_addpairs($ui_pos_mediafieldlabel[$i], ui_getpos($group->{'Speeds'}[0])),
			-size			=> $ui_dim_mediafieldlabel[$i],
			-disabled	=> 1,
			-font			=> $FontTahoma,

		) or ui_abort('Initialization Error.');

		$group->{'Fields'}[$i] = new Win32::GUI::Textfield
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

			-name			=> $namepre . "Fields$i",
			-pos			=> ui_addpairs([ 0, $ui_dim_mediafieldlabel[$i][1] + 1 ], ui_getpos($group->{'FieldLabels'}[$i])),
			-size			=> $ui_dim_mediafield[$i],
			-addstyle	=> (($i == 0) ? 1 : 0) * WS_GROUP,
			-font			=> $FontCourierNew,
			-disabled	=> 1,
			-remstyle	=> WS_BORDER,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');

		$group->{'Fields'}[$i]->MaxLength($UI_MAX_LEN[$i]);
	}

	$group->{'StratLabel'} = new Win32::GUI::Label
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name			=> $namepre . 'StratLabel',
		-text			=> $UI_STRATLABEL[0],
		-pos			=> ui_addpairs([ 0, $UI_MARGINS_GENERAL + $ui_dim_medialist->[1] ], ui_getpos($group->{'List'})),
		-size			=> $ui_dim_medialabel,
		-align		=> center,
		-disabled	=> 1,
		-font			=> $FontTahomaItalic,
		-sunken		=> 1,

	) or ui_abort('Initialization Error.');

	foreach my $i (0 .. 1)
	{
		$group->{'Divider'}[$i] = new Win32::GUI::Label
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

			-name			=> $namepre . 'Divider$i',
			-pos			=> ui_addpairs($ui_pos_mediadiv[$i], ui_getpos_cond($group->{'Frame'})),
			-size			=> $ui_dim_mediadiv[$i],
			-disabled	=> 1,
			-sunken		=> 1,

		) or ui_abort('Initialization Error.');
	}

	$group->{'InfoBox'} = new Win32::GUI::Textfield
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name			=> $namepre . 'InfoBox',
		-pos			=> ui_addpairs([ 0, $ui_dim_mediadiv[1][1] + $UI_MARGINS_GENERAL ], ui_getpos($group->{'Divider'}[1])),
		-size			=> $ui_dim_mediainfo,
		-addstyle	=> WS_VSCROLL,
		-font			=> $FontCourierNewSmall,
		-multiline	=> 1,
		-readonly	=> ($UI_OS_VERSION >= 5.1) ? 1 : 0,
		-remstyle	=> WS_BORDER,

	) or ui_abort('Initialization Error.');

	$group->{'Tweak'} = new Win32::GUI::Button
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name			=> $namepre . 'Tweak',
		-text			=> 'Apply Recommended Media T&weaks',
		-pos			=> ui_addpairs([ 0, $UI_MARGINS_GENERAL + $ui_dim_mediadiv[0][1] ], ui_getpos($group->{'Divider'}[0])),
		-size			=> $ui_dim_mediacmd,
		-addstyle	=> WS_GROUP,
		-disabled	=> 1,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$group->{'ExtCmds'} = new Win32::GUI::Button
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name			=> $namepre . 'ExtCmds',
		-text			=> 'More &Commands >>',
		-pos			=> ui_addpairs([ $UI_MARGINS_GENERAL + $ui_dim_mediacmd->[0], 0 ], ui_getpos($group->{'Tweak'})),
		-size			=> $ui_dim_mediacmd,
		-disabled	=> 1,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$group->{'Menu'} = new Win32::GUI::Menu
	(
		"Extended Commands" => "Popup",
		">&Save DVD media code report..." => "PopupSaveReport",
		">&Import speed and strategy settings from a report file..." => "PopupLoadReport",
		">Rename this code using a media code &block dump..." => "PopupImportCode",
		">&Reset media ID and speed changes for this code" => "PopupUndoCode",

	) or ui_abort('Initialization Error.');
}

################################################################################
# Tab contents: general patches
{
	my($tid) = $UI_TABID_PATCHES;
	my($namepre) = "MainTabs$tid";
	my($group) = $ObjMainTabs[$tid];

	$FlagTabEnabledStatus[$tid] = 0;

	foreach my $key (@FW_PATCH_KEYS)
	{
		push(@ui_pos_patches, ui_addpairs([ $ui_margins_patchesframe, $UI_MARGINS_BLANKGROUP->[1] + $UI_MARGINS_GENERAL + (($UI_FONTHEIGHT_TAHOMA + 4) * ($#ui_pos_patches + 1)) ], ui_getpos_cond($group->{'Frame'})));

		$group->{$key} = new Win32::GUI::Checkbox
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

			-name			=> $namepre . "Patch$key",
			-text			=> $FW_PATCHES{$key}->[0],
			-pos			=> $ui_pos_patches[-1],
			-size			=> [ $ui_width_patchesframe, $UI_FONTHEIGHT_TAHOMA ],
			-addstyle	=> (($#ui_pos_patches == 0) ? 1 : 0) * WS_GROUP,
			-disabled	=> 1,
			-font			=> $FontTahoma,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');
	}

	$group->{'RSFrame'} = new Win32::GUI::Groupbox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name		=> $namepre . "RSFrame",
		-text		=> 'Set DVD Read Speeds',
		-pos		=> ui_addpairs([ $ui_margins_patchesframe, $ui_dim_frame->[1] - ($ui_dim_rsgroup->[1] + $ui_margins_patchesframe) ], ui_getpos_cond($group->{'Frame'})),
		-size		=> $ui_dim_rsgroup,
		-font		=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	foreach my $i (@FW_RS_IDX)
	{
		$group->{'DropLabels'}[$i] = new Win32::GUI::Label
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'RSFrame'},

			-name			=> $namepre . "DropLabels$i",
			-text			=> "$FW_RS_NAME[$i]:",
			-pos			=> ($i) ? ui_addpairs([ $group->{'DropLabels'}[$i - 1]->Width() + $UI_MARGINS_GENERAL, 0 ], ui_getpos($group->{'DropLabels'}[$i - 1])) : ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($group->{'RSFrame'})),
			-size			=> [ $ui_dim_rsdrop->[0] + (($i > ($#FW_RS_IDX - $ui_dim_rsextra)) ? 1 : 0), $UI_FONTHEIGHT_TAHOMA ],
			-disabled	=> 1,
			-font			=> $FontTahoma,

		) or ui_abort('Initialization Error.');

		$group->{'Drops'}[$i] = new Win32::GUI::Combobox
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'RSFrame'},

			-name			=> $namepre . "Drops$i",
			-pos			=> ui_addpairs([ 0, $UI_FONTHEIGHT_TAHOMA + 1 ], ui_getpos($group->{'DropLabels'}[$i])),
			-size			=> [ $group->{'DropLabels'}[$i]->Width(), $ui_dim_rsdrop->[1] + 6 + $UI_FONTHEIGHT_TAHOMA * 7 ],
			-addstyle	=> WS_VSCROLL | ((($i == 0) ? 1 : 0) * WS_GROUP) | 0x03,
			-disabled	=> 1,
			-font			=> $FontTahoma,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');
	}

	$group->{'LEDFrame'} = new Win32::GUI::Groupbox
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name		=> $namepre . "LEDFrame",
		-text		=> 'LED Blink Options',
		-pos		=> ui_addpairs([ 0, -($ui_dim_rsgroup->[1] + $UI_MARGINS_GENERAL) ], ui_getpos($group->{'RSFrame'})),
		-size		=> $ui_dim_rsgroup,
		-font		=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	foreach my $i (0 .. $#FW_LED_LABELS)
	{
		$group->{'LEDDropLabels'}[$i] = new Win32::GUI::Label
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'LEDFrame'},

			-name			=> $namepre . "LEDDropLabels$i",
			-text			=> "$FW_LED_LABELS[$i]:",
			-pos			=> ($i) ? ui_addpairs([ $group->{'LEDDropLabels'}[$i - 1]->Width() + $UI_MARGINS_GENERAL, 0 ], ui_getpos($group->{'LEDDropLabels'}[$i - 1])) : ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos_cond($group->{'LEDFrame'})),
			-size			=> [ $ui_width_leddrop[$i], $UI_FONTHEIGHT_TAHOMA ],
			-font			=> $FontTahoma,

		) or ui_abort('Initialization Error.');

		$group->{'LEDDrops'}[$i] = new Win32::GUI::Combobox
		(
			($UI_USE_ROOT) ? $ObjMain : $group->{'LEDFrame'},

			-name			=> $namepre . "LEDDrops$i",
			-pos			=> ui_addpairs([ 0, $UI_FONTHEIGHT_TAHOMA + 1 ], ui_getpos($group->{'LEDDropLabels'}[$i])),
			-size			=> [ $group->{'LEDDropLabels'}[$i]->Width(), $ui_dim_rsdrop->[1] + 6 + $UI_FONTHEIGHT_TAHOMA * 7 ],
			-addstyle	=> WS_VSCROLL | ((($i == 0) ? 1 : 0) * WS_GROUP) | 0x03,
			-font			=> $FontTahoma,
			-tabstop		=> 1,

		) or ui_abort('Initialization Error.');
	}

	$group->{'LEDDrops'}[0]->Add(@FW_LED_BEHAVS);
	$group->{'LEDDrops'}[1]->Add( map { sprintf("%d ms", $_ * 20) } ($FW_LED_MINRATE .. $FW_LED_MAXRATE));
}

################################################################################
# Tab contents: debug log
{
	my($tid) = $UI_TABID_DEBUG;
	my($namepre) = "MainTabs$tid";
	my($group) = $ObjMainTabs[$tid];

	$FlagTabEnabledStatus[$tid] = 1;

	$group->{'Log'} = new Win32::GUI::Textfield
	(
		($UI_USE_ROOT) ? $ObjMain : $group->{'Frame'},

		-name				=> $namepre . 'Log',
		-pos				=> ui_addpairs([ 0 * $UI_MARGINS_BLANKGROUP->[0], 0 * $UI_MARGINS_BLANKGROUP->[1] ], ui_getpos_cond($group->{'Frame'})),
		-size				=> ui_addpairs([ -0 * $UI_MARGINS_BLANKGROUP->[0], -0 * $UI_MARGINS_BLANKGROUP->[1] ], $ui_dim_frame),
		-addstyle		=> WS_VSCROLL | WS_HSCROLL | ES_WANTRETURN,
		-font				=> $FontCourierNewSmall,
		-keepselection	=> 1,
		-multiline		=> 1,
		-remstyle		=> WS_BORDER,

	) or ui_abort('Initialization Error.');
}

################################################################################
# Strategy box window
{
	$ObjStBox = new GUI::DialogBox
	(
		-name			=> "StBox",
		-size			=> $ui_dim_stb,
		-remexstyle	=> WS_EX_CONTEXTHELP,

	) or ui_abort('Initialization Error.');

	$ObjStBox->ChangeIcon($OPIconLg);
	$ObjStBox->ChangeSmallIcon($OPIconSm);

	$ObjStBoxGroup = new Win32::GUI::Groupbox
	(
		$ObjStBox,

		-name	=> "StBoxGroup",
		-text	=> "Select Write Strategy",
		-pos	=> [ $UI_MARGINS_GENERAL, $UI_MARGINS_GENERAL ],
		-size	=> $ui_dim_stb_group,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	$ObjStBoxList = new Win32::GUI::Listbox
	(
		$ObjStBox,

		-name			=> "StBoxList",
		-pos			=> ui_addpairs([$UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1]], ui_getpos($ObjStBoxGroup)),
		-size			=> $ui_dim_stb_list,
		-addstyle	=> WS_VSCROLL | WS_GROUP,
		-font			=> $FontCourierNew,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$ObjStBoxApply = new Win32::GUI::Button
	(
		$ObjStBox,

		-name			=> "StBoxApply",
		-text			=> "&Apply",
		-pos			=> ui_addpairs([ 0, $ui_dim_stb_list->[1] + $UI_MARGINS_GENERAL ], ui_getpos($ObjStBoxList)),
		-size			=> $ui_dim_stb_cmd,
		-addstyle	=> WS_GROUP,
		-font			=> $FontTahoma,
		-ok			=> 1,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$ObjStBoxCancel = new Win32::GUI::Button
	(
		$ObjStBox,

		-name			=> "StBoxCancel",
		-text			=> "&Cancel",
		-pos			=> ui_addpairs([ $ui_dim_stb_cmd->[0] + $UI_MARGINS_GENERAL, 0 ], ui_getpos($ObjStBoxApply)),
		-size			=> $ui_dim_stb_cmd,
		-cancel		=> 1,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');
}

################################################################################
# Media code input window
{
	my($title) = "Input Media Code Block";
	my($unique_title) = $title . (time() + 0);

	$ObjMIDBox = new GUI::DialogBox
	(
		-name			=> "MIDBox",
		-text			=> $unique_title,
		-size			=> $ui_dim_mib,
		-remexstyle	=> WS_EX_CONTEXTHELP,

	) or ui_abort('Initialization Error.');

	$hWndMIDBox = Win32::GUI::FindWindow('', $unique_title);
	$ObjMIDBox->Text($title);
	$ObjMIDBox->ChangeIcon($OPIconLg);
	$ObjMIDBox->ChangeSmallIcon($OPIconSm);

	$ObjMIDBoxInstrGroup = new Win32::GUI::Groupbox
	(
		$ObjMIDBox,

		-name	=> "MIDBoxInstrGroup",
		-text	=> "Instructions",
		-pos	=> [ $UI_MARGINS_GENERAL, $UI_MARGINS_GENERAL ],
		-size	=> $ui_dim_mib_instrgrp,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	$ObjMIDBoxInstr = new Win32::GUI::Textfield
	(
		$ObjMIDBox,

		-name			=> "MIDBoxInstr",
		-text			=> $UI_MIDBOX_INSTR,
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos($ObjMIDBoxInstrGroup)),
		-size			=> $ui_dim_mib_instr,
		-addstyle	=> WS_VSCROLL | ES_READONLY,
		-font			=> $FontTahoma,
		-multiline	=> 1,
		-remstyle	=> WS_BORDER,

	) or ui_abort('Initialization Error.');

	$ObjMIDBoxEditGroup = new Win32::GUI::Groupbox
	(
		$ObjMIDBox,

		-name	=> "MIDBoxEditGroup",
		-text	=> "Media Code Block",
		-pos	=> ui_addpairs([ 0, $ui_dim_mib_instrgrp->[1] + $UI_MARGINS_GENERAL ], ui_getpos($ObjMIDBoxInstrGroup)),
		-size	=> $ui_dim_mib_editgrp,
		-font	=> $FontTahomaBold,

	) or ui_abort('Initialization Error.');

	$ObjMIDBoxEdit = new Win32::GUI::Textfield
	(
		$ObjMIDBox,

		-name			=> "MIDBoxEdit",
		-pos			=> ui_addpairs([ $UI_MARGINS_GROUP->[0], $UI_MARGINS_GROUP->[1] ], ui_getpos($ObjMIDBoxEditGroup)),
		-size			=> $ui_dim_mib_edit,
		-addstyle	=> WS_VSCROLL,
		-font			=> $FontCourierNewSmall,
		-multiline	=> 1,
		-remstyle	=> WS_BORDER,

	) or ui_abort('Initialization Error.');

	$ObjMIDBoxImport = new Win32::GUI::Button
	(
		$ObjMIDBox,

		-name			=> "MIDBoxImport",
		-text			=> "&Import",
		-pos			=> ui_addpairs([ $ui_dim_mib_instrgrp->[0] - (2 * $ui_dim_mib_cmd->[0] + $UI_MARGINS_GROUP->[0] + $UI_MARGINS_GENERAL), $ui_dim_mib_edit->[1] + $UI_MARGINS_GENERAL + $UI_MARGINS_GROUP->[1] ], ui_getpos($ObjMIDBoxEditGroup)),
		-size			=> $ui_dim_mib_cmd,
		-addstyle	=> WS_GROUP,
		-font			=> $FontTahoma,
		-ok			=> 1,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');

	$ObjMIDBoxCancel = new Win32::GUI::Button
	(
		$ObjMIDBox,

		-name			=> "MIDBoxCancel",
		-text			=> "&Cancel",
		-pos			=> ui_addpairs([ $ui_dim_mib_instrgrp->[0] - ($ui_dim_mib_cmd->[0] + $UI_MARGINS_GROUP->[0]), $ui_dim_mib_edit->[1] + $UI_MARGINS_GENERAL + $UI_MARGINS_GROUP->[1] ], ui_getpos($ObjMIDBoxEditGroup)),
		-size			=> $ui_dim_mib_cmd,
		-cancel		=> 1,
		-font			=> $FontTahoma,
		-tabstop		=> 1,

	) or ui_abort('Initialization Error.');
}

################################################################################
# Create aliases
{
	$DriveTab = $ObjMainTabs[$UI_TABID_DRIVE];
	$MediaTab = $ObjMainTabs[$UI_TABID_MEDIA];
	$PatchesTab = $ObjMainTabs[$UI_TABID_PATCHES];
	$DebugTab = $ObjMainTabs[$UI_TABID_DEBUG];
}

$ObjMain->Show();
MainTabstrip_Change();
fw_led_ctrltoggle(0);

1;
