extends Area2D

# Script del proyectil que viaja hacia el enemigo y hace daño

# Variables de configuración
var objetivo = null
var danio: float = 10.0
var velocidad: float = 600.0  # Velocidad aumentada para que sea más rápida
var danio_area: bool = false
var radio_area: float = 100.0

# Variables internas
var direccion: Vector2 = Vector2.ZERO
var distancia_maxima: float = 1500.0
var distancia_recorrida: float = 0.0

func _ready():
	# Añadir al grupo de proyectiles
	add_to_group("proyectiles")
	
	# Configurar la capa de colisión
	collision_layer = 4  # Capa 3 (proyectiles)
	collision_mask = 2   # Detecta capa 2 (enemigos)
	
	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	print("Proyectil creado en: ", global_position)

func _process(delta):
	# Si el objetivo está muerto o no existe, seguir en línea recta
	if not objetivo or not is_instance_valid(objetivo) or not objetivo.esta_vivo:
		# Continuar en la dirección original
		position += direccion * velocidad * delta
		distancia_recorrida += velocidad * delta
	else:
		# Perseguir al objetivo actualizando la dirección
		direccion = global_position.direction_to(objetivo.global_position)
		position += direccion * velocidad * delta
		distancia_recorrida += velocidad * delta
		
		# Rotar el sprite hacia la dirección de movimiento
		rotation = direccion.angle()
	
	# Autodestruirse si recorrió mucha distancia
	if distancia_recorrida > distancia_maxima:
		print("Proyectil se autodestruye por distancia")
		queue_free()

# Configurar el proyectil desde la torre
func configurar(enemigo_objetivo, danio_torre: float, area: bool = false, radio: float = 100.0):
	objetivo = enemigo_objetivo
	danio = danio_torre
	danio_area = area
	radio_area = radio
	
	print("Proyectil configurado - Objetivo: ", objetivo, " | Daño: ", danio)
	
	# Calcular dirección inicial
	if objetivo and is_instance_valid(objetivo):
		direccion = global_position.direction_to(objetivo.global_position)
		rotation = direccion.angle()
		print("Dirección inicial: ", direccion)

# Cuando colisiona con un enemigo (Area2D)
func _on_area_entered(area):
	print("Proyectil colisionó con área: ", area)
	# Verificar si el padre es un enemigo
	var padre = area.get_parent()
	if padre and is_instance_valid(padre) and padre.is_in_group("enemigos"):
		print("¡Impacto con enemigo!")
		impactar(padre)

# Cuando colisiona con un cuerpo
func _on_body_entered(body):
	print("Proyectil colisionó con body: ", body)
	if is_instance_valid(body) and body.is_in_group("enemigos"):
		print("¡Impacto con enemigo!")
		impactar(body)

# Hacer daño al impactar
func impactar(enemigo):
	if not enemigo or not is_instance_valid(enemigo):
		print("Enemigo no válido, destruyendo proyectil")
		queue_free()
		return
	
	print("Impactando enemigo...")
	
	# Si hace daño en área (bomber)
	if danio_area:
		hacer_danio_area(enemigo.global_position)
	else:
		# Daño directo
		if enemigo.esta_vivo:
			enemigo.recibir_danio(danio)
			print("Daño aplicado: ", danio)
	
	# Destruir el proyectil
	queue_free()

# Hacer daño en área (para torre bomber)
func hacer_danio_area(centro: Vector2):
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	for enemigo in enemigos:
		if not is_instance_valid(enemigo) or not enemigo.esta_vivo:
			continue
		
		var distancia = centro.distance_to(enemigo.global_position)
		
		if distancia <= radio_area:
			enemigo.recibir_danio(danio)
