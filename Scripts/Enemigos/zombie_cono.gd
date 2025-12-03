extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Cono
# Zombie con cono de tráfico en la cabeza, bastante resistente
# Es un tanque terrestre que puede ser atacado por todas las torres
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Cono
	vida_maxima = 150.0
	velocidad = 50.0
	dinero_al_morir = 40
	es_volador = false
	
	# Llamar al _ready del padre para inicializar todo
	super._ready()
	
	print("Zombie Cono spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad, " TANQUE")
