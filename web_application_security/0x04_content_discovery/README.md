curl -I http://web0x04.hbtn/

task2:
 gobuster dir -u http://web0x04.hbtn -w common.txt -t 20 --timeout 20s --exclude-length 53720
 
task3:
dig @10.42.38.222 web0x04.hbtn NS

