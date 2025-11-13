extends Camera2D

# Script para controlar la cámara con movimiento WASD y zoom con rueda del mouse

# Velocidad de movimiento de la cámara
@export var velocidad_movimiento: float = 500.0

# Velocidad del zoom
@export var velocidad_zoom: float = 0.1

# Límites de zoom
@export var zoom_minimo: float = 0.8
@export var zoom_maximo: float = 2.5

func _ready():
	# Centrar cámara al inicio
	position = Vector2(1187, 1295)
	
	# Zoom inicial
	zoom = Vector2(1.0, 1.0)
	
	# Configurar límites fijos - método simple
	position_smoothing_enabled = true

func _process(delta):
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
	
	# Normalizar dirección
	if direccion.length() > 0:
		direccion = direccion.normalized()
	
	# Aplicar movimiento
	position += direccion * velocidad_movimiento * delta
	
	position.x = clamp(position.x, 960, 1320)
	position.y = clamp(position.y, 540, 2140)

func _input(event):
	# Zoom con rueda del mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(velocidad_zoom, velocidad_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(velocidad_zoom, velocidad_zoom)
		
		# Limitar el zoom
		zoom.x = clamp(zoom.x, zoom_minimo, zoom_maximo)
		zoom.y = clamp(zoom.y, zoom_minimo, zoom_maximo)
