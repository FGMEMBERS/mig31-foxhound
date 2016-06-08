# +---------------------------------------------------------------------------+
# | Zaslon SB16 radar                                                         |
# | Radar du Mig 31 "Foxhound"                                                |
# | Charles INGELS, Novembre 2009                                             |
# | http://charles.ingels.free.fr/flightgear/mig31.html                       |
# | Diffusion sous les termes de la licence GPL.                              |
# +---------------------------------------------------------------------------+

var total_mp = 0;
var targets_list = {};

MPjoin = func(n) 
{
  print(n.getValue(), " added");
  setprop("instrumentation/radar",n.getValue(),"radar/y-shift",0);
  setprop("instrumentation/radar",n.getValue(),"radar/x-shift",0);
  setprop("instrumentation/radar",n.getValue(),"radar/rotation",0);
  setprop("instrumentation/radar",n.getValue(),"joined",1);
  setprop("instrumentation/radar",n.getValue(),"callsign","noname");
  setprop("instrumentation/radar",n.getValue(),"radar/x-offset", 0.0);
  setprop("instrumentation/radar",n.getValue(),"radar/y-offset", 0.0);
  setprop("instrumentation/radar",n.getValue(),"radar/h-offset", 0.0);
  setprop("instrumentation/radar",n.getValue(),"radar/v-offset", 0.0);
	props.globals.getNode("instrumentation/radar/" ~ n.getValue() ~ "/radar/in-range", 1).setBoolValue(0);
	props.globals.getNode("instrumentation/radar/" ~ n.getValue() ~ "/radar/in-sight", 1).setBoolValue(0);	
	total_mp = total_mp + 1;
	print("Nombre de connectés: ", total_mp);
}

MPleave= func(n) 
{
	print(n.getValue(), " removed");
	props.globals.getNode("instrumentation/radar/" ~ n.getValue() ~ "/radar/in-range", 0).setBoolValue(0);
	props.globals.getNode("instrumentation/radar/" ~ n.getValue() ~ "/radar/in-sight", 0).setBoolValue(0);

	total_mp = total_mp - 1;
	print("Nombre de connectés: ", total_mp);
  # setprop("instrumentation/radar",n.getValue(),"radar/in-range",0);
	# setprop("instrumentation/radar",n.getValue(),"radar/in-sight",0);
  # setprop("instrumentation/radar",n.getValue(),"joined",0);
}


var SortTargetsList = func(list)
{
	var targets = props.globals.getNode("instrumentation/radar/ai/").getChildren("multiplayer");
}

#
# Copie des propriétés pour éviter d'accéder à des propriétés inexistantes depuis 
# le XML. Dès qu'un avion se connecte, on l'ajoute  dans la  liste des  avions et
# multiplayers pour pouvoir y accéder ensuite.
# Si un connecté se déconnecte, les variables associées sont mises à des  valeurs
# par défaut (en général false) mais les propriétés ne sont pas supprimées. Elles
# sont persistantes.
# 
MPradarProperties = func 
{
	targetList= props.globals.getNode("ai/models/").getChildren("multiplayer");
	# foreach (d; props.globals.getNode("ai/models/").getChildren("aircraft")) 
	# {
	# 	append(targetList,d);
	# }
	
	foreach (m; targetList) 
	{
		var string = "instrumentation/radar/ai/models/"~m.getName()~"["~m.getIndex()~"]/";
		# if (getprop(string,"joined")==1 or m.getName()=="aircraft") 
		if (getprop(string,"joined")==1 or m.getName()=="multiplayer") 
		{
			var target_callsign = m.getNode("callsign").getValue();
			setprop(string,"callsign", target_callsign);
			#
			# Lecture de la distance entre l'avion et la cible (en nautiques).
			#
			var distance_nm = m.getNode("radar/range-nm").getValue();
			#
			# Conversion de la distance en mètres.
			#
			var distance_m = distance_nm * 1852;
			#
			# On teste si la cible est à portée du radar.
			#
			if (distance_nm <= getprop("instrumentation/radar/range-nm"))
			{
				# La cible est dans la portée du radar.
				setprop(string, "radar/in-range", 1);
				#
				# On récupère les valeurs des angles solides entre l'axe de
				# l'avion et la cible.
				#
				var h_offset = m.getNode("radar/h-offset").getValue();
				var v_offset = m.getNode("radar/v-offset").getValue();
				#
				# Par défaut, on considère que la cible n'est pas dans le cône radar avant,
				# donc non visible dans un réticule.
				setprop(string, "radar/in-sight", 0);
				#
				# On traite l'avion s'il est dans le cadran avant -60 < h_offset < 60
				# et -60 < v_offset < 60.
				#
				if ((h_offset > -60 and h_offset < 60) and (v_offset > -60 and v_offset < 60))
				{
					#
					# La cible est dans une pyramide de 60° devant l'avion.
					# Elle peut donc être visible dans un réticule.
					#
					setprop(string, "radar/in-sight", 1);
					#
					# Récupération de la position de la vue sur l'axe X (avant-arrière).
					#
					var view_y = getprop("sim/view[0]/config/z-offset-m"); 
					# var hud_y = 0.327878; # Distance suposée entre la vue et le HUD.
					var hud_y = 0.337;
					var hud_z = 0.355;
					#
					# Calcul de l'écart horizontal.
					#
					var Dx = distance_m * math.sin(h_offset * D2R);
					var Dy = distance_m * math.cos(h_offset * D2R);
					var horz = (hud_y * Dx) / (Dy - view_y);
					#
					# Calcul de l'écart vertical.
					#
					var Dx = distance_m * math.sin(v_offset * D2R);
					var Dy = distance_m * math.cos(v_offset * D2R);
					var vert = (hud_z * Dx) / (Dy - view_y);
					#
					# Traitement du tracking sur la cible spécifiée. On ne fait cette opération que
					# si le tracking de cible est activé (propriété "instrumentation/radar/tracked").
					#
					if (props.globals.getNode("instrumentation/radar/tracked").getBoolValue())
					{
						var tracked_callsign = getprop("instrumentation/radar/tracked-callsign");
						if (streq(tracked_callsign, target_callsign))
						{
							setprop("instrumentation/radar", "tracked-x-offset", -horz);
							setprop("instrumentation/radar", "tracked-y-offset", vert);
							# setprop(string, "radar/in-range", 0);
						}
						else
						{
							setprop(string, "radar/x-offset", -horz);
							setprop(string, "radar/y-offset", vert);
							# setprop(string, "radar/in-range", 1);
						}
					}
					else
					{
						setprop(string, "radar/x-offset", -horz);
						setprop(string, "radar/y-offset", vert);
					}
				}

				#
				# Modification des propriétés.
				#
				var x_factor = getprop("instrumentation/radar/x-range-factor");
				var y_factor = getprop("instrumentation/radar/y-range-factor");
				setprop(string, "radar/distance-m", distance_m);
				setprop(string, "radar/y-shift",m.getNode("radar/y-shift").getValue() * x_factor);
				setprop(string, "radar/x-shift",m.getNode("radar/x-shift").getValue() * y_factor);
				setprop(string, "radar/rotation",m.getNode("radar/rotation").getValue());
				setprop(string, "radar/in-range",m.getNode("radar/in-range").getValue());
				# setprop(string, "radar/h-offset",m.getNode("radar/h-offset").getValue());	
				# setprop(string, "radar/v-offset",m.getNode("radar/v-offset").getValue());	
			} 
			else
			{
				setprop(string, "radar/in-range", 0);
				setprop(string, "radar/in-sight", 0);
			}
   	}
	}

   settimer(MPradarProperties,0.125);
}

