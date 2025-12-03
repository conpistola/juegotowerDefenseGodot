extends Camera2D

# Script de cámara SIN ZOOM - Tamaño fijo con límites MANUALES
# Se puede mover con WASD hasta las esquinas del mapa

# Velocidad de movimiento de la cámara
var velocidad = 500

# TAMAÑO DEL MAPA (ajustado para incluir el tile faltante)
var ancho_mapa = 2592  # 12 * 216 (un tile más)
var alto_mapa = 2808   # 13 * 216

# Tamaño de la ventana
var ancho_ventana = 1920
var alto_ventana = 1080

# Límites calculados
var limite_min_x = 0
var limite_max_x = 0
var limite_min_y = 0
var limite_max_y = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	zoom = Vector2(1.0, 1.0)
	
	var mitad_ancho = ancho_ventana / 2.0
	var mitad_alto = alto_ventana / 2.0
	
	limite_min_x = mitad_ancho
	limite_max_x = ancho_mapa - mitad_ancho
	limite_min_y = mitad_alto
	limite_max_y = alto_mapa - mitad_alto
	
	# Centrar la cámara
	position = Vector2(ancho_mapa / 2.0, alto_mapa / 2.0)
	

func _process(delta):
	if get_tree().paused:
		return
	
	# Movimiento con WASD
	var direccion = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direccion.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direccion.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direccion.y -= 1
	
	# Aplicar movimiento
	if direccion.length() > 0:
		direccion = direccion.normalized()
		position += direccion * velocidad * delta
		
		# APLICAR LÍMITES MANUALMENTE
		position.x = clamp(position.x, limite_min_x, limite_max_x)
		position.y = clamp(position.y, limite_min_y, limite_max_y)
