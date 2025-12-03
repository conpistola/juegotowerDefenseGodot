extends Node2D

# Script base para todas las torres del juego
# Controla detección de enemigos, disparo y animaciones direccionales con flip

# Propiedades de la torre
@export var tipo_torre: String = "arquero"
@export var danio: float = 10.0
@export var rango: float = 300.0
@export var cadencia: float = 1.0
@export var precio_base: int = 100
@export var puede_atacar_voladores: bool = true
@export var ataque_multiple: bool = false
@export var cantidad_ataques: int = 1
@export var danio_area: bool = false
@export var radio_area: float = 100.0


var esta_mejorada: bool = false
var puede_disparar: bool = true
var enemigo_objetivo = null
var nivel_actual: int = 1
var nivel_maximo: int = 5

var coordenadas_tile = Vector2i.ZERO  
var datos_tile_original = {}  
var mapa_referencia = null  

# Referencias a nodos hijos
@onready var base_estructura: Sprite2D = $BaseEstructura
@onready var torre_animada: AnimatedSprite2D = get_node_or_null("BaseEstructura/torre")
@onready var arquero: AnimatedSprite2D = get_node_or_null("Arquero")
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var collision_deteccion: CollisionShape2D = $AreaDeteccion/CollisionShape2D
@onready var timer_disparo: Timer = $TimerDisparo

# Escena del proyectil (se asigna en cada torre específica)
@export var escena_proyectil: PackedScene = null

func _ready():
	# Configurar el rango de detección
	if collision_deteccion and collision_deteccion.shape is CircleShape2D:
		collision_deteccion.shape.radius = rango
	
	# Hacer el Area2D clickeable para el panel de mejora
	if area_deteccion:
		area_deteccion.input_pickable = true
		# CONECTAR LA SEÑAL DE INPUT
		if not area_deteccion.input_event.is_connected(_on_area_deteccion_input_event):
			area_deteccion.input_event.connect(_on_area_deteccion_input_event)
			print("Señal input_event conectada para ", tipo_torre)
	
	# Configurar timer de disparo
	timer_disparo.wait_time = cadencia
	timer_disparo.one_shot = true
	timer_disparo.timeout.connect(_on_timer_disparo_timeout)
	
	# Añadir al grupo de torres
	add_to_group("torres")
	
	# Iniciar la base en nivel 1
	if torre_animada:
		torre_animada.play("nivel1")
	
	# Reproducir animación idle por defecto del arquero
	if arquero and arquero.sprite_frames.has_animation("idle"):
		arquero.play("idle")
	
	print("Torre ", tipo_torre, " creada - Daño: ", danio, " | Rango: ", rango, " | Cadencia: ", cadencia)

func _process(delta):
	if not puede_disparar:
		return
	
	# Buscar objetivo
	if ataque_multiple:
		var objetivos = buscar_enemigos_multiples()
		if objetivos.size() > 0:
			disparar_multiple(objetivos)
	else:
		enemigo_objetivo = buscar_enemigo_mas_cercano()
		if enemigo_objetivo:
			disparar(enemigo_objetivo)