# -----------------------------------------------------------------------------
# MFDSwitchChange
#
# Fonction appelée dès que le commutateur radar a changé de position
# "instrumentation/radar/selected"
# -----------------------------------------------------------------------------
var MFDSwitchChange = func
{
	var selected = getprop("instrumentation/radar/selected");
	print("Selected: ", selected);
	if (selected == 3)
	{
		# Portée: 200 nautiques
		setprop("instrumentation/radar/range-nm", 200);
		setprop("instrumentation/radar/x-range-factor", 3.68125E-4);
		setprop("instrumentation/radar/y-range-factor", 5.10625E-4);
	}
	elsif (selected == 4)
	{
		# Portée: 100 nautiques
		setprop("instrumentation/radar/range-nm", 100);
		setprop("instrumentation/radar/x-range-factor", 7.36250E-4);
		setprop("instrumentation/radar/y-range-factor", 1.02125E-3);
	}
	elsif (selected == 5)
	{
		# Portée: 40 nautiques
		setprop("instrumentation/radar/range-nm", 40);
		setprop("instrumentation/radar/x-range-factor", 1.850625E-3);
		setprop("instrumentation/radar/y-range-factor", 2.553125E-3);
	}
	elsif (selected == 6)
	{
		# Portée: 10 nautiques
		setprop("instrumentation/radar/range-nm", 10);
		setprop("instrumentation/radar/x-range-factor", 7.36250E-3);
		setprop("instrumentation/radar/y-range-factor", 10.2125E-3);
	}
	elsif (selected == 22)
	{
		# Portée: 2 nautiques (3704 mètres)
		setprop("instrumentation/radar/range-nm", 2);
		setprop("instrumentation/radar/x-range-factor", 0.0368125);
		setprop("instrumentation/radar/y-range-factor", 0.0510625);
	}
}

#
# Initialisation des valeurs par défaut.
#
props.globals.getNode("instrumentation/radar/x-range-factor", 1).setDoubleValue(3.68125E-4);
props.globals.getNode("instrumentation/radar/y-range-factor", 1).setDoubleValue(5.10625E-4);
#
# Valeurs possibles pour les portées (en nautiques): 200, 100, 40 et 10.
#
props.globals.getNode("instrumentation/radar/range-nm", 1).setDoubleValue(200);
#
# Valeur du commutateur radar par défaut.
#
props.globals.getNode("instrumentation/radar/selected", 1).setIntValue(3);
#
# Création des propriétés pour le tracking.
#
props.globals.getNode("instrumentation/radar/tracked-callsign", 1).setValue("");
props.globals.getNode("instrumentation/radar/tracked", 1).setBoolValue(0);
props.globals.getNode("instrumentation/radar/tracked-x-offset", 1).setDoubleValue(0.0);
props.globals.getNode("instrumentation/radar/tracked-y-offset", 1).setDoubleValue(0.0);

setlistener("ai/models/model-added", MPjoin);
setlistener("ai/models/model-removed", MPleave);
settimer(MPradarProperties,0.75);

setlistener("instrumentation/radar/selected", MFDSwitchChange);

#
# On active les "listeners" dès que le FDM est correctement initialisé.
#
# _setlistener("/sim/signals/fdm-initialized", func {
#	setlistener("ai/models/model-added", MPjoin);
#	setlistener("ai/models/model-removed", MPleave);
#	settimer(MPradarProperties,0.75);
# });

## settimer(boreSightLock, 1.0);

