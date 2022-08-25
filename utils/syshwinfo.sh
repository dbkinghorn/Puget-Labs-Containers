######################Script Start #################################################

#!/bin/bash
clear;
printf "**********************************************************************************************************";
echo -e '\n'"This is a small script which would need \"dmidecode\" , \"smartmontools\" package and runs with the help of";
echo -e "other native linux utilities. So, make sure your system got this. This script also creates temporary files necessary ";
echo -e "to collect data under /tmp which would be wiped out after the successful run of the script.";
echo -e '\n'"Successful execution of the script would dump the hardware details under /tmp with the name \"hwlist.txt\"."'\n';
echo -e "**********************************************************************************************************";

#reading user choice whether to continue or terminate program
ans=y;
printf "If this is okay? Please enter your choice \"y\" OR \"n\" :";
read ans;
ans=$(echo $ans|tr 'a-z' 'A-Z');
if [ "$ans" != "Y" ]
then
    echo - "Terminating program on user request... Bye!"
    exit 1
fi

#check for the existence of "dmidecode" command/package
printf "\nChecking the availability \"dmidecode\" package..........";
if [ ! -x /usr/sbin/dmidecode ]
then
    printf "\t\tFailed\n\n"
    printf "Error : Either \"dmidecode\" command not available OR \"dmidecode\" package is not properly installed. Please make sure this package is installed and working properly!\n\n"
    exit 1
fi
printf "\t\tPassed ";

printf "\nChecking the availability \"smartmontools\" package..........";
if [ ! -x /usr/sbin/smartctl ]
then
    printf "\t\tFailed\n\n"
    printf "Error : Either \"smartctl\" command not available OR \"smartmontools\" package is not properly installed. Please make sure this package is installed and working properly!\n\n"
    exit 1
fi
printf "\tPassed \n";

# check the available space under /tmp which should not be 100% full or at least 95% full.
# If /tmp is not mounted as separate then this would check under / for the space availability.

######### /tmp checking starts here ##########
printf "Checking the space availability under \"tmp\" directory..........";
n=`mount|grep tmp|grep -v tmpfs`;
if [ `echo $?` != 0 ]
then   
{
    #checking the space under "root" directory since /tmp is not a separate..
 #modified
    n=`df -Ph |grep -w /|awk '{print $5}'|sed -e 's/%//g'`;
    if [ $n -ge 95 ]
    then
    {
        echo "Seems not enough space.......... please make some space under /tmp ...... this program is going to terminate    now...!"
        exit 1
    }
    fi
printf "\tPassed\n";
}
else
{ 
    #checking the space under "/tmp"
    n=`df -Ph |grep -w /tmp|awk '{print $5}'|sed -e 's/%//g'`; 
    if [ $n -ge 95 ]
    then
    {
        echo "Seems not enough space.......... please make some space under /tmp ...... this program is going to terminate now...!"
        exit 1
    }
    fi
printf "\tPassed\n";
}
fi
######### /tmp checking ends here ##########

############# Creating functions for easy usage #############
############# defining header function here #############
head_fun()
{ 
    cd /tmp;
    touch hwlist.txt;
    echo -e "******************************************************************************************************" > hwlist.txt;
    echo -e "**        Welcome to hwlist script which fetches basic hardware details from your system            **" >> hwlist.txt;
    echo -e "******************************************************************************************************" >> hwlist.txt;
    printf "\nPlease wait while the script fetches the required details!\n\n";
}

#define function to fetch main system details on RHEL/CentOS systems
os_fun()
{
hostname -f 2>/dev/null
if [ `echo $?` == 0 ]
then 
 echo -e "Hostname" '\t\t\t\t' ":" `hostname -f` >> hwlist.txt;
else
 echo -e "Hostname" '\t\t\t\t' ":" `hostname -s` >> hwlist.txt;
fi
 if [ -e /usr/bin/lsb_release ]
 then 
 echo -e "Operating System" '\t\t\t' ":" `lsb_release -d|awk -F: '{print $2}'|sed -e 's/^[ \t]*//'` >> hwlist.txt;
 else
 echo -e "Operating System" '\t\t\t' ":" `cat /etc/system-release` >> hwlist.txt;
 fi

echo -e "Kernel Version" '\t\t\t\t' ":" `uname -r` >> hwlist.txt;
printf "OS Architecture\t\t\t\t :" >> hwlist.txt;
 if [ "`arch`" == "x86_64" ]
 then 
 printf " 64 Bit OS\n" >> hwlist.txt;
 else
 printf " 32 Bit OS\n" >> hwlist.txt;
 fi
   
uptime|egrep "day|min" 2>&1 > /dev/null
if [ `echo $?` == 0 ]
then   
 echo -e "System Uptime"  '\t\t\t\t' ":" `uptime|awk '{print $2" "$3" "$4}'|sed -e 's/,.*//g'` >> hwlist.txt;
else 
  echo -e "System Uptime"  '\t\t\t\t' ":" `uptime|awk '{print $2" "$3}'|sed -e 's/,.*//g'`" hours" >> hwlist.txt;
fi
echo -e "Current System Date & Time" '\t\t' ":" `date +%c` >> hwlist.txt;
}

