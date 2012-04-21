#ifndef LIGHTSENSOR_H
#define LIGHTSENSOR_H

typedef nx_struct LightSensorMsg {
	nx_uint16_t nodeid;
	nx_bool red;
	nx_bool green;
	nx_bool blue;
} LightSensorMsg;

enum {
  AM_LIGHTSENSORMSG = 6,
};

#endif