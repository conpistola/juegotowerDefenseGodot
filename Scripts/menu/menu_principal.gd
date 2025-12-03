extends Control

# Script del menú principal
# Controla la navegación y los botones del menú

# Referencias a botones
@onready var boton_jugar = $ContenedorUI/VBoxContainer/BotonJugar
@onready var boton_opciones = $ContenedorUI/VBoxContainer/BotonOpciones
@onready var boton_salir = $ContenedorUI/VBoxContainer/BotonSalir

func _ready():
	# Conectar señales de botones
	boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	boton_opciones.pressed.connect(_on_boton_opciones_pressed)
	boton_salir.pressed.connect(_on_boton_salir_pressed)
	
	# Asegurar que funcione siempre (sin pausas)
	process_mode = Node.PROCESS_MODE_ALWAYS
	GestorMusica.reproducir_musica("menu", true)
	print("=== MENÚ PRINCIPAL CARGADO ===")

func _on_boton_jugar_pressed():
	print("Iniciando juego...")
	# Cambiar a la escena del juego (mapa_01)
	get_tree().change_scene_to_file("res://escenas/Mapas/mapa_01.tscn")

func _on_boton_opciones_pressed():
	print("Botón Opciones presionado")
	# Aquí puedes crear una escena de opciones después
	print("(Opciones no implementadas aún)")

func _on_boton_salir_pressed():
	print("Saliendo del juego...")
	# Cerrar el juego
	get_tree().quit()
