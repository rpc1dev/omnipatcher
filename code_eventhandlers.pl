sub Main_Terminate
{
	return -1;
}

sub Main_Activate
{
	if ($ObjStMain->IsVisible())
	{
		$ObjStMain->SetForegroundWindow();
		return 0;
	}

	return 1;
}

sub StMain_Terminate
{
	$ObjStMain->Hide();
	return 0;
}

sub List_Click
{
	my($idx) = $ObjList->SelectedItem();
	my($i, $type);

	if ($idx < 0)
	{
		foreach $i (0 .. $#ObjSpeeds)
		{
			SetDisable($ObjSpeeds[$i]);
			SetCheck($ObjSpeeds[$i], 0);
			SetText($ObjSpeeds[$i], "$MEDIA_SPEEDS[$i]x");
			($MEDIA_SPEEDS[$i] > $file_data{'r_limit'}) ? SetInvisible($ObjSpeeds[$i]) : SetVisible($ObjSpeeds[$i])
		}
	}
	else
	{
		$type = $file_data{'codes'}->[$idx][0];

		foreach $i (0 .. $#ObjSpeeds)
		{
			if ( ($MEDIA_SPEEDS[$i] > $file_data{'r_limit'}) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'r9_limit'} && $type =~ /^.R9/) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'rw_limit'} && $type =~ /^.RW/) ||
			     ($MEDIA_SPEEDS[$i] == 1 && $type =~ /^\+/) )
			{
				SetDisable($ObjSpeeds[$i]);
				SetInvisible($ObjSpeeds[$i]);
			}
			else
			{
				SetEnable($ObjSpeeds[$i]);
				SetVisible($ObjSpeeds[$i]);
			}

			if ($MEDIA_SPEEDS[$i] == 2 && $type =~ /^\+/)
			{
				SetText($ObjSpeeds[$i], "2.4x");
			}
			else
			{
				SetText($ObjSpeeds[$i], "$MEDIA_SPEEDS[$i]x");
			}

			SetCheck($ObjSpeeds[$i], ($file_data{'speeds'}->[$idx] & (2 ** $i)) ? 1 : 0);
		}
	}

	return 1;
}

sub List_DblClick
{
	my($idx) = $ObjList->SelectedItem();
	my($i);

	if ($file_data{'strat_status'} >= 0 && $file_data{'codes'}->[$idx][0] =~ /^.R$/)
	{
		@StratList = grep { $_->[0] eq $file_data{'codes'}->[$idx][0] } @{$file_data{'codes'}};

		for ($i = 0; $i <= $#StratList; ++$i)
		{
			last if ($StratList[$i][3] == $file_data{'strats'}->[$idx]);
		}

		$ObjStList->Clear();
		$ObjStList->Add( map { $_->[2] } @StratList );
		$ObjStList->Select($i);

		if ($file_data{'codes'}->[$idx][0] eq "+R")
		{
			$ObjStMain->Text(sprintf("%s%s-%02X", @{$file_data{'codes'}->[$idx][1]}));
		}
		else
		{
			$ObjStMain->Text($file_data{'codes'}->[$idx][1][0]);
		}

		$ObjStMain->Left($ObjMain->Left() + $NC_WIDTH);
		$ObjStMain->Top($ObjMain->Top() + $NC_HEIGHT);
		$ObjStMain->Show();
	}

	return 1;
}

sub Speeds0_Click { return proc_speed(); }
sub Speeds1_Click { return proc_speed(); }
sub Speeds2_Click { return proc_speed(); }
sub Speeds3_Click { return proc_speed(); }
sub Speeds4_Click { return proc_speed(); }
sub Speeds5_Click { return proc_speed(); }
sub Speeds6_Click { return proc_speed(); }

sub SpdRep_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select File Name for the Media Code Report",
		-directory			=> "",
		-file					=> "",
		-filter				=> [ "Text Documents (*.txt)", "*.txt" ],
		-defaultextention	=> "txt",
		-pathmustexist		=> 1,
	);

	return 1 unless ($ofn{'-ret'} = Win32::GUI::GetSaveFileName(%ofn));

	save_report($ofn{'-ret'});

	return 1;
}

