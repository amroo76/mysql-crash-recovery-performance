pkill mysqld
sync
sleep 10
rm -rf ./data/mysqld_error.log
BASE=/home/amrendra/TAF/database_software_installs/mysql-9.6.0-linux-x86_64
BIN_DIR=/home/amrendra/TAF/database_software_installs/mysql-9.6.0-linux-x86_64/bin
config=/home/amrendra/projects/crash-recovery/mysql_simple_binlog_2gbp.cnf

$BIN_DIR/mysqld  --defaults-file=$config  -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock  &

sleep 20

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e "set @@cte_max_recursion_depth=100000;drop table test.t1 if exists; select count(*) from test.t1; SHOW ENGINE INNODB STATUS; set global innodb_checkpoint_disabled=1; INSERT INTO test.t1 (c) WITH RECURSIVE row_generator as  ( SELECT 1 as n   UNION ALL  SELECT n + 1 FROM row_generator WHERE n < 100000 ) SELECT CONCAT('row_', n) FROM row_generator;  SHOW ENGINE INNODB STATUS" > before.txt
sleep 10

pkill mysqld
sync
sleep 10

$BIN_DIR/mysqld  --defaults-file=$config  -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock  &
sleep 20

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e "select count(*) from test.t1;  SHOW ENGINE INNODB STATUS;" > after.txt
