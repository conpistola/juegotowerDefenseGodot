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
	
	# Registrar en el gestor de juego
	GestorJuego.registrar_enemigo_spawneado()
	
	# Iniciar animación por defecto
	if sprite_animado:
		sprite_animado.play("derecha")
	
	print("Enemigo spawneado con vida: ", vida_maxima)

# Proceso en cada frame
func _process(delta):
	if not esta_vivo:
		return
	
	# En el primer frame, solo guardar posición
	if primer_frame:
		posicion_anterior = global_position
		primer_frame = false
		return
	
	# Mover al enemigo a lo largo del camino
	progress += velocidad * delta
	
	# Actualizar animación según dirección de movimiento
	actualizar_animacion()
	
	# Verificar si llegó al final del camino
	if progress_ratio >= 1.0:
		llegar_al_final()

# Actualizar la animación según la dirección de movimiento
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
	
	# Ajustar el tamaño de la barra roja según la vida actual
	# Mantener la altura original pero reducir el ancho
	var ancho_original = barra_vida_fondo.size.x
	barra_vida_relleno.size.x = ancho_original * porcentaje_vida

# Enemigo muere
func morir():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	# Dar dinero al jugador
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
	
	# El jugador pierde una vida
	GestorJuego.perder_vida()
	
	print("Enemigo llegó al final. Vida perdida.")
	
	# Eliminar el enemigo
	queue_free()

# Función para obtener la posición global del enemigo
func obtener_posicion() -> Vector2:
	return global_position

# Verificar si el enemigo es volador
func es_enemigo_volador() -> bool:
	return es_volador
