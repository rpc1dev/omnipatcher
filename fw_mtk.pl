##
# OmniPatcher for Optical Drives
# Firmware : MediaTek helper functions
#
# Modified: 2005/07/17, C64K
#

sub fw_mtk_rebank # ( &data, &bootcode, mode, common_len )
{
	my($data, $bootcode, $mode, $common_len) = @_;
	my($ret, $i);

	my($bc_len) = 0x4000;

	if ($mode == 1)
	{
		for ($i = 0; $bc_len + $common_len + (0x10000 - $common_len) * $i < length(${$data}); ++$i)
		{
			$ret .= substr(${$data}, $bc_len, $common_len);
			$ret .= substr(${$data}, $bc_len + $common_len + (0x10000 - $common_len) * $i, (0x10000 - $common_len));
		}

		# Note that the mode #1 return does so in two different ways.
		# There is the standard function return for the rebanked firmware
		# as well as a by-reference return for the bootcode!
		#
		${$bootcode} = substr(${$data}, 0x0, $bc_len);
	}
	elsif ($mode == 0)
	{
		$ret = ${$bootcode} . substr(${$data}, 0x000000, $common_len);

		for ($i = 0; $i <= ((length(${$data}) - 1) >> 16); ++$i)
		{
			$ret .= substr(${$data}, 0x10000 * $i + $common_len, (0x10000 - $common_len));
		}
	}
	else
	{
		$ret = ${$data};
	}

	return $ret;
}

sub fw_mtk_isokay # ( )
{
	foreach my $i (0 .. $Current{'fw_nbanks'} - 1)
	{
		return 0 if (substr($Current{'fw'}, $i << 16, 1) ne chr(0x02));
	}

	return 1;
}

1;
