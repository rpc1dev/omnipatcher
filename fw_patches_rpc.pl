##
# OmniPatcher for Optical Drives
# Firmware : RPC patching
#
# Modified: 2005/08/01, C64K
#

sub fw_rpc_relevancy # ( )
{
	return 0;
}

sub fw_rpc_pat # ( testmode, patchmode )
{
	my($testmode, $patchmode) = @_;

	##
	# Establish the framework for testmode
	#
	my($fw, $fw_testmode);

	if ($testmode)
	{
		$fw_testmode = $Current{'fw'};
		$fw = \$fw_testmode;
	}
	else
	{
		$fw = \$Current{'fw'};
	}

	#op_dbgout("fw_rpc_pat", "Hello, world! :)");

	return -1;
}

1;
