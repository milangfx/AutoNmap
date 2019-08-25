#!/bin/bash

DATE=`date +%F`

source autonmap.conf

echo "`date` - Welcome to AutoNmap2."

# Ensure we can change to the run directory
cd $RUN_DIRECTORY || exit 2
echo "`date` - Running nmap, please wait. This may take a while."
# $NMAP --open -T4 -Pn $SCAN_SUBNETS -n -oX scan-$DATE.xml > /dev/null
# running nmap without -Pn because we know all of our hosts respond to ping
$NMAP --open -T4 -sS $SCAN_SUBNETS -n -oX scan-$DATE.xml > /dev/null
echo "`date` - Nmap process completed with exit code $?"

# If this is not the first time autonmap2 has run, we can check for a diff. Otherwise skip this section, and tomorrow when the link exists we can diff.
if [ -e scan-prev.xml ]
then
    echo "`date` - Running ndiff..."
    # Run ndiff with the link to yesterdays scan and todays scan
    DIFF=`$NDIFF scan-prev.xml scan-$DATE.xml`

    echo "`date` - Checking ndiff output"
    # There is always two lines of difference; the run header that has the time/date in. So we can discount that.
    # match for 'open' ports only. don't care about interchange between filtered and closed ports 
    if [ `echo "$DIFF" | tail -n +4 | grep open | wc -l` -ne 0 ] 
    then
            echo "`date` - Differences Detected. Sending mail."
            #Added a for loop to send the emails because sending the email to 3 recipients was getting kicked back by Office365.
            for RECIPIENT in $EMAIL_RECIPIENTS
            do
            echo -e "AutoNmap2 found differences in a scan since yesterday. \n\n$DIFF\n\nFull report available at $WEB_URL" | mail -r "from@address.com" -s "Port Scan Changes $DATE" $RECIPIENT
            done
 
            # Copy the scan report to the web directory so it can be viewed later. only make the web report if there were differences
            echo "`date` - Copying the XML and the ndiff output to the web directory."
            echo "$DIFF" > $WEB_DIRECTORY/ndiff-$DATE.txt
            cp scan-$DATE.xml $WEB_DIRECTORY

            echo "`date` - Converting XML to HTML."
            xsltproc -o $WEB_DIRECTORY/scan-$DATE.html nmap-bootstrap.xsl $WEB_DIRECTORY/scan-$DATE.xml 
            rm $WEB_DIRECTORY/scan-$DATE.xml
    else
            echo "`date` - No differences, skipping mail."
    fi

else 
    echo "`date` - There is no previous scan (scan-prev.xml). Cannot diff today; will do so tomorrow."
fi

# Create the link from today's report to scan-prev so it can be used tomorrow for diff.
echo "`date` - Linking todays scan to scan-prev.xml"
ln -sf scan-$DATE.xml scan-prev.xml

echo "`date` - AutoNmap2 is complete."
exit 0 
