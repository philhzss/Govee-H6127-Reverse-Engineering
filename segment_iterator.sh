#!/bin/bash
#Quick bash script to iterate over all the segments in the strip.
for i in {1..255}
 do
  x=$(printf '%x\n' $i)
  xord=$((0x33^0x05^0x0b^0xff^0x$x^0x$x))
  xor=$(printf '%x\n' $xord)
  if [[ $i -lt 16 ]]; then
   echo less than value
   x=0$x
  else
   echo safe
  fi
  zzz=33050bff0000${x}${x}0000000000000000000000${xor}
  echo $i,$x,$xor,$zzz
  gatttool -i hci0 -b xx:xx:xx:xx:xx:xx --char-write-req -a 0x0015 -n 33050200FF0000000000000000000000000000cb #insert mac
  gatttool -i hci0 -b xx:xx:xx:xx:xx:xx --char-write-req -a 0x0015 -n $zzz                                     #insert mac
  sleep 1
done
