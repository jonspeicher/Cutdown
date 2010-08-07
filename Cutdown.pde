// Cutdown 8/6/10
//
// Copyright (c) 2010 Jonathan Speicher (jon.speicher@hackpittsburgh.org)
// http://www.hackpittsburgh.org
//
// Licensed under the MIT license: http://creativecommons.org/licenses/MIT

#include <NewSoftSerial.h>
#include <TinyGPS.h>

// Set the serial pins here.

#define RX_PIN 3
#define TX_PIN 2

// Set the cutdown pin and cutdown on time here.

#define CUTDOWN_PIN 4
#define CUTDOWN_ON_TIME_MS 3000

// Set the cutdown altitude here.

#define CUTDOWN_TARGET_ALTITUDE 98000.0

// Set the cutdown count threshold here.  We need to see the altitude be above the cutdown altitude for this many times
// in a row before we trigger the cutdown.

#define CUTDOWN_TARGET_COUNT_THRESHOLD 3

// Set the beep pin and beep interval here.

#define BEEP_PIN 5
#define BEEP_INTERVAL_MS 20000
#define BEEP_ON_TIME_MS  3000

// Don't touch below this line -----------------------------------------------------------------------------------

TinyGPS gps;
NewSoftSerial serial(RX_PIN, TX_PIN);
unsigned int cutdownTargetAltitudeCount = 0;
boolean cutdownComplete = false;
unsigned long lastBeepMillis = 0;

void setup()
{
  pinMode(CUTDOWN_PIN, OUTPUT);
  pinMode(CUTDOWN_PIN, OUTPUT);
}

void loop()
{ 
  while (serial.available())
  {
    int ch = serial.read();
    
    if (gps.encode(ch))
    {
      float latitude, longitude, altitude;
      unsigned long fixAge;
      
      gps.f_get_position(&latitude, &longitude, &fixAge);
      altitude = gps.f_altitude();
      
      if ((altitude >= CUTDOWN_TARGET_ALTITUDE) && (fixAge != TinyGPS::GPS_INVALID_AGE))
      {
        cutdownTargetAltitudeCount++;
      }
      else
      {
        cutdownTargetAltitudeCount = 0;
      }
      
      if ((cutdownTargetAltitudeCount >= CUTDOWN_TARGET_COUNT_THRESHOLD) && (!cutdownComplete))
      {
        cutdown();
        cutdownComplete = true;
      }
    }
  }
  
  if ((millis() - lastBeepMillis) > BEEP_INTERVAL_MS)
  {
    beep();
    lastBeepMillis = millis();
  }
}

void cutdown()
{
  digitalWrite(CUTDOWN_PIN, HIGH);
  delay(CUTDOWN_ON_TIME_MS);
  digitalWrite(CUTDOWN_PIN, LOW);
}

void beep()
{
  digitalWrite(BEEP_PIN, HIGH);
  delay(BEEP_ON_TIME_MS);
  digitalWrite(BEEP_PIN, LOW);
}
