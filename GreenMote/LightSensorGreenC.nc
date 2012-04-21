#include <Timer.h>
#include "LightSensor.h"

module LightSensorGreenC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Read<uint16_t>;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
}

implementation {
	#define SAMPLE_RATE 2048
	#define BLUE_RATE 512
	#define DARK_THRESH 40
	
	bool busy = FALSE;
	message_t pkt;
	
	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
  	  		call Timer0.startPeriodic(SAMPLE_RATE);
  	  		call Timer1.startPeriodic(BLUE_RATE);
  		} else {
  	  		call AMControl.start();
  		}
	}
	
	event void Timer0.fired() {
		call Read.read();
	}
	
	event void Timer1.fired() {
		if((call Leds.get() & LEDS_LED0) && (call Leds.get() & LEDS_LED1)) {
			call Leds.led2On();
		} else {
			call Leds.led2Off();
		}
	}
	
	event void Read.readDone(error_t result, uint16_t data) {
		if(result == SUCCESS) {
			if(data > DARK_THRESH) {
				if(!(call Leds.get() & LEDS_LED1)) {
					if(!busy) {
  	  					LightSensorMsg* lspkt = (LightSensorMsg*) (call Packet.getPayload(&pkt, sizeof(LightSensorMsg)));
  	  					lspkt->nodeid = TOS_NODE_ID;
  	  					lspkt->green = TRUE;
  	  					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						busy = TRUE;
  	  					}
  					}
				}
				call Leds.led1On();
			} else {
				if(call Leds.get() & LEDS_LED1) {
					if(!busy) {
  	  					LightSensorMsg* lspkt = (LightSensorMsg*) (call Packet.getPayload(&pkt, sizeof(LightSensorMsg)));
  	  					lspkt->nodeid = TOS_NODE_ID;
  	  					lspkt->green = FALSE;
  	  					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						busy = TRUE;
  	  					}
  					}
				}
				call Leds.led1Off();
			}
		}
	}
	
	event void AMControl.stopDone(error_t err) {
  	}
  
  	event void AMSend.sendDone(message_t* msg, error_t error) {
  		if(&pkt == msg) {
  	  		busy = FALSE;
  		}
  	}
  
  	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    	if (len == sizeof(LightSensorMsg)) {
      		LightSensorMsg* lspkt = (LightSensorMsg*)payload;
      		if(lspkt->red) {
      			call Leds.led0On();
      		} else {
      			call Leds.led0Off();
      		}
    	}
  		return msg;
  	}
}
