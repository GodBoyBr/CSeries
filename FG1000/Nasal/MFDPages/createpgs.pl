#!/usr/bin/perl -w
use strict;
use warnings;

my %pages = ("Stormscope" => "MAP - STORMSCOPE",
"WeatherDataLink" => "MAP - WEATHER DATA LINK",
"TAWSB" => "MAP - TAWS",
#"AirportInfo" => "WPT - AIRPORT INFORMATION",
"AirportDirectory" => "WPT - AIRPORT DIRECTORY",
"AirportDeparture" => "WPT - AIRPORT DEPARTURE INFORMATION",
"AirportArrival" => "WPT - AIRPORT ARRIVAL INFORMATION",
"AirportApproach" => "WPT - AIRPORT APPROACH INFORMATION",
"AirportWeather" => "WPT - WEATHER INFORMATION",
"IntersectionInfo" => "WPT - INTERSECTION INFORMATION",
"NDBInfo" => "WPT - NDB INFORMATION",
"VORInfo" => "WPT - VOR INFORMATION",
"UserWPTInfo" => "WPT - USER WPT INFORMATION",
"TripPlanning" => "AUX - TRIP PLANNING",
"Utility" => "AUX - UTILITY",
"GPSStatus" => "AUX - GPS STATUS",
"XMRadio" => "AUX - XM RADIO",
"XMInfo" => "AUX - XM INFORMATION",
"SystemStatus" => "AUX - SYSTEM STATUS",
"ActiveFlightPlanWide" => "FPL - ACTIVE FLIGHT PLAN",
"ActiveFlightPlanNarrow" => "FPL - ACTIVE FLIGHT PLAN",
"FlightPlanCatalog" => "FPL - FLIGHT PLAN CATALOG",
"StoredFlightPlan" => "FPL - STORED FLIGHT PLAN",
"Checklist1" => "LST - CHECKLIST 1",
"Checklist2" => "LST - CHECKLIST 2",
"Checklist3" => "LST - CHECKLIST 3",
"Checklist4" => "LST - CHECKLIST 4",
"Checklist5" => "LST - CHECKLIST 5",
#"NearestAirports" => "NRST - NEAREST AIRPORTS",
"NearestIntersections" => "NRST - NEAREST INTERSECTIONS",
"NearestNDB" => "NRST - NEAREST NDB",
"NearestVOR" => "NRST - NEAREST VOR",
"NearestUserWPT" => "NRST - NEAREST USER WPTS",
"NearestFrequencies" => "NRST - NEAREST FREQUENCIES",
"NearestAirspaces" => "NRST - NEAREST AIRSPACES"
);

foreach my $page (sort(keys(%pages))) {
  my $pageTitle = $pages{$page};
  #print "$page : $pageTitle\n";
  if (! -d $page) { mkdir($page) };
  chdir("~/FlightGear/fgdata/Aircraft/Instruments-3d/FG1000/Nasal/$page");
  system("cp ./TemplatePage/TemplatePage.nas ${page}/${page}.nas");
  system("cp ./TemplatePage/Options.nas ${page}/${page}Options.nas");
  system("cp ./TemplatePage/Controller.nas ${page}/${page}Controller.nas");
  system("cp ./TemplatePage/Styles.nas ${page}/${page}Styles.nas");
  foreach my $f (glob("${page}/*.nas")) {
    #print("Substituting on $f\n");
    system("perl -pi -e \"s/TemplateTitle/$pageTitle/g\" $f");
    system("perl -pi -e \"s/Template/$page/g\" $f");
  }
  #print("obj._pageGroupController.addPage(\"${page}\", fg1000.${page}.new(obj, myCanvas, obj._MFDDevice, obj._svg));\n")
}
