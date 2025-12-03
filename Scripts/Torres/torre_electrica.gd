extends Node2D

# Torre Eléctrica - Ataque con proyectiles que saltan entre enemigos
# Proyectiles eléctricos que pueden saltar hasta 3 veces

# Propiedades de la torre
@export var tipo_torre: String = "electrica"
@export var danio: float = 15.0
@export var rango: float = 350.0
@export var precio_base: int = 300
@export var puede_atacar_voladores: bool = true

var puede_disparar: bool = true
var nivel_actual: int = 1
var nivel_maximo: int = 5
var coordenadas_tile = Vector2i.ZERO

# Escena del proyectil eléctrico
var escena_proyectil = preload("res://escenas/Torres/proyectil_electrico.tscn")

# Referencias a nodos
@onready var base_estructura: Sprite2D = $BaseEstructura
@onready var torre_animada: AnimatedSprite2D = $BaseEstructura/AnimatedSprite2D
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var collision_deteccion: CollisionShape2D = $AreaDeteccion/CollisionShape2D
@onready var timer_disparo: Timer = $TimerDisparo

func _ready():
	
	# Configurar el rango de detección
	if collision_deteccion and collision_deteccion.shape is CircleShape2D:
		collision_deteccion.shape.radius = rango
		print("Rango de detección configurado: ", rango)
	else:
		print("ERROR: No se pudo configurar el rango de detección")
	
	# Hacer el Area2D clickeable
	if area_deteccion:
		area_deteccion.input_pickable = true
		area_deteccion.process_mode = Node.PROCESS_MODE_ALWAYS
		if not area_deteccion.input_event.is_connected(_on_area_deteccion_input_event):
			area_deteccion.input_event.connect(_on_area_deteccion_input_event)
		print("Area de detección configurada")
	
	# Configurar timer de disparo
	if timer_disparo:
		timer_disparo.one_shot = true
		timer_disparo.timeout.connect(_on_timer_disparo_timeout)
	else:
		print("ERROR: No se encontró TimerDisparo")
	
	# Añadir al grupo de torres
	add_to_group("torres")
	
	# Iniciar en nivel 1
	if torre_animada:
		torre_animada.play("idle_1")
		print("Animación idle_1 iniciada")
	else:
		print("ERROR: No se encontró torre_animada")
	

func _process(delta):
	# DEBUG cada 60 frames
	if Engine.get_frames_drawn() % 60 == 0:
		print("Puede disparar: ", puede_disparar)
		print("Posición: ", global_position)
	
	if not puede_disparar:
		return
	
	# Buscar un enemigo para disparar
	var enemigo = buscar_enemigo_mas_cercano()
	if enemigo:
		print("Torre Eléctrica encontró enemigo: ", enemigo.name)
		disparar(enemigo)

# Buscar el enemigo más cercano en rango
func buscar_enemigo_mas_cercano():
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	# DEBUG cada 60 frames
	if Engine.get_frames_drawn() % 60 == 0:
		print("Torre Eléctrica buscando enemigos...")
		print("Total enemigos en grupo: ", enemigos.size())
	
	if enemigos.size() == 0:
		return null
	
	var enemigo_prioritario = null
	var menor_distancia = rango
	
	for enemigo in enemigos:
		# Verificar si el enemigo está vivo
		if not enemigo.esta_vivo:
			continue
		
		# Verificar si la torre puede atacar voladores
		if enemigo.es_volador and not puede_atacar_voladores:
			continue
		
		# Calcular distancia
		var distancia = global_position.distance_to(enemigo.global_position)
		
		# DEBUG primer enemigo
		if enemigo_prioritario == null and Engine.get_frames_drawn() % 60 == 0:
			print("Primer enemigo vivo:")
			print("  Posición: ", enemigo.global_position)
			print("  Distancia: ", int(distancia), " px")
			print("  En rango? ", distancia <= rango)
		
		# Solo considerar enemigos dentro del rango
		if distancia > rango:
			continue
		
		# Elegir el más cercano
		if distancia < menor_distancia:
			menor_distancia = distancia
			enemigo_prioritario = enemigo
	
	return enemigo_prioritario

# Disparar proyectil eléctrico
func disparar(objetivo):
	if not objetivo or not objetivo.esta_vivo:
		return
	
	# Marcar que no puede disparar hasta que termine el cooldown
	puede_disparar = false
	timer_disparo.start()
	
	GestorSonidos.reproducir_disparo_electrico()
	# Crear proyectil eléctrico
	crear_proyectil(objetivo)
	
	print(">>> TORRE ELÉCTRICA DISPARÓ <<<")

# Crear un proyectil eléctrico
func crear_proyectil(objetivo):
	if not escena_proyectil:
		print("ERROR: No hay escena_proyectil asignada")
		return
	
	# Instanciar proyectil
	var proyectil = escena_proyectil.instantiate()
	
	# Añadir al árbol (en el mapa)
	get_parent().add_child(proyectil)
	
	# Posicionar en la torre
	proyectil.global_position = global_position + Vector2(0, -40)
	
	print("Proyectil eléctrico instanciado en: ", proyectil.global_position)
	
	# Configurar el proyectil con el objetivo y los saltos
	if proyectil.has_method("configurar"):
		proyectil.configurar(objetivo, danio, false, 0)
		print("Proyectil eléctrico configurado")

# Callback cuando termina el cooldown de disparo
func _on_timer_disparo_timeout():
	puede_disparar = true
	print("Torre Eléctrica puede disparar de nuevo")

# Mejorar la torre
func mejorar():
	# Aumentar estadísticas: +50% daño, +20% rango, -20% cadencia
	danio *= 1.5
	rango *= 1.2
	timer_disparo.wait_time *= 0.8
	
	# Actualizar timer y área de detección
	if collision_deteccion and collision_deteccion.shape is CircleShape2D:
		collision_deteccion.shape.radius = rango
	
	# Cambiar animación según nivel
	nivel_actual += 1
	if nivel_actual > nivel_maximo:
		nivel_actual = nivel_maximo
		return false
	
	# Cambiar a la animación del siguiente nivel
	var nombre_animacion = "idle_" + str(nivel_actual)
	if torre_animada and torre_animada.sprite_frames.has_animation(nombre_animacion):
		torre_animada.play(nombre_animacion)
		print("Torre Eléctrica subida a nivel ", nivel_actual)

	return true

# Función para vender la torre
func vender():
	# Calcular dinero a devolver (75% del dinero invertido)
	var dinero_invertido = precio_base * nivel_actual
	var dinero_devuelto = int(dinero_invertido * 0.75)
	
	print("Nivel: ", nivel_actual)
	print("Dinero devuelto: ", dinero_devuelto)
	
	# Devolver dinero
	GestorJuego.agregar_dinero(dinero_devuelto)
	
	# Llamar al método vender_torre del mapa para restaurar el tile
	var mapa = get_parent()
	if mapa and mapa.has_method("vender_torre"):
		print("Llamando a mapa.vender_torre()")
		mapa.vender_torre(self)
	else:
		print("ERROR: No se encontró el mapa")
		queue_free()

# Función para detectar clics en la torre
func _on_area_deteccion_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verificar que el clic está cerca de la torre
		var pos_clic = get_global_mouse_position()
		var distancia = global_position.distance_to(pos_clic)
		
		if distancia > 100:
			return
		
		print("Clic detectado en torre eléctrica")
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_panel_mejora"):
			hud.mostrar_panel_mejora(global_position, self)
