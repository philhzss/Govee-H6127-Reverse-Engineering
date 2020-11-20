# Govee-H6127-Reverse-Engineering
My attempt at reverse engineering the Govee H6127 RGB lighting strips BLE commands.

------
# A Message to Govee

>In the U.S., Section 103(f) of the Digital Millennium Copyright Act (DMCA) [(17 USC § 1201 (f) - Reverse Engineering)](https://www.law.cornell.edu/uscode/text/17/1201) specifically states that it is legal to reverse engineer and circumvent the protection to achieve interoperability between computer programs (such as information transfer between applications). Interoperability is defined in paragraph 4 of Section 103(f).
>
>It is also often lawful to reverse-engineer an artifact or process as long as it is obtained legitimately. If the software is patented, it doesn't necessarily need to be reverse-engineered, as patents require a public disclosure of invention. It should be mentioned that, just because a piece of software is patented, that does not mean the entire thing is patented; there may be parts that remain undisclosed.


Govee I love your product, and I mean no harm in releasing this information. I only did this as a side project so I can control the lighting strips from my own app that runs in my car. I decided to publish my findings and protocol reverse engineering so that anyone else who is looking to do the same might have a place to start. Long story short, __please don't sue me, or DMCA this repo__. If you wish for me to take it down, __please email me or leave a issue on this repo stating that you would like it to be removed, and I will happily do so__.

With all that out of the way, on to the documentation!

# My Findings

I have only tested this on the Govee H6127 so I am unsure if these packets or UUID's work for anything else.
Log is found by enabling developer options bluetooth_hci snoop log `adb bugreport anewbugreport && unzip anewbugreport.zip && wireshark FS/data/log/bt/btsnoop_hci.log`
To filter the ATT packets, 
### Checklist of packets
- [x] Keep alive
- [x] Change Color
- [x] Change Color of each of 15 segments
- [x] Gradient
- [x] Set global brightness
- [x] Change to music mode
- [x] Change music mode to cycle colors
- [X] Change Scenes(update)
- [x] DIY Mode

### How packets work
From my understanding, all packets are 20 bytes long. 
The first byte is a identifier, followed by 18 bytes of data, followed by an XOR of ALL the bytes.
0x33 seems to be a command indicator (the only alternatives value for the first byte is 0xaa, 0xa1)
    
    0x33: Indicator
    0xaa: keep alive
    0xa1: DIY VALUES

The second byte seems identify the packet type

    0x01: Power
    0x04: Brightness
    0x05: Color

The third byte differs based on type.

    For power packets, it's a boolean indicating the power state. (0x00, or 0x01)
    For brightness packets, it corresponds to a uint8 brightness value, affecting lights at about 0x14 to 1% - 0xfe to 100%
    For color packets, this indicates an operation mode.
    
    0x33: Indicator
        0x01: Power
            0x00: Off
            0x01: On
        0x04: Brightness
            0x00: 0% (also Off)
            0x14: 1%
            0xfe: 100%
        0x05: Color
            0x02: Manual
            0x01: Music
            0x04: Scene
            0x0a: DIY


Color packets also carry an RGB value, followed by a boolean and a second RGB value. The boolean seems to switch the set of LEDs used within the bulb. 

```
Have not verified this in the H6127 but the condition appears to exist. (from h6113)
There is one set for RGB values and one for warm/cold-white values, where True corresponds to the warm/cold-white LEDs. When the flag is set, the first RGB value seems to be ignored and vice-versa. The values for warm/cold-white LEDs cannot be set arbitrarily. The slider within the app UI uses a list of hardcoded color codes. (thanks Henje!)
````

Zeropadding follows. unless colors can be changed within mode.
Finally, a checksum over the payload is calculated by XORing all bytes.
     
     0x33: Indicator
        0x01: power
            0x00: Off
            0x01: On
        0x04: brightness
            0x00: 0% (also Off)
            0x14: 1%
            0xfe: 100%
        0x14: gradient
            0x01: On
            0x00: Off
        0x05: color
            0x02: Manual
                0x000000: red, green, blue
                0xffffff: red, green, blue
            0x01: Music
                0x00: Energic
                0x01: Spectrum(colors)
                    0x000000: red, green, blue
                    0xffffff: red, green, blue
                0x02: Rolling(colors)
                    0x000000: red, green, blue
                    0xffffff: red, green, blue
                0x03: Rhythm
            0x04: Scene
                0x00: Sunrise
                0x01: Sunset
                0x04: Movie
                0x05: Dating
                0x07: Romantic
                0x08: Twinkle (Formerly Blinking)
                0x09: Candlelight
                0x0f: Snowflake
                0x10: Energetic
                0x0a: Breathe
                0x14: Crossing
                0x15: Rainbow
            0x0a: DIY
            0x0b: Segments
                0x00:Left Half(1,2,3,4,5,6,7,8)
                     0x00:Right Half (9,10,11,12,13,15)


```
IDENTIFIER, PACKETTYPE, MODE/DATA, MODEID, MODEDATA/DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, DATA, XOR

```

| Type           | Unformatted UUID                 | Formatted UUID                       |
|----------------|----------------------------------|--------------------------------------|
| Service        | 000102030405060708090a0b0c0d1910 | 00010203-0405-0607-0809-0a0b0c0d1910 |
| Characteristic | 000102030405060708090a0b0c0d2b11 | 00010203-0405-0607-0809-0a0b0c0d2b11 |




### Keep Alive
It is always this, it never seems to change. This is sent every 2 seconds from the mobile app to the device.
```
0xAA, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAB
aa010000000000000000000000000000000000ab
```
### On/Off
```
0x33, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x33
3301010000000000000000000000000000000033 = on

0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x32
3301000000000000000000000000000000000032 = off

#Also setting brightness to 0% seems to turn it off, however the app doesn't even realise this and it can screw it up (if you turn lights on via brightness, app still thinks lights are off, and vice versa)
0x33, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x37
330400000000000000000000000000000000037
```

### Set Color
RED, GREEN, BLUE range is 0 - 255 or 0x00 - 0xFF
```
0x33, 0x05, 0x02, RED, GREEN, BLUE, 0x00, 0xFF, 0xAE, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, XOR)

