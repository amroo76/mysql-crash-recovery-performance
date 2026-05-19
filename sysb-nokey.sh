BASE=/home/amrendra/TAF/database_software_installs/mysql-9.6.0-linux-x86_64
BIN_DIR=/home/amrendra/TAF/database_software_installs/mysql-9.6.0-linux-x86_64/bin
config=/home/amrendra/projects/crash-recovery/mysql_simple_binlog_2gbp.cnf
export BMK_HOME=/home/amrendra/sw/BMK-kit/BMK
cd $BMK_HOME
source $BMK_HOME/.bench
dt=`date +%Y%m%d%H%M%S`
logdir="/home/amrendra/projects/crash-recovery/log/nokey"
threads=10

pkill mysqld
sync
sleep 10
rm -rf /home/amrendra/projects/crash-recovery/data/*
# initialize db
$BIN_DIR/mysqld  --defaults-file=$config --initialize-insecure -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock --loose-log-error-verbosity=3

sleep 20

#start db
$BIN_DIR/mysqld  --defaults-file=$config  -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock  &

sleep 20

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock   -e  "ALTER USER 'root'@'localhost' IDENTIFIED BY '.userMDS00';"

#create user dim and create db test


#create sysbench db

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e " create database test; create user 'dim'@'%' identified by '.userMDS00';grant SELECT,INSERT,DELETE,UPDATE,CREATE,DROP,PROCESS,USAGE,INDEX,SHOW DATABASES on *.* to 'dim'@'%' ;"

cd $BMK_HOME/sb_exec/lua

$BMK_HOME/sysbench-1.1-mysql80-ssl111L-x64 $BMK_HOME/sb_exec/lua/oltp_update_non_index.lua   --db-driver=mysql --mysql-host=localhost --events=0 --time=300 --mysql-db=test --mysql-password=.userMDS00 --mysql-socket=/home/amrendra/projects/crash-recovery/mysql.sock --mysql-user=dim --threads=${threads} --rand-type=uniform --tables=8 --forced-shutdown=1 --table-size=500000 --auto-inc=on --mysql-ssl=disabled --thread-init-timeout=0 create

$BMK_HOME/sysbench-1.1-mysql80-ssl111L-x64 $BMK_HOME/sb_exec/lua/oltp_update_non_index.lua   --db-driver=mysql --mysql-host=localhost --events=0 --time=300 --mysql-db=test --mysql-password=.userMDS00 --mysql-socket=/home/amrendra/projects/crash-recovery/mysql.sock --mysql-user=dim --threads=${threads} --rand-type=uniform --tables=8 --forced-shutdown=1 --table-size=500000 --auto-inc=on --mysql-ssl=disabled --thread-init-timeout=0 prepare

#do shutdown to flush all dirty pages
$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e "SET GLOBAL innodb_fast_shutdown = 0; shutdown;"
sleep 20
#start server again
$BIN_DIR/mysqld  --defaults-file=$config  -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock  &
sleep 20

#disable checkpoint

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e " SHOW ENGINE INNODB STATUS;set global innodb_checkpoint_disabled=1;" >  ${logdir}/${dt}_key_100k_before_test.log

$BMK_HOME/sysbench-1.1-mysql80-ssl111L-x64 $BMK_HOME/sb_exec/lua/oltp_update_non_index.lua   --db-driver=mysql --mysql-host=localhost --events=100000 --time=300 --mysql-db=test --mysql-password=.userMDS00 --mysql-socket=/home/amrendra/projects/crash-recovery/mysql.sock --mysql-user=dim --threads=${threads} --rand-type=uniform --tables=8 --forced-shutdown=1 --table-size=500000 --auto-inc=on --mysql-ssl=disabled --thread-init-timeout=0 run > ${logdir}/${dt}_key_100k_sysb.log
sleep 10
$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e " SHOW ENGINE INNODB STATUS;" > ${logdir}/${dt}_key_100k_after_test.log

pkill mysqld
sync
sleep 20

$BIN_DIR/mysqld  --defaults-file=$config  -uroot --basedir=$BASE --datadir=/home/amrendra/projects/crash-recovery/data/ --loose-log-error-verbosity=3 --log-error=/home/amrendra/projects/crash-recovery/data/mysqld_error.log --port=3306 --socket=/home/amrendra/projects/crash-recovery/mysql.sock  &
sleep 20

$BIN_DIR/mysql --host=localhost -uroot --get-server-public-key --socket=/home/amrendra/projects/crash-recovery/mysql.sock -p.userMDS00 -vvv -e " SHOW ENGINE INNODB STATUS;" >  ${logdir}/${dt}_key_100k_after_crash.log
sleep 10


cp /home/amrendra/projects/crash-recovery/data/mysqld_error.log ${logdir}/${dt}_key_100k_error.log

cd  /home/amrendra/projects/crash-recovery

