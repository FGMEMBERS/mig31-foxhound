
#
# Mig31 Foxhound 
#
# Nasal scripts
# Charles INGELS <charles@maisonblv.net>
# The 17th of July, 2009
# See http://charles.ingels.free.fr/flightgear/mig31-foxhound
#

# -----------------------------------------------------------------------------
# - Reheat management.                                                        -
# -----------------------------------------------------------------------------
#
# If throttle is greater that 0.9, then set reheat on, otherwise set reheat off.
# Here is a reminder on Mig31 engine specification:
# Engine thrust : 9547 lbs/engine
# Afterburner   : 15500 lbs/engine
#

#
# On crèe les propriétés "reheat" sinon le code suivant renverra une erreur de
# type "Nasal runtime error: non-objects have no members" !
#
# setprop("/controls/engines/engine[0]/reheat", "0");
# setprop("/controls/engines/engine[1]/reheat", "0");


var Mig31throttle0 = props.globals.getNode("/controls/engines/engine[0]/throttle");
var Mig31throttle1 = props.globals.getNode("/controls/engines/engine[1]/throttle");
var Mig31reheat0 = props.globals.getNode("/controls/engines/engine[0]/reheat");
var Mig31reheat1 = props.globals.getNode("/controls/engines/engine[1]/reheat");

var MPthrottle0 = props.globals.getNode("/sim/multiplay/generic/float[0]");
var MPthrottle1 = props.globals.getNode("/sim/multiplay/generic/float[1]");
var MPreheat0 = props.globals.getNode("/sim/multiplay/generic/float[2]");
var MPreheat1 = props.globals.getNode("/sim/multiplay/generic/float[3]");


var ManageThrottle0 = func 
{
	if(Mig31throttle0.getValue() >= 0.90) 
	{
		Mig31reheat0.setValue(1);
	}
	else 
	{
		Mig31reheat0.setValue(0);
	}
	# Pass throttle value over MP.
	MPthrottle0.setValue(Mig31throttle0.getValue());
}

var ManageThrottle1 = func 
{
	if(Mig31throttle1.getValue() >= 0.90) 
	{
		Mig31reheat1.setValue(1);
	}
	else 
	{
		Mig31reheat1.setValue(0);
	}
	# Pass throttle value over MP.
	MPthrottle1.setValue(Mig31throttle1.getValue());
}

setlistener("/controls/engines/engine[0]/throttle", ManageThrottle0, 1);
setlistener(Mig31throttle1, ManageThrottle1, 1);


#
# Pass reheat values over MP when a change triggers.
#
setlistener(Mig31reheat0, func {
	MPreheat0.setValue(Mig31reheat0.getValue());
});

setlistener(Mig31reheat1, func {
	MPreheat1.setValue(Mig31reheat1.getValue());
});


#
# Gestion des vibrations si la vitesse dépasse mach 2.86
#
var coef = 1;
var vibration_level = func
{
	var mach = getprop("/velocities/mach");
	if(mach >= 2.95)
	{
		var aleat = 0.55 * rand();
		var offset = coef * (mach - 2.95) * aleat;
		setprop("/controls/flight/elevator-trim", offset);
		coef = -coef;
	}
	settimer(vibration_level, 0.080);
}

settimer(vibration_level, 0.125);

#
# Gestion des lumières.
#
var strobe = aircraft.light.new("/sim/model/lights/strobe1", [0.10, 0.85]);
strobe.interval = 0;
strobe.switch(1);


#
# End of file.
#

