extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Cacerola
# Zombie con cacerola en la cabeza, más resistente que el Cono
# Es un super tanque terrestre que puede ser atacado por todas las torres
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Cacerola
	vida_maxima = 180.0
	velocidad = 50.0
	dinero_al_morir = 45
	es_volador = false
	
	# Llamar al _ready del padre para inicializar todo
	super._ready()
	
	print("Zombie Cacerola spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad, " SUPER TANQUE")
