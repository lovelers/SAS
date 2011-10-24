#!/bin/bash
# Samba Configurer for Lychee Linux

## Set some local variables for use throughout the script.

host=`hostname` ## put the hostname into a variable for reuse later.
who=`whoami` ## establish who the script is running as.
file="smb.conf" ## choose a name for the file generated.
defaultplace="/etc/samba" ## The default place to put the file.

## check if the script is being run by an admin
if [ "$who" != "root" ]; then
  echo "Unable to add samba users as non-admin user.\n Please run the script again as root."
  exit 0
fi

## Welcome messages.

echo "Samba Configuration Script by Luke Channings. Edit by Sebastian Grebe"
echo "If you want to add samba users make sure to run the script as root."

  saveplace=$defaultplace ## Default to /etc/samba

## BEGIN QUESTIONS FOR GENERAL SAMBA CONFIGURATION.

# NetBios
if [ -z "$netbios" ]; then netbios=$host; fi ## If no netbios name is passed default to the hostname.

# Server String
if [ -z "$serverString" ]; then serverString="Devnet %v"; fi ## Default to Samba Version.

# Workgroup
if [ -z "$workgroup" ]; then workgroup="DEVNET"; fi ## Default to WORKGROUP

# Security Mode#!/bin/bash
# Samba Configurer for Lychee Linux

## Set some local variables for use throughout the script.

host=`hostname` ## put the hostname into a variable for reuse later.
who=`whoami` ## establish who the script is running as.
file="smb.conf" ## choose a name for the file generated.
defaultplace="/etc/samba" ## The default place to put the file.

## check if the script is being run by an admin
if [ "$who" != "root" ]; then
  echo "Unable to add samba users as non-admin user.\n Please run the script again as root."
  exit 0
fi

## Welcome messages.

echo "Samba Configuration Script by Luke Channings. Edit by Sebastian Grebe"
echo "If you want to add samba users make sure to run the script as root."

  saveplace=$defaultplace ## Default to /etc/samba

## BEGIN QUESTIONS FOR GENERAL SAMBA CONFIGURATION.

# NetBios
if [ -z "$netbios" ]; then netbios=$host; fi ## If no netbios name is passed default to the hostname.

# Server String
if [ -z "$serverString" ]; then serverString="Devnet %v"; fi ## Default to Samba Version.

# Workgroup
if [ -z "$workgroup" ]; then workgroup="DEVNET"; fi ## Default to WORKGROUP

# Security Mode
if [ -z "$security" ]; then security="user"; fi ## Default security mode to "user".

# WINS
wins = "y"
if [ "$wins" = "y" ]; then wins="yes" ; elif [ "$wins" = "n" ]; then wins="no"; fi ## change y/n to yes/no so that it can be used directly when generating smb.conf.

# CUPS
cups = "y"
if [ "$cups" = "y" ]; then cups="printing = CUPS"; else cups="#printing = CUPS"; fi ## construct CUPS string.

## PREPARE WRITING LOCATION ##

if [ -e $dir/$file ]; then cp $dir/$file $dir/$file~ ; fi ## Backup old smb.conf should it exist.

> $dir/$file ## Empty destination file.

out="$dir/$file" ## Shorten output location.

## GENERATE GENERAL SAMBA CONFIGURATION ##

echo "[global]" >> $out
echo " netbios name = $netbios" >> $out ## Set the NetBios Name.
echo " server string = $serverString" >> $out ## Set the Server Description.
echo " workgroup = $workgroup" >> $out ## Set the Workgroup
echo " announce version = 5.0" >> $out ## Version to identify as.
echo " socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=8192 SO_SNDBUF=8192" >> $out ## Some tricks to speed up data transfer.
echo " security = $security" >> $out ## Set security mode.
echo " wins support = $wins" >> $out ## Set WINS
echo "$cups" >> $out ## Set CUPS options.
echo " null passwords = false" >> $out ## Disable null passwords for security reasons.
echo " syslog = 1" >> $out ## Set syslog level to 1
echo " syslog only = yes" >> $out ## set additional syslog option.

