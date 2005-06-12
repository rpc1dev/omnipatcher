##
# OmniPatcher for LiteOn DVD-Writers
# User Interface : Main module
#
# Modified: 2005/06/12, C64K
#

use Win32::GUI;

################################################################################
# UI flags
{
	$FlagIgnoreMediaChange = 0;
	$FlagWarnedStratSpeed = 0;
	$FlagWarnedNonRSpeed = 0;
	$FlagWarnedPatchFF = 0;
	$FlagWarnedPatchDL = 0;

	# By default, all controls are "really visible", meaning that they
	# are visible when their tab is selected and invisible when their
	# tab is unselected.  An "invisible" control is one that is invisible
	# whether the tab is selected or not.  This has of control names keeps
	# track of them.  Likewise, if a control is on an invisible tab, it should
	# not be brought alive.
	#
	%FlagInvisibleControl = ( );
	%FlagOnInvisibleTab = ( );
}

################################################################################
# UI helper functions
{
	sub ui_addpairs # ( pairs )
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

	sub ui_getpos # ( obj )
	{
		return [ $_[0]->Left(), $_[0]->Top() ];
	}

	sub ui_getpos_cond # ( obj )
	{
		return ($UI_USE_ROOT) ? [ $_[0]->Left(), $_[0]->Top() ] : [0, 0];
	}
}

################################################################################
# Message boxes
{
	sub ui_abort # ( message )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], "Error", MB_OK | MB_ICONWARNING);
		exit 1;
	}

	sub ui_error # ( message[, retcode ] )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], "Error", MB_OK | MB_ICONWARNING);
		return $_[1];
	}

	sub ui_warning # ( message[, retcode ] )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], "Warning!", MB_OK | MB_ICONWARNING);
		return $_[1];
	}

	sub ui_infobox # ( message, title[, retcode ] )
	{
		Win32::GUI::MessageBox($hWndMain, $_[0], $_[1], MB_OK | MB_ICONINFORMATION);
		return $_[2];
	}
}

################################################################################
# Accessors
{
	sub ui_getcheck # ( obj )
	{
		return $_[0]->GetCheck();
	}

	sub ui_getselected # ( obj )
	{
		return $_[0]->SelectedItem();
	}

	sub ui_gettext # ( obj )
	{
		return $_[0]->Text();
	}
}

################################################################################
# Modifiers
{
	sub ui_setleft # ( obj, loc )
	{
		my($obj, $loc) = @_;

		if ($obj->Left() != $loc)
		{
			$obj->Left($loc);
		}
	}

	sub ui_settop # ( obj, loc )
	{
		my($obj, $loc) = @_;

		if ($obj->Top() != $loc)
		{
			$obj->Top($loc);
		}
	}

	sub ui_settext # ( obj, str )
	{
		my($obj, $str) = @_;

		if ($obj->Text() ne $str)
		{
			$obj->Text($str);
		}
	}

	sub ui_setcheck # ( obj, check )
	{
		my($obj, $check) = @_;

		if ($obj->GetCheck() != $check)
		{
			$obj->SetCheck($check);
		}
	}

	sub ui_clear # ( obj )
	{
		$_[0]->Clear();
	}

	sub ui_setenable # ( obj )
	{
		my($obj) = @_;

		if (!$obj->IsEnabled())
		{
			$obj->Enable();
		}
	}

	sub ui_setdisable # ( obj )
	{
		my($obj) = @_;

		if ($obj->IsEnabled())
		{
			$obj->Disable();
		}
	}

	sub ui_setvisible # ( obj )
	{
		my($obj) = @_;
		my($name) = $obj->{'-name'};

		$FlagInvisibleControl{$name} = 0;

		if (!$obj->IsVisible() && !$FlagOnInvisibleTab{$name})
		{
			$obj->Show();
		}
	}

	sub ui_setinvisible # ( obj )
	{
		my($obj) = @_;
		my($name) = $obj->{'-name'};

		$FlagInvisibleControl{$name} = 1;

		if ($obj->IsVisible())
		{
			$obj->Hide();
		}
	}

	sub ui_setvisible_tabchng # ( obj )
	{
		my($obj) = @_;
		my($name) = $obj->{'-name'};

		$FlagOnInvisibleTab{$name} = 0;

		if (!$obj->IsVisible() && !$FlagInvisibleControl{$name})
		{
			$obj->Show();
		}
	}

	sub ui_setinvisible_tabchng # ( obj )
	{
		my($obj) = @_;
		my($name) = $obj->{'-name'};

		$FlagOnInvisibleTab{$name} = 1;

		if ($obj->IsVisible())
		{
			$obj->Hide();
		}
	}

	sub ui_setreadonly # ( obj, flag )
	{
		my($obj, $flag) = @_;
		$obj->ReadOnly($flag);
	}

	sub ui_addstring # ( obj, str )
	{
		my($obj, $str) = @_;
		$obj->AddString($str);
	}

	sub ui_add # ( obj, array )
	{
		my($obj, @array) = @_;
		$obj->Add(@array);
	}

	sub ui_changeitem # ( obj, idx, str )
	{
		my($obj, $idx, $str) = @_;

		if ($obj->GetString($idx) ne $str)
		{
			my($cur_idx) = $obj->SelectedItem();

			$obj->RemoveItem($idx);
			$obj->InsertItem($str, $idx);
			$obj->Select($idx) if ($idx == $cur_idx);
		}
	}

	sub ui_changeitem_safe # ( obj, idx, str )
	{
		$FlagIgnoreMediaChange = 1;
		ui_changeitem(@_);
		$FlagIgnoreMediaChange = 0;
	}

	sub ui_select # ( obj, idx )
	{
		my($obj, $idx) = @_;
		$obj->Select($idx);
	}

	sub ui_reflow_patches # ( )
	{
		my($key, $i);

		foreach $key (@FW_PATCH_KEYS)
		{
			unless ($FlagInvisibleControl{$PatchesTab->{$key}->{'-name'}})
			{
				ui_settop($PatchesTab->{$key}, $ui_pos_patches[$i][1]);
				++$i;
			}
		}
	}
}

1;
