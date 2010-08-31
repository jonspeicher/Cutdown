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
#define CUTDOWN_PIN       12  // The nichrome wire relay is connected to this active high pin.
#define BEACON_LED_PIN    10  // The beacon LED is connected to this active high pin.
#define BEACON_PIEZO_PIN  11  // The beacon piezo buzzer is connected to this active high pin.

// Define some parameters specific to the GPS module and to GPS tracking.

#define GPS_BAUD_RATE         4800  // The baud rate at which the GPS module sends data.
#define GPS_FIX_AGE_LIMIT_MS  5000  // The time limit beyond which we will discard GPS fix data.

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
unsigned long gpsLastGoodLockMillis = 0;

unsigned int cutdownTargetAltitudeCount = 0;
boolean cutdownComplete = false;

boolean beaconActive = false;
unsigned long beaconStartMillis = 0;

// Setup and loop ----------------------------------------------------------------------------------

void setup()
{
  // Configure the pins and start up the serial communication with the GPS.

  gpsSerial.begin(GPS_BAUD_RATE);
  pinMode(GPS_LOCK_LED_PIN, OUTPUT);
  
  pinMode(CUTDOWN_PIN, OUTPUT);
  
  pinMode(BEACON_PIEZO_PIN, OUTPUT);
  pinMode(BEACON_LED_PIN, OUTPUT);
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
        gpsLastGoodLockMillis = millis();
        
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
    }
  }

  // Ensure that the GPS lock indicator is in the proper state.
  
  handleGpsLockIndicator();
  
  // Handle a cutdown event if it's time.
  
  handleCutdown();
  
  // Mmm, beacon.

  handleBeacon();
}

// GPS helper functions ----------------------------------------------------------------------------

void handleGpsLockIndicator()
{
  // If we haven't seen a good GPS lock within the proper time, turn the indicator off.  Otherwise,
  // make sure it's on.
  
  if ((millis() - gpsLastGoodLockMillis) >= GPS_FIX_AGE_LIMIT_MS)
  {
    digitalWrite(GPS_LOCK_LED_PIN, LOW);
  }
  else
  {
    digitalWrite(GPS_LOCK_LED_PIN, HIGH);
  }
}

// Cutdown helper functions ------------------------------------------------------------------------

void handleCutdown()
{
  // If we've counted enough target altitude events and haven't already cut down, cut down.
  // Remember that the cutdown has occurred.

  if ((!cutdownComplete) && (cutdownTargetAltitudeCount >= CUTDOWN_TARGET_COUNT_THRESHOLD))
  {
    cutdown();
    cutdownComplete = true;
  }
}

void cutdown()
{
  digitalWrite(CUTDOWN_PIN, HIGH);
  delay(CUTDOWN_WIRE_ACTIVE_TIME_MS);
  digitalWrite(CUTDOWN_PIN, LOW);
}

// Beacon helper functions -------------------------------------------------------------------------

void handleBeacon()
{
  // If the beacon is off and it's time to turn it on, turn it on.  Remember the time we started the
  // beacon for later use.  If the beacon is on and it's time to turn it off, turn it off.
  
  if ((!beaconActive) && ((millis() - beaconStartMillis) >= BEACON_INTERVAL_MS))
  {
    beaconOn();
    beaconStartMillis = millis();
  }
  else if ((beaconActive) && ((millis() - beaconStartMillis) >= BEACON_ON_TIME_MS))
  {
    beaconOff();
  }
}

void beaconOn()
{
  digitalWrite(BEACON_PIEZO_PIN, HIGH);
  digitalWrite(BEACON_LED_PIN, HIGH);
  beaconActive = true;
}

void beaconOff()
{
  digitalWrite(BEACON_PIEZO_PIN, LOW);
  digitalWrite(BEACON_LED_PIN, LOW);
  beaconActive = false;
}