#not sure what the middles section is for,(ffae54) but it is included in the XOR and is not always required. Above mentions may be for warm white colors etc)

0x33, 0x05, 0x02, RED, GREEN, BLUE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, XOR)
```

### Set Color Gradient On/Off
```
3314010000000000000000000000000000000026 = Gradient On
3314000000000000000000000000000000000027 = Gradient Off
```
### Set Color Segments
The individual 15, segments are distrubuted between left(1-8)(00-ff)and right(9-15)(00-7f, or 80-ff).
To address individual segments see ***Color_Segments_chart.md***.
```
0x33, 0x05, 0x0b, RED, GREEN, BLUE, LEFT, RIGHT, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, XOR)
```

### Set Brightness
BRIGHTNESS range is 0 - 255 or 0x00 - 0xFF
```
0x33, 0x04, BRIGHTNESS, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, (0x33 ^ 0x04 ^ BRIGHTNESS)
```

### Set Music Modes
```
3305010000000000000000000000000000000037 = music Energic
3305010100ff00000000000000000000000000c9 = music spectrum(red)
33050101000000ff0000000000000000000000c9 = music spectrum(blue)
3305010200ff00000000000000000000000000ca = music rolling (red)
33050102000000ff0000000000000000000000ca = music rolling (blue)
3305010300000000000000000000000000000034 = music Rhythm
```

### Set Scene
```
3305040000000000000000000000000000000032 = Scene(Sunrise)
3305040100000000000000000000000000000033 = Scene(Sunset)
3305040400000000000000000000000000000036 = Scene(Movie)
3305040500000000000000000000000000000037 = Scene(Dating)
3305040700000000000000000000000000000035 = Scene(Romantic)
330504080000000000000000000000000000003a = Scene(Blinking)
330504090000000000000000000000000000003b = Scene(Candlelight)
3305040f0000000000000000000000000000003d = Scene(snowflake)```
```
### DIY
DIY mode appears to start with a keep alive followed by a start data packet, followed by 1 to 3 packets of data, followed by an end data packet, followed by the DIY mode command.

#### DIY Mode Data
Start Packet consists of 0xa102, PACKET#(0x00), TOTAL PACKET#'S, PADDING, XOR
````
a102 00 02 000000000000000000000000000000a1 = Start
````
First 2 bytes are a1 and 02 sigaling a write
    
    0xa102: Write Data

Third byte is the Number of the packet from 00-ff
    
    0x00: Start
    0x01: Number of packet
    0x02: Number of packet
    0x03: Number of packet
    0xff: End

Fourth byte is the name of the DIY in the App

    3b: Name

Fifth and Sixth bytes are the Style and the Style Mode

    00:Fade               01:Jumping              02:Flicker             03:Marquee           04:Music           FF:combo
        00:Whole              00:whole                00:Whole               03:Straight          08:Rhythm          00:??
        01: N/A               01:subsection           01:subsection          04:Gathered          06:Spectrum
        02:Circulation        02:circulation          02:Circulation         05:Dispersive        07:Rolling

