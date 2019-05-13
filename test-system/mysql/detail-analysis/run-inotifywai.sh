>> inotifywait -m -r --format 'Time:%T PATH:%w%f EVENTS:%,e' --timefm '%F %T' /mnt/nvme0n1/docker/ 
>> fatrace -t -o $DIR


### Container generation
>> ./genMySQL.sh 1
>> /data/mkwon-mysql/root-dir-access-test/fatrace/volume-gen.access 

### TEST
>> ./test-mysql-each.sh 1 oltp_read_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_prepare.sysbench 1
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_prepare.access

>> ./test-mysql-each.sh 1 oltp_read_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_run.sysbench 2
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_run.access

>> ./test-mysql-each.sh 1 oltp_read_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_cleanup.sysbench 3
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_read_only_cleanup.access

>> ./test-mysql-each.sh 1 oltp_write_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_prepare.sysbench 1
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_prepare.access

>> ./test-mysql-each.sh 1 oltp_write_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_run.sysbench 2
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_run.access

>> ./test-mysql-each.sh 1 oltp_write_only /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_cleanup.sysbench 3
>> /data/mkwon-mysql/root-dir-access-test/fatrace/oltp_write_only_cleanup.access

>> docker checkpoint create mysql1 checkpoint0
>> /data/mkwon-mysql/root-dir-access-test/fatrace/checkpoint.access 
