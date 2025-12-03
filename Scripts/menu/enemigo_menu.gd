extends "res://Scripts/Enemigos/enemigo.gd"

# Script para enemigos en el menú
# Sobrescribe funciones que usan GestorJuego para que funcionen sin él

func _ready():
	# Configurar para que funcione sin pausas
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Desactivar rotación automática
	rotates = false
	
	# Inicializar vida al máximo
	vida_actual = vida_maxima
	
	# Obtener referencias a los nodos hijos
	sprite_animado = get_node("AnimatedSprite2D")
	barra_vida_fondo = get_node("BarraVida/Fondo")
	barra_vida_relleno = get_node("BarraVida/Relleno")
	
	# Configurar la barra de vida inicial
	actualizar_barra_vida()
	
	# Añadir al grupo de enemigos
	add_to_group("enemigos")
	
	# NO registrar en GestorJuego (no existe en el menú)
	
	# Iniciar animación por defecto
	if sprite_animado:
		sprite_animado.play("derecha")
	
	print("Enemigo de menú spawneado")

func morir():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	# NO dar dinero (no hay GestorJuego en el menú)
	
	print("Enemigo de menú eliminado")
	
	# Efecto visual de muerte
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func llegar_al_final():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	# NO restar vida (no hay GestorJuego en el menú)
	
	print("Enemigo de menú llegó al final")
	
	# Simplemente eliminar
	queue_free()