Seventh byte is the Speed of transitions 00 being no movement, and 64 appearing to be the fastest
    
    00: No movement
    64: Fastest movement

Eighth byte is unknown at this time:

    18: PADDING?
    
Remaining bytes are the Colors limited to 8 colors total between (2 packets) 
    
    0xFFFFFF: Red, Green, Blue
    0xFFFFFF: Red, Green, Blue
    0xFFFFXX: Red, Green, XOR

Last byte is the XOR as shown above:

    XX: XOR

```
0xa102, PACKET#, NAME, STYLE, MODE, SPEED, ??, RED, GREEN, BLUE, RED, GREEN, BLUE, RED, GREEN, BLUE, RED, GREEN, XOR
a102 01 0a 03 03 2b 18 ff0000 ff7f00 ffff00 00ff 1b
```

****The Second packet is mostly only color data and is only necessary if there are more than 2 colors in the DIY:****

First 2 bytes of 2nd Packet a102

    0xa102: Write Data
    
Third bytes of 2nd Packet is the packet number

    0x02: Packet number

Fourth byte of 2nd Packet is the Blue color data of the previous packet (if more than 2 colors)

    0xFF: Blue

Remaining packets are color packets, adding and XOR

    0xFFFFFF: Red, Green, Blue
    0xFFFFFF: Red, Green, Blue
    0xFFFFFF: Red, Green, Blue
    0xFFFFFF: Red, Green, Blue
    0x000000XX: Padding and XOR

```
0xa102, PACKET#, BLUE, RED, GREEN, BLUE, RED, GREEN, BLUE, RED, GREEN, BLUE, RED, GREEN, BLUE, 0x00, 0x00, 0x00, XOR
a102 02 00 0000ff 00ffff 8b00ff ffffff 000000d5 = Data
```

****Third Packet Appears to be for Combo Style and Style mode data****
    
    a102 03 0100 0200 0303 00000000000000000000a3 

End Packet appears to be 0xa102, 0xff, Padding, XOR

```
a102 ff 000000000000000000000000000000005c = End
```

#### DIY Mode command
```
33050a000000000000000000000000000000003c
```

### Full Stream
```
aa010000000000000000000000000000000000ab            = keep alive
a1020003000000000000000000000000000000a0            = Start Data
a102 01 3b ff 00 62 18 ffffff ff0000 ffffff ff001c  = Data
a102 02 00 ffffff ff0000 ffffff ff0000 080000a9     = Data
a102 03 0100 0200 0303 00000000000000000000a3       = Data
a102 ff 000000000000000000000000000000005c          = End Data
33050a000000000000000000000000000000003c            = DIY Command

``` 

gatttool -i hci0 -b (mac) --char-write-req -a 0x0015 -n (command)



### Phil notes
```
keep alive:
gatttool -i hci0 -b A4:C1:38:9C:70:21 --char-write-req -a 0x0015 -n aa010000000000000000000000000000000000ab --listen
will return "aa 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 aa" if  on, and "aa 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ab" if off

on
gatttool -i hci0 -b A4:C1:38:9C:70:21 --char-write-req -a 0x0015 -n 3301010000000000000000000000000000000033 -t public

off
gatttool -i hci0 -b A4:C1:38:9C:70:21 --char-write-req -a 0x0015 -n 3301000000000000000000000000000000000032 -t public

``` 

## Reading current values (seems to be broadcast by Govee device when you initially connect to it, WIP:
There has to be a way to read current status. So far I've discovered this.
For brightness, it's aa04......... etc. :
```
On notification handle (0x0011):
aa04fe0000000000000000000000000000000050 seems to mean that brightness is 100%
aa041400000000000000000000000000000000ba seems to mean that brightness is 1%

It seems like those values are spat out by the bluetooth controller if you write this to the same handle as usual 0x0015:
aa040000000000000000000000000000000000ae
```
For colour, it's aa05......... etc:
```
On notification handle (0x0011):
aa050dff0000000000000000000000000000005d seems to mean that colour is 100% red (I have not tested other colours at this time)
We should be able to assume then that aa05 means colour, 0d = ?? (colour state??) and FF, 00 ,00 is the current colour)

It seems like those values are spat out by the bluetooth controller if you write this to the same handle as usual 0x0015:
aa050100000000000000000000000000000000ae
```

Thank you to egold555,Freemanium, and ddxtanx for the initial findings.
