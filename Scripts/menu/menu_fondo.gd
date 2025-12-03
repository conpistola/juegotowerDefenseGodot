extends Node2D

# Script del fondo animado del menú
# Detecta automáticamente posiciones de construcción del mapa
# Coloca torres aleatorias en algunas posiciones
# Spawnea zombies continuamente que son atacados por las torres

# Referencias a escenas
var escena_zombie_normal = preload("res://escenas/Enemigo/zombie_normal.tscn")
var escena_zombie_escudo = preload("res://escenas/Enemigo/zombie_escudo.tscn")
var escena_zombie_gorro = preload("res://escenas/Enemigo/zombie_gorro.tscn")
var escena_torre_arquero = preload("res://escenas/Torres/torre_arquero.tscn")
var escena_torre_bomber = preload("res://escenas/Torres/Torre_bomber.tscn")
var escena_torre_electrica = preload("res://escenas/Torres/torre_electrica.tscn")
var escena_torre_franco = preload("res://escenas/Torres/torre_franco.tscn")

# Script específico para enemigos del menú
var script_enemigo_menu = preload("res://Scripts/menu/enemigo_menu.gd")

# Array con todas las escenas para variedad
var tipos_zombies = []
var tipos_torres = []

# Referencias a nodos del mapa
var capa_torre: TileMapLayer = null
var nodo_camino: Node2D = null
var caminos: Array = []

# Referencias a nodos propios
@onready var contenedor_torres = $ContenedorTorres
@onready var timer_spawn = $TimerSpawn

# Control de spawn
var zombies_activos = []
var max_zombies = 15

func _ready():
	print("=== INICIANDO MENU FONDO ===")
	
	# Llenar arrays
	tipos_zombies = [
		escena_zombie_normal,
		escena_zombie_escudo,
		escena_zombie_gorro,
		escena_zombie_normal,
		escena_zombie_normal
	]
	
	tipos_torres = [
		escena_torre_arquero,
		escena_torre_bomber,
		escena_torre_electrica,
		escena_torre_franco
	]
	
	# Buscar nodos del mapa
	buscar_nodos_del_mapa()
	
	# Colocar torres automáticamente
	if capa_torre:
		await get_tree().create_timer(0.1).timeout  # Pequeña espera
		colocar_torres()
	else:
		print("ERROR: No se encontró capa_torre")
	
	# Conectar timer
	if timer_spawn:
		timer_spawn.timeout.connect(_on_timer_spawn_timeout)
		print("Timer conectado")
	
	# Spawnear zombies iniciales
	await get_tree().create_timer(0.5).timeout
	for i in range(5):
		spawnear_zombie()
		await get_tree().create_timer(0.2).timeout
	
	print("=== FONDO MENU INICIALIZADO ===")
	print("Torres colocadas: ", contenedor_torres.get_child_count())
	print("Caminos disponibles: ", caminos.size())

func buscar_nodos_del_mapa():
	print("Buscando nodos del mapa...")
	var padre = get_parent()
	
	if not padre:
		print("ERROR: No hay nodo padre")
		return
	
	print("Padre encontrado: ", padre.name)
	print("Hijos del padre:")
	for hijo in padre.get_children():
		print("  - ", hijo.name, " (", hijo.get_class(), ")")
	
	# Buscar TileMapLayer "torre"
	if padre.has_node("torre"):
		capa_torre = padre.get_node("torre")
		print("✓ TileMapLayer 'torre' encontrado")
	else:
		print("✗ ERROR: No se encontró TileMapLayer 'torre'")
	
	# Buscar caminos
	if padre.has_node("camino"):
		nodo_camino = padre.get_node("camino")
		print("✓ Nodo 'camino' encontrado")
		
		for hijo in nodo_camino.get_children():
			if hijo is Path2D:
				caminos.append(hijo)
				print("  ✓ Camino encontrado: ", hijo.name)
		
		if caminos.size() == 0:
			print("✗ ERROR: No se encontraron Path2D dentro de 'camino'")
	else:
		print("✗ ERROR: No se encontró el nodo 'camino'")

