use Win32::API;

$GetOpenFileName = Win32::API->new('comdlg32', 'GetOpenFileName', 'P', 'N');
$GetSaveFileName = Win32::API->new('comdlg32', 'GetSaveFileName', 'P', 'N');

$OFN_READONLY             = 0x00000001;
$OFN_OVERWRITEPROMPT      = 0x00000002;
$OFN_HIDEREADONLY         = 0x00000004;
$OFN_NOCHANGEDIR          = 0x00000008;
$OFN_SHOWHELP             = 0x00000010;
$OFN_ENABLEHOOK           = 0x00000020;
$OFN_ENABLETEMPLATE       = 0x00000040;
$OFN_ENABLETEMPLATEHANDLE = 0x00000080;
$OFN_NOVALIDATE           = 0x00000100;
$OFN_ALLOWMULTISELECT     = 0x00000200;
$OFN_EXTENSIONDIFFERENT   = 0x00000400;
$OFN_PATHMUSTEXIST        = 0x00000800;
$OFN_FILEMUSTEXIST        = 0x00001000;
$OFN_CREATEPROMPT         = 0x00002000;
$OFN_SHAREAWARE           = 0x00004000;
$OFN_NOREADONLYRETURN     = 0x00008000;
$OFN_NOTESTFILECREATE     = 0x00010000;
$OFN_NONETWORKBUTTON      = 0x00020000;
$OFN_NOLONGNAMES          = 0x00040000;
$OFN_EXPLORER             = 0x00080000;
$OFN_NODEREFERENCELINKS   = 0x00100000;
$OFN_LONGNAMES            = 0x00200000;
$OFN_ENABLEINCLUDENOTIFY  = 0x00400000;
$OFN_ENABLESIZING         = 0x00800000;

sub OFNDialog # ( func, data )
{
	my($func, $data) = @_;

	my($hwndOwner) = $data->{'hwnd'};
	my($lpstrFilter) = join("\x00", map { join("\x00", @{$_}) } @{$data->{'filter'}}) . "\x00\x00";
	my($nFilterIndex) = $data->{'filter_idx'};
	my($lpstrFile) = sprintf("%-1024s", $data->{'file'} . "\x00");
	my($lpstrFileTitle) = sprintf("%-1024s", $data->{'file_title'} . "\x00");
	my($lpstrInitialDir) = $data->{'initial_dir'} . "\x00";
	my($lpstrTitle) = $data->{'title'} . "\x00";
	my($Flags) = $data->{'flags'};
	my($lpstrDefExt) = $data->{'def_ext'} . "\x00";

	my($ofn) = pack "LLLpLLLpLpLppLSSpLLL",
	(
		76,								# lStructSize			DWORD
		$hwndOwner,						# hwndOwner				HWND
		0,									# hInstance				HINSTANCE
		$lpstrFilter,					# lpstrFilter			LPCTSTR
		0,									# lpstrCustomFilter	LPTSTR
		0,									# nMaxCustFilter		DWORD
		$nFilterIndex,					# nFilterIndex			DWORD
		$lpstrFile,						# lpstrFile				LPTSTR
		length($lpstrFile),			# nMaxFile				DWORD
		$lpstrFileTitle,				# lpstrFileTitle		LPTSTR
		length($lpstrFileTitle),	# nMaxFileTitle		DWORD
		$lpstrInitialDir,				# lpstrInitialDir		LPCTSTR
		$lpstrTitle,					# lpstrTitle			LPCTSTR
		$Flags,							# Flags					DWORD
		0,									# nFileOffset			WORD
		0,									# nFileExtension		WORD
		$lpstrDefExt,					# lpstrDefExt			LPCTSTR
		0,									# lCustData				DWORD
		0,									# lpfnHook				LPOFNHOOKPROC
		0,									# lpTemplateName		LPCTSTR
	);

	if ($func->Call($ofn))
	{
		$data->{'filter_idx'} = unpack("L", substr($ofn, 6 * 4, 4));
		$data->{'file'} = substr($lpstrFile, 0, index($lpstrFile, "\x00"));
		$data->{'file_title'} = substr($lpstrFileTitle, 0, index($lpstrFileTitle, "\x00"));

		return 1;
	}

	return 0;
}

1;
