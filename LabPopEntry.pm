package Tk::LabPopEntry;

require Tk::LabEntry;

@ISA = qw(Tk::Derived Tk::LabEntry);
$VERSION = 0.01;

Construct Tk::Widget 'LabPopEntry';

sub Populate{
   my($dw, $args) = @_;
   $dw->SUPER::Populate($args);
   
   my $entry = $dw->Subwidget('entry');  
   my $menuitems = delete $args->{-menuitems};
   my $nomenu = delete $args->{-nomenu};
   
   # Create the toplevel here, for easier reference later
   my $menu = $entry->Toplevel(-bd=>2, -relief=>'raised');
   $menu->withdraw;
   $menu->overrideredirect(1);
   $menu->transient;
   
   # The default menu items
   if(!defined($menuitems)){
      $menuitems = [
         ["Cut",'CutToClip','<Control-x>',2],
         ["Copy",'CopyToClip','<Control-c>',0],
         ["Paste",'PasteFromClip','<Control-v>',0],
         ["Delete",'DeleteSelected','<Control-d>',0],
         ["Select All",'SelectAll','<Control-a>',7],
      ];
   }
   
   $dw->Advertise('toplevel' => $menu);
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # The -entry and -menu options are for convenience, but are not generally 
   # meant to be called as a configure option once created.  Caveat Progammor.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   $dw->ConfigSpecs(
      -pattern    => ['PASSIVE'],
      -case       => ['PASSIVE'],
      -maxwidth   => ['PASSIVE'],
      -maxvalue   => ['PASSIVE'],
      -minvalue   => ['PASSIVE'],
      -nomenu     => ['PASSIVE',undef,undef,$nomenu],
      -nospace    => ['PASSIVE',undef,undef,0],
      -menuitems  => ['PASSIVE',undef,undef,$menuitems],
      -menu       => ['PASSIVE',undef,undef,$menu],
      -entry      => ['PASSIVE',undef,undef,$entry],
      DEFAULT     => [$dw],
   );
    
   $dw->SetBindings($entry);
}

# Set the default bindings
sub SetBindings{
   my($dw, $entry) = @_;
      
   $entry->bind("<Key>", sub{ $dw->Validate($entry)} );
   $entry->bind("<Button-3>", sub{ $dw->DisplayMenu($entry)} );
   $entry->bind("<Button-1>", sub{ $dw->WithdrawMenu($entry)} );
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Validate the Entry widget's value as the user types in data.  This is tied
# to the 'Key' event, set in the 'SetBindings' method.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub Validate{
   my($dw, $entry) = @_;
   
   my $pattern = $dw->cget(-pattern);
   my $nospace = $dw->cget(-nospace);
   my $maxwidth = $dw->cget(-maxwidth);
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the user specifies -maxvalue, take their word for it that they will
   # only enter numeric values.  Otherwise they'll be comparing ascii values,
   # which may or may not be what they wanted.  
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   my $maxValue = $dw->cget(-maxvalue);
   my $minValue = $dw->cget(-minvalue);
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Get the original string before the key was pressed.  This means getting
   # all but the last character.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   my $length = $entry->index('end');   
   my $string = $entry->get;
   my $oldString = substr($string,0,$length-1);
   
   # Check for whitespaces if the 'nospace' option is set
   if( ($nospace == 1) && ($string =~ /^\S*\s+$/) ){
      $dw->bell;
      $dw->Restore(-entry=>$entry, -oldval=>$oldString);
      return;
   }
   
   # Change all characters to uppercase or lowercase if appropriate
   if($dw->cget(-case) eq "upper"){ $string =~ tr/a-z/A-Z/ }
   if($dw->cget(-case) eq "lower"){ $string =~ tr/A-Z/a-z/ }
   
   if($pattern =~ /unsigned_int/i){
      if($nospace){ $pattern = '^\d*$' }
      else{ $pattern = '^\s*\d*\s*$' }
   }  
   elsif($pattern =~ /signed_int/i){
      if($nospace){ $pattern = '^[\+\-]?\d*$' }
      else{ $pattern = '^\s*[\+\-]?\d*\s*$' }
   }
   elsif($pattern =~ /float/i){
      if($nospace){ $pattern = '^?\.?\d*\.?\d*?$' }
      else{ $pattern = '^\s*?\.?\d*\.?\d*?\s*?$' }
   }
   elsif($pattern =~ /alpha/i){
      if($nospace){ $pattern = '^[A-Za-z]*$' }
      else{ $pattern = '^\s*[A-Za-z]*\s*$' }
   }
   elsif($pattern =~ /capsonly/i){
      if($nospace){ $pattern = '^[A-Z]*$' }
      else{ $pattern = '^\s*[A-Z]*\s*$' }
   }
   elsif($pattern =~ /nondigit/i){
      if($nospace){ $pattern = '^\D*$' }
      else{ $pattern = '^\s*\D*\s*$' }
   }
   # Check for a user-defined pattern
   elsif($dw->cget(-pattern)){ $pattern = $dw->cget(-pattern) }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the string doesn't match the pattern, replace it with the old
   # string and ring the bell.  Otherwise, allow the new value.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( defined($pattern) ){
      unless($string =~ /$pattern/){
         $dw->Restore(-entry=>$entry, -oldval=>$oldString);
         return;
      }
   }
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the maximum or minimum value is not entered, replace it with the old
   # string and ring the bell.  Otherwise, allow the new value.  Note that
   # 'minvalue' is not perfect, as it could fail on the first number.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(defined($maxValue) && ($string > $maxValue)){
      $dw->Restore(-entry=>$entry, -oldval=>$oldString);
      return;
   }
   if(defined($minValue) && ($string < $minValue)){
      $dw->Restore(-entry=>$entry, -oldval=>$oldString);
      return;
   }

   if(defined($maxwidth) && (length($string) > $maxwidth)){
      $dw->Restore(-entry=>$entry, -oldval=>$oldString);
      return;
   }
   
   # If the validation rule is obeyed, insert the new string.
   $entry->delete(0,'end');
   $entry->insert('end',$string);
}

