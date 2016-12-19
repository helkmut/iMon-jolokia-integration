#!/usr/bin/perl
#
# Description: Monitor java jmx rest integration services.
#
#
# Author:
#        Gabriel Prestes (gabriel.prestes@ilegra.com)
#
#30-08-2016 : Created (author: Gabriel Prestes)
#15-09-2016 : Text fix (author: Gabriel Prestes)
#19-12-2016 : Add heap functions (author: Kristy Noms)

# Modules
use strict;
use POSIX;
use Getopt::Long;
use File::Basename;
use Switch;

# ENVs
$ENV{"USER"}="imon";
$ENV{"HOME"}="/home/imon";
$ENV{TZ} = 'America/Sao_Paulo';

# Global variables
 our $name = basename($0, ".pl");
 our $version="0.1";
 our $date=strftime("%Y-%m-%d",localtime);
 our $path = "/home/imon/imon/plugins/jolokia-jmx-java-common";
 our $log = "$path/logs/jolokia-jmx-java-common-$date.log";
 our ($opt_object, $opt_port, $opt_host, $opt_context, $opt_managedserver, $opt_help, $opt_verbose, $opt_version);

sub main {

        # --- Get Options --- #
        getoption();

        # --- Create log directory --- #
        my @cmdlog = `mkdir -p $path/logs`;

        # --- Check and write pid --- #
        if(check_instances() == 0){

		if ($opt_verbose == 1) {

	                logger("----------------------");
	                logger("|PROGRAM OUT: CRITICAL - Soo many jobs in execution|");
	                logger("----------------------");
	
		}

                exit(1);

        } 

        # --- Init agent --- #
	if ($opt_verbose == 1) {

	        logger("----------------------");
	        logger("|PROGRAM OUT: INIT AGENT - $date|");
	        logger("----------------------");

	}

        # --- Rotate logs more than 15 days --- #
        my $cmd;

	if ($opt_verbose == 1) {
	
	        logger("----------------------");
	        logger("|PROGRAM OUT: LOGs - Search for more than 15 days old|");
	        logger("----------------------");
	
	}

        $cmd=`\$\(which find\) $path/logs/*.log -name "*" -mtime +15 -exec \$\(which rm\) -rf {} \\; > /dev/null 2>&1`;

	setprops();

	# --- Choice object option --- #
	switch ($opt_object) {
		case "HeapMemoryUsage"		{ heapusage() }
        case "HeapMemoryMax"        { heapmax() }
        case "HeapPercent"          { heappercent()}		
		case "NonHeapMemoryUsage"	{ nonheapusage() }
		case "ThreadCount"		    { threadcount() }
		else				        { print "ERROR - Case objects not exist" }
	}
	
        # --- End agent --- #
        if ($opt_verbose == 1) {

	        logger("----------------------");
	        logger("|PROGRAM OUT: END AGENT - $date|");
	        logger("----------------------");

	}

        exit_program();

}

sub exit_program {

        exit;

}

