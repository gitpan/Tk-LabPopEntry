use Tk;

require LabPopEntry;

my $mw = MainWindow->new;

my $lpe = $mw->LabPopEntry(
   -pattern    => 'alphanum',
   -label      => 'Alpha-numeric only:',
   -labelPack  => [-side=>'left'],
   
);
$lpe->pack;

my $button = $mw->Button(-text=>"Exit", -command=>sub{exit})->pack;
my $label = $mw->Label(-text=>"Right click somewhere")->pack;

# Uncomment either or both of these lines to see their effect
#$lpe->deleteItem(2,'end');
#$lpe->addItem(1,["Exit", 'main::exitApp', '<Control-g>', 1]);

MainLoop;

sub exitApp{ exit }
