for i in  1 2 3
do
echo "iteration ${i}"
	./sysb-writeonly.sh
	sleep 20
	./sysb-key.sh
	sleep 20
	./sysb-nokey.sh
	sleep 20
done
