extends "res://Scripts/Torres/torre_base.gd"

# Variables internas
var debug_contador = 0
var timer_activo = false
var sprite_animado = null

func _ready():
	# Configurar valores iniciales
	tipo_torre = "bomber"
	danio = 25.0
	rango = 500.0
	cadencia = 2.0
	precio_base = 150
	puede_atacar_voladores = false
	danio_area = true
	radio_area = 200.0
	nivel_actual = 1
	nivel_maximo = 5
	
	
	# BUSCAR AREA2D para clics
	area_deteccion = buscar_nodo_por_tipo(self, "Area2D")
	if area_deteccion:
		area_deteccion.input_pickable = true
		if not area_deteccion.input_event.is_connected(_on_area_deteccion_input_event):
			area_deteccion.input_event.connect(_on_area_deteccion_input_event)
	
	# BUSCAR TIMER
	var timer_disparo = buscar_nodo_por_tipo(self, "Timer")
	if timer_disparo:
		if not timer_disparo.timeout.is_connected(_on_timer_disparo_timeout):
			timer_disparo.timeout.connect(_on_timer_disparo_timeout)
	
	# BUSCAR ANIMATEDSPRITE2D
	sprite_animado = buscar_nodo_por_tipo(self, "AnimatedSprite2D")
	
	reproducir_animacion_idle()
	
	print("Torre Bomber lista - Radio: ", radio_area, "px")

func buscar_nodo_por_tipo(nodo_raiz, tipo_clase: String):
	if nodo_raiz.get_class() == tipo_clase:
		return nodo_raiz
	
	for hijo in nodo_raiz.get_children():
		var resultado = buscar_nodo_por_tipo(hijo, tipo_clase)
		if resultado:
			return resultado
	
	return null

func _process(delta):
	debug_contador += 1
	
	if timer_activo:
		return
	
	# USAR LA MISMA LÓGICA QUE EL ARQUERO
	var objetivo = buscar_enemigo_mas_cercano_bomber()
	
	if objetivo:
		if debug_contador % 60 == 0:
			print("Objetivo encontrado: ", objetivo.name)
		disparar_a(objetivo)

# COPIAR la lógica del arquero pero adaptada al bomber
func buscar_enemigo_mas_cercano_bomber():
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	if debug_contador % 120 == 0:
		print("Total enemigos: ", enemigos.size())
		print("Posición torre: ", global_position)
		print("Rango: ", rango)
	
	if enemigos.size() == 0:
		return null
	
	var enemigo_prioritario = null
	var mayor_progreso = -1.0
	var enemigos_en_rango = 0
	
	for enemigo in enemigos:
		# Verificar si el enemigo está vivo (IGUAL QUE ARQUERO)
		if not enemigo.esta_vivo:
			continue
		
		# Verificar si puede atacar voladores (IGUAL QUE ARQUERO)
		if enemigo.es_volador and not puede_atacar_voladores:
			continue
		
		# Calcular distancia (IGUAL QUE ARQUERO)
		var distancia = global_position.distance_to(enemigo.global_position)
		
		if debug_contador % 120 == 0:
			print("  Enemigo: ", enemigo.name)
			print("    Distancia: ", int(distancia), "px")
		
		# Solo considerar enemigos dentro del rango (IGUAL QUE ARQUERO)
		if distancia > rango:
			if debug_contador % 120 == 0:
				print("    FUERA DE RANGO")
			continue
		
		enemigos_en_rango += 1
		
		# Obtener progress_ratio (IGUAL QUE ARQUERO)
		var progreso = enemigo.progress_ratio
		
		if debug_contador % 120 == 0:
			print("    Progreso: ", progreso, " - EN RANGO")
		
		# Elegir el más avanzado (IGUAL QUE ARQUERO)
		if progreso > mayor_progreso:
			mayor_progreso = progreso
			enemigo_prioritario = enemigo
	
	if debug_contador % 120 == 0:
		print("Enemigos en rango: ", enemigos_en_rango)
		if enemigo_prioritario:
			print("  OBJETIVO: ", enemigo_prioritario.name)
	
	return enemigo_prioritario

func disparar_a(objetivo):
	if not objetivo or not objetivo.esta_vivo:
		return
	
	print(">>> DISPARANDO <<<")
	print("    Enemigo: ", objetivo.name)
	
	# Iniciar timer
	timer_activo = true
	GestorSonidos.reproducir_disparo_bomber()
	var timer_disparo = buscar_nodo_por_tipo(self, "Timer")
	if timer_disparo:
		timer_disparo.wait_time = cadencia
		timer_disparo.start()
	
	reproducir_animacion_disparo()
	crear_proyectil(objetivo)

func crear_proyectil(objetivo):
	if not escena_proyectil:
		print("ERROR: No hay escena_proyectil")
		return
	
	print("Torre: ", global_position)
	print("Objetivo: ", objetivo.global_position)
	print("Radio torre: ", radio_area, "px")
	
	var proyectil = escena_proyectil.instantiate()
	get_parent().add_child(proyectil)
	proyectil.global_position = global_position
	
	if proyectil.has_method("configurar"):
		print("Configurando bomba con radio: ", radio_area, "px")
		proyectil.configurar(objetivo, danio, danio_area, radio_area)
	else:
		print("ERROR: Sin método configurar()")
	
	print("Bomba lanzada")


func _on_timer_disparo_timeout():
	print("Timer completado")
	timer_activo = false
	reproducir_animacion_idle()

func reproducir_animacion_idle():
	if not sprite_animado:
		return
	
	var nombre_animacion = "idle_" + str(nivel_actual)
	if sprite_animado.sprite_frames.has_animation(nombre_animacion):
		sprite_animado.play(nombre_animacion)

func reproducir_animacion_disparo():
	if not sprite_animado:
		return
	
	var nombre_animacion = "disparo_" + str(nivel_actual)
	if sprite_animado.sprite_frames.has_animation(nombre_animacion):
		sprite_animado.play(nombre_animacion)

func _on_area_deteccion_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos_clic = get_global_mouse_position()
		var distancia = global_position.distance_to(pos_clic)
		
		if distancia > 100:
			print("Clic a ", int(distancia), "px de torre Bomber - ignorando")
			return
		
		print("Clic en Torre Bomber")
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_panel_mejora"):
			# PASAR LA POSICIÓN GLOBAL DE LA TORRE
			hud.mostrar_panel_mejora(global_position, self)
			
func mejorar():
	if nivel_actual >= nivel_maximo:
		return false
	
	var costo = precio_base
	if GestorJuego.dinero < costo:
		return false
	
	GestorJuego.dinero -= costo
	nivel_actual += 1
	danio = danio * 1.5
	rango = rango * 1.2
	cadencia = cadencia * 0.8
	radio_area = radio_area * 1.2
	
	reproducir_animacion_idle()
	
	print("Torre mejorada a nivel ", nivel_actual)
	print("  Radio: ", radio_area, "px")
	
	return true

# Función para vender la torre
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