# Restore the original string if a validation check fails.
sub Restore{
   my($dw, %args) = @_;
   
   my $entry  = delete $args{-entry};
   my $oldVal = delete $args{-oldval};
   
   $dw->bell;
   $entry->delete(0,'end');
   $entry->insert('end',$oldVal);
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Display the right-click menu.  The contents of that menu are derived from
# the -menuitems option.  There are five options by default, found in the
# 'Populate()' method above.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub DisplayMenu{
   my($dw,$entry) = @_;
   
   if($dw->cget(-nomenu) != 0){ return }
   
   my $menu = $dw->cget(-menu);
   my $menuitems = $dw->cget(-menuitems);

   if(Tk::Exists($menu)){ $dw->WithdrawMenu }
   
   # Create the menu item buttons
   foreach my $item(@$menuitems){
      $string   = $item->[0];
      $callback = $item->[1];
      $binding  = $item->[2];
      $index    = $item->[3];     
      
      $dw->{"mb_$string"} = $menu->Button(
         -text       => "$string\t$binding",
         -underline  => $index,  
         -command    => [$callback, $dw],
      );
      
      # Disable the default menu items initially.
      if($string =~ /Cut|Copy|Paste|Delete|Select.All/i){
         $dw->{"mb_$string"}->configure(-state=>'disabled');
      }
      
      $entry->bind($binding, \$callback);
   }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Perform some additional configuration options and pack the buttons onto
   # the screen.  Note that all buttons are disabled by default, and enabled
   # later in the 'SetState()' method.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   foreach my $item (@$menuitems){
      $button = $dw->{"mb_$item->[0]"};
      $button->configure(-relief=>'flat', -padx=>0, -pady=>0, -anchor=>'w');
      $button->pack(-expand=>1, -fill=>'x');
      $button->bind("<Enter>", sub{
            if($_[0]->cget('-state') ne "disabled"){
               $_[0]->configure(-relief=>'raised')
            }
         }
      );
      $button->bind('<Leave>', sub{$_[0]->configure(-relief=>'flat')});
   }
   
   # Check for state each time the menu appears
   $dw->SetState;
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # I like this bit of code.  This 'snaps' the pull down to the bottom left
   # corner of the Entry widget.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   $menu->geometry(sprintf("+%d+%d", $entry->rootx, $entry->rooty+20));
   
   # A 'grabGlobal()' call is necessary here to retain selection in some cases.
   $dw->grabGlobal;
   
   # Finally, raise the menu
   $menu->deiconify;
   $menu->raise;

}

