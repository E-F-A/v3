#!/bin/bash
# +--------------------------------------------------------------------+
# EFA Project whitelist and blacklist mass import script
# Version 20140921
# +--------------------------------------------------------------------+
# Copyright (C) 2014~2018  http://www.efa-project.org
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

SQLTMPFILE="listimport.sql"
SQLTMPDIR="/tmp/EFA/"
infile=""
isblacklist="0"
iswhitelist="0"
append="0"
overwrite="0"
quiet="0"


function help(){
  echo 
  echo "EFA Mass Whitelist and Blacklist Import Help"
  echo 
  echo "listimport.sh  Copyright (C) 2014  efa-project.org"
  echo "Licened GNU GPL v3. This program comes with ABSOLUTELY NO WARRANTY"
  echo "This is free software, and you are welcome to redistribute it under"
  echo "certain conditions.  See http://www.gnu.org/licenses for more details"
  echo 
  echo "Usage: listimport.sh -f mylist -b|-w [-a|-o [-q]]"
  echo "-f	Whitelist or Blacklist File"
  echo "-a	append to existing list"
  echo "-b	File is a Blacklist"
  echo "-q      force overwrite database tables without prompting"
  echo "-o	overwrite existing list"
  echo "-w	File is a Whitelist"
  echo
  echo "Whitelist and Blacklist is newline separated list with each"
  echo "line in either of the following formats:"
  echo 
  echo '<From Address Domain or IP>, <To Address Domain or IP>'
  echo '<From Address Domain or IP>'
  echo 
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
    -b|--blacklist)
    isblacklist="1"
    ;;
    -w|--whitelist)
    iswhitelist="1"
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

if [[ $iswhitelist == "1" && $isblacklist == "1" ]]; then
  echo "Incompatible parameter combination (-w and -b)"
  flag="1"
fi

if [[ $iswhitelist == "0" && $isblacklist == "0" ]]; then
  echo "Whitelist or Blacklist not specified"
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
  
  if [[ $iswhitelist == "1" ]]; then
    echo 'DROP TABLE IF EXISTS `whitelist`;' >> $SQLTMPDIR$SQLTMPFILE
    echo 'CREATE TABLE `whitelist` (' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `id` int(11) NOT NULL AUTO_INCREMENT,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `to_address` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `to_domain` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `from_address` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' PRIMARY KEY (`id`),' >> $SQLTMPDIR$SQLTMPFILE
    echo ' UNIQUE KEY `whitelist_uniq` (`to_address`(100),`from_address`(100))' >> $SQLTMPDIR$SQLTMPFILE
    echo ') ENGINE=MyISAM DEFAULT CHARSET=utf8;' >> $SQLTMPDIR$SQLTMPFILE
  elif [[ $isblacklist == "1" ]]; then
    echo 'DROP TABLE IF EXISTS `blacklist`;' >> $SQLTMPDIR$SQLTMPFILE 
    echo 'CREATE TABLE `blacklist` (' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `id` int(11) NOT NULL AUTO_INCREMENT,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `to_address` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `to_domain` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' `from_address` text,' >> $SQLTMPDIR$SQLTMPFILE
    echo ' PRIMARY KEY (`id`),' >> $SQLTMPDIR$SQLTMPFILE
    echo ' UNIQUE KEY `blacklist_uniq` (`to_address`(100),`from_address`(100))' >> $SQLTMPDIR$SQLTMPFILE
    echo ') ENGINE=MyISAM DEFAULT CHARSET=utf8;' >> $SQLTMPDIR$SQLTMPFILE
  fi
fi

# Lock Tables for writing and begin input
if [[ $iswhitelist == "1" ]]; then
  echo 'LOCK TABLES `whitelist` WRITE;' >> $SQLTMPDIR$SQLTMPFILE
  echo -n 'INSERT INTO `whitelist` (to_address,to_domain,from_address) VALUES ' >> $SQLTMPDIR$SQLTMPFILE
elif [[ $isblacklist == "1" ]]; then
  echo 'LOCK TABLES `blacklist` WRITE;' >> $SQLTMPDIR$SQLTMPFILE
  echo -n 'INSERT INTO `blacklist` (to_address,to_domain,from_address) VALUES ' >> $SQLTMPDIR$SQLTMPFILE
fi

# Process each line of file

firstloop="1"
TMPIFS=$IFS
IFS=","
while read col1 col2
do
  fromaddress=""
  toaddress=""
  todomain=""
  # check input length 
  fromaddress=$col1
  if [[ $fromaddress =~ ^.{2,100}$ ]]; then
    if [[ $col2 != "" && $col2 =~ ^.{2,100}$ ]]; then
      toaddress=$col2
      todomain=`echo $col2 | awk -F@ '{print $2}'`
      if [[ $todomain == "" ]]; then
        todomain=$toaddress
      fi
    else
      toaddress="default"
    fi
  
    if [[ $firstloop != "1" ]]; then
      echo -n "," >> $SQLTMPDIR$SQLTMPFILE
    else
      firstloop="0"
    fi
    echo -n "('$toaddress','$todomain','$fromaddress')" >> $SQLTMPDIR$SQLTMPFILE
  fi  

done < $infile
IFS=$TMPIFS

echo ";" >> $SQLTMPDIR$SQLTMPFILE
echo "UNLOCK TABLES;" >> $SQLTMPDIR$SQLTMPFILE

# Import into MySQL
mysql -u mailwatch --password=$MAILWATCHSQLPWD mailscanner < /tmp/EFA/listimport.sql

# Cleanup
rm -f /tmp/EFA/listimport.sql
rmdir /tmp/EFA

