#!/usr/bin/perl

require "ec2ops.pl";

parse_input();
print "SUCCESS: parsed input\n";

exit_if_not_ha("CLC");
print "SUCCESS: detected HA configuration for component 'CLC'\n";

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

#$masters{"ARB"} = $masters{"CLC"};
#$slaves{"ARB"} = $slaves{"CLC"};
#describe_services();
#find_real_master("ARB");

find_master_arbitrator();
print "SUCCESS: found master arbitrator: $current_artifacts{master_arbitrator}\n";

setrandomip($masters{"NC00"});
print "SUCCESS: set pingable IP on $masters{NC00}\n";

setproperties("$current_artifacts{master_arbitrator}\.arbitrator\.gatewayhost", $current_artifacts{"arbitrator_ip"});
print "SUCCESS: set property for arbitrator IP $current_artifacts{arbitrator_ip}\n";

foreach $comp ("CLC", "WS", "SC") {
    if ($masters{"$comp"} eq $current_artifacts{"master_arbitrator_host"}) {
	$before_masters{$comp} = $masters{$comp};
    }
}

removeip($masters{"NC00"});
print "SUCCESS: removed pingable IP on $masters{NC00}\n";

sleep(120);

describe_services();
find_real_master("CLC");
describe_services();
foreach $comp ("WS", "SC00") {
    find_real_master($comp);
}

my $errors=0;
foreach $comp (keys(%before_masters)) {
    if ($masters{"$comp"} eq $before_masters{$comp}) {
	print "ERROR: $comp: new master ($masters{$comp}) equals pre-arb fail master ($before_masters{$comp})\n";
	$errors++;
    } else {
	print "SUCCESS: $comp: new master ($masters{$comp}) different from pre-arb fail master ($before_masters{$comp})\n";
    }
}

setproperties("$current_artifacts{master_arbitrator}\.arbitrator\.gatewayhost", "192.168.7.1");
print "SUCCESS: reset property for arbitrator to 192.168.7.1\n";

if ($errors) {
    doexit(1, "ERROR: one or more service didn't swap after arbitrator switch\n");
} 

doexit(0, "EXITING SUCCESS\n");

