extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Gorro
# Zombie con gorro, ligeramente más resistente que el normal
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Gorro
	vida_maxima = 70.0
	velocidad = 80.0
	dinero_al_morir = 25
	es_volador = false
	
	# Llamar al _ready del padre para inicializar todo
	super._ready()
	
	print("Zombie Gorro spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad)
