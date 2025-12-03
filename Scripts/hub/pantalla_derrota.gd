extends CanvasLayer

# Referencias
@onready var boton_menu = $ColorRect/CenterContainer/PanelCartel/BotonMenu

func _ready():
	# Verificar que el botón existe
	if not boton_menu:
		push_error("No se encontró el botón en la ruta especificada")
		return
	
	# Conectar señal del botón
	boton_menu.pressed.connect(_on_boton_menu_pressed)
	
	# Pausar el juego
	get_tree().paused = true
	
	# Configurar process_mode para que funcione durante pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_boton_menu_pressed():
	# Despausar antes de cambiar escena
	get_tree().paused = false
	
	# Resetear el juego en GestorJuego (solo variables)
	GestorJuego.reiniciar_juego()
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://escenas/Mapas/menu/menuPrincipal.tscn")
