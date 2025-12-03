extends "res://Scripts/Enemigos/enemigo.gd"

# Script del Zombie Volador Pro
# Versión mejorada del zombie volador: más resistente y ligeramente más lento
# IMPORTANTE: Solo puede ser atacado por torres anti-aéreas (Arquero y Franco)
# Hereda toda la funcionalidad de enemigo.gd, solo cambia los valores

func _ready():
	# Configurar estadísticas del Zombie Volador Pro
	vida_maxima = 120.0
	velocidad = 90.0
	dinero_al_morir = 50
	es_volador = true  # Es volador, solo atacado por Arquero y Franco
	
	super._ready()
	
	print("Zombie Volador Pro spawneado - Vida: ", vida_maxima, " Velocidad: ", velocidad, " ES VOLADOR PRO")
