##
# OmniPatcher for LiteOn DVD-Writers
# Main : Miscellaneous helper/utility functions
#
# Modified: 2005/06/25, C64K
#

sub op_dbgout # ( function, str )
{
	my($line) = sprintf("%-16s : %s", @_);

	if ($COM_PRINT_DEBUGGING_MESSAGES)
	{
		ui_appendtext($DebugTab->{'Log'}, "$line\r\n");
		dbgout("$line\n");
	}

	if ($OP_SAVE_LOG)
	{
		open logfile, ">>dvdrw_omnipatcher.log";
		print logfile "$line\n";
		close logfile;
	}
}

sub addr_bankid { $_[0] >> 16 }
sub addr_bank   { $_[0] & 0xFF0000 }
sub addr_16bit  { $_[0] & 0x00FFFF }

1;
