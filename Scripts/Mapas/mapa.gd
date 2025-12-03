extends Node2D

# Escenas de las pantallas de victoria y derrota
var pantalla_victoria_scene = preload("res://escenas/hub/pantalla_victoria.tscn")
var pantalla_derrota_scene = preload("res://escenas/hub/pantalla_derrota.tscn")

# Referencias a nodos del mapa
@onready var capa_torre = $torre  # TileMapLayer donde se construye
@onready var camino1 = $camino/Camino1
@onready var camino2 = $camino/Camino2
@onready var hud = $Hub

# Diccionario para recordar tiles borrados (posición -> datos del tile)
var tiles_originales = {}

# Diccionario para rastrear torres construidas (posición -> torre)
var torres_construidas = {}

# Gestor de oleadas
var gestor_oleadas

func _ready():
	# CRÍTICO: Conectar señales de GestorJuego con el HUD PRIMERO
	conectar_senales_gestor_juego()
	
	# Conectar señales de victoria y derrota
	GestorJuego.victoria.connect(_on_victoria)
	GestorJuego.derrota.connect(_on_derrota)
	
	# Crear el gestor de oleadas dinámicamente
	crear_gestor_oleadas()
	
	# Asegurarse de que el HUD tiene la referencia al mapa
	if hud:
		hud.mapa_referencia = self
		print("Referencia del mapa asignada al HUD")
	else:
		print("ERROR: No se encontró el HUD")
	
	# Inicializar el gestor de oleadas
	if gestor_oleadas:
		# Obtener todos los caminos del nodo "camino"
		var nodo_camino = $camino
		var array_caminos = []
		
		# Buscar todos los Path2D dentro del nodo camino
		for hijo in nodo_camino.get_children():
			if hijo is Path2D:
				array_caminos.append(hijo)
				print("Camino encontrado: ", hijo.name)
		
		# Validar que se encontraron caminos
		if array_caminos.size() == 0:
			print("ERROR: No se encontraron caminos Path2D")
		else:
			print("Total de caminos encontrados: ", array_caminos.size())
			gestor_oleadas.inicializar(array_caminos, hud)
			
			# Iniciar el juego automáticamente
			await get_tree().create_timer(1.0).timeout
			gestor_oleadas.iniciar_juego()
	else:
		print("ERROR: No se pudo crear el gestor de oleadas")

func conectar_senales_gestor_juego():
	# Conectar señales de GestorJuego de forma simple y directa
	GestorJuego.dinero_cambiado.connect(_on_dinero_cambiado)
	GestorJuego.vidas_cambiadas.connect(_on_vidas_cambiadas)
	GestorJuego.oleada_cambiada.connect(_on_oleada_cambiada)
	
	# Emitir valores iniciales al HUD
	_on_dinero_cambiado(GestorJuego.dinero)
	_on_vidas_cambiadas(GestorJuego.vidas)
	_on_oleada_cambiada(GestorJuego.oleada_actual)
	
	print("Señales de GestorJuego conectadas al mapa")


func _on_dinero_cambiado(nuevo_dinero: int):
	if hud and hud.has_method("actualizar_dinero"):
		hud.actualizar_dinero(nuevo_dinero)

func _on_vidas_cambiadas(nuevas_vidas: int):
	if hud and hud.has_method("actualizar_vidas"):
		hud.actualizar_vidas(nuevas_vidas)

func _on_oleada_cambiada(nueva_oleada: int):
	print(">>> MAPA: _on_oleada_cambiada recibida con oleada: ", nueva_oleada)
	print(">>> HUD existe: ", hud != null)
	if hud:
		print(">>> Llamando a hud._actualizar_oleada(", nueva_oleada, ")")
		hud._actualizar_oleada(nueva_oleada)
	else:
		print(">>> ERROR: HUD es null")

func crear_gestor_oleadas():
	# Cargar el script del gestor
	var script_gestor = load("res://Scripts/gestor/gestor_oleadas.gd")
	if script_gestor:
		# Crear instancia del gestor
		gestor_oleadas = Node.new()
		gestor_oleadas.set_script(script_gestor)
		gestor_oleadas.name = "GestorOleadas"
		add_child(gestor_oleadas)
		print("GestorOleadas creado dinámicamente")
	else:
		print("ERROR: No se pudo cargar el script del gestor de oleadas")

func _unhandled_input(event):
	# Solo procesar clics izquierdos
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Obtener posición del mouse en el mundo
		var posicion_mundo = get_global_mouse_position()
		
		# CRÍTICO: Obtener posición del mouse en la PANTALLA (para UI)
		var posicion_pantalla = get_viewport().get_mouse_position()
		
		# Convertir a coordenadas locales del mapa
		var posicion_local = to_local(posicion_mundo)
		
		# Obtener coordenadas del tile
		var coordenadas_tile = capa_torre.local_to_map(posicion_local)
		
		print("Coordenadas tile: ", coordenadas_tile)
		
		# Verificar si el tile es construible
		var puede_construir = verificar_tile_construible(coordenadas_tile)
		print("Puede construir: ", puede_construir)
		
		# Si el tile es construible y no hay torre ahí
		if puede_construir and not torres_construidas.has(coordenadas_tile):
			print("ABRIENDO PANEL DE CONSTRUCCIÓN")
			
			# CRÍTICO: Asignar referencias ANTES de mostrar el panel
			hud.casilla_seleccionada = coordenadas_tile
			hud.mapa_referencia = self
			
			# CRÍTICO: Pasar posición de PANTALLA, no de mundo
			hud.mostrar_panel_construccion(posicion_pantalla)
			
		# Si hay una torre en el tile, mostrar panel de mejora
		elif torres_construidas.has(coordenadas_tile):
			var torre = torres_construidas[coordenadas_tile]
			
			# Verificar que el clic está suficientemente cerca de la torre
			var posicion_torre = torre.global_position
			var distancia = posicion_mundo.distance_to(posicion_torre)
			
			if distancia < 100:  # 100 píxeles de tolerancia
				print("ABRIENDO PANEL DE MEJORA")
				# CRÍTICO: Pasar posición de mundo de la torre (hub.gd la convertirá)
				hud.mostrar_panel_mejora(posicion_torre, torre)
				
