# Icinga2 Plugin to Monitor the Cost (Money) of the 2 Power Input of 
# gude-8220-1 (https://www.gude.info/unternehmen/news/news/article/die-firma-gude-praesentiert-ihre-neueste-generation-an-intelligenten-power-distribution-units-pdus.html)
# Expert Power Control 8220-1 - v1.0.4
# gude 8220 has two mesurable Power Input called A and B
# 
# version: 0.01 | 21.08.2018 14:35 Author: Vincent Kocher | www.wombat.ch
# ==================================================================
# a place for notes if it runs will be deleted:
#    ***  | awk '{print $4}' | cut -c 2- )
#
#
#
#
#############################################################################
Variable and to define/change

device.snmp.h= 10.147.42.31          # Power Control IP Address
device.snmp.c= public                # Community String
device.snmp.v= 2c                    # SNMP Version // 1 not supported
device.snmp.u=                       # SNMPv3 User
device.snmp.A=                       # SNMPv3 Password
device.snmp.a=                       # SNMPv3 set authentication protocol (MD5|SHA)
device.snmp.x=                       # SNMPv3 set privacy protocol (DES|AES)
device.snmp.w=                       # Icinga2 warning 
device.snmp.c=                       # Icinga2 critical

device.snmp.retries=                      # SNMPv3 set the number of retries
device.snmp.timeout=                      # SNMPv3 set the request timeout (in seconds)

A.iso= iso.3.6.1.4.1.28507.38.1.5.1.2.1.3.1 # ISO Path to the Bank A Power input
B.iso= iso.3.6.1.4.1.28507.38.1.5.1.2.1.3.2 # ISO Path to the Bank B Power input

Niedertarif.start= 18:00
Niedertarif.stop= 05:00

Hochtarif.start= 05:00
Hochtarif.stop= 18:00

Hochtarif.wert= 8.50                    # SFr. /kWh
Niedertarif.wert= 5.50                  # SFr. /kwh

Zeitzone= Schweiz               
Zeit.ntp.source= 10.147.42.6           # IP or Hostname of a NTP Server

Kosten.steps= 5                        # Minuten             
============================================



# snmpwalk -v -c -h 
if device.snmp.v =2*
snmpget -v 2c -c public 10.147.42.31 iso.3.6.1.4.1.28507.38.1.5.1.2.1.3.1 | awk '{print $4}'
# output is 755487 but should be divided by 1000 and be like 755.487

else
snmpget........................ 

A.Stromverbrauch.0   =  SNMPget
A.Stromvarbrauch.5   =  SNMPget
A.stromverbrach.dif  =  Stromvarbrauch.5 - Stromverbrauch.0

Hochtarif.min        = Hochtarif.wert / 60
A.Tarif-5min         = Hochtarif.min x Kosten.steps X A.stromverbrach.dif

snmpget -v 2c -c public 10.147.42.31 iso.3.6.1.4.1.28507.38.1.5.1.2.1.3.2 | awk '{print $4}'
B.Stromverbrauch.0   =  SNMPget
B.Stromvarbrauch.5   =  SNMPget
B.stromverbrach.dif  =  Stromvarbrauch.5 - Stromverbrauch.0

B.Tarif-5min         = Hochtarif.min x Kosten.steps X B.stromverbrach.dif

// snmpwalk -v 2c -c public 10.147.42.31 iso.3.6.1.4.1.28507.38.1.5.1.2.1.3
// .1 = A
// .2 = B


===========================================
Output should be a graf 5 minutes a Preis
color nightblue = Niedertarif
color dayOrange = Hochtarif

Output schould be kumuliert pro Stunde
color nightblue = Niedertarif
color dayOrange = Hochtarif

Output should be kumuliert pro Tag
color nightblue = Niedertarif
color dayOrange = Hochtarif

Output Kumuliert pro Woche
color nightblue = Niedertarif
color dayOrange = Hochtarif

Pro Monat
color nightblue = Niedertarif
color dayOrange = Hochtarif

Pro Jahr
color nightblue = Niedertarif
color dayOrange = Hochtarif