## ADDING SHARES ##

shares = "y"
while [ "$shares" = "y" ]; do

  ## GATHER SHARE INFO ##

  # Share Name
  until read -p "Please enter a name for the share. " sharename && [ $sharename ]; do
    echo "You didn't enter a name..."
  done

  #Share Path
  until read -p "Please enter a path for the share. " sharepath && [ $sharepath ]; do
    echo "You didn't enter a path."
  done

  # Share Writeable?
  until read -p "Should the share be writeable? (y/n) " sharewriteable && [ "$sharewriteable" = "y" ] || [ "$sharewriteable" = "n" ]; do
    echo "Please enter y or n"
  done
  if [ "$sharewriteable" = "y" ]; then sharewriteable="yes"; else sharewriteable="no"; fi ## Change y/n to yes/no

  # Directory Mask
  read -p "Enter directory mask (Default is 0775) " sharemask
  if [ -z "$sharemask" ]; then sharemask="0775"; fi

  ## BUILD SHARE ##
  echo "[$sharename]" >> $out
  echo "  path = $sharepath" >> $out
  echo "  writeable = $sharewriteable" >> $out
  echo "  create mask = $sharemask" >> $out
  echo "  guest ok = no" >> $out ## Disable guest access by default

  ## Write success message.
  echo -e "\nSuccessfully added share."

  ## LOOP OR NOT ##
  until read -p "Would you like to add another share? (y/n) " shares && [ "$shares" = "y" ] || [ "$shares" = "n" ]; do
    echo "Please enter y or n"
  done

done

## ADDING SAMBA USERS ##

until read -p "Would you like to add a samba user? (y/n) " adduser && [ "$adduser" = "y" ] || [ "$adduser" = "n" ]; do
  echo "Please enter y or n"
done

while [ "$adduser" = "y" ]; do

  until read -p "Please enter name for the new user. " username && [ $username ]; do
    echo "You didn't enter a name."
  done

  smbpasswd -a $username
  smbpasswd -e $username

  ## LOOP OR NOT ##
  until read -p "Add another user? (y/n) " adduser && [ "$adduser" = "y" ] || [ "$adduser" = "n" ]; do
    echo "Please enter y or n"
  done

done

echo -e "\nScript completed sucessfully."

## Find Samba init script.

if [ -e "/etc/init.d/smbd" ]; then
  init="/etc/init.d/smbd"
elif [ -e "/etc/rc.d/samba" ]; then
  init="/etc/rc.d/samba"
elif [ -e "/etc/init.d/samba" ];then
  init="/etc/init.d/samba"
elif [ -e "/etc/rc.d/smbd" ]; then
  init="/etc/rc.d/smbd"
fi

## Restart Samba if the init script if found.

if [ -z "$init" ]; then
  echo "Failed to find Samba init script. Please restart Samba manually."
else
  echo "Found Samba in $init. Restarting."
  $init stop > /dev/null 2>&1
  $init start > /dev/null 2>&1
  echo "All Done."
fi

if [ -z "$security" ]; then security="user"; fi ## Default security mode to "user".

# WINS
until read -p "Enable WINS (Windows Internet Name Service)? (y/n) " wins && [ "$wins" = "y" ] || [ "$wins" = "n" ]; do echo "Please enter y or n"; done ## Demand y/n for the question.
if [ "$wins" = "y" ]; then wins="yes" ; elif [ "$wins" = "n" ]; then wins="no"; fi ## change y/n to yes/no so that it can be used directly when generating smb.conf.

# CUPS
until read -p "Enable CUPS printing? (y/n) " cups && [ "$cups" = "y" ] || [ "$cups" = "n" ]; do echo "Please enter y or n"; done ## Demand y/n.
if [ "$cups" = "y" ]; then cups="printing = CUPS"; else cups="#printing = CUPS"; fi ## construct CUPS string.

## PREPARE WRITING LOCATION ##

if [ -e $dir/$file ]; then cp $dir/$file $dir/$file~ ; fi ## Backup old smb.conf should it exist.

> $dir/$file ## Empty destination file.

