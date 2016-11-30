#!/usr/bin/perl
#
# Description: Monitor oracle_reports jobs status.
#
#
# Author:
#        Gabriel Prestes (gabriel.prestes@ilegra.com)
#
#15-09-2016 : Created
#07-10-2016 : Modified

# Modules
use strict;
use POSIX;
use Getopt::Long;
use File::Basename;
use Switch;

# ENVs
$ENV{"USER"}="oracle";
$ENV{"HOME"}="/home/oracle";
$ENV{TZ} = 'America/Sao_Paulo';

# Global variables
 our $name = basename($0, ".pl");
 our $version="0.3";
 our $date=strftime("%Y-%m-%d",localtime);
 our $path = "/home/oracle/imon/plugins/oracle_reports_jobs";
 our $log = "$path/logs/oracle_reports_jobs_-$date.log";
 our ($opt_object, $opt_port, $opt_host, $opt_context, $opt_help, $opt_verbose, $opt_version, $opt_server, $opt_count);

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
		case "current"		{ current() }
		case "pastsuccess"	{ pastsuccess() }
		case "pasterror"	{ pasterror() }
		case "future"		{ future() }
		else			{ print "ERROR - Case objects not exist" }
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

sub pastsuccess {

        my @job = ();
        my @page = `/usr/bin/elinks \'http://$opt_host:$opt_port/$opt_context/rwservlet/showjobs?server=$opt_server&queuetype=past&count=$opt_count\' -dump`;
        my $flag = 0;
        my $line;

	if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: /usr/bin/elinks \'http://$opt_host:$opt_port/$opt_context/rwservlet/showjobs?server=$opt_server&queuetype=past&count=$opt_count\' -dump |");
                logger("----------------------");

        }

        foreach(@page){

                chomp($_);

                if(($_ =~ "$opt_host:$opt_port") and ($_ =~ "statusonly")){

                        if($_ =~ m/.+\. (.+)/){ $line = $1; }

                        @job = `/usr/bin/elinks \'$line\' -dump`;

			if ($opt_verbose == 1) {

		                logger("----------------------");
        		        logger("|PROGRAM OUT: /usr/bin/elinks \'$line\' -dump |");
				logger("----------------------");

			}

                        foreach(@job){

                                chomp($_);

                                if(($_ =~ "com sucesso") or ($_ =~ "successfully")){

					$flag++;

					if($opt_verbose == 1){

	                                         logger("----------------------");
	                                         logger("|PROGRAM OUT: JOB SUCESSO - $line|");
	                                         logger("----------------------");

					}

                                }
                        }


                }

        }

        print "$flag\n";


}

sub pasterror {

	my @job = ();
	my @page = `/usr/bin/elinks \'http://$opt_host:$opt_port/$opt_context/rwservlet/showjobs?server=$opt_server&queuetype=past&count=$opt_count\' -dump`;
	my $flag = 0;
	my $line;

	foreach(@page){

		chomp($_);

		if(($_ =~ "$opt_host:$opt_port") and ($_ =~ "statusonly")){

			if($_ =~ m/.+\. (.+)/){ $line = $1; }

			@job = `/usr/bin/elinks \'$line\' -dump`;

			foreach(@job){

				chomp($_);
				if($_ =~ "com o erro"){ 

					$flag++;

					if ($opt_verbose == 1) {

		                                logger("----------------------");
                	        	        logger("|PROGRAM OUT: JOB ERRO - $line|");
                		                logger("----------------------");

                        		}

				}

			}


		}

	}

	print "$flag\n";

}

sub future {

        my @page = `/usr/bin/elinks \'http://$opt_host:$opt_port/$opt_context/rwservlet/showjobs?server=$opt_server&queuetype=$opt_object&count=$opt_count\' -dump`;
        my $flag = 0;

        foreach(@page){

                chomp($_);

                if(($_ =~ "$opt_host:$opt_port") and ($_ =~ "jobid")){

                        if($_ =~ m/.+\. (.+)/){ 

				$flag++; 

                        	if ($opt_verbose == 1) {

                                	logger("----------------------");
                                        logger("|PROGRAM OUT: JOB IN QUEUE - $_|");
                                        logger("----------------------");

                                }

                        }

                }

        }

        print "$flag\n";

}

sub current {

        my @page = `/usr/bin/elinks \'http://$opt_host:$opt_port/$opt_context/rwservlet/showjobs?server=$opt_server&queuetype=$opt_object&count=$opt_count\' -dump`;
        my $flag = 0;

        foreach(@page){

                chomp($_);

                if(($_ =~ "$opt_host:$opt_port") and ($_ =~ "jobid")){

                        if($_ =~ m/.+\. (.+)/){

                                $flag++;

                                if ($opt_verbose == 1) {

                                        logger("----------------------");
                                        logger("|PROGRAM OUT: JOB IN PROCESS - $_|");
                                        logger("----------------------");

                                }

                        }

                }

        }

        print "$flag\n";


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

		if(($row =~ m/server\=(.+)/) and (!$opt_server)){

                        $opt_server=$1;

                        if ($opt_verbose == 1) {

                                logger("----------------------");
                                logger("|PROGRAM OUT: SERVER - $opt_server|");
                                logger("----------------------");

                        }

                }

		if(($row =~ m/count\=(.+)/) and (!$opt_count)){

                        $opt_count=$1;

                        if ($opt_verbose == 1) {

                                logger("----------------------");
                                logger("|PROGRAM OUT: COUNT - $opt_count|");
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
	    'c|count=i'                  => \$opt_count,
            'S|server=s'        	=> \$opt_server,
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

     if(!$opt_server){

            print "Error - Missing option -S or --server\n";
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

                This is a agent to check jobs in Oracle Reports

                Arguments:

		-H  : IP address of host 
		-O  : Object to collect
		-C  : Context-root of Reports
		-c  : Total history of jobs to check
		-P  : Port
		-S  : Server
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

                E.g: $path/bin/oracle_reports_jobs.pl -v 1





HELP

                system("clear");
                print $help;

}

&main
