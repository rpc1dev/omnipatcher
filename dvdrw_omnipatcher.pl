require 'appinfo.pl';

use Win32::GUI;

require "lib_extconfig.pl";
require "lib_xflashx.pl";
require "lib_rebank.pl";

require "code_patches.pl";
require "code_speedhack.pl";
require "code_strat.pl";
require "code_mediahack2.pl";
require "code_slimmedia.pl";
require "code_funcs.pl";
require "code_eventhandlers.pl";

extconfig_load();

require "code_initgui.pl";

$ObjMain->Show();
Win32::GUI::Dialog();
