#include <Timer.h>
#include "LightSensor.h"

module LightSensorRedC {
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
	uses interface Packet as SPacket;
	uses interface AMPacket as SAMPacket;
	uses interface AMSend as SAMSend;
	uses interface SplitControl as SAMControl;
}

implementation {
	#define SAMPLE_RATE 1024
	#define BLUE_RATE 512
	#define DARK_THRESH 40
	
	bool busy = FALSE;
	bool ser_busy = FALSE;
	message_t pkt;
	message_t ser_pkt;
	
	event void Boot.booted() {
		call AMControl.start();
		call SAMControl.start();
	}
	
	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
  	  		call Timer0.startPeriodic(SAMPLE_RATE);
  	  		call Timer1.startPeriodic(BLUE_RATE);
  		} else {
  	  		call AMControl.start();
  		}
	}
	
	event void SAMControl.startDone(error_t err) {
  	}
	
	event void Timer0.fired() {
		call Read.read();
	}
	
	event void Timer1.fired() {
		if((call Leds.get() & LEDS_LED0) && (call Leds.get() & LEDS_LED1)) {
			if(!(call Leds.get() & LEDS_LED2)) {
				if(!ser_busy) {
  	  				LightSensorMsg* ser_lspkt = (LightSensorMsg*) (call SPacket.getPayload(&ser_pkt, sizeof(LightSensorMsg)));
  	  				ser_lspkt->nodeid = TOS_NODE_ID;
  	  				ser_lspkt->green = TRUE;
  	  				ser_lspkt->red = TRUE;
  	  				ser_lspkt->blue = TRUE;
  	  				if(call SAMSend.send(AM_BROADCAST_ADDR, &ser_pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  					ser_busy = TRUE;
  	  				}
  				}
			}
			call Leds.led2On();
		} else {
			if(call Leds.get() & LEDS_LED2) {
				if(!ser_busy) {
  	  				LightSensorMsg* ser_lspkt = (LightSensorMsg*) (call SPacket.getPayload(&ser_pkt, sizeof(LightSensorMsg)));
  	  				ser_lspkt->nodeid = TOS_NODE_ID;
  	  				ser_lspkt->green = call Leds.get() & LEDS_LED1;
  	  				ser_lspkt->red = call Leds.get() & LEDS_LED0;
  	  				ser_lspkt->blue = FALSE;
  	  				if(call SAMSend.send(AM_BROADCAST_ADDR, &ser_pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  					ser_busy = TRUE;
  	  				}
  				}
			}
			call Leds.led2Off();
		}
	}
	
	event void Read.readDone(error_t result, uint16_t data) {
		if(result == SUCCESS) {
			if(data > DARK_THRESH) {
				if(!(call Leds.get() & LEDS_LED0)) {
					if(!busy) {
  	  					LightSensorMsg* lspkt = (LightSensorMsg*) (call Packet.getPayload(&pkt, sizeof(LightSensorMsg)));
  	  					lspkt->nodeid = TOS_NODE_ID;
  	  					lspkt->red = TRUE;
  	  					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						busy = TRUE;
  	  					}
  					}
  					if(!ser_busy) {
  	  					LightSensorMsg* ser_lspkt = (LightSensorMsg*) (call SPacket.getPayload(&ser_pkt, sizeof(LightSensorMsg)));
  	  					ser_lspkt->nodeid = TOS_NODE_ID;
  	  					ser_lspkt->green = call Leds.get() & LEDS_LED1;
  	  					ser_lspkt->red = TRUE;
  	  					ser_lspkt->blue = call Leds.get() & LEDS_LED2;
  	  					if(call SAMSend.send(AM_BROADCAST_ADDR, &ser_pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						ser_busy = TRUE;
  	  					}
  					}
				}
				call Leds.led0On();
			} else {
				if(call Leds.get() & LEDS_LED0) {
					if(!busy) {
  	  					LightSensorMsg* lspkt = (LightSensorMsg*) (call Packet.getPayload(&pkt, sizeof(LightSensorMsg)));
  	  					lspkt->nodeid = TOS_NODE_ID;
  	  					lspkt->red = FALSE;
  	  					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						busy = TRUE;
  	  					}
  					}
  					if(!ser_busy) {
  	  					LightSensorMsg* ser_lspkt = (LightSensorMsg*) (call SPacket.getPayload(&ser_pkt, sizeof(LightSensorMsg)));
  	  					ser_lspkt->nodeid = TOS_NODE_ID;
  	  					ser_lspkt->green = call Leds.get() & LEDS_LED1;
  	  					ser_lspkt->red = FALSE;
  	  					ser_lspkt->blue = call Leds.get() & LEDS_LED2;
  	  					if(call SAMSend.send(AM_BROADCAST_ADDR, &ser_pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						ser_busy = TRUE;
  	  					}
  					}
				}
				call Leds.led0Off();
			}
		}
	}
	
	event void AMControl.stopDone(error_t err) {
  	}
	
	event void SAMControl.stopDone(error_t err) {
  	}
  
  	event void AMSend.sendDone(message_t* msg, error_t error) {
  		if(&pkt == msg) {
  	  		busy = FALSE;
  		}
  	}
  
	event void SAMSend.sendDone(message_t* msg, error_t error) {
  		if(&ser_pkt == msg) {
  	  		ser_busy = FALSE;
  		}
  	}
  
  	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    	if (len == sizeof(LightSensorMsg)) {
      		LightSensorMsg* lspkt = (LightSensorMsg*)payload;
      		if(lspkt->green) {
      			if(!(call Leds.get() & LEDS_LED1)) {
      				if(!ser_busy) {
  	  					LightSensorMsg* ser_lspkt = (LightSensorMsg*) (call SPacket.getPayload(&ser_pkt, sizeof(LightSensorMsg)));
  	  					ser_lspkt->nodeid = TOS_NODE_ID;
  	  					ser_lspkt->green = TRUE;
  	  					ser_lspkt->red = call Leds.get() & LEDS_LED0;
  	  					ser_lspkt->blue = call Leds.get() & LEDS_LED2;
  	  					if(call SAMSend.send(AM_BROADCAST_ADDR, &ser_pkt, sizeof(LightSensorMsg)) == SUCCESS) {
  	  						ser_busy = TRUE;
  	  					}
  					}
      			}
      			call Leds.led1On();
      		}
    	}
  		return msg;
  	}
}
