sub SetText # ( obj, str )
{
	my($obj, $str) = @_;

	if ($obj->Text() ne $str)
	{
		$obj->Text($str);
	}
}

sub SetCheck # ( obj, check )
{
	my($obj, $check) = @_;

	if ($obj->GetCheck() != $check)
	{
		$obj->SetCheck($check);
	}
}

sub SetEnable # ( obj )
{
	my($obj) = @_;

	if (!$obj->IsEnabled())
	{
		$obj->Enable();
	}
}

sub SetDisable # ( obj )
{
	my($obj) = @_;

	if ($obj->IsEnabled())
	{
		$obj->Disable();
	}
}

1;
