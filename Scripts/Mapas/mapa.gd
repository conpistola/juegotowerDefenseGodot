extends Node2D

# Script temporal para probar el sistema de enemigos
# Este script será reemplazado más adelante por el sistema completo

# Referencia a los caminos del mapa
var camino1: Path2D
var camino2: Path2D

# Escena del zombie a instanciar
var escena_zombie = preload("res://escenas/Enemigo/zombie_normal.tscn")

func _ready():
	# Obtener referencias a los caminos
	camino1 = $camino/Camino1
	camino2 = $camino/Camino2
	
	# Esperar 1 segundo y luego spawnear un zombie de prueba
	await get_tree().create_timer(1.0).timeout
	spawnear_zombie_prueba()

# Función para spawnear un zombie de prueba en el Camino1
func spawnear_zombie_prueba():
	# Instanciar la escena del zombie
	var zombie = escena_zombie.instantiate()
	
	# Añadir el zombie al Camino1
	camino1.add_child(zombie)
	
	# Posicionar al inicio del camino
	zombie.progress_ratio = 0.0
	
	print("Zombie de prueba spawneado en Camino1")
