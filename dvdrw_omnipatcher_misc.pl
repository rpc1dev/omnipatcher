##
# OmniPatcher for LiteOn DVD-Writers
# Main : Miscellaneous helper/utility functions
#
# Modified: 2005/06/14, C64K
#

sub op_dbgout # ( function, str )
{
	dbgout(sprintf("%-16s : %s\n", @_));

	if ($OP_SAVE_LOG)
	{
		open logfile, ">>dvdrw_omnipatcher.log";
		print logfile sprintf("%-16s : %s\n", @_);
		close logfile;
	}
}

sub addr_bankid { $_[0] >> 16 }
sub addr_bank   { $_[0] & 0xFF0000 }
sub addr_16bit  { $_[0] & 0x00FFFF }

1;
