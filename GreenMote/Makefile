COMPONENT=LightSensorGreenAppC
BUILD_EXTRA_DEPS=LightSensorMsg.class

LightSensorMsg.class: LightSensorMsg.java
	javac LightSensorMsg.java
	
LightSensorMsg.java:
	mig java -target=null -java-classname=LightSensorMsg LightSensor.h LightSensorMsg -o $@
include $(MAKERULES)
