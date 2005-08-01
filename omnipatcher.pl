##
# OmniPatcher for Optical Drives
# Main : Main module
#
# Modified: 2005/08/01, C64K
#

require "appinfo.pl";

require "common_util.pl";
require "common_xflash.pl";

require "omnipatcher_config.pl";
require "omnipatcher_misc.pl";

load_extconfig();

##
# Load modules...
#
require "fw.pl";
require "fw_const.pl";
require "fw_mtk.pl";
require "fw_patches.pl";
require "fw_patches_ledblink.pl";
require "fw_patches_readspeed.pl";
require "fw_patches_rpc.pl";
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
# Process command line parameters and enter the main GUI loop
#
op_proc_args();
Win32::GUI::Dialog();