# Buscar el enemigo más avanzado en el camino (mayor progress_ratio)
func buscar_enemigo_mas_cercano():
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	# DEBUG CRÍTICO
	if Engine.get_frames_drawn() % 60 == 0:
		print("Total enemigos en grupo: ", enemigos.size())
		print("Posición torre: ", global_position)
		print("Rango torre: ", rango)
	
	if enemigos.size() == 0:
		return null
	
	var enemigo_prioritario = null
	var mayor_progreso = -1.0
	var enemigos_revisados = 0
	var enemigos_vivos = 0
	var enemigos_en_rango = 0
	
	for enemigo in enemigos:
		enemigos_revisados += 1
		
		# Verificar si el enemigo está vivo
		if not enemigo.esta_vivo:
			continue
		
		enemigos_vivos += 1
		
		# Verificar si la torre puede atacar voladores
		if enemigo.es_volador and not puede_atacar_voladores:
			continue
		
		# Calcular distancia para verificar rango
		var distancia = global_position.distance_to(enemigo.global_position)
		
		# DEBUG: Primer enemigo vivo
		if enemigos_vivos == 1 and Engine.get_frames_drawn() % 60 == 0:
			print("Primer enemigo vivo:")
			print("  Posición: ", enemigo.global_position)
			print("  Distancia: ", int(distancia), " px")
			print("  En rango? ", distancia <= rango)
		
		# Solo considerar enemigos dentro del rango
		if distancia > rango:
			continue
		
		enemigos_en_rango += 1
		
		# Obtener el progress_ratio (qué tan avanzado está en el camino)
		var progreso = enemigo.progress_ratio
		
		# Elegir el enemigo con mayor progreso (más avanzado)
		if progreso > mayor_progreso:
			mayor_progreso = progreso
			enemigo_prioritario = enemigo
	
	# DEBUG FINAL
	if Engine.get_frames_drawn() % 60 == 0:
		print("Enemigos revisados: ", enemigos_revisados)
		print("Enemigos vivos: ", enemigos_vivos)
		print("Enemigos en rango: ", enemigos_en_rango)
		print("Objetivo seleccionado: ", enemigo_prioritario)
	
	return enemigo_prioritario

# Buscar múltiples enemigos para torres de ataque múltiple
func buscar_enemigos_multiples() -> Array:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var objetivos = []
	
	for enemigo in enemigos:
		# Verificar si el enemigo está vivo
		if not enemigo.esta_vivo:
			continue
		
		# Verificar si la torre puede atacar voladores
		if enemigo.es_volador and not puede_atacar_voladores:
			continue
		
		# Calcular distancia
		var distancia = global_position.distance_to(enemigo.global_position)
		
		# Verificar si está en rango
		if distancia <= rango:
			objetivos.append(enemigo)
			
			# Limitar cantidad de objetivos
			if objetivos.size() >= cantidad_ataques:
				break
	
	return objetivos

# Calcular la dirección y obtener la animación + flip correspondiente
func obtener_animacion_y_flip(objetivo) -> Dictionary:
	if not objetivo:
		return {"animacion": "disparar_izquierda", "flip": false}
	
	# Calcular dirección hacia el enemigo
	var direccion = global_position.direction_to(objetivo.global_position)
	var angulo = direccion.angle()
	
	# Convertir radianes a grados (0-360)
	var grados = rad_to_deg(angulo)
	if grados < 0:
		grados += 360
	
	var animacion = "disparar_izquierda"
	var flip = false
	
	# Determinar dirección según el ángulo (8 direcciones)
	if grados >= 337.5 or grados < 22.5:
		# DERECHA - usar disparar_izquierda con flip
		animacion = "disparar_izquierda"
		flip = true
	elif grados >= 22.5 and grados < 67.5:
		# ABAJO-DERECHA - usar disparar_abajo_izquierda con flip
		animacion = "disparar_abajo_izquierda"
		flip = true
	elif grados >= 67.5 and grados < 112.5:
		# ABAJO - sin flip
		animacion = "disparar_abajo"
		flip = false
	elif grados >= 112.5 and grados < 157.5:
		# ABAJO-IZQUIERDA - sin flip
		animacion = "disparar_abajo_izquierda"
		flip = false
	elif grados >= 157.5 and grados < 202.5:
		# IZQUIERDA - sin flip
		animacion = "disparar_izquierda"
		flip = false
	elif grados >= 202.5 and grados < 247.5:
		# ARRIBA-IZQUIERDA - sin flip
		animacion = "disparar_arriba_izquierda"
		flip = false
	elif grados >= 247.5 and grados < 292.5:
		# ARRIBA - sin flip
		animacion = "disparar_arriba"
		flip = false
	elif grados >= 292.5 and grados < 337.5:
		# ARRIBA-DERECHA - usar disparar_arriba_izquierda con flip
		animacion = "disparar_arriba_izquierda"
		flip = true
	
	return {"animacion": animacion, "flip": flip}

