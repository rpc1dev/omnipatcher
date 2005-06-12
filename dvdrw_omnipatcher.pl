##
# OmniPatcher for LiteOn DVD-Writers
# Main : Main module
#
# Modified: 2005/06/12, C64K
#

require "appinfo.pl";

require "common_util.pl";
require "common_xflash.pl";

require "dvdrw_omnipatcher_config.pl";
require "dvdrw_omnipatcher_misc.pl";

load_extconfig();

##
# Load modules...
#
require "fw.pl";
require "fw_const.pl";
require "fw_patches.pl";
require "fw_readspeed.pl";
require "fw_specs.pl";

require "media.pl";
require "media_const.pl";
require "media_dataproc.pl";
require "media_strat.pl";
require "media_tweaks.pl";

require "ui.pl";
require "ui_const.pl";
require "ui_eventhandlers.pl";

##
# Initialize the GUI...
#
require "ui_init_dimensions.pl";
require "ui_init_windows.pl";

##
# Process command line parameters...
#
if ($ARGV[0] eq "-savelog")
{
	$OP_SAVE_LOG = 1;
	fw_load($ARGV[1]) if ($ARGV[1] ne "");
}
elsif ($ARGV[0] ne "")
{
	fw_load($ARGV[0]);
}

##
# Enter GUI loop...
#
Win32::GUI::Dialog();