#defining function for server hardware details
server_fun()
{
    echo -e '\n\n\t\t' "System Hardware Details" >> hwlist.txt;
    echo -e '\t' "----------------------------------" >> hwlist.txt;
    echo -e "Product Name" '\t\t\t\t' ":" `dmidecode -s system-product-name` >> hwlist.txt;
    echo -e "Manufacturer" '\t\t\t\t' ":" `dmidecode -s system-manufacturer` >> hwlist.txt;
    echo -e "System Serial Number" '\t\t\t' ":" `dmidecode -s system-serial-number` >> hwlist.txt;
    echo -e "System Version" '\t\t\t\t' ":" `dmidecode -s system-version` >> hwlist.txt;
    echo -e '\n' >> hwlist.txt;
}

#defining function to fetch motherboard details
mobo_fun()
{
 dmidecode --type baseboard > /tmp/baseboard.out;
    echo -e '\t\t' "System Motherboard Details" >> hwlist.txt;
    echo -e '\t' "----------------------------------" >> hwlist.txt;
    echo -e "Manufacturer" '\t\t\t\t' ":" `grep "Manufacturer" /tmp/baseboard.out|awk '{print $2}'`>> hwlist.txt;
    echo -e "Product Name" '\t\t\t\t' ":" `grep "Product Name" /tmp/baseboard.out|awk -F: '{print $2}'`>> hwlist.txt;
    echo -e "Version" '\t\t\t\t' ":" `grep "Version" /tmp/baseboard.out|awk '{print $2}'`>> hwlist.txt;
    echo -e "Serial Number" '\t\t\t\t' ":" `grep "Serial Number" /tmp/baseboard.out|awk -F: '{print $2}'`>> hwlist.txt;
    echo -e '\n' >> hwlist.txt;
}

#function for BIOS call
bios_fun()
{
    echo -e '\t\t' "System BIOS Details" >> hwlist.txt;
    echo -e '\t' "----------------------------------" >> hwlist.txt;
    echo -e "BIOS Vendor" '\t\t\t\t' ":" `dmidecode -s bios-vendor` >> hwlist.txt;
    echo -e "BIOS Version" '\t\t\t\t' ":" `dmidecode -s bios-version` >> hwlist.txt;
    echo -e "BIOS Release Date" '\t\t\t' ":" `dmidecode -s bios-release-date` >> hwlist.txt;
    echo -e '\n' >> hwlist.txt;
}