func verificar_tile_construible(coordenadas: Vector2i) -> bool:
	# Obtener el tile data
	var tile_data = capa_torre.get_cell_tile_data(coordenadas)
	
	# Si no hay tile, no es construible
	if tile_data == null:
		return false
	
	# Obtener el tileset
	var tileset = capa_torre.tile_set
	if not tileset:
		return false
	
	# Verificar si existe el custom data layer "construir"
	var custom_data_count = tileset.get_custom_data_layers_count()
	if custom_data_count == 0:
		return false
	
	# Buscar el layer "construir"
	for i in range(custom_data_count):
		var layer_name = tileset.get_custom_data_layer_name(i)
		if layer_name == "construir":
			var valor = tile_data.get_custom_data_by_layer_id(i)
			return valor == true
	
	return false

func construir_torre(tipo_torre: String, coordenadas_tile: Vector2i):
	print("Tipo: ", tipo_torre)
	print("Coordenadas: ", coordenadas_tile)
	
	# Verificar que la casilla aún es válida
	if not verificar_tile_construible(coordenadas_tile):
		print("ERROR: Casilla no válida para construcción")
		return
	
	# Verificar que no hay torre ya construida
	if torres_construidas.has(coordenadas_tile):
		print("ERROR: Ya hay una torre en esta casilla")
		return
	
	# GUARDAR DATOS DEL TILE ORIGINAL antes de borrarlo
	var tile_data = capa_torre.get_cell_tile_data(coordenadas_tile)
	if tile_data:
		var source_id = capa_torre.get_cell_source_id(coordenadas_tile)
		var atlas_coords = capa_torre.get_cell_atlas_coords(coordenadas_tile)
		var alternative_tile = capa_torre.get_cell_alternative_tile(coordenadas_tile)
		
		# Guardar en diccionario
		tiles_originales[coordenadas_tile] = {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		}
		print("Datos del tile guardados: ", tiles_originales[coordenadas_tile])
	
	# Cargar escena de la torre
	var ruta_escena = ""
	match tipo_torre:
		"arquero":
			ruta_escena = "res://escenas/Torres/torre_arquero.tscn"
		"bomber":
			ruta_escena = "res://escenas/Torres/Torre_bomber.tscn"
		"electrica":
			ruta_escena = "res://escenas/Torres/torre_electrica.tscn"
		"sniper":
			ruta_escena = "res://escenas/Torres/torre_franco.tscn"
		_:
			print("ERROR: Tipo de torre no reconocido: ", tipo_torre)
			return
	
	# Instanciar torre
	var escena_torre = load(ruta_escena)
	if escena_torre == null:
		print("ERROR: No se pudo cargar la escena: ", ruta_escena)
		return
	
	var torre = escena_torre.instantiate()
	
	# Calcular posición en el mundo (centro del tile)
	var posicion_mundo = capa_torre.map_to_local(coordenadas_tile)
	torre.position = posicion_mundo
	
	# Guardar las coordenadas del tile en la torre
	torre.coordenadas_tile = coordenadas_tile
	
	# Agregar torre al mapa
	add_child(torre)
	
	# Registrar torre en el diccionario
	torres_construidas[coordenadas_tile] = torre
	
	# BORRAR el tile de decoración
	capa_torre.set_cell(coordenadas_tile, -1, Vector2i(-1, -1))
	
	print("Torre construida exitosamente en: ", posicion_mundo)
	print("Total de torres: ", torres_construidas.size())

func vender_torre(torre: Node2D):
	
	# Buscar las coordenadas de la torre
	var coordenadas_encontradas = null
	for coords in torres_construidas.keys():
		if torres_construidas[coords] == torre:
			coordenadas_encontradas = coords
			break
	
	if coordenadas_encontradas == null:
		print("ERROR: Torre no encontrada en el registro")
		return
	
	# Eliminar del registro
	torres_construidas.erase(coordenadas_encontradas)
	
	# RESTAURAR el tile original
	if tiles_originales.has(coordenadas_encontradas):
		var datos_tile = tiles_originales[coordenadas_encontradas]
		capa_torre.set_cell(
			coordenadas_encontradas,
			datos_tile["source_id"],
			datos_tile["atlas_coords"],
			datos_tile["alternative_tile"]
		)
		print("Tile restaurado en: ", coordenadas_encontradas)
		
		# Limpiar del diccionario
		tiles_originales.erase(coordenadas_encontradas)
	else:
		print("ADVERTENCIA: No se encontraron datos del tile original")
	
	# Eliminar la torre de la escena
	torre.queue_free()
	
	print("Torre vendida exitosamente")
	print("Total de torres restantes: ", torres_construidas.size())

func obtener_caminos() -> Array:
	return [camino1, camino2]

# Funciones para manejar victoria y derrota
func _on_victoria():
	print("¡VICTORIA! Mostrando pantalla...")
	var pantalla = pantalla_victoria_scene.instantiate()
	add_child(pantalla)

func _on_derrota():
	print("DERROTA. Mostrando pantalla...")
	var pantalla = pantalla_derrota_scene.instantiate()
	add_child(pantalla)
