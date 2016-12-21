#!/usr/bin/perl

# Description: Monitor Oracle FusionMiddleware Reports and Forms Events and threads in Windows
#
#
# Author:
#        Gabriel Prestes (gabriel.prestes@ilegra.com)
#
#16-11-2016 : Created
#21-12-2016 : Modified(fix functions logger)

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
 our $version="0.8";
 our $date=strftime("%Y-%m-%d",localtime);
 our $path = "$ENV{HOME}/imon/plugins/oracle-rf-stats-win";
 our $log = "$path/logs/$name-$date.log";
 our ($opt_object, $opt_port, $opt_host, $opt_type, $opt_help, $opt_verbose, $opt_version);

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

        # --- Choice object option --- #
        switch ($opt_object) {
                case "connections"          	{ check_connections($opt_port) }
                case "port_alive"          	{ check_port_alive($opt_port) }
                #case "formsruntime"          	{ formsruntime_count() }
                #case "reportstatus"          	{ reports_status($opt_type) }
                #case "restartcomponent"         { restartcomponent() }
                else                            { logger("ERROR - Case objects not exist") }
        }

        # --- End agent --- #
        if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: END AGENT - $date|");
                logger("----------------------");

        }

        exit_program();

}

sub restartcomponent {

	my @command = `opmnctl status -l | awk '{print \$3,\$13}'`;
	my $component;
	my $newtime = 0;
	my $oldtime = 0;
	my $difftime = 0;
	my $flag = 0;
	my $compontent_list;

	system("mkdir -p $path/var");

	foreach(@command){

		chomp($_);

		if(($_ !~ "FormsRuntime") and ($_ !~ "process-type") and ($_ !~ "Instance:")){

			if($_ =~ m/(.+) (.+):.+:.+/){

				$component = $1; 
				$newtime = $2; 
				if($opt_verbose == 1) {logger("$component - $newtime");}

				if(-e "$path/var/$component-restartcomponent.db"){

					$oldtime=`cat $path/var/$component-restartcomponent.db`; 
					chomp($oldtime);

				} 

				system("echo $newtime > $path/var/$component-restartcomponent.db");

				$difftime = $newtime - $oldtime;

				if($opt_verbose == 1) {logger("$component - old : $oldtime new : $newtime diff : $difftime");}

				if($difftime < 0){ 

					$flag++;
					system("echo '$date - $component restarted' >> $path/var/restart-report.out");

				}

			}

		}

	}

	logger($flag);

}

sub reports_status {

	my $type = shift (@_);

        if(!$type){

                error();

        }

	my @total = `\$\(which opmnctl\) status | grep -i ReportsServer`;
	my $total_proc = 0;
	my $error_proc = 0;
	my $result = 0;

	foreach(@total){

		chomp($_);

		$total_proc++;

		if($_ !~ "Alive"){

			$error_proc++;		

		} 

	}

	$result = $total_proc - $error_proc;
	
	if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: ReportServer total - $total_proc : error - $error_proc : alive - $result|");
                logger("----------------------");

        }
	
	$result = $total_proc - $error_proc;

	if($type =~ "alive"){	

		logger($result);

	} 

	elsif($type =~ "total"){

		logger($total_proc);


	}else {

		logger($error_proc);
	
	}

}

sub formsruntime_count {

	my $command = `\$\(which opmnctl\) status | grep -i FormsRuntime | wc -l`;

	chomp($command);

	if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: RuntimeForms count - $command|");
                logger("----------------------");

        }

        logger($command);

}

sub check_connections {

        my $port = shift (@_);

        if((!$port) or (!$opt_host)){

		error();

	}

	my $command = `$ENV{HOME}/imon/bin/imon_get -s $opt_host -k connports[$port]`;
	chomp($command);

        if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: CONNECTIONS ACTIVE ON PORT $port - $command|");
                logger("----------------------");

	}

	logger($command);

}

sub check_port_alive {

        my $port = shift (@_);

        if((!$port) or (!$opt_host)){

                error();

        }

	my $command = `$ENV{HOME}/imon/bin/imon_get -s $opt_host -k aliveports[$port]`;
	chomp($command);

        if ($opt_verbose == 1) {

                logger("----------------------");
                logger("|PROGRAM OUT: PORT COUNT $port LISTEN - $command|");
                logger("----------------------");

        }

        logger($command);

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

sub exit_program {

        exit;

}

sub error {

        print "|ERROR - Unexpected return - contact support|\n";
        exit_program();

}

sub getoption {

     Getopt::Long::Configure('bundling');
     GetOptions(

            'P|port=i'                  => \$opt_port,
            'H|host=s'                  => \$opt_host,
            'O|object=s'                => \$opt_object,
            'T|type=s'                  => \$opt_type,
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

                This is a agent to check objects on Oracle Fusion Middleware Reports and Forms in Windows

                Arguments:

				-H  : host
				-P  : Port
                -O  : Object to collect
				-T  : Type of object
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

                E.g: oracle-rf-stats-win.pl -v 1





HELP

                system("clear");
                print $help;

}

&main
