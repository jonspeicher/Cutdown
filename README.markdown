Cutdown
=======

cutdown is an Arduino-based launch stack cutdown system for HackPittsburgh's high-altitude balloon.

Description
===========

[HackPittsburgh](http://www.hackpittsburgh.org) has launched two high-altitude balloon project.  One
was successful, one was not.  Prior to the second launch I was pressed into service to develop a 
launch stack cutdown system that would switch voltage to a nichrome wire after passing a target
altitude to separate the payload from the balloon.  With not a single bit of hardware in sight, I
hacked together this monstrosity.  Several smart folks pulled a late night to update it with 
new features including a GPS lock freshness guarantee and an audible/visual location beacon.

Although the code did not fly due to power supply issues, I wanted to make sure it had been cleaned 
up and was available in case HackPittsburgh or any other group feels that they can make use of it in 
the future.

Balloon launch photos are available at the [HackPittsburgh Flickr Pool](http://www.flickr.com/groups/hackpgh).  My favorites, plus my ground photos, are in [My Flickr set](http://www.flickr.com/photos/jonspeicher/sets/72157624683638916/).

Minimum Requirements
====================

* Arduino 0018 (http://arduino.cc)
* NewSoftSerial 10c (http://arduiniana.org/libraries/newsoftserial)
* TinyGPS 9 (http://arduiniana.org/libraries/tinygps)

Installation
============

Refer to the installation instructions on the Arduino website to install the development 
environment.  To install the required libraries, assuming you are using a modern Arduino 
environment, simply unzip them to their own directories within:

    [your_sketchbook_directory]/libraries

There should be plenty of online documentation describing this process.

Usage
=====

To use Cutdown in your project, you must ensure that a few preprocessor definitions are accurate, and you must of course wire up the proper circuit.  The best place to see what is required is in the code itself.  If you have any questions, email me.

Tests
=====

Cutdown is *still* completely and utterly untested.  The code compiles, and that's all.  I tried to 
be careful with the coding and design, I read the TinyGPS and NewSoftSerial documentation and 
examined the library code, and I did a code walkthrough with a peer.  Nevertheless, I haven't 
actually *run* this thing, as hardware was unavailable and time was tight.  Although a few
contributors have done some informal testing, I've since been in to potentially wreck things again.  
Caveat emptor.

Improvements
============

The code really wants to be object-oriented.  As it stands functions have side effects and there are 
a handful of mashed-up global variables.  I think if these were broken out into a few small classes 
my ick factor would go down dramatically, but I can't justify the time or effort, especially for
something so small and niche.  Maybe if this ever flies I  will give it the treatment it deserves :)

History
=======

0.1
---

* Initial release (totally untested)

0.2
---

* Fix a bug where cutdown target altitude was specified in feet but TinyGPS returns altitude in
  meters
* Still totally untested :)

0.3
---

* Integrated Doug and Isaac's changes
    * GPS lock LED
    * Visual beacon in addition to audible beacon
    * Updates to cutdown algorithm
    * Actual testing!
* Refactored contributions to:
    * Clean up #defines
    * Remove redundant variables
    * Reduce complexity and modularize code somewhat

Contributors
============

* Jon Speicher ([jon.speicher@hackpittsburgh.org](mailto:jon.speicher@hackpittsburgh.org))
* Doug Philips
* Isaac Gierard

Credits
=======

Cutdown is pretty dumb.  For the most part, it just ties together existing software, and so credit
is due to the author of NewSoftSerial and TinyGPS, [Mikal Hart](http://arduiniana.org).

License
=======

    The MIT License

    Copyright (c) 2010 Jonathan Speicher

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.