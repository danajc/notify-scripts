#!/bin/bash 
declare -x DOMAIN=`dsconfigad -show | grep "Active Directory Domain" | awk '{ print $5 }' | grep -o "lookout"`
declare -x COCOADIALOG="/var/lookout/cocoaDialog.app/Contents/MacOS/cocoaDialog"
declare -x DIALOG_ICON="/var/lookout/lookout-it.png"
declare -x CHANGE_PASSWORD="/var/lookout/change-pw.app/Contents/MacOS/applet"

# Logged in user
LoggedInUser=`ls -l /dev/console | awk '{ print $3 }'`

# Current password change policy
PasswdPolicy=365

# Last password set date
LastPasswordSet=`dscl /Active\ Directory/CORP/All\ Domains/ read /Users//$LoggedInUser SMBPasswordLastSet | awk '{print $2}'`

# Calculations
LastPasswordCalc1=`expr $LastPasswordSet / 10000000 - 1644473600`
LastPasswordCalc2=`expr $LastPasswordCalc1 - 10000000000`
TimeStampToday=`date +%s`
TimeSinceChange=`expr $TimeStampToday - $LastPasswordCalc2`
DaysSinceChange=`expr $TimeSinceChange / 86400`
DaysRemaining=`expr $PasswdPolicy - $DaysSinceChange`

if [[ $DOMAIN == "lookout" ]]; then
		DIALOG_RESULT=`$COCOADIALOG msgbox --icon-file $DIALOG_ICON --title "Lookout Password Expiration Notice" --text "Your password will expire in $DaysRemaining days." --informative-text "      Would you like to change your password now?" --button1 "Yes" --button2 "No" --float`
	if [[ $DIALOG_RESULT == 1 ]]; then
			$CHANGE_PASSWORD
	else
		echo " "
	fi	
else
	$COCOADIALOG msgbox --icon-file $DIALOG_ICON --title "Lookout Password Expiration Notice" --text "Your password will expire in $DaysRemaining days." --informative-text "      Would you like to change your password now?" --button1 "Yes" --button2 "No" --float
		if [[ $DIALOG_RESULT == 1 ]]; then
			$CHANGE_PASSWORD
		else
			echo " "
		fi	
fi
