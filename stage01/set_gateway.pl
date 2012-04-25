#!/usr/bin/perl

require "ec2ops.pl";

sub get_last_hex{
        my $this_ip = shift @_;

        if( $this_ip =~ /\d+\.\d+\.\d+\.(\d+)/ ){
                return $1;
        };

        return "NULL";
};

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(0);
print "SUCCESS: set sleep time for each lib call\n";

sub test_arb{
   $front_end_ip = shift @_;
   $arb = "ARB_" . get_last_hex($front_end_ip);
   my $ip = setrandomip($masters{'NC00'});
   "Setting arbitrator gateway host for: $arb to $ip";
   setproperties("$arb\.arbitrator\.gatewayhost", $ip);
   sleep(20);
   describe_services();
   if(find_arbitrator($arb) eq $arb) {
       print "Yay $arb is ENABLED!\n";
   } else {
       print "NOOO $arb is NOT ENABLED!\n";
       exit(1);
   }
   removeip($masters{'NC00'}, $ip);
   sleep(20);
   describe_services();
   if(!(find_arbitrator($arb) eq $arb)) {
       print "Yay $arb is NOT enabled!\n";
   } else {
       print "NOOO $arb is STILL enabled!\n";
       exit(1);
   }
}

if($masters{'NC00'}) {
    test_arb($masters{'CLC'});
    if(!($masters{'CLC'} eq $masters{'WS'})) {
        test_arb($masters{'WS'});
    }
}

doexit(0, "EXITING SUCCESS\n");