# Withdraw the menu and destroy any children to prevent "menu buildup".
sub WithdrawMenu{
   my($dw,$entry) = @_;
   
   my $menu = $dw->cget(-menu);
   if($menu->state eq 'normal'){
      $menu->withdraw;
   }
   
   my @children = $menu->children;
   foreach my $child(@children){ $child->destroy }
   
   $dw->grabRelease;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set the state of the various buttons based on certain criterion, detailed
# below.  Note that any non-default menu-items should automatically have 
# their state set to 'normal'.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub SetState{
   my $dw = shift; 
   my $menuitems = $dw->cget(-menuitems);
   my $entry = $dw->cget(-entry); 
   my $entryVal = $entry->get;
   
   my $selection = GetSelection($dw, 'PRIMARY');
   my $clipboard = GetSelection($dw, 'CLIPBOARD');
     
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Only set state to 'normal' for default items if clipboard is
   # not empty or selection is present.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(($clipboard) && ($dw->{"mb_Paste"}->cget(-state) ne 'normal') ){
         $dw->{mb_Paste}->configure(-state=>'normal');
   }
   if(($selection) && ($dw->{"mb_Cut"}->cget(-state) ne 'normal') ){
      $dw->{mb_Cut}->configure(-state=>'normal');
   }
   if(($selection) && ($dw->{"mb_Copy"}->cget(-state) ne 'normal') ){
      $dw->{mb_Copy}->configure(-state=>'normal');
   }
   if(($selection) && ($dw->{"mb_Delete"}->cget(-state) ne 'normal') ){
      $dw->{mb_Delete}->configure(-state=>'normal');
   }
   if(($entryVal) && ($dw->{"mb_Select All"}->cget(-state) ne 'normal') ){
      $dw->{"mb_Select All"}->configure(-state=>'normal');
   }   
}

# Get the selected contents of the Entry widget
sub GetSelection{
   my($dw, $selectionType) = @_;
   my $entry = $dw->cget(-entry);
   my $string;

   Tk::catch { $string = $entry->SelectionGet(-selection=>$selectionType) };

   $string = '' unless defined $string;
   return $string;
}

# Select all the contents of the Entry widget
sub SelectAll{
   my $dw = shift;
   my $entry = $dw->cget(-entry);
   $entry->selectionRange(0,'end');
   $dw->SetState;
}

# Get the selected contents of the Entry widget
sub SetSelection{
   my($dw,$selection) = @_;
   my $entry = $dw->cget(-entry);
   my $string;

   Tk::catch { $string = $entry->SelectionGet(-selection=>$selection) };

   $string = '' unless defined $string;
   return $string;
}

# Append data to the clipboard
sub SetClip{
    my ($dw,$string) = @_;
    $dw->clipboardClear;
    $dw->clipboardAppend('--', $string);
}

# Copy data to the clipboard
sub CopyToClip{
    my $dw = shift;
    my $entry = $dw->cget(-entry);
    if($entry->selectionPresent){ SetClip($dw, GetSelection($dw,'PRIMARY')) }
    $dw->WithdrawMenu;
}

# Automatically put cut or deleted data into the clipboard
sub CutToClip{
    my $dw = shift;
    my $entry = $dw->cget(-entry);
    if($entry->selectionPresent){ SetClip($dw, DeleteSelected($dw)) }
    $dw->WithdrawMenu;
}

# Delete selected text
sub DeleteSelected{
    my $dw = shift;
    my $entry = $dw->cget(-entry);
    my $deleted_string;

    if($entry->selectionPresent){
      my $from = $entry->index('sel.first');
	   my $to = $entry->index('sel.last');
	   $deleted_string = substr($entry->get, $from, $to-$from);
	   $entry->delete($from,$to);
    }
    $dw->WithdrawMenu;
    return $deleted_string;
}

