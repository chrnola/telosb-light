#include <Timer.h>
#include "LightSensor.h"

configuration LightSensorRedAppC {
}

implementation {
	components LightSensorRedC as App;
	components MainC;
	components LedsC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new HamamatsuS10871TsrC() as Sensor;
	components ActiveMessageC as AM;
	components new AMSenderC(AM_LIGHTSENSORMSG) as AMS;
	components new AMReceiverC(AM_LIGHTSENSORMSG) as AMR;
	components SerialActiveMessageC as SAM;
	components new SerialAMSenderC(AM_LIGHTSENSORMSG) as SAMS;
	
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	App.Read -> Sensor;
	App.Packet -> AM;
	App.AMPacket -> AMS;
	App.AMSend -> AMS;
	App.AMControl -> AM;
	App.Receive -> AMR;
	App.SPacket -> SAM;
	App.SAMPacket -> SAMS;
	App.SAMSend -> SAMS;
	App.SAMControl -> SAM;
}
