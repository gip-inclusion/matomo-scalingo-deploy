#!/bin/bash

# Usage:
#
#    scalingo --region osc-secnum-fr1 -a inclusion-matomo-production run -e 'FTP_URL=… --detached 'curl -L https://raw.githubusercontent.com/gip-inclusion/matomo-scalingo-deploy/etalab-migration/scripts/import_from_ftp.sh | bash'
#

set -euo pipefail

mkdir -p import_work
cd import_work

function install_tools() {
  mkdir -p /app/bin

  curl -LO https://github.com/q3aql/aria2-static-builds/releases/download/v1.36.0/aria2-1.36.0-linux-gnu-64bit-build1.deb \
    && dpkg -x aria2-*.deb /tmp/aria2 \
    && mv /tmp/aria2/usr/bin/aria2c /app/bin

  apt-get -qq download pv \
    && dpkg -x pv*.deb /tmp/pv \
    && mv /tmp/pv/usr/bin/* /app/bin
}

function mysql_setup() {
  dbclient-fetcher mysql
  printf '%s\n' $(printenv DATABASE_URL |
      sed -E 's,mysql://(.*):(.*)@(.*):(.*)/(.*)\?.*,[mysql] user=\1 password=\2 host=\3 port=\4 database=\5 [mysqldump] user=\1 password=\2 host=\3 port=\4,') \
      > ~/.my.cnf
}

function get_dump() {
  echo "Downloading tables dump..."

  aria2c --split=16 --max-connection-per-server=16 \
    "$FTP_URL/export_sites_global.tar.gz"

  time tar xvzf ./export_sites_global.tar.gz --strip-components=1
}

function transform_log_action() {
  echo "Transforming piwik_log_action.csv..."

  < ./piwik_log_action.csv sed -E \
    -e 's/\\\\/____BKS____/g' \
    -e 's/\\N/NULL/g' \
    -e 's/\\\t/____TAB____/g' \
    | awk '-F\t' '
      {
        if(started) {
          printf ","
        } else {
          printf "INSERT IGNORE INTO `log_action`(idaction,name,hash,type,url_prefix) VALUES ";
          started=1
        }
        gsub("'\''", "\\'\''", $2);
        gsub("____BKS____", "\\\\\\\\", $2);
        gsub("____TAB____", "\t", $2);
        printf("(%s,'\''%s'\'',%s,%s,%s)\n", $1,$2,$3,$4,$5)
      }
      NR%100000==0 {
        print ";";
        started=0
      }
      BEGIN {
        print "SET NAMES utf8mb4; LOCK TABLES `log_action` WRITE; ALTER TABLE `log_action` DISABLE KEYS;"
      }
      END {
        print ";";
        print "ALTER TABLE `log_action` ENABLE KEYS; UNLOCK TABLES;"
      }' \
    | pv -l > log_action.sql
}

function import_log_action() {
  echo "Importing log_action..."

  time pv log_action.sql | mysql
}

function import_files() {
  echo "Importing tables..."

  for f in ./export_sites_global/*.sql; do
    echo $f
    time pv $f \
      | LANG=C sed 's/piwik_//' \
      | mysql
  done
}

function fix_sequence() {
  echo "Fixing sequence table..."

  mysql -e "TRUNCATE sequence"
  for t in $(mysql -B --skip-column-names -e 'SELECT name FROM sequence'); do
    echo "SELECT CONCAT('UPDATE sequence SET value=', 1+COALESCE(MAX(idarchive),1), ' WHERE name=\\'$t\\';') FROM $t;"
  done | mysql -B --skip-column-names | mysql
}

steps=$@
: ${steps:=
  mysql_setup
  install_tools
  get_dump
  transform_log_action
  import_log_action
  import_files
  fix_sequence
}
for step in $steps; do
  echo "\$ $step"
  $step
done