sub heapusage {

        my @command = `\$\(which jmx4perl\) --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:type=Memory HeapMemoryUsage`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/used => (.+)/){

                        $counter=+$1;

                }

        }

	$counter = ($counter/1024)/1024;
	$counter = sprintf("%.2f", $counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: HEAP USED -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub heapmax {

        my @command = `\$\(which jmx4perl\) --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:type=Memory HeapMemoryUsage`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/max => (.+)/){

                        $counter=+$1;

                }

        }

        $counter = ($counter/1024)/1024;
        $counter = sprintf("%.2f", $counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: HEAP MAX -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub heappercent {

        my @command = `\$\(which jmx4perl\) --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:type=Memory HeapMemoryUsage`;
        my $counter;
        my $counter2;

        foreach(@command){

                chomp($_);
                if($_ =~ m/used => (.+)/){

                        $counter=+$1;

                }
                                 chomp($_);
                if($_ =~ m/max => (.+)/){

                        $counter2=+$1;

                }

        }

        $counter = ($counter *100) / $counter2;
        $counter = sprintf("%.2f", $counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: HEAP PERCENT -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub nonheapusage {

        my @command = `\$\(which jmx4perl\) --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:type=Memory NonHeapMemoryUsage`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/used => (.+)/){

                        $counter=+$1;

                }

        }

        $counter = ($counter/1024)/1024;
        $counter = sprintf("%.2f", $counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: NONHEAP USED -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub threadcount {

        my $counter = `\$\(which jmx4perl\) --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:type=Threading ThreadCount`;
	chomp($counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: TOTAL THREADS -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub setprops {

	my $filename = "$path/lib/config.inc";
	
	open(my $fh, '<:encoding(UTF-8)', $filename) or do error();
 
	while (my $row = <$fh>) {

		chomp $row;

		if(($row =~ m/host\=(.+)/) and (!$opt_host)){

			$opt_host=$1;
			if ($opt_verbose == 1) {

		                logger("----------------------");
                		logger("|PROGRAM OUT: HOST - $opt_host|");
		                logger("----------------------");

        		}

		}

		if(($row =~ m/port\=(.+)/) and (!$opt_port)){

			$opt_port=$1;

                        if ($opt_verbose == 1) {

                                logger("----------------------");
                                logger("|PROGRAM OUT: PORT - $opt_port|");
                                logger("----------------------");

                        }

		}
		
		if(($row =~ m/context\=(.+)/) and (!$opt_context)){

			$opt_context=$1;

                        if ($opt_verbose == 1) {

                                logger("----------------------");
                                logger("|PROGRAM OUT: CONTEXT - $opt_context|");
                                logger("----------------------");

                        }

		}

	}

}

sub check_instances {

        my $instances = `cat /proc/cpuinfo | grep processor | wc -l`;
        my $instances = $instances*2;
        my $running = `\$\(which ps\) -ef | grep $name | grep -v grep | wc -l`;

        if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: TEST INSTANCES IN EXECUTION - $date|");
                logger("----------------------");


                logger("MAX INSTANCES ALLOW -> $instances");
                logger("INSTANCES RUNNING -> $running");

        }

        if( $running >= $instances){

                return 0;

        } else {

                return 1;

        }

}

sub error {

        print "|ERROR - Unexpected return - contact support|\n";
        exit_program();

}

sub getoption {

     Getopt::Long::Configure('bundling');
     GetOptions(

            'O|object=s'                => \$opt_object,
            'H|host=s'                  => \$opt_host,
            'P|port=i'                  => \$opt_port,
            'C|context=s'               => \$opt_context,
            'S|managedserver=s'        => \$opt_managedserver,
            'V|version'                 => \$opt_version,
            'h|help'                    => \$opt_help,
            'v|verbose=i'               => \$opt_verbose,
        );

     if($opt_help){

             printHelp();
             exit;

     }

     if($opt_version){

             print "$name\.pl - '$version'\n";
             exit;

     }

     if(!$opt_verbose){

             $opt_verbose = 0;

     }

     if(!$opt_object){

	    print "Error - Missing option -O or --object\n";
            exit;

     }

     if(!$opt_managedserver){

            print "Error - Missing option -MS or --managedserver\n";
            exit;

     }

}

sub logger {

        return (0) if (not defined $opt_verbose);

        my $msg = shift (@_);

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        $wday++;
        $yday++;
        $mon++;
        $year+=1900;
        $isdst++;

        if ($opt_verbose == 0){

                print "$msg\n";

        }

        else {

           open(LOG, ">>$log") or do error();
           printf LOG ("%02i/%02i/%i - %02i:%02i:%02i => %s\n",$mday,$mon,$year,$hour,$min,$sec,$msg);
           close(LOG);

        }

}

sub printHelp {

                my $help = <<'HELP';

                This is a agent to check events in java jmx rest jolokia

                Arguments:

		-H  : IP address of host 
		-O  : Object to collect
		-C  : Context-root of Jolokia
		-P  : Port
                -V  : Version
                -h  : Help
                -v 1: Send to log(debug mode)
                -v 0: Show log in console

                Required APIs:

                use strict;
                use Getopt::Long;
                use POSIX;
                use File::Basename;
		use Switch;

                E.g: $path/bin/jolokia-jmx-java-common.pl -v 1





HELP

                system("clear");
                print $help;

}

&main
