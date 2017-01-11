#!/bin/bash
# +--------------------------------------------------------------------+
# EFA Project whitelist and blacklist mass import script
# Version 20140921
# +--------------------------------------------------------------------+
# Copyright (C) 2014~2017  http://www.efa-project.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# +--------------------------------------------------------------------+

SQLTMPFILE="userimport.sql"
SQLTMPDIR="/tmp/EFA/"
infile=""
append="0"
overwrite="0"
quiet="0"


function help(){
  echo 
  echo "EFA Mass User Import Help"
  echo 
  echo "userimport.sh  Copyright (C) 2014  efa-project.org"
  echo "Licensed GNU GPL v3. This program comes with ABSOLUTELY NO WARRANTY"
  echo "This is free software, and you are welcome to redistribute it under"
  echo "certain conditions.  See http://www.gnu.org/licenses for more details"
  echo 
  echo "Usage: userimport.sh -f mylist -a|-o [-q]"
  echo "-a      append to existing list"
  echo "-q      force overwrite database tables without prompting"
  echo "-o      overwrite existing list (admins and domain admins exempt)"
  echo
  echo "user list mylist is newline comma separated list with each"
  echo "line in the following format:"
  echo 
  echo '<username>,<password>,<fullname>,<type>'
  echo 'type={A,D,U,R,H}'
}

if [[ "$#" == "0" ]]; then
  help  
fi

if [[ `whoami` != "root" ]]; then
  echo "Root access is required to execute script, exiting."
  exit 1
fi

while [[ $# > 0 ]]
do
  param="$1"
  shift

  case $param in
    -f|--file)
    infile="$1"
    shift
    ;;
    -a|--append)
    append="1"
    ;;
    -q|--quiet)
    quiet="1"
    ;;
    -o|--overwrite)
    overwrite="1"
    ;;
    *)
    help
    ;;
  esac  
done

flag="0"
# parameter sanity check
if [[ $overwrite == "1" && $append == "1" ]]; then
  echo "Incompatible parameter combination (-a and -o)"
  flag="1"
fi

if [[ $quiet == "1" && $overwrite == "0" ]]; then
  echo "Quiet flag (-q) used without overwrite (-o)"
  flag="1"
fi

if [[ $infile == "" ]]; then
  echo "No input file specified"
  flag="1"
elif [[ ! -f $infile ]]; then
  echo "File not found or not a regular file"
  flag="1"
fi

[ $flag == "1" ] && exit 1

# get access to mysql
MAILWATCHSQLPWD=`grep MAILWATCHSQLPWD /etc/EFA-Config | sed 's/.*://'`
if [[ -z $MAILWATCHSQLPWD ]]; then
  echo "Unable to access SQL password from /etc/EFA-Config, exiting."
fi

# Build SQL SCript Header and prompt for overwrite if needed
mkdir -p $SQLTMPDIR
rm -f $SQLTMPDIR$SQLTMPFILE
touch $SQLTMPDIR$SQLTMPFILE
echo 'LOCK TABLES `users` WRITE;' >> $SQLTMPDIR$SQLTMPFILE
if [[ $overwrite == "1" ]]; then
  if [[ $quiet == "0" ]]; then
    flag="0"
    echo "The table in mySQL will be overwritten with values from your file."
    echo -n "Continue? (y/N):"
    read CONFIRM
    while [ $flag -eq 0 ]
      do
        if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]] 
        then
          flag="1"
        elif [[ $CONFIRM == "n" || $CONFIRM == "N" || $CONFIRM == "" ]]; then
          exit 1
        else
          echo -n "Continue? (y/N):"
          read CONFIRM
        fi
      done
  fi
  
  echo "DELETE from \`users\` where type RLIKE '[UHR]';" >> $SQLTMPDIR$SQLTMPFILE 
  
  fi

# Lock Tables for writing and begin input
  echo -n 'INSERT INTO `users` (username,password,fullname,type) VALUES ' >> $SQLTMPDIR$SQLTMPFILE

# Process each line of file

firstloop="1"
TMPIFS=$IFS
IFS=","
while read col1 col2 col3 col4
do
  username=""
  password=""
  fullname=""
  type=""
  # check input length 
  username=$col1
  if [[ $username != "" && $username =~ ^.{2,60}$ ]]; then
    password=$col2
    
    if [[ $col2 != "" && $col2 =~ ^.{4,32}$ ]]; then
      password=$col2
      if [[ $col3 =~ ^.{0,50}$ ]]; then
        fullname=$col3
        if [[ $col4 != "" && $col4 =~ ^[ADURH]$ ]]; then
            type=$col4
        fi
      fi
     fi
   if [[ $firstloop != "1" ]]; then
      echo -n "," >> $SQLTMPDIR$SQLTMPFILE
    else
      firstloop="0"
    fi
    echo -n "('$username',md5('$password'),'$fullname','$type')" >> $SQLTMPDIR$SQLTMPFILE
  fi  

done < $infile
IFS=$TMPIFS

echo ";" >> $SQLTMPDIR$SQLTMPFILE
echo "UNLOCK TABLES;" >> $SQLTMPDIR$SQLTMPFILE

# Import into MySQL
mysql -u mailwatch --password=$MAILWATCHSQLPWD mailscanner < /tmp/EFA/userimport.sql

# Cleanup
rm -f /tmp/EFA/userimport.sql
rmdir /tmp/EFA

