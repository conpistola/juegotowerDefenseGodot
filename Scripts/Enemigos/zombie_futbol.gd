extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Futbol
# Zombie con armadura de futbol americano - EL MÁS RESISTENTE DEL JUEGO
# Es el jefe final, extremadamente resistente pero muy lento
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Futbol (JEFE FINAL)
	vida_maxima = 250.0
	velocidad = 40.0
	dinero_al_morir = 60
	es_volador = false
	
	# Llamar al _ready del padre para inicializar todo
	super._ready()
	
	print("ZOMBIE FUTBOL spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad, " ¡¡¡JEFE FINAL!!!")
