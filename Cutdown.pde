// -------------------------------------------------------------------------------------------------
// Cutdown - High-altitude balloon launch stack cutdown via nichrome wire plus tracer beacons
// A project of HackPittsburgh (http://www.hackpittsburgh.org)
//
// Copyright (c) 2010 Jonathan Speicher (jon.speicher@hackpittsburgh.org)
// Licensed under the MIT license: http://creativecommons.org/licenses/MIT
// -------------------------------------------------------------------------------------------------

#include <NewSoftSerial.h>
#include <TinyGPS.h>

// Define the I/O pins used by this sketch.  These are kept in one place to make it easy to ensure
// that there is no duplication.

#define GPS_RX_PIN        3   // The GPS receiver's TTL level output is connected to this pin.
#define GPS_TX_PIN        2   // NewSoftSerial requires a TX pin; set this to something unused!
#define GPS_LOCK_LED_PIN  8   // The GPS lock indicator LED is connected to this active high pin.
#define BEACON_LED_PIN    10  // The beacon LED is connected to this active high pin.
#define BEACON_PIEZO_PIN  11  // The beacon piezo buzzer is connected to this active high pin.
#define CUTDOWN_PIN       12  // The nichrome wire relay is connected to this active high pin.

// Define some parameters specific to the GPS module and to GPS tracking.

#define GPS_BAUD_RATE         4800  // The baud rate at which the GPS module sends data.
#define GPS_FIX_AGE_LIMIT_MS  5000  // The time limit beyond which we will discard GPS fix data.
#define GPS_LOCK_LED_LIMIT_MS 2000  // THe time limit beyond which we will turn off the lock LED.

// Define some parameters specific to the cutdown functionality.  Experiments at room temperature on
// the ground indicate less than 1 second of cutdown activation time is needed.  Given the ambient
// temperature and potential for ice at altitude, we're hoping that these parameters are enough to 
// work but not so long as to potentially melt or otherwise damage the chute.

#define CUTDOWN_WIRE_ACTIVE_TIME_MS    5000     // The amount of time to keep the cutdown wire on.
#define CUTDOWN_TARGET_ALTITUDE_METERS 29870.4  // This is 98,000 feet.
#define CUTDOWN_TARGET_COUNT_THRESHOLD 3        // The count of samples at target before cutdown.

// Define some parameters specific to the beacon functionality.

#define BEACON_INTERVAL_MS 4000  // The time between the start of one beacon and the next.
#define BEACON_ON_TIME_MS  2000  // The duration of the beacon.  Make this less than the interval!

// Global variables --------------------------------------------------------------------------------

TinyGPS gpsDecoder;
NewSoftSerial gpsSerial(GPS_RX_PIN, GPS_TX_PIN);

unsigned int cutdownTargetAltitudeCount = 0;
boolean cutdownComplete = false;

unsigned long lastGoodGPSLockMillis = 0;
unsigned long beepStartMillis = 0;
boolean beeping = false;

boolean gpsLockPinHigh = false;

// Setup and loop ----------------------------------------------------------------------------------

void setup()
{
  // Configure the pins and start up the serial communication with the GPS.

  pinMode(GPS_LOCK_LED_PIN, OUTPUT);
  pinMode(CUTDOWN_PIN, OUTPUT);
  pinMode(BEACON_PIEZO_PIN, OUTPUT);
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
      float latitude, longitude, altitudeMeters;
      unsigned long fixAge;

      // Grab the position and the altitude.  We don't much care about the position but we get a
      // convenient indication of the GPS decoder's last good "fix" along with it.

      gpsDecoder.f_get_position(&latitude, &longitude, &fixAge);
      altitudeMeters = gpsDecoder.f_altitude();

      // Did we get a good and locked reading from the GPS that's not too stale.
      if ((fixAge != TinyGPS::GPS_INVALID_AGE) && (fixAge < GPS_FIX_AGE_LIMIT_MS))
      {
        lastGoodGPSLockMillis = millis();
        if (!gpsLockPinHigh)
        {
          digitalWrite(GPS_LOCK_LED_PIN, HIGH);
          gpsLockPinHigh = true;
        }
        
        if (altitudeMeters > CUTDOWN_TARGET_ALTITUDE_METERS)
        {
          cutdownTargetAltitudeCount++;
        }
        else
        {
          cutdownTargetAltitudeCount = 0;
        }
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

  if ((!beeping) && ((millis() - beepStartMillis) > BEACON_INTERVAL_MS))
  {
    digitalWrite(BEACON_PIEZO_PIN, HIGH);
    digitalWrite(BEACON_LED_PIN, HIGH);
    beepStartMillis = millis();
    beeping = true;
  }
  else if ((beeping) && ((millis() - beepStartMillis) > BEACON_ON_TIME_MS))
  {
    digitalWrite(BEACON_LED_PIN, LOW);
    digitalWrite(BEACON_PIEZO_PIN, LOW);
    beeping = false;
  }
  
  if (gpsLockPinHigh && ((millis() - lastGoodGPSLockMillis) > GPS_LOCK_LED_LIMIT_MS))
  {
    digitalWrite(GPS_LOCK_LED_PIN, LOW);
    gpsLockPinHigh = false;
  }
  


}

// Helper functions --------------------------------------------------------------------------------

void cutdown()
{
  digitalWrite(CUTDOWN_PIN, HIGH);
  delay(CUTDOWN_WIRE_ACTIVE_TIME_MS);
  digitalWrite(CUTDOWN_PIN, LOW);
}
