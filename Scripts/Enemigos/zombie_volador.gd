extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Volador
# Zombie que vuela, más rápido pero con menos vida
# IMPORTANTE: Solo puede ser atacado por torres anti-aéreas (Arquero y Franco)
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Volador
	vida_maxima = 60.0
	velocidad = 100.0
	dinero_al_morir = 35
	es_volador = true  
	
	# Llamar al _ready del padre para inicializar todo
	super._ready()
	
	print("Zombie Volador spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad, " ES VOLADOR")