out="$dir/$file" ## Shorten output location.

## GENERATE GENERAL SAMBA CONFIGURATION ##

echo "[global]" >> $out
echo " netbios name = $netbios" >> $out ## Set the NetBios Name.
echo " server string = $serverString" >> $out ## Set the Server Description.
echo " workgroup = $workgroup" >> $out ## Set the Workgroup
echo " announce version = 5.0" >> $out ## Version to identify as.
echo " socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=8192 SO_SNDBUF=8192" >> $out ## Some tricks to speed up data transfer.
echo " security = $security" >> $out ## Set security mode.
echo " wins support = $wins" >> $out ## Set WINS
echo "$cups" >> $out ## Set CUPS options.
echo " null passwords = false" >> $out ## Disable null passwords for security reasons.
echo " syslog = 1" >> $out ## Set syslog level to 1
echo " syslog only = yes" >> $out ## set additional syslog option.

## ADDING SHARES ##

until read -p "Would you like to add a share? (y/n) " shares && [ "$shares" = "y" ] || [ "$shares" = "n" ]; do  echo "Please enter y or n"; done

while [ "$shares" = "y" ]; do

  ## GATHER SHARE INFO ##

  # Share Name
  until read -p "Please enter a name for the share. " sharename && [ $sharename ]; do
    echo "You didn't enter a name..."
  done

  #Share Path
  until read -p "Please enter a path for the share. " sharepath && [ $sharepath ]; do
    echo "You didn't enter a path."
  done

  # Share Writeable?
  until read -p "Should the share be writeable? (y/n) " sharewriteable && [ "$sharewriteable" = "y" ] || [ "$sharewriteable" = "n" ]; do
    echo "Please enter y or n"
  done
  if [ "$sharewriteable" = "y" ]; then sharewriteable="yes"; else sharewriteable="no"; fi ## Change y/n to yes/no

  # Directory Mask
  read -p "Enter directory mask (Default is 0775) " sharemask
  if [ -z "$sharemask" ]; then sharemask="0775"; fi

  ## BUILD SHARE ##
  echo "[$sharename]" >> $out
  echo "  path = $sharepath" >> $out
  echo "  writeable = $sharewriteable" >> $out
  echo "  create mask = $sharemask" >> $out
  echo "  guest ok = no" >> $out ## Disable guest access by default

  ## Write success message.
  echo -e "\nSuccessfully added share."

  ## LOOP OR NOT ##
  until read -p "Would you like to add another share? (y/n) " shares && [ "$shares" = "y" ] || [ "$shares" = "n" ]; do
    echo "Please enter y or n"
  done

done

## ADDING SAMBA USERS ##

until read -p "Would you like to add a samba user? (y/n) " adduser && [ "$adduser" = "y" ] || [ "$adduser" = "n" ]; do
  echo "Please enter y or n"
done

while [ "$adduser" = "y" ]; do

  until read -p "Please enter name for the new user. " username && [ $username ]; do
    echo "You didn't enter a name."
  done

  smbpasswd -a $username
  smbpasswd -e $username

  ## LOOP OR NOT ##
  until read -p "Add another user? (y/n) " adduser && [ "$adduser" = "y" ] || [ "$adduser" = "n" ]; do
    echo "Please enter y or n"
  done

done

echo -e "\nScript completed sucessfully."

## Find Samba init script.

if [ -e "/etc/init.d/smbd" ]; then
  init="/etc/init.d/smbd"
elif [ -e "/etc/rc.d/samba" ]; then
  init="/etc/rc.d/samba"
elif [ -e "/etc/init.d/samba" ];then
  init="/etc/init.d/samba"
elif [ -e "/etc/rc.d/smbd" ]; then
  init="/etc/rc.d/smbd"
fi

## Restart Samba if the init script if found.

if [ -z "$init" ]; then
  echo "Failed to find Samba init script. Please restart Samba manually."
else
  echo "Found Samba in $init. Restarting."
  $init stop > /dev/null 2>&1
  $init start > /dev/null 2>&1
  echo "All Done."
fi