#function call for processor
proc_fun()
{
dmidecode --type processor > /tmp/proc.out

 echo -e '\t\t' "System Processor Details" >> hwlist.txt;
 echo -e '\t' "----------------------------------" >> hwlist.txt;
 echo -e "Manufacturer" '\t\t\t\t' ":" `grep "vendor_id" /proc/cpuinfo|uniq|awk -F: '{print $2}'` >> hwlist.txt;
 echo -e "Model Name" '\t\t\t\t' ":" `grep "model name" /proc/cpuinfo|uniq|awk -F: '{print $2}'` >> hwlist.txt;
 echo -e "CPU Family" '\t\t\t\t' ":" `grep "family" /proc/cpuinfo|uniq|awk -F: '{print $2}'` >> hwlist.txt;
 echo -e "CPU Stepping" '\t\t\t\t' ":" `grep "stepping" /proc/cpuinfo|awk -F":" '{print $2}'|uniq` >> hwlist.txt;

if [ -e /usr/bin/lscpu ]
then
{
 echo -e "No. Of Processors" '\t\t\t' ":" `lscpu|grep -w "Socket(s):"|awk -F":" '{print $2}'` >> hwlist.txt;
 echo -e "No. of Cores/Processor" '\t\t\t' ":" `lscpu|grep -w "Core(s) per socket:"|awk -F":" '{print $2}'` >> hwlist.txt;
}
else
{
 echo -e "No. Of Processors Found" '\t\t' ":" `grep -c processor /proc/cpuinfo` >> hwlist.txt;
}
fi

echo -e '\n' "Details Of Each Processor (Based On dmidecode)" '\t' '\t' >> hwlist.txt;
echo -e '\t' "----------------------------------" >> hwlist.txt;
#grep -w "Populated, Enabled" -A7 -B5 /tmp/proc.out|egrep -v -w "L1|L2|L3|Upgrade"|sed -e 's/^\s*//' -e '/^$/d' -e 's/^/\t\t/g' >> hwlist.txt;

#grep -w "Populated, Enabled" -A7 -B5 /tmp/proc.out|egrep -v -w "L1|L2|L3|Upgrade|Version|Manufacturer|ID|Family"|sed -e 's/^\s*//'|awk -F":" '{print $1}' > /tmp/p1.out;
#grep -w "Populated, Enabled" -A7 -B5 /tmp/proc.out|egrep -v -w "L1|L2|L3|Upgrade|Version|Manufacturer|ID|Family"|awk -F":" '{print $2}'|sed -e 's/^\s*//' > /tmp/p2.out;
#pr -t -m -w 80 -S:\   /tmp/p1.out /tmp/p2.out >> hwlist.txt;

COUNT=`grep -c processor /proc/cpuinfo`

egrep -w -m$COUNT "Socket Designation:" /tmp/proc.out > /tmp/s1.out
egrep -w -m$COUNT "Type:" /tmp/proc.out > /tmp/s2.out
egrep -w -m$COUNT "Family:" /tmp/proc.out  > /tmp/s3.out
egrep -w -m$COUNT "Version:" /tmp/proc.out > /tmp/s4.out
egrep -w -m$COUNT "Voltage:" /tmp/proc.out > /tmp/s5.out
egrep -w -m$COUNT "Max Speed:" /tmp/proc.out > /tmp/s6.out
egrep -w -m$COUNT "Current Speed:" /tmp/proc.out > /tmp/s7.out
egrep -w -m$COUNT "Serial Number:" /tmp/proc.out > /tmp/s8.out
egrep -w -m$COUNT "Asset Tag:" /tmp/proc.out > /tmp/s9.out
egrep -w -m$COUNT "Part Number:" /tmp/proc.out > /tmp/s10.out

for (( num=1; num <= $COUNT; num++ ))
do
    echo "-------------------------------" >> /tmp/s11.out;
done

paste -d'\n' /tmp/s1.out /tmp/s2.out /tmp/s3.out /tmp/s4.out /tmp/s5.out /tmp/s6.out /tmp/s7.out /tmp/s8.out /tmp/s9.out /tmp/s10.out /tmp/s11.out|sed -e 's/^\s*//' -e '/^$/d' -e 's/^/\t\t/g' >> hwlist.txt;

echo -e '\n' >> hwlist.txt;
}


#function call for memory
mem_fun()
{
dmidecode --type memory > /tmp/mem.out
sed -n -e '/Memory Device/,$p' /tmp/mem.out > /tmp/memory-device.out

echo -e '\t' "System Memory Details (RAM)" >> hwlist.txt;
echo -e '\t' "----------------------------------" >> hwlist.txt;

echo -e "Total (Based On Free Command)" '\t' ": "$((`grep -w MemTotal /proc/meminfo|awk '{print $2}'`/1024))" MB" $((`grep -w MemTotal /proc/meminfo|awk '{print $2}'`/1024/1024))" GB" >> hwlist.txt;
echo -e "Error Detecting Method" '\t\t' ":" `grep -w "Error Detecting Method" /tmp/mem.out|awk -F":" '{print $2}'` >> hwlist.txt; 
echo -e "Error Correcting Capabilities" '\t' ":" `grep -w -m1 "Error Correcting Capabilities" /tmp/mem.out|awk -F":" '{print $2}'` >> hwlist.txt;

echo -e "No. Of Memory Modules Found" '\t' ":" `grep -w "Installed Size" /tmp/mem.out|grep -vc "Not Installed"` >> hwlist.txt;
p=`dmidecode --type memory | grep 'Installed Size'|awk -F: '{print $2}'|grep -v 'Not' |wc -l`;

echo -e '\n\t' "Memory Modules Detected" '\t\t\t' >> hwlist.txt;
echo -e '\t' "----------------------------------" >> hwlist.txt;
grep "Installed Size" /tmp/mem.out|grep -v "Not"|awk -F: '{print $2}' >> hwlist.txt;
echo -e '\n\t' "Details of Each Memory Module" '\t' '\t' >> hwlist.txt;
echo -e '\t' "----------------------------------" >> hwlist.txt;

grep -E '[[:blank:]]Size: [0-9]+' /tmp/memory-device.out -A11|egrep -v "Set|Tag"|sed -e 's/^\s*//'|awk -F":" '{print $1}' > /tmp/m1.out;
grep -E '[[:blank:]]Size: [0-9]+' /tmp/memory-device.out -A11|egrep -v "Set|Tag"|awk -F":" '{print $2}'|sed -e 's/^\s*//' > /tmp/m2.out;
pr -t -m -w 50 -S:\   /tmp/m1.out /tmp/m2.out |sed -e 's/^/\t\t/g' >> hwlist.txt;
}

