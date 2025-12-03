extends "res://Scripts/Torres/torre_base.gd"


func _ready():
	arquero = get_node_or_null("francotirador")
	
	if not arquero:
		print("ERROR CRÍTICO: No se encontró el nodo francotirador")
	else:
		print("Nodo francotirador cargado correctamente")
		
		# FORZAR LOOP EN LA ANIMACIÓN IDLE
		if arquero.sprite_frames:
			arquero.sprite_frames.set_animation_loop("idle", true)
			print("Loop de idle activado para franco")
	
	# Configurar propiedades específicas del franco
	tipo_torre = "sniper"
	danio = 50.0
	rango = 900.0
	cadencia = 3.0
	precio_base = 500
	puede_atacar_voladores = true
	ataque_multiple = false
	danio_area = false
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Torre Franco (Sniper) creada - Danio: ", danio, " | Rango: ", rango)

# Sobrescribir el mapeo de animaciones para el franco
func obtener_animacion_y_flip(objetivo) -> Dictionary:
	if not objetivo:
		return {"animacion": "idle", "flip": false}
	
	# Calcular dirección hacia el enemigo
	var direccion = global_position.direction_to(objetivo.global_position)
	var angulo = direccion.angle()
	
	# Convertir radianes a grados (0-360)
	var grados = rad_to_deg(angulo)
	if grados < 0:
		grados += 360
	
	var animacion = "disparar_izquierda"
	var flip = false
	
	# Mapeo específico para las animaciones del franco
	# El franco tiene: disparar_arriba_derecha (NO arriba_izquierda)
	
	if grados >= 337.5 or grados < 22.5:
		# DERECHA (0°)
		animacion = "disparar_izquierda"
		flip = true
	elif grados >= 22.5 and grados < 67.5:
		# ABAJO-DERECHA (45°)
		animacion = "disparar_abajo_izquierda"
		flip = true
	elif grados >= 67.5 and grados < 112.5:
		# ABAJO (90°)
		animacion = "disparar_abajo"
		flip = false
	elif grados >= 112.5 and grados < 157.5:
		# ABAJO-IZQUIERDA (135°)
		animacion = "disparar_abajo_izquierda"
		flip = false
	elif grados >= 157.5 and grados < 202.5:
		# IZQUIERDA (180°)
		animacion = "disparar_izquierda"
		flip = false
	elif grados >= 202.5 and grados < 247.5:
		# ARRIBA-IZQUIERDA (225°)
		animacion = "disparar_arriba_derecha"
		flip = true
	elif grados >= 247.5 and grados < 292.5:
		# ARRIBA (270°)
		animacion = "disparar_arriba"
		flip = false
	elif grados >= 292.5 and grados < 337.5:
		# ARRIBA-DERECHA (315°)
		animacion = "disparar_arriba_derecha"
		flip = false
	
	return {"animacion": animacion, "flip": flip}
