extends Area2D

# Script simple para los placeholders de torres
# Permite mejorar la torre y cambiar su apariencia

var tipo_torre: String = ""
var esta_mejorada: bool = false
var coordenadas_tile: Vector2i
var mapa_referencia = null  # Referencia al mapa
var datos_tile_original: Dictionary = {}  # Datos del tile que se borró al construir

func _ready():
	print("Tipo: ", tipo_torre)
	print("Posición: ", global_position)
	print("input_pickable: ", input_pickable)
	
	# Asegurar configuración
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_pickable = true
	
	# Conectar señal de input
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
		print("Señal input_event conectada")

func _on_input_event(viewport, event, shape_idx):
	print("Tipo de evento: ", event)
	
	# Detectar clic izquierdo
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Tipo torre: ", tipo_torre)
		print("Posición: ", global_position)
		
		# Buscar el HUD
		var hud = get_tree().get_first_node_in_group("hud")
		
		if hud:
			print("HUD encontrado, abriendo panel de mejora...")
			hud.mostrar_panel_mejora(get_viewport().get_mouse_position(), self)
			
			# CONSUMIR EL EVENTO para que no llegue a _unhandled_input
			get_viewport().set_input_as_handled()
			print("Evento marcado como manejado")
		else:
			print("ERROR: HUD no encontrado")

func mejorar():
	if esta_mejorada:
		print("Torre ya mejorada")
		return
	
	esta_mejorada = true
	
	# Cambiar el color a uno más brillante
	var visual = get_node_or_null("ColorRect")
	if visual and visual is ColorRect:
		visual.color = Color(visual.color.r * 1.5, visual.color.g * 1.5, visual.color.b * 1.5, 0.9)
		print("Torre ", tipo_torre, " mejorada visualmente")
	
	# Actualizar el label
	var label = get_node_or_null("Label")
	if label and label is Label:
		label.text = tipo_torre.capitalize() + " [MAX]"
