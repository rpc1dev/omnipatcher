##
# OmniPatcher for LiteOn DVD-Writers
# User Interface : Event handlers
#
# Modified: 2005/06/12, C64K
#

################################################################################
# Main window
{
	sub Main_Terminate
	{
		return -1;
	}

	sub Main_Activate
	{
		if ($ObjStBox->IsVisible())
		{
			$ObjStBox->SetForegroundWindow();
			return 0;
		}

		return 1;
	}

	sub Main_DropFiles
	{
		my($hDrop) = @_;
		
		my($buflen) = 1024;
		my($buffer) = chr(" ") x $buflen;

		if (Win32::GUI::DragQueryFile($hDrop, 0xFFFFFFFF, $buffer, $buflen) != 1)
		{
			Win32::GUI::DragFinish($hDrop);
			ui_error("Only one file can be opened at a time.");
		}
		else
		{
			my($bytes) = Win32::GUI::DragQueryFile($hDrop, 0, $buffer, $buflen);
			Win32::GUI::DragFinish($hDrop);
			fw_load(substr($buffer, 0, $bytes));
		}

		return 1;
	}

	sub MainTabstrip_Change
	{
		my($i);

		if ($UI_USE_ROOT)
		{
			foreach $i (0 .. $#ObjMainTabs)
			{
				($i == ui_getselected($ObjMainTabstrip)) ?
				map { (ref($ObjMainTabs[$i]{$_}) eq 'ARRAY') ? map { ui_setvisible_tabchng($_) } @{$ObjMainTabs[$i]{$_}} : ui_setvisible_tabchng($ObjMainTabs[$i]{$_}) } keys(%{$ObjMainTabs[$i]}) :
				map { (ref($ObjMainTabs[$i]{$_}) eq 'ARRAY') ? map { ui_setinvisible_tabchng($_) } @{$ObjMainTabs[$i]{$_}} : ui_setinvisible_tabchng($ObjMainTabs[$i]{$_}) } grep { $_ ne 'Frame' } keys(%{$ObjMainTabs[$i]});
			}
		}
		else
		{
			foreach $i (0 .. $#ObjMainTabs)
			{
				($i == ui_getselected($ObjMainTabstrip)) ?
				ui_setvisible_tabchng($ObjMainTabs[$i]{'Frame'}) :
				ui_setinvisible_tabchng($ObjMainTabs[$i]{'Frame'});
			}
		}

		return 1;
	}
}

################################################################################
# General command buttons
{
	sub MainCmdLoad_Click
	{
		my(%ofn) =
		(
			-owner				=> $hWndMain,
			-title				=> "Select File to Patch",
			-directory			=> "",
			-file					=> "",
			-filter				=> [ "Firmwares (*.bin;*.exe)", "*.bin;*.exe" ],
			-defaultextention	=> "bin",
			-filemustexist		=> 1,
			-hidereadonly		=> 1,
			-pathmustexist		=> 1,
		);

		return 1 unless ($ofn{'-ret'} = Win32::GUI::GetOpenFileName(%ofn));

		fw_load($ofn{'-ret'});

		return 1;
	}

	sub MainCmdSave_Click
	{
		my($default_name) = $Current{'shortname'};
		$default_name =~ s/\.(?:bin|exe)$/-patched.$Current{'ext'}/i unless ($default_name =~ s/stock/patched/i);

		my(%ofn) =
		(
			-owner				=> $hWndMain,
			-title				=> "Select Output File",
			-directory			=> "",
			-file					=> $default_name,
			-pathmustexist		=> 1,
		);

		if ($Current{'ext'} eq "bin")
		{
			$ofn{'-filter'} = [ "Raw Firmwares (*.bin)", "*.bin" ];
			$ofn{'-defaultextention'} = "bin";
		}
		else
		{
			$ofn{'-filter'} = [ "Executable Firmwares (*.exe)", "*.exe", "Raw Firmwares (*.bin)", "*.bin" ];
			$ofn{'-defaultextention'} = "exe";
		}

		return 1 unless ($ofn{'-ret'} = Win32::GUI::GetSaveFileName(%ofn));

		fw_save($ofn{'-ret'});

		return 1;
	}

	sub MainCmdAbout_Click
	{
		return ui_infobox("$PROGRAM_TITLE\nVersion $PROGRAM_VERSION, built on $BUILD_STAMP\n\nWeb: http://codeguys.rpc1.org/", "About", 1);
	}
}

################################################################################
# Tab contents: drive ID
{
	sub MainTabs0Selector_Change
	{
		fw_proc_drivesel(ui_getselected($DriveTab->{'Selector'}));
		return 1;
	}
}

################################################################################
# Tab contents: DVD media support
{
	sub MainTabs1List_Click
	{
		$FlagIgnoreMediaChange = 1;
		media_proc_listclick(ui_getselected($MediaTab->{'List'}));
		$FlagIgnoreMediaChange = 0;

		return 1;
	}

	sub MainTabs1List_DblClick
	{
		my($idx) = ui_getselected($MediaTab->{'List'});
		return 1 if ($idx < 0);

		my($code) = $Current{'media_table'}->[$idx];
		my($i);

		if ( $Current{'media_strat_status'} >= 0 &&
		     ($code->[0] == $MEDIA_TYPE_DVD_PR || $code->[0] == $MEDIA_TYPE_DVD_DR) &&
		     $Current{'media_strat'}->[$code->[0]]{'status'} >= 0 )
		{
			@StratList = grep { $_->[0] == $code->[0] } @{$Current{'media_table'}};

			for ($i = 0; $i <= $#StratList; ++$i)
			{
				last if ($StratList[$i][1] == $code->[3]);
			}

			$ObjStBoxList->Clear();
			$ObjStBoxList->Add( map { $_->[5] } @StratList );
			$ObjStBoxList->Select($i);
			$ObjStBox->Left($ObjMain->Left() + $UI_NC_WIDTH);
			$ObjStBox->Top($ObjMain->Top() + $UI_NC_HEIGHT);

			$ObjStBox->Text((media_istype($code->[0], $MEDIA_TYPE_DVD_P)) ?
				media_cleandisp(sprintf("%s%s-%02X", $code->[4]{'MID'}, $code->[4]{'TID'}, $code->[4]{'RID'})) :
				media_cleandisp(sprintf("%s-%02X", $code->[4]{'MID'}, $code->[4]{'RID'})));

			$ObjStBox->Show();
		}

		return 1;
	}

	sub MainTabs1Speeds0_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds1_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds2_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds3_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds4_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds5_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Speeds6_Click { media_proc_spdchange() unless ($FlagIgnoreMediaChange); return 1; }

	sub MainTabs1Fields0_Change { media_proc_fieldchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Fields1_Change { media_proc_fieldchange() unless ($FlagIgnoreMediaChange); return 1; }
	sub MainTabs1Fields2_Change { media_proc_fieldchange() unless ($FlagIgnoreMediaChange); return 1; }

	sub MainTabs1Tweak_Click
	{
		media_proc_tweaks(ui_getselected($MediaTab->{'List'}));
		return 1;
	}

	sub MainTabs1Report_Click
	{
		my($default_name) = $Current{'shortname'};
		$default_name =~ s/\.(?:bin|exe)$/-media_report.txt/i;

		my(%ofn) =
		(
			-owner				=> $hWndMain,
			-title				=> "Select File Name for the Media Code Report",
			-directory			=> "",
			-file					=> $default_name,
			-filter				=> [ "Text Documents (*.txt)", "*.txt" ],
			-defaultextention	=> "txt",
			-pathmustexist		=> 1,
		);

		return 1 unless ($ofn{'-ret'} = Win32::GUI::GetSaveFileName(%ofn));

		media_save_report($ofn{'-ret'});

		return 1;
	}
}

################################################################################
# Tab contents: general patches
{
	sub MainTabs2PatchES_Click
	{
		if ($PatchesTab->{'ES'}->GetCheck() && $PatchesTab->{'FS'}->IsEnabled() && !$PatchesTab->{'FS'}->GetCheck())
		{
			ui_infobox(qq(If you choose to apply the "$FW_PATCHES{'ES'}->[0]"\npatch, it is highly recommended that you also apply the\n"$FW_PATCHES{'FS'}->[0]" patch.), "Notice");
			ui_setcheck($PatchesTab->{'FS'}, 1);
		}

		return 1;
	}

	sub MainTabs2PatchFF_Click
	{
		if ($PatchesTab->{'FF'}->GetCheck() && !$FlagWarnedPatchFF)
		{
			$FlagWarnedPatchFF = 1;
			ui_infobox("It is recommended that you apply this patch only if your burns exhibit\na \"mountain\" error effect at the very end of a disc.\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.", "Notice");
		}

		return 1;
	}

	sub MainTabs2PatchDL_Click
	{
		if ($PatchesTab->{'DL'}->GetCheck() && !$FlagWarnedPatchDL)
		{
			$FlagWarnedPatchDL = 1;
			ui_warning("Please note that this is an experimental patch!\n\nYou should not use this patch unless you are experiencing\nproblems with deteriorating burns.\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.");
		}

		return 1;
	}

	sub MainTabs2Drops0_Change { fw_rs_proc(0, ui_getselected($PatchesTab->{'Drops'}[0])); return 1; }
	sub MainTabs2Drops1_Change { fw_rs_proc(1, ui_getselected($PatchesTab->{'Drops'}[1])); return 1; }
	sub MainTabs2Drops2_Change { fw_rs_proc(2, ui_getselected($PatchesTab->{'Drops'}[2])); return 1; }
	sub MainTabs2Drops3_Change { fw_rs_proc(3, ui_getselected($PatchesTab->{'Drops'}[3])); return 1; }
	sub MainTabs2Drops4_Change { fw_rs_proc(4, ui_getselected($PatchesTab->{'Drops'}[4])); return 1; }
}

################################################################################
# Strategy box window
{
	sub StBox_Terminate
	{
		StBoxCancel_Click();
		return 0;
	}

	sub StBoxList_DblClick
	{
		return StBoxApply_Click();
	}

	sub StBoxApply_Click
	{
		my($idxa) = $MediaTab->{'List'}->SelectedItem();
		my($idxb) = $ObjStBoxList->SelectedItem();

		$Current{'media_table'}->[$idxa][3] = $StratList[$idxb][1];
		media_refresh_listitem($idxa);

		return StBoxCancel_Click();
	}

	sub StBoxCancel_Click
	{
		$ObjStBox->Hide();
		return 1;
	}
}

1;