sub DefStrat_Click
{
	my($entry, $gen, $src, $dst, $st_count, $sp_count);

	if ($DEF_STRAT_REV eq "" || $#DEF_STRATS < 0)
	{
		error(qq(The "$DEFSTRATCONF" file is missing or corrupt.));
		return 1;
	}

	foreach $entry (@DEF_STRATS)
	{
		foreach $gen (@{$entry->[3]})
		{
			if ($file_data{'gen'} == $gen)
			{
				$src = find_index($entry->[0]);

				if ($src >= 0)
				{
					$dst = find_index($entry->[1]);

					if ($dst >= 0 && $file_data{'strats'}->[$src] != $file_data{'codes'}->[$dst][3])
					{
						++$st_count;
						$file_data{'strats'}->[$src] = $file_data{'codes'}->[$dst][3];
						refresh_st_display($src);
					}

					if ($#{$entry->[2]} == 0 && $entry->[2][0] > 0 && $file_data{'speeds'}->[$src] != $entry->[2][0])
					{
						++$sp_count;
						$file_data{'speeds'}->[$src] = $entry->[2][0];
					}
				}

				last;

			} # END: if $gen

		} # END: foreach $gen

	} # END: foreach $entry

	List_Click();

	Win32::GUI::MessageBox($hWndMain, sprintf("%d write strategy replacement(s) applied.\n%d writing speed adjustment(s) applied.\n\nRevision %s", $st_count, $sp_count, $DEF_STRAT_REV), "Status", MB_OK | MB_ICONINFORMATION);

	return 1;
}

sub Patches2_Click
{
	if ($ObjPatches[2]->GetCheck() && $ObjPatches[3]->IsEnabled())
	{
		my($temp) = $PATCH_NAMES[3];
		$temp =~ s/"/'/g;
		Win32::GUI::MessageBox($hWndMain, "If you choose to apply the \"$PATCH_NAMES[2]\"\npatch, it is highly recommended that you also apply the\n\"$temp\" patch.", "Notice", MB_OK | MB_ICONINFORMATION);

		SetCheck($ObjPatches[3], 1);
	}

	return 1;
}

sub Patches4_Click
{
	if ($ObjPatches[4]->GetCheck())
	{
		Win32::GUI::MessageBox($hWndMain, "It is recommended that you do not apply this patch unless your burns\nexhibit a \"mountain\" error effect at the very end of a disc.  This patch\nmay cause undesirable linking-related side effects.\n\nPlease refer to the documentation for more information.", "Warning!", MB_OK | MB_ICONWARNING);
	}

	return 1;
}

sub Cmds0_Click
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

	my(%new_file) =
	(
		longname => $ofn{'-ret'},
		shortname => substr($ofn{'-ret'}, rindex($ofn{'-ret'}, '\\') + 1),
	);

	if ($new_file{'shortname'} =~ /\.(bin|exe)$/i)
	{
		$new_file{'ext'} = lc($1);
	}
	else
	{
		return error("Invalid file type.", 1)
	}

	if ($new_file{'ext'} eq "bin")
	{
		open file, $new_file{'longname'};
		binmode file;
		read(file, $new_file{'work'}, -s file);
		close file;

		return error("Invalid .BIN file size!\nAborting load process.", 1) if (length($new_file{'work'}) != 0x100000);
		return error("This firmware appears to be corrupted.\nAborting load process.", 1) if (substr($new_file{'work'}, 0, 1) ne "\x02");
	}
	else
	{
		my($xfx) = xflashx($new_file{'longname'});

		$new_file{'name'} = $xfx->[0][0][0];
		$new_file{'work'} = $xfx->[0][0][1];
		$new_file{'offset'} = $xfx->[0][0][2];
		$new_file{'key_offset'} = $xfx->[0][0][3];
		$new_file{'exkey'} = $xfx->[0][0][4];
		$new_file{'exedata'} = $xfx->[1];

		return error("Unable to process this .EXE file!\nPlease make sure that the file is valid.\n\nIf this firmware flasher is scrambled/compressed, you\nshould consider downloading an unscrambled version\nof the flasher from one of these two websites:\n-  http://dhc014.rpc1.org/indexOEM.htm\n-  http://codeguys.rpc1.org/firmwares.html", 1) if (length($new_file{'work'}) != 0x100000);
	}

	%file_data = %new_file;
	load_file();

	return 1;
}

sub Cmds1_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select Output File",
		-directory			=> "",
		-file					=> "",
		-pathmustexist		=> 1,
	);

	if ($file_data{'ext'} eq "bin")
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

	save_file($ofn{'-ret'});

	return 1;
}

sub Cmds2_Click
{
	Win32::GUI::MessageBox($hWndMain, "$PROGRAM_TITLE\nVersion $PROGRAM_VERSION, built on $BUILD_STAMP\n\nWeb: http://codeguys.rpc1.org/", "About", MB_OK | MB_ICONINFORMATION);
	return 1;
}

sub StList_DblClick
{
	StCmds0_Click();
	return 1;
}

sub StCmds0_Click
{
	my($idxa) = $ObjList->SelectedItem();
	my($idxb) = $ObjStList->SelectedItem();

	$ObjStMain->Hide();

	$file_data{'strats'}->[$idxa] = $StratList[$idxb][3];
	refresh_st_display($idxa);

	return 1;
}

sub StCmds1_Click
{
	$ObjStMain->Hide();
	return 1;
}

1;