# Paste data from the clipboard into the Entry widget
sub PasteFromClip{
    my $dw = shift;
    my $entry = $dw->cget(-entry);
    my $from = $entry->index('insert');

    if($entry->selectionPresent){
	   $from = $entry->index('sel.first');
	   DeleteSelected($dw);
    }

    $entry->insert($from,GetSelection($dw,'CLIPBOARD'));
    $dw->WithdrawMenu;
}
1;
__END__
=head1 LabPopEntry

LabPopEntry - A LabEntry widget with an automatic, configurable right-click
menu built in, plus input masks.

=head1 SYNOPSIS

  use LabPopEntry
  $dw = $parent->LabPopEntry(
      -pattern   => 'alpha', 'capsonly', 'signed_int', 'unsigned_int', 'float',
                 'nondigit', or any supplied regexp.
      -nomenu    => 0 or 1,
      -case      => 'upper', 'lower', 'capitalize',
      -maxwidth  => int,
      -minwidth  => int,
      -maxvalue  => int,
      -nospace   => 0 or 1,
      -menuitems => ['string', 'callback', 'binding', 'index'],
   );
   $dw->pack;
   
=head1 DESCRIPTION

LabPopEntry is a LabEntry widget with a right-click menu automatically attached.
In addition, certain field masks can easily be applied to the entry widget in
order to force the end-user into entering only the values you want him or her
to enter.

By default, there are five items attached to the right-click menu: Cut, Copy,
Paste, Delete and Select All.  The default bindings for the items are ctrl-x,
ctrl-c, ctrl-v, ctrl-d, and ctrl-a, respectively.

The difference between 'Cut' and 'Delete' is that the former automatically
copies the contents that were cut to the clipboard, while the latter does not.

=head1 OPTIONS

-pattern
   The pattern specified here creates an input mask for the LabPopEntry widget.
There are six pre-defined masks:
alpha - Upper and lower case a-z only.
capsonly - Upper case A-Z only.
nondigit - Any characters except 0-9.
float - A float value, which may or may not include a decimal.
signed_int - A signed integer value, which may or may not include a '+'.
unsigned_int - An unsigned integer value.

You may also specify a regular expression of your own design using Perl's
standard regular expression mechanisms.  Be sure to use single quotes.

-nomenu
   If set to true, then no right-click menu will appear.  Presumably, you would
set this if you were only interested in the input-mask functionality.

-nospace
   If set to true, the user may not enter whitespace before, after or between
words within that LabPopEntry widget.

-maxwidth
   Specifies the maximum number of characters that the user can enter in that
particular LabPopEntry widget.  Note that this is not the same as the width
of the widget.

-maxvalue
   If one of the pre-defined numeric patterns is chosen, this specifies the
maximum allowable value that may be entered by a user for the widget.

-minvalue
   If one of the pre-defined numeric patterns is chosen, this specifies the
minimum allowable value for the first digit (0-9).  This should work better.

-menuitems
   If specified, this creates a user-defined right-click menu rather than
the one that is provided by default.  The value specified must be a four
element nested anonymous array that contains: 

a string that appears on the menu,
a callback (in 'package::callback' syntax format), 
a binding for that option (see below), 
and an index value specifying where on the menu it should appear,  starting at 
index 0.

   The binding specified need only be in the form, '<ctrl-x>'.  You needn't
explicitly bind it yourself.  Your callback will automatically be bound to
the event sequence you specified.

=head1 NOTES
This widget is functionally identical to the PopEntry widget, with the exception
that a label may be added since it is derived from a LabEntry widget rather than
an Entry widget.

In terms of code, this widget was completely re-written.  I am now using a 
'Key' binding to check for validation, rather than overloading the 'insert'
method of the Entry widget.  Also, the toplevel menu is now available as an
advertised subwidget, making for much easier configuration of the right-click
menu.
   
=head1 KNOWN BUGS

The -pattern option "capsonly" will only work properly if no more than one 
word is supplied.

The -minvalue only works for the first digit.

Possible to have a leading '.' and a following '.' in a float

=head1 PLANNED CHANGES

Fix the issues mentioned above.

Allow individual entries to be added or removed from the menu via predefined
methods.

=head1 AUTHOR

Daniel J. Berger
djberg96@hotmail.com

=head1 SEE ALSO

Entry, PopEntry

=cut