#function call to fetch PCI devices
pci_fun()
{
    echo -e '\n\t\t' "PCI Controller(s) Found" '\t' '\t' '\t' >> hwlist.txt;
    echo -e '\t' "----------------------------------" >> hwlist.txt;
    lspci | grep controller|awk -F":" '{print $2}'|sed -e 's/^....//'|awk '{ printf "%-10s\n", $1}' > /tmp/n1.txt;
    lspci | grep controller|awk -F":" '{print ":"$3}'|sed -e 's/^\s*//' -e '/^$/d' -e 's/^/\t\t\t/g' > /tmp/n2.txt;
    paste -d" " /tmp/n1.txt /tmp/n2.txt|sort -u >> /tmp/hwlist.txt;
}


#function call to fetch Hard Disk Drive (HDD) details
disk_fun()
{ 

    echo -e '\n\t\t' "Disk Details" '\t\t\t' >> hwlist.txt;
    echo -e "--------------------------------------------------------------" >> hwlist.txt;
    echo -e "Device type" '\t\t' "Logical Name" '\t\t' "Size" >> hwlist.txt;
    echo -e "--------------------------------------------------------------" >> hwlist.txt;
    fdisk -l > /tmp/n1.txt 2>/dev/null;
    cat /tmp/n1.txt|grep -w "Disk"|egrep -v "mapper|identifier"|column -t|awk -F" " '{print $1"\t\t\t",$2"\t\t",$3$4}'|sed -e 's/[:|,]//g'|sort >> hwlist.txt;

       #### Printing each disk details depending on version##########

 cat /tmp/n1.txt|grep "Disk"|egrep -v "mapper|identifier|contain"|awk -F" " '{print $2}'|sed 's/://g'|sort > /tmp/n2.txt;
 echo -e '\n\t\t' "Details Of Each Hard Drive(s) Found" >> hwlist.txt;
 
 
 awk -F"/" '{print $3}' /tmp/n2.txt > /tmp/n3.txt;
 
 for i in  $(cat /tmp/n2.txt); 
 do
 {
 echo -e '\t' "--------------------------------------------------" >> hwlist.txt;
 echo -e '\t\t\t' "Disk" $i >> hwlist.txt; 
 echo -e '\t' "--------------------------------------------------" >> hwlist.txt;
 
 H=`echo $i|awk -F"/" '{print $3}'`;
 
 echo -e '\t' "Disk Model" '\t\t\t' ":" `cat /sys/block/$H/device/model` >> hwlist.txt;
 echo -e '\t' "Disk Vendor" '\t\t\t' ":" `cat /sys/block/$H/device/vendor` >> hwlist.txt;
 echo -e '\t' "Disk Serial Number" '\t\t' ":" `smartctl -i $i|grep "Serial Number"|awk -F":" '{print $2}'` >> hwlist.txt;  
 echo -e '\t' "Drive Firmware Version" '\t' ":" `smartctl -i $i|grep "Firmware Version"|awk -F":" '{print $2}'` >> hwlist.txt;
 echo -e "\t Device Path \t\t\t :" `ls -l /dev/disk/by-path/|grep -w $H|grep -o "pci.*"` >> hwlist.txt;
 }
 done; 
} 


