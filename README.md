# iMon-jolokia-integration
iMon-jolokia-integration - Integration between iMon and Jolokia

Help program: jolokia-jmx-java-common.pl

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

Help program: jolokia-jmx-java-common.pl

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
			
				

Examples: 

/home/imon/imon/plugins/jolokia-jmx-as-wls/jolokia-jmx-as-wls.pl -H ORAPROD11G -P 8080 -C jolokia-war-1.3.3 -O StuckThreadCount -S WLS_TEST -T 20 -v 1 



/home/imon/imon/plugins/jolokia-jmx-java-common/jolokia-jmx-java-common.pl -v 0 -H ORAPROD11G -P 8080 -C jolokia-war-1.3.3 -O HeapMemoryUsage -S WLS_TEST

Status iMon Templates:

https://docs.google.com/a/ilegra.com/spreadsheets/d/1w0Yf1SYTzGy3P3OvmBF8lS6IGiZRMIfXSqfraap9g8Y/edit?usp=sharing

New requests: middleops@ilegra.com

Reference : https://jolokia.org/reference/html/index.html
