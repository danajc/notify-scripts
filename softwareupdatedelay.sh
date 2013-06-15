#!/bin/sh

# Have we run this already?
if [ -f /Library/Application\ Support/JAMF/Receipts/$4 ]; then
	echo "Patches already run"
	exit 2
fi

# Let's make sure we've got the timer file
if [ ! -e /Library/Application\ Support/JAMF/.SoftwareUpdateTimer.txt ]; then
	echo "5" > /Library/Application\ Support/JAMF/.SoftwareUpdateTimer.txt
fi

LoggedInUser=`who | grep console | awk '{print $1}'`
Timer=`cat /Library/Application\ Support/JAMF/.SoftwareUpdateTimer.txt`

fRunUpdates ()
{
	echo "5" > /Library/Application\ Support/JAMF/.SoftwareUpdateTimer.txt
	
	/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon "/System/Library/CoreServices/Software Update.app/Contents/Resources/lookout.png" -heading 'Lookout is installing updates to your Mac' -description 'Please do not turn off this computer. It will reboot when updates are completed.' > /dev/null 2>&1 &
	
	# Run the update policy
	/usr/sbin/jamf policy -trigger patchme
	touch /Library/Application\ Support/JAMF/Receipts/$4
	
	killall -9 jamfHelper
	/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon "/System/Library/CoreServices/Software Update.app/Contents/Resources/lookout.png" -heading 'Updates Complete' -description 'If a reboot is required, it will be performed now.' -button1 "OK" -defaultButton "1" -timeout 30 
	exit 0
}

# If nobody's home, fire away. Else, prompt (assuming they haven't delayed too many times)
if [ "$LoggedInUser" == "" ]; then
	fRunUpdates
else
	if [ $Timer -gt 0 ]; then
		HELPER=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon "/System/Library/CoreServices/Software Update.app/Contents/Resources/lookout.png" -heading "Software Updates are available for your Mac" -description "If you would like to install updates now, click OK. If you would not like to install updates now, click Cancel. You may choose to not install updates $Timer more time(s) before this computer will forcibly install them. A reboot will be required." -button1 "OK" -button2 "Cancel" -defaultButton "2" -timeout 300 -countdown -startlaunchd`

		echo "jamf helper result was $HELPER";
		
		if [ "$HELPER" == "0" ]; then
			fRunUpdates
		else
			let CurrTimer=$Timer-1
			echo "user chose No"
			echo "$CurrTimer" > /Library/Application\ Support/JAMF/.SoftwareUpdateTimer.txt
			exit 1
		fi
	fi
fi

# If Timer is already 0, run the updates automatically, the user has been warned!
if [ $Timer -eq 0 ]; then
	fRunUpdates
fi