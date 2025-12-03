extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Escudo
# Zombie más resistente y lento que el normal
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores iniciales

func _ready():
	# Configurar estadísticas del Zombie Escudo ANTES de llamar al _ready del padre
	vida_maxima = 100.0
	velocidad = 60.0  
	dinero_al_morir = 30
	es_volador = false
	
	super._ready()
	
	print("Zombie Escudo spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad)
