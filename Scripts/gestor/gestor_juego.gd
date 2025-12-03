extends Node

# Señales del juego
signal dinero_cambiado(nuevo_dinero)
signal vidas_cambiadas(nuevas_vidas)
signal oleada_cambiada(nueva_oleada)
signal victoria
signal derrota

# Variables del estado del juego
var dinero: int = 1000
var vidas: int = 5
var oleada_actual: int = 1
var oleadas_totales: int = 10

# Variables de mapas
var mapas_disponibles: Array = []
var mapa_actual_index: int = 0
var ruta_mapas: String = "res://escenas/Mapas/"

# Variables de estadísticas
var enemigos_spawneados: int = 0
var enemigos_muertos: int = 0
var oro_ganado_total: int = 0

func _ready():
	# Detectar automáticamente todos los mapas disponibles
	detectar_mapas()
	print("Mapas detectados: ", mapas_disponibles)

# Detecta automáticamente todos los archivos mapa_XX.tscn en la carpeta
func detectar_mapas():
	mapas_disponibles.clear()
	var dir = DirAccess.open(ruta_mapas)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Buscar archivos que empiecen con "mapa_" y terminen con ".tscn"
			if file_name.begins_with("mapa_") and file_name.ends_with(".tscn"):
				# Extraer el número del mapa (ej: "mapa_01.tscn" -> 1)
				var numero_str = file_name.replace("mapa_", "").replace(".tscn", "")
				mapas_disponibles.append({
					"numero": int(numero_str),
					"ruta": ruta_mapas + file_name,
					"nombre": file_name
				})
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		# Ordenar mapas por número
		mapas_disponibles.sort_custom(func(a, b): return a.numero < b.numero)
	else:
		push_error("No se pudo abrir la carpeta de mapas: " + ruta_mapas)

# Obtener el mapa actual
func obtener_mapa_actual() -> Dictionary:
	if mapa_actual_index < mapas_disponibles.size():
		return mapas_disponibles[mapa_actual_index]
	return {}

# Verificar si hay más mapas disponibles
func hay_siguiente_mapa() -> bool:
	return mapa_actual_index + 1 < mapas_disponibles.size()

# Cargar el siguiente mapa
func cargar_siguiente_mapa():
	if hay_siguiente_mapa():
		mapa_actual_index += 1
		var siguiente_mapa = obtener_mapa_actual()
		print("Cargando siguiente mapa: ", siguiente_mapa.nombre)
		
		# Resetear oleada pero mantener dinero
		oleada_actual = 1
		oleada_cambiada.emit(oleada_actual)
		
		# Cargar la escena del siguiente mapa
		get_tree().change_scene_to_file(siguiente_mapa.ruta)
	else:
		# No hay más mapas, VICTORIA
		print("¡VICTORIA! No hay más mapas disponibles")
		victoria.emit()

# Reiniciar variables del juego (sin cambiar escena)
func reiniciar_juego():
	mapa_actual_index = 0
	dinero = 1000
	vidas = 5
	oleada_actual = 1
	enemigos_spawneados = 0
	enemigos_muertos = 0
	oro_ganado_total = 0
	
	dinero_cambiado.emit(dinero)
	vidas_cambiadas.emit(vidas)
	oleada_cambiada.emit(oleada_actual)
	
	print("Variables del juego reseteadas")

# Nueva función: Reiniciar y volver al primer mapa
func reiniciar_y_jugar():
	reiniciar_juego()
	
	# Cargar el primer mapa
	if mapas_disponibles.size() > 0:
		get_tree().change_scene_to_file(mapas_disponibles[0].ruta)
		
# Registrar cuando se spawnea un enemigo
func registrar_enemigo_spawneado():
	enemigos_spawneados += 1

# Registrar cuando muere un enemigo Y agregar el oro
func registrar_enemigo_muerto(oro_obtenido: int):
	enemigos_muertos += 1
	oro_ganado_total += oro_obtenido
	agregar_dinero(oro_obtenido)  # AGREGADO: Sumar el oro al dinero

# Agregar dinero
func agregar_dinero(cantidad: int):
	dinero += cantidad
	dinero_cambiado.emit(dinero)

# Gastar dinero
func gastar_dinero(cantidad: int) -> bool:
	if dinero >= cantidad:
		dinero -= cantidad
		dinero_cambiado.emit(dinero)
		return true
	return false

# Restar vida
func restar_vida():
	vidas -= 1
	vidas_cambiadas.emit(vidas)
	print("Vida perdida. Vidas restantes: ", vidas)
	
	# Verificar derrota
	if vidas <= 0:
		print("¡DERROTA! Vidas agotadas")
		derrota.emit()

# Cambiar oleada
func cambiar_oleada(nueva_oleada: int):
	oleada_actual = nueva_oleada
	oleada_cambiada.emit(oleada_actual)

# Verificar si se completó la última oleada del último mapa
func verificar_victoria_oleada():
	# Si estamos en la oleada 10 Y es el último mapa disponible
	if oleada_actual >= oleadas_totales and not hay_siguiente_mapa():
		print("¡VICTORIA! Oleada final del último mapa completada")
		victoria.emit()
	elif oleada_actual >= oleadas_totales and hay_siguiente_mapa():
		# Hay más mapas, cargar el siguiente
		print("Oleada 10 completada. Cargando siguiente mapa...")
		cargar_siguiente_mapa()
