#!/usr/bin/perl
#
# Description: Monitor java jmx rest integration services.
#
#
# Author:
#        Gabriel Prestes (gabriel.prestes@ilegra.com)
#
#16-08-2016 : Created
#26-08-2016 : Modified(new methods)
#06-09-2016 : Modified(take threaddump)

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
 our $version="0.2";
 our $date=strftime("%Y-%m-%d",localtime);
 our $path = "/home/$ENV{USER}/imon/plugins/jolokia-jmx-as-wls";
 our $log = "$path/logs/jolokia-jmx-as-wls-$date.log";
 our ($opt_object, $opt_port, $opt_host, $opt_context, $opt_managedserver, $opt_help, $opt_verbose, $opt_version, $opt_threshould);

sub main {

        getoption();

        my @cmdlog = `mkdir -p $path/logs`;

        if(check_instances() == 0){

		if ($opt_verbose == 1) {

	                logger("----------------------");
	                logger("|PROGRAM OUT: CRITICAL - Soo many jobs in execution|");
	                logger("----------------------");
	
		}

                exit(1);

        } 

	if ($opt_verbose == 1) {

	        logger("----------------------");
	        logger("|PROGRAM OUT: INIT AGENT - $date|");
	        logger("----------------------");

	}

        my $cmd;

	if ($opt_verbose == 1) {
	
	        logger("----------------------");
	        logger("|PROGRAM OUT: LOGs - Search for more than 15 days old|");
	        logger("----------------------");
	
	}

        $cmd=`\$\(which find\) $path/logs/*.log -name "*" -mtime +15 -exec \$\(which rm\) -rf {} \\; > /dev/null 2>&1`;

	setprops();

	switch ($opt_object) {
		case "StuckThreadCount"		{ stuckthreads() }
		case "HoggingThreadCount"	{ hoggingthreads() }
		case "Throughput"		{ throughput() }
		case "ExecuteThreadTotalCount"	{ executethreads() }
		case "GCCollectionTimeScavenge"	{ gctime("Scavenge") }
		case "GCCollectionCountScavenge"{ gccount("Scavenge") }
                case "GCCollectionTimeMarkSweep" { gctime("MarkSweep") }
                case "GCCollectionCountMarkSweep"{ gccount("MarkSweep") }
		else				{ print "ERROR - Case objects not exist" }
	}
	
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

sub throughput {

        my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read com.bea:Name=*,ServerRuntime=$opt_managedserver,Type=ThreadPoolRuntime Throughput`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/Throughput => '(.+)'/){

                        $counter=+$1;

                }

        }

	$counter = sprintf("%.2f", $counter);

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: THROUGHPUT -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub gccount {

	my $type = shift (@_);
	chomp($type);
        my $counter = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:name=\'PS $type\',type=GarbageCollector CollectionCount`;

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: GC $type COLLECTION COUNT -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub gctime {

        my $type = shift (@_);
        chomp($type);
        my $counter = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read java.lang:name=\'PS $type\',type=GarbageCollector CollectionTime`;

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: GC $type COLLECTION TIME -> $counter|");
        logger("----------------------");

        }

        print "$counter\n";

}

sub executethreads {

        my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read com.bea:Name=*,ServerRuntime=$opt_managedserver,Type=ThreadPoolRuntime ExecuteThreadTotalCount`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/ExecuteThreadTotalCount => (.+)/){

                        $counter=+$1;

                }

        }

        if ($opt_verbose == 1) {

	        logger("----------------------");
	        logger("|PROGRAM OUT: EXECUTE THREADS -> $counter|");
	        logger("----------------------");

        }

        print "$counter\n";

}

sub stuckthreads {

	my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read com.bea:ApplicationRuntime=*,Name=*,ServerRuntime=$opt_managedserver,Type=WorkManagerRuntime StuckThreadCount`;
	my $counter;

	foreach(@command){

		chomp($_);
		if($_ =~ m/StuckThreadCount => (.+)/){

			$counter=+$1;	

		}

	}

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: STUCK THREADS -> $counter|");
        logger("----------------------");

        }

		my $datedump=strftime("%Y-%m-%d-%H",localtime);
        my $directory_dump = "$path/var/dumpthread-$opt_managedserver-$datedump.log";

        if(($counter>=$opt_threshould) and (! -e $directory_dump)){

                if ($opt_verbose == 1) {

                        logger("----------------------");
                        logger("|PROGRAM OUT: THREAD DUMP in -> $directory_dump|");
                        logger("----------------------");

                }

                my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context exec java.lang:type=Threading dumpAllThreads true true`;

                open(DUMP, ">>$directory_dump") or do error();

                foreach(@command){

                        chomp($_);
                        printf DUMP ("$_\n");

                }

                close(DUMP);

        }

	print "$counter\n";

}

sub hoggingthreads {

        my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context read com.bea:Name=*,ServerRuntime=$opt_managedserver,Type=ThreadPoolRuntime HoggingThreadCount`;
        my $counter;

        foreach(@command){

                chomp($_);
                if($_ =~ m/HoggingThreadCount => (.+)/){

                        $counter=+$1;

                }

        }

        if ($opt_verbose == 1) {

        logger("----------------------");
        logger("|PROGRAM OUT: HOGGING THREADS -> $counter|");
        logger("----------------------");

        }

	    my $datedump=strftime("%Y-%m-%d-%H",localtime);
        my $directory_dump = "$path/var/dumpthread-$opt_managedserver-$datedump.log";

        if(($counter>=$opt_threshould) and (! -e $directory_dump)){


		if ($opt_verbose == 1) {
	
		        logger("----------------------");
		        logger("|PROGRAM OUT: THREAD DUMP in -> $directory_dump|");
		        logger("----------------------");

		}

		my @command = `/usr/local/bin/jmx4perl --option ignoreErrors=true http://$opt_host:$opt_port/$opt_context exec java.lang:type=Threading dumpAllThreads true true`;

           	open(DUMP, ">>$directory_dump") or do error();

		foreach(@command){

         	       	chomp($_);
			printf DUMP ("$_\n");

        	}

		close(DUMP);

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
                                logger("|PROGRAM OUT: HOST - $opt_port|");
                                logger("----------------------");

                        }

		}
		
		if(($row =~ m/context\=(.+)/) and (!$opt_context)){

			$opt_context=$1;

                        if ($opt_verbose == 1) {

                                logger("----------------------");
                                logger("|PROGRAM OUT: HOST - $opt_context|");
                                logger("----------------------");

                        }

		}

	}

}

sub check_instances {

	my $instances = `tail -n 20 /proc/cpuinfo | grep processor | awk '{print \$3}'`;
	my $instances = $instances+5; 
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
	    'T|threshoulds=i'		=> \$opt_threshould,
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

     if((!$opt_threshould) || ($opt_threshould == 0)){

		$opt_threshould = 5;
		# - Test mode
		#$opt_threshould = 0

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
		-T  : Threshoulds for take threaddump of server container(J2EE)
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

                E.g: $path/bin/jolokia-jmx-as-wls.pl -v 1





HELP

                system("clear");
                print $help;

}

&main