func colocar_torres():
	print("Intentando colocar torres...")
	
	var posiciones = obtener_posiciones_construibles()
	
	print("Posiciones construibles encontradas: ", posiciones.size())
	
	if posiciones.size() == 0:
		print("ERROR: No hay posiciones construibles")
		print("Verificando TileSet...")
		if capa_torre and capa_torre.tile_set:
			print("  TileSet existe")
			print("  Custom data layers: ", capa_torre.tile_set.get_custom_data_layers_count())
			for i in range(capa_torre.tile_set.get_custom_data_layers_count()):
				print("    Layer ", i, ": ", capa_torre.tile_set.get_custom_data_layer_name(i))
		return
	
	
	var cantidad = int(posiciones.size())
	cantidad = clamp(cantidad, 3, posiciones.size())
	
	print("Colocando ", cantidad, " torres de ", posiciones.size(), " posiciones")
	
	posiciones.shuffle()
	
	for i in range(cantidad):
		var coords = posiciones[i]
		var pos_mundo = capa_torre.map_to_local(coords)
		
		var tipo_torre = tipos_torres[randi() % tipos_torres.size()]
		var torre = tipo_torre.instantiate()
		
		torre.position = pos_mundo
		torre.process_mode = Node.PROCESS_MODE_ALWAYS
		contenedor_torres.add_child(torre)
		
		print("  Torre colocada en ", coords, " -> ", pos_mundo)

func obtener_posiciones_construibles() -> Array:
	var posiciones = []
	
	if not capa_torre:
		print("ERROR: capa_torre es null")
		return posiciones
	
	var tileset = capa_torre.tile_set
	if not tileset:
		print("ERROR: tileset es null")
		return posiciones
	
	var custom_count = tileset.get_custom_data_layers_count()
	print("Custom data layers: ", custom_count)
	
	if custom_count == 0:
		print("ERROR: No hay custom data layers")
		return posiciones
	
	# Buscar layer "construir"
	var layer_index = -1
	for i in range(custom_count):
		var layer_name = tileset.get_custom_data_layer_name(i)
		print("  Layer ", i, ": ", layer_name)
		if layer_name == "construir":
			layer_index = i
			print(" Layer 'construir' encontrado en índice ", i)
			break
	
	if layer_index == -1:
		print("ERROR: No se encontró layer 'construir'")
		return posiciones
	
	# Escanear tiles
	var tiles_usados = capa_torre.get_used_cells()
	print("Tiles usados en la capa: ", tiles_usados.size())
	
	for coords in tiles_usados:
		var tile_data = capa_torre.get_cell_tile_data(coords)
		
		if tile_data:
			var puede_construir = tile_data.get_custom_data_by_layer_id(layer_index)
			if puede_construir == true:
				posiciones.append(coords)
	
	print("Posiciones con construir=true: ", posiciones.size())
	
	return posiciones

func spawnear_zombie():
	if zombies_activos.size() >= max_zombies:
		return
	
	if caminos.size() == 0:
		print("ERROR: No hay caminos para spawnear")
		return
	
	var tipo_zombie = tipos_zombies[randi() % tipos_zombies.size()]
	var zombie = tipo_zombie.instantiate()
	
	# IMPORTANTE: Cambiar el script al script del menú
	zombie.set_script(script_enemigo_menu)
	
	var camino_aleatorio = caminos[randi() % caminos.size()]
	camino_aleatorio.add_child(zombie)
	
	zombie.process_mode = Node.PROCESS_MODE_ALWAYS
	zombie.velocidad *= 1.5
	
	zombies_activos.append(zombie)
	zombie.tree_exited.connect(_on_zombie_eliminado.bind(zombie))
	
	print("Zombie spawneado en ", camino_aleatorio.name, " (Total: ", zombies_activos.size(), ")")

func _on_zombie_eliminado(zombie):
	if zombie in zombies_activos:
		zombies_activos.erase(zombie)

func _on_timer_spawn_timeout():
	spawnear_zombie()

func _process(_delta):
	# Limpiar zombies que llegaron al final
	for zombie in zombies_activos.duplicate():
		if is_instance_valid(zombie) and zombie.progress_ratio >= 1.0:
			print("Zombie llegó al final, eliminando...")
			zombie.queue_free()
