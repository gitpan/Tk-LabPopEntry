use Tk;
use LabPopEntry;

$mw = MainWindow->new;
$pe = $mw->LabPopEntry(
   -pattern    => 'unsigned_int',
   -maxvalue   => '525',
   -minvalue   => '4',
   -nospace    => 1,
   -label      => "Right Click Somewhere!",
   -labelPack  => [-side=>'left'],
);

$pe->pack;

$exitbutton = $mw->Button(-text=>"Exit", -command=>sub{exit});
$exitbutton->pack;

$mw->Label(-text=>"In this demo, only unsigned integers will be allowed, with
a maximum value of 525, and a minimum value of 4.  No spaces are allowed.")->pack;

MainLoop;