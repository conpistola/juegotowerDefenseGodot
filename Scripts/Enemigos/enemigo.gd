extends PathFollow2D

# Script base para todos los enemigos del juego
# Controla movimiento por camino, vida, daño, muerte y recompensas

# Propiedades exportadas (se pueden modificar en el Inspector)
@export var velocidad: float = 80.0  # Velocidad de movimiento en píxeles por segundo
@export var vida_maxima: float = 50.0  # Vida máxima del enemigo
@export var dinero_al_morir: int = 20  # Dinero que da al jugador al morir
@export var es_volador: bool = false  # Si es volador (afecta qué torres pueden atacarlo)

# Variables internas
var vida_actual: float = 0.0
var esta_vivo: bool = true
var posicion_anterior: Vector2 = Vector2.ZERO
var primer_frame: bool = true

# Referencias a nodos hijos (se asignan en _ready)
var sprite_animado: AnimatedSprite2D
var barra_vida_fondo: TextureRect
var barra_vida_relleno: TextureRect

# Inicialización del enemigo
func _ready():
	# Configurar para que se pause cuando el juego esté pausado
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	var timer_idle = Timer.new()
	timer_idle.wait_time = randf_range(3.0, 8.0)  
	timer_idle.one_shot = false
	timer_idle.timeout.connect(_on_timer_idle_sonido)
	add_child(timer_idle)
	timer_idle.start()
	
	# Desactivar rotación automática
	rotates = false
	
	# NUEVO: Desactivar loop para que no vuelva al inicio
	loop = false
	
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
	
	# Registrar en el gestor de juego
	GestorJuego.registrar_enemigo_spawneado()
	
	# Iniciar animación por defecto
	if sprite_animado:
		sprite_animado.play("derecha")
	
	print("Enemigo spawneado con vida: ", vida_maxima)
	
# Proceso en cada frame
# Proceso en cada frame
func _process(delta):
	if not esta_vivo:
		return
	
	if primer_frame:
		posicion_anterior = global_position
		primer_frame = false
		return
	
	progress += velocidad * delta
	
	actualizar_animacion()
	if progress_ratio >= 1.0:
		print("PROGRESO >= 1.0 DETECTADO - Llamando llegar_al_final()")
		llegar_al_final()
		return  

# Actualizar la animación según la dirección de movimiento
func actualizar_animacion():
	if not sprite_animado:
		return
	
	# Calcular dirección del movimiento
	var direccion_movimiento = global_position - posicion_anterior
	
	# Si no hay movimiento significativo, no cambiar animación
	if direccion_movimiento.length() < 1.0:
		return
	
	# Actualizar posición anterior para el próximo frame
	posicion_anterior = global_position
	
	# Normalizar dirección
	direccion_movimiento = direccion_movimiento.normalized()
	
	# Usar componentes X e Y para determinar dirección de forma más simple
	var abs_x = abs(direccion_movimiento.x)
	var abs_y = abs(direccion_movimiento.y)
	
	# Determinar dirección predominante
	if abs_x > abs_y:
		# Movimiento horizontal predomina
		if direccion_movimiento.x > 0:
			# Derecha
			if sprite_animado.animation != "derecha":
				sprite_animado.play("derecha")
			sprite_animado.flip_h = false
		else:
			# Izquierda (usa la animación derecha volteada)
			if sprite_animado.animation != "derecha":
				sprite_animado.play("derecha")
			sprite_animado.flip_h = true
	else:
		# Movimiento vertical predomina
		sprite_animado.flip_h = false  # Sin voltear en vertical
		if direccion_movimiento.y > 0:
			# Abajo
			if sprite_animado.animation != "delante":
				sprite_animado.play("delante")
		else:
			# Arriba
			if sprite_animado.animation != "arriba":
				sprite_animado.play("arriba")

# Recibir daño de una torre o proyectil
func recibir_danio(cantidad: float):
	if not esta_vivo:
		return
	
	# Reducir vida
	vida_actual -= cantidad
	vida_actual = max(0, vida_actual)  # No permitir vida negativa
	GestorSonidos.reproducir_zombie_hurt()
	
	# Actualizar barra de vida
	actualizar_barra_vida()
	
	print("Enemigo recibió ", cantidad, " de daño. Vida restante: ", vida_actual)
	
	# Verificar si murió
	if vida_actual <= 0:
		morir()

# Actualizar la barra de vida visual
func actualizar_barra_vida():
	if not barra_vida_relleno:
		return
	
	# Calcular porcentaje de vida
	var porcentaje_vida = vida_actual / vida_maxima
	
	# Ajustar usando scale (método más efectivo para TextureRect)
	barra_vida_relleno.scale.x = porcentaje_vida
	
	# Ajustar posición para que se reduzca desde la derecha hacia la izquierda
	# El pivot debe estar en la izquierda (0, 0.5)
	barra_vida_relleno.pivot_offset = Vector2(0, barra_vida_relleno.size.y / 2.0)
	
# Enemigo muere
func morir():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	# Dar dinero al jugador
	GestorSonidos.reproducir_zombie_death()
	GestorJuego.registrar_enemigo_muerto(dinero_al_morir)
	
	print("Enemigo eliminado. Dinero otorgado: ", dinero_al_morir)
	
	# Reproducir animación de muerte (opcional: usar frame final)
	if sprite_animado:
		sprite_animado.stop()
	
	# Efecto visual de muerte (opcional: fade out)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


# Enemigo llega al final del camino
func llegar_al_final():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	print("Enemigo llegó al final. RESTANDO VIDA")
	
	# El jugador pierde una vida
	GestorJuego.restar_vida()
	
	# Eliminar el enemigo (diferir para asegurar que la señal se procesa)
	call_deferred("queue_free")

# Función para obtener la posición global del enemigo
func obtener_posicion() -> Vector2:
	return global_position

# Verificar si el enemigo es volador
func es_enemigo_volador() -> bool:
	return es_volador
	
func _on_timer_idle_sonido():
	# Reproducir sonido idle solo si el zombie está vivo
	if vida_actual > 0:
		GestorSonidos.reproducir_zombie_idle()
	
	# Cambiar el tiempo para el próximo sonido (aleatorio)
	if has_node("Timer"):
		get_node("Timer").wait_time = randf_range(3.0, 8.0)