func disparar(objetivo):
	if not objetivo or not objetivo.esta_vivo:
		return
	
	# Marcar que no puede disparar hasta que termine el cooldown
	puede_disparar = false
	timer_disparo.start()
	
	# Obtener la animación y el flip correcto
	var datos = obtener_animacion_y_flip(objetivo)
	var nombre_animacion = datos["animacion"]
	var necesita_flip = datos["flip"]
	
	# Aplicar flip horizontal si es necesario
	if arquero:
		arquero.flip_h = necesita_flip
		
		# Reproducir animación de disparo direccional
		if arquero.sprite_frames.has_animation(nombre_animacion):
			arquero.play(nombre_animacion)
			
			# Esperar a que termine la animación ANTES de crear el proyectil
			await arquero.animation_finished
			
			# Crear proyectil DESPUÉS de la animación
			if escena_proyectil:
				if objetivo and is_instance_valid(objetivo) and objetivo.esta_vivo:
					crear_proyectil(objetivo)
			else:
				# Daño instantáneo si no hay proyectil
				if objetivo and is_instance_valid(objetivo) and objetivo.esta_vivo:
					objetivo.recibir_danio(danio)
			
			# Volver a idle
			if arquero and arquero.sprite_frames.has_animation("idle"):
				arquero.play("idle")
				arquero.flip_h = false
	match tipo_torre:
		"arquero":
			GestorSonidos.reproducir_disparo_arquero()
		"sniper":
			GestorSonidos.reproducir_disparo_sniper()
			
func disparar_multiple(objetivos: Array):
	if objetivos.size() == 0:
		return
	
	# Marcar que no puede disparar hasta que termine el cooldown
	puede_disparar = false
	timer_disparo.start()
	
	# Usar el primer objetivo para determinar la dirección
	var datos = obtener_animacion_y_flip(objetivos[0])
	var nombre_animacion = datos["animacion"]
	var necesita_flip = datos["flip"]
	
	# Aplicar flip horizontal
	if arquero:
		arquero.flip_h = necesita_flip
	
	# Reproducir animación de disparo
	if arquero and arquero.sprite_frames.has_animation(nombre_animacion):
		arquero.play(nombre_animacion)
		await arquero.animation_finished
		# Verificar que el arquero sigue existiendo antes de volver a idle
		if arquero and arquero.sprite_frames.has_animation("idle"):
			arquero.play("idle")
			arquero.flip_h = false
	
	# Crear proyectiles o hacer daño a todos los objetivos
	for objetivo in objetivos:
		if not objetivo or not objetivo.esta_vivo:
			continue
		
		# Crear proyectil o hacer daño instantáneo
		if escena_proyectil:
			crear_proyectil(objetivo)
		else:
			# Daño instantáneo (para torre eléctrica)
			if objetivo.has_method("recibir_danio"):
				objetivo.recibir_danio(danio)
	
	print("Torre ", tipo_torre, " atacó ", objetivos.size(), " enemigos")
# Crear un proyectil hacia el objetivo
func crear_proyectil(objetivo):
	if not escena_proyectil:
		print("ERROR: No hay escena_proyectil asignada")
		return
	
	print(">>> CREANDO PROYECTIL <<<")
	
	# Instanciar proyectil
	var proyectil = escena_proyectil.instantiate()
	
	# Añadir al árbol (en el mapa, no como hijo de la torre)
	get_parent().add_child(proyectil)
	
	# Posicionar en el arquero (no en el centro de la torre)
	if arquero:
		proyectil.global_position = arquero.global_position
	else:
		proyectil.global_position = global_position
	
	print("Proyectil instanciado en: ", proyectil.global_position)
	
	# Configurar el proyectil
	if proyectil.has_method("configurar"):
		proyectil.configurar(objetivo, danio, danio_area, radio_area)
	
	print("Proyectil configurado y lanzado")

# Callback cuando termina el cooldown de disparo
func _on_timer_disparo_timeout():
	puede_disparar = true