#function call for network info
net_fun()
{

echo -e '\n\n''\t\t'"Network Hardware Info" >> hwlist.txt;
echo -e '\t' "----------------------------------" >> hwlist.txt;
echo -e "Ethernet Controller Name" '\t\t' ":" >> hwlist.txt;
lspci | grep Ethernet|awk -F":" '{print $3}'|uniq|sed -e 's/^/\t\t\t\t\t/g' >> hwlist.txt;
echo -e "Total Network Interfaces" '\t\t' ":" `ifconfig -a|grep HWaddr|wc -l` >> hwlist.txt;
echo -e "Active Network Interfaces" '\t\t' ":" `ifconfig|grep HWaddr|wc -l` >> hwlist.txt;
echo -e '\n' >> hwlist.txt;
echo -e '\t'"Details Of Active Network Interface(s) Found" >> hwlist.txt;
echo -e '\t'"  ""----------------------------------" >> hwlist.txt;
ifconfig |grep -i hwaddr|awk '{print $1}' > /tmp/n1.txt ;

for i in $(cat /tmp/n1.txt) ;
    do
    {
    echo -e '\t'"Interface Name" '\t\t\t' ":" $i >> hwlist.txt;
    echo -e '\t'"IP Address" '\t\t\t' ":" `ifconfig $i|grep "inet addr"|awk '{print $2}'|sed -e 's/^addr://g'` >> hwlist.txt;
    echo -e '\t'"Hardware Address" '\t\t' ":" `ifconfig $i|grep HWaddr|awk '{print $5}'` >> hwlist.txt;
    echo -e '\t'"Driver Module Name" '\t\t' ":" `ethtool -i $i|grep driver|awk '{print $2}'` >> hwlist.txt;
    echo -e '\t'"Driver Version" '\t\t\t' ":" `ethtool -i $i|grep -A1 -i driver|grep version|awk '{print $2}'` >> hwlist.txt;
    echo -e '\t'"Firmware Version" '\t\t' ":" `ethtool -i $i|grep firmware|awk '{print $2}'` >> hwlist.txt;
    echo -e '\t'"Speed" '\t\t\t\t' ":" `ethtool $i|grep Speed|awk '{print $2}'` >> hwlist.txt;
    echo -e '\t'"Duplex Mode" '\t\t\t' ":" `ethtool $i|grep Duplex|awk '{print $2}'` >> hwlist.txt;
    echo -e '\n' >> hwlist.txt;
    }
done
}

#function call for footer
foot_fun()
{
 echo -e "!!!!! If any of the above fields are marked as \"blank\" or \"NONE\" or \"UNKNOWN\" or \"Not Available\" or \"Not Specified\" that means either there is no value present in the system for these fields, otherwise that value may not be available !!!!!" >> hwlist.txt;
 echo -e '\n\t\t\t'"Powered By : http://simplylinuxfaq.blogspot.in. Keep checking this site for changes." >> hwlist.txt;
 echo -e '\n\n'"The dump has been stored under \"/tmp/hwlist.txt\" file"'\t\t'"...DONE";
 echo -e "Wiping out temporarily created files under \"/tmp\" directory"'\t'"...DONE";
 rm -rf /tmp/n1.txt /tmp/n2.txt /tmp/n3.txt /tmp/baseboard.out /tmp/mem.out /tmp/memory-device.out /tmp/p1.out /tmp/p2.out /tmp/m1.out /tmp/m2.out /tmp/s1.out /tmp/s2.out /tmp/s3.out /tmp/s4.out /tmp/s5.out /tmp/s6.out /tmp/s7.out /tmp/s8.out /tmp/s9.out /tmp/s10.out /tmp/s11.out;
 echo -e '\n'"Thanks for Choosing this script!!!!\n";
}


#######calling above functions #######
cd /tmp;
if [ -f hwlist.txt ]
then
{
  printf "\nThere is \"hwlist.txt\" file present under \"tmp\" directory. Do you wish to remove this file and create a new one. Please enter your choice \"y\" OR \"n\" :";
   read ans;
   ans=$(echo $ans|tr 'a-z' 'A-Z');
    if [ "$ans" != "Y" ]
     then
      echo - "Terminating program on user request... Bye!"
      exit 1
 fi 
    printf "\nThe existing \"hwlist.txt\" file has been removed and would be re-created now. \n";
    rm -rf hwlist.txt; 
}
touch hwlist.txt;
fi

#calling the header function to print header text here
head_fun

#print operating system details
os_fun 

#calling function to print Server details
server_fun

#calling function to print motherboard details
mobo_fun

#calling function to print system BIOS details
bios_fun

#calling processor function now
proc_fun

#memory related details function to be called now
mem_fun

#calling PCI function
pci_fun

#call to disk function now
disk_fun

#calling network function
net_fun

#call to footer function
foot_fun
exit
###############Script End ##############################################
