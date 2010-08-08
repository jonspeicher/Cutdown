// -------------------------------------------------------------------------------------------------
// Cutdown - High-altitude balloon launch stack cutdown via nichrome wire; audible tracer beacon
// A project of HackPittsburgh (http://www.hackpittsburgh.org)
//
// Copyright (c) 2010 Jonathan Speicher (jon.speicher@hackpittsburgh.org)
// Licensed under the MIT license: http://creativecommons.org/licenses/MIT
// -------------------------------------------------------------------------------------------------

#include <NewSoftSerial.h>
#include <TinyGPS.h>


// Pin definitions - all in one place to make it easy to visually verify they're all different.
#define GPS_TX_PIN     2  // We aren't using it, but the NewSoftSerial library needs something.
#define GPS_RX_PIN     3  // The GPS TTL level output comes in.
#define GPS_LOCK_PIN   8  // High when we get good data from the GPS and have a GPS lock.
#define BEACON_PIN    10  // LED beacon.
#define BEEP_PIN      11  // The piezo buzzer.
#define CUTDOWN_PIN   12  // The Nichrome cut-down wire relay.

#define GPS_BAUD_RATE 4800
#define FIX_AGE_LIMIT_MS 5000 // GPS Lock data must be at least this fresh for us to use it.
#define GPS_LOCK_INDICATOR_LIMIT 2000 // Turn off the GPS_LOCK_PIN if last lock older than this.

// This is a complete guess. Experiments at room temperature on the ground indicate less
// than 1000ms is needed. Given the ambient temperature and potential for ice, we're hoping
// that this is long enough to work but not so long as to potentially melt/damage the chute.
#define CUTDOWN_WIRE_ACTIVE_TIME_MS    5000
#define CUTDOWN_TARGET_ALTITUDE_METERS 29870.4

// Number of consecutive good readings above the target altitude before triggering the CUTDOWN_PIN
#define CUTDOWN_TARGET_COUNT_THRESHOLD 3


#define BEEP_INTERVAL_MS 4000 // Time between the start of one beep and the start of the next.
#define BEEP_ON_TIME_MS  2000 // Duration of the beep. Must be less than the interval time.

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

  pinMode(GPS_LOCK_PIN, OUTPUT);
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
      float latitude, longitude, altitudeMeters;
      unsigned long fixAge;

      // Grab the position and the altitude.  We don't much care about the position but we get a
      // convenient indication of the GPS decoder's last good "fix" along with it.

      gpsDecoder.f_get_position(&latitude, &longitude, &fixAge);
      altitudeMeters = gpsDecoder.f_altitude();

      // Did we get a good and locked reading from the GPS that's not too stale.
      if ((fixAge != TinyGPS::GPS_INVALID_AGE) && (fixAge < FIX_AGE_LIMIT_MS))
      {
        lastGoodGPSLockMillis = millis();
        if (!gpsLockPinHigh)
        {
          digitalWrite(GPS_LOCK_PIN, HIGH);
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

  if ((!beeping) && ((millis() - beepStartMillis) > BEEP_INTERVAL_MS))
  {
    digitalWrite(BEEP_PIN, HIGH);
    digitalWrite(BEACON_PIN, HIGH);
    beepStartMillis = millis();
    beeping = true;
  }
  else if ((beeping) && ((millis() - beepStartMillis) > BEEP_ON_TIME_MS))
  {
    digitalWrite(BEEP_PIN, LOW);
    digitalWrite(BEACON_PIN, LOW);
    beeping = false;
  }
  
  if (gpsLockPinHigh && ((millis() - lastGoodGPSLockMillis) > GPS_LOCK_INDICATOR_LIMIT))
  {
    digitalWrite(GPS_LOCK_PIN, LOW);
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