# Mejorar la torre
# Mejorar la torre
func mejorar():
	# Verificar si ya está en nivel máximo
	if nivel_actual >= nivel_maximo:
		print("Torre ", tipo_torre, " ya está en nivel máximo (", nivel_maximo, ")")
		return false
	
	# Verificar si hay dinero suficiente
	var costo_mejora = precio_base
	if GestorJuego.dinero < costo_mejora:
		print("No hay dinero suficiente. Costo: ", costo_mejora, " | Dinero actual: ", GestorJuego.dinero)
		return false
	
	# GASTAR EL DINERO
	GestorJuego.gastar_dinero(costo_mejora)
	print("Dinero gastado: ", costo_mejora)
	
	# Incrementar nivel ANTES de calcular las estadísticas
	nivel_actual += 1
	
	# Aumentar estadísticas: +50% daño, +20% rango, -20% cadencia
	danio *= 1.5
	rango *= 1.2
	cadencia *= 0.8
	
	# Actualizar timer de disparo
	if timer_disparo:
		timer_disparo.wait_time = cadencia
	
	# Actualizar área de detección con el nuevo rango
	if collision_deteccion and collision_deteccion.shape is CircleShape2D:
		collision_deteccion.shape.radius = rango
	
	# Cambiar sprite de la base al nuevo nivel
	cambiar_sprite_nivel()
	
	print("Torre ", tipo_torre, " mejorada a nivel ", nivel_actual)
	print("  Nuevas estadísticas:")
	print("  - Daño: ", danio)
	print("  - Rango: ", rango)
	print("  - Cadencia: ", cadencia)
	
	return true
	
# Cambiar el sprite de la base cuando se mejora
func cambiar_sprite_nivel():
	# BUSCAR EL NODO CORRECTO (se llama "torre", no "torre_animada")
	var sprite_torre = get_node_or_null("BaseEstructura/torre")
	
	if not sprite_torre:
		print("ERROR: No se encontró el nodo BaseEstructura/torre")
		return
	
	# Cambiar a la animación del nivel actual
	var nombre_animacion = "nivel" + str(nivel_actual)
	
	if sprite_torre.sprite_frames.has_animation(nombre_animacion):
		sprite_torre.play(nombre_animacion)
		print("Sprite cambiado a: ", nombre_animacion)
	else:
		print("ERROR: No existe la animación ", nombre_animacion)

func vender():
	# Calcular dinero a devolver (75% del dinero invertido)
	var dinero_invertido = precio_base * nivel_actual
	var dinero_devuelto = int(dinero_invertido * 0.75)
	
	print("Torre: ", tipo_torre)
	print("Nivel: ", nivel_actual)
	print("Dinero devuelto: ", dinero_devuelto)
	print("Coordenadas tile: ", coordenadas_tile)
	
	# Devolver dinero
	GestorJuego.agregar_dinero(dinero_devuelto)
	
	# Llamar al método vender_torre del mapa para restaurar el tile
	var mapa = get_parent()
	if mapa and mapa.has_method("vender_torre"):
		print("Llamando a mapa.vender_torre()")
		mapa.vender_torre(self)
	else:
		print("ERROR: No se encontró el mapa o no tiene el método vender_torre()")
		# Si no podemos usar el método del mapa, al menos eliminamos la torre
		queue_free()
# Función para detectar clics en la torre (para panel de mejora)
func _on_area_deteccion_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verificar que el clic está cerca de la torre
		var pos_clic = get_global_mouse_position()
		var distancia = global_position.distance_to(pos_clic)
		
		if distancia > 100:
			print("Clic a ", int(distancia), "px de la torre - ignorando")
			return
		
		print("Clic detectado en torre ", tipo_torre)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_panel_mejora"):
			# PASAR LA POSICIÓN GLOBAL DE LA TORRE (en coordenadas del mundo)
			hud.mostrar_panel_mejora(global_position, self)
			print("Panel de mejora llamado")
