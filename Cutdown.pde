// -------------------------------------------------------------------------------------------------
// Cutdown - High-altitude balloon launch stack cutdown via nichrome wire; audible tracer beacon
// A project of HackPittsburgh (http://www.hackpittsburgh.org)
//
// Copyright (c) 2010 Jonathan Speicher (jon.speicher@hackpittsburgh.org)
// Licensed under the MIT license: http://creativecommons.org/licenses/MIT
// -------------------------------------------------------------------------------------------------

#include <NewSoftSerial.h>
#include <TinyGPS.h>

// Set the serial pins and baud rate here.  The NewSoftSerial library is used for reliablility and
// therefore the GPS module must be connected to Arduino pins other than RX and TX.

#define GPS_RX_PIN    3
#define GPS_TX_PIN    2
#define GPS_BAUD_RATE 4800

// Set the cutdown parameters here.  You must define the pin to which the nichrome wire is attached,
// the amount of time that the cutdown wire will be active when a cutdown event is triggered, the
// altitude at which to trigger the cutdown event, and the cutdown target count threshold.  We need
// to see the altitude be above the cutdown altitude for this many times in a row before we trigger
// the cutdown.

#define CUTDOWN_PIN                    4
#define CUTDOWN_WIRE_ACTIVE_TIME_MS    3000
#define CUTDOWN_TARGET_ALTITUDE        98000.0
#define CUTDOWN_TARGET_COUNT_THRESHOLD 3

// Set the beep pin, beep interval here, and beep on time here.  The beep pin should be connected to
// a piezo or other such noisemaker.  It will be turned on at the specified interval, and will
// remain on for the specified on time.

#define BEEP_PIN 5
#define BEEP_INTERVAL_MS 20000
#define BEEP_ON_TIME_MS  3000

// Global variables --------------------------------------------------------------------------------

TinyGPS gpsDecoder;
NewSoftSerial gpsSerial(GPS_RX_PIN, GPS_TX_PIN);

unsigned int cutdownTargetAltitudeCount = 0;
boolean cutdownComplete = false;

unsigned long beepStartMillis = 0;
boolean beeping = false;

// Setup and loop ----------------------------------------------------------------------------------

void setup()
{
  // Configure the pins and start up the serial communication with the GPS.
    
  pinMode(CUTDOWN_PIN, OUTPUT);
  pinMode(BEEP_PIN, OUTPUT);
  gpsSerial.begin(GPS_BAUD_RATE);
}

void loop()
{ 
  // If serial data from the GPS is available, handle it.
  
  while (gpsSerial.available())
  {
    int ch = gpsSerial.read();
    
    if (gpsDecoder.encode(ch))
    {
      float latitude, longitude, altitude;
      unsigned long fixAge;
      
      // Grab the position and the altitude.  We don't much care about the position but we get a
      // convenient indication of the GPS decoder's last good "fix" along with it.
      
      gpsDecoder.f_get_position(&latitude, &longitude, &fixAge);
      altitude = gpsDecoder.f_altitude();
      
      // If we're above the target altitude and we've seen at least one good "fix" from the GPS, 
      // bump the cutdown altitude target counter.  Otherwise start over.
      
      if ((altitude >= CUTDOWN_TARGET_ALTITUDE) && (fixAge != TinyGPS::GPS_INVALID_AGE))
      {
        cutdownTargetAltitudeCount++;
      }
      else
      {
        cutdownTargetAltitudeCount = 0;
      }
      
      // If we've counted enough target altitude events and haven't already cut down, cut down.
      // Remember that the cutdown has occurred.
      
      if ((!cutdownComplete) && (cutdownTargetAltitudeCount >= CUTDOWN_TARGET_COUNT_THRESHOLD))
      {
        cutdown();
        cutdownComplete = true;
      }
    }
  }
  
  // If we're not beeping and it's time to start, start.  Remember the time we started beeping for
  // later use.  If we're beeping and it's time to stop, stop.  
  
  if ((!beeping) && ((millis() - beepStartMillis) > BEEP_INTERVAL_MS))
  {
    digitalWrite(BEEP_PIN, HIGH);
    beepStartMillis = millis();
    beeping = true;
  }
  else if ((beeping) && ((millis() - beepStartMillis) > BEEP_ON_TIME_MS))
  {
    digitalWrite(BEEP_PIN, LOW);
    beeping = false;
  }
  
  
}

// Helper functions --------------------------------------------------------------------------------

void cutdown()
{
  digitalWrite(CUTDOWN_PIN, HIGH);
  delay(CUTDOWN_WIRE_ACTIVE_TIME_MS);
  digitalWrite(CUTDOWN_PIN, LOW);
}
