##
# OmniPatcher for LiteOn DVD-Writers
# Main : Miscellaneous helper/utility functions
#
# Modified: 2005/06/12, C64K
#

sub op_dbgout # ( function, str )
{
	dbgout(sprintf("%-16s : %s\n", @_));

	if ($OP_SAVE_LOG)
	{
		open logfile, ">>dvdrw_omnipatcher.log";
		print logfile sprintf("%-16s : %s\n", @_);
		close file;
	}
}

sub getaddr_full # ( addr )
{
	use integer;
	my($addr) = @_;

	if (ref($addr) && $#{$addr} == 0)
	{
		# [ 0x0E ]
		return $addr->[0] << 16;
	}
	elsif (ref($addr) && $#{$addr} > 0)
	{
		# [ 0x0E, 0x1234 ]
		return ($addr->[0] << 16) + $addr->[1];
	}
	else
	{
		# 0xE1234
		return $addr;
	}
}

sub getaddr_bank # ( addr )
{
	use integer;
	my($addr) = @_;

	if (ref($addr))
	{
		# [ 0x0E ] or [ 0x0E, 0x1234 ]
		return $addr->[0];
	}
	else
	{
		# 0xE1234
		return $addr >> 16;
	}
}

sub getaddr_16bit # ( addr )
{
	use integer;
	my($addr) = @_;

	if (ref($addr) && $#{$addr} == 0)
	{
		# [ 0x0E ]
		return 0;
	}
	elsif (ref($addr) && $#{$addr} > 0)
	{
		# [ 0x0E, 0x1234 ]
		return $addr->[1];
	}
	else
	{
		# 0xE1234
		return $addr & 0xFFFF;
	}
}

1;
