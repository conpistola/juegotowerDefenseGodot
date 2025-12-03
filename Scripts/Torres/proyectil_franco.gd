extends Area2D

# Proyectil de franco (sniper) - Bala rápida que persigue al objetivo

# Variables de configuración
var objetivo = null
var danio: float = 50.0
var velocidad: float = 800.0
var danio_area: bool = false
var radio_area: float = 0.0

# Variables internas
var direccion: Vector2 = Vector2.ZERO
var distancia_maxima: float = 2000.0
var distancia_recorrida: float = 0.0

@onready var sprite = $SpriteFranco

func _ready():
	# Añadir al grupo de proyectiles
	add_to_group("proyectiles")
	
	# Configurar la capa de colisión
	collision_layer = 4  # Capa 3 (proyectiles)
	collision_mask = 2   # Detecta capa 2 (enemigos)
	
	# Conectar señales de colisión
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	print("Proyectil franco creado en: ", global_position)

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
		if sprite:
			sprite.rotation = direccion.angle()
	
	# Autodestruirse si recorrió mucha distancia
	if distancia_recorrida > distancia_maxima:
		queue_free()

# Configurar el proyectil desde la torre
func configurar(enemigo_objetivo, danio_torre: float, area: bool = false, radio: float = 0.0):
	objetivo = enemigo_objetivo
	danio = danio_torre
	danio_area = area
	radio_area = radio
	
	print("Proyectil franco configurado - Objetivo: ", objetivo, " | Danio: ", danio)
	
	# Calcular dirección inicial
	if objetivo and is_instance_valid(objetivo):
		direccion = global_position.direction_to(objetivo.global_position)
		if sprite:
			sprite.rotation = direccion.angle()

# Cuando colisiona con un área
func _on_area_entered(area):
	# Ignorar AreaDeteccion de torres
	if area.name == "AreaDeteccion":
		return
	
	# Verificar si el padre es un enemigo
	var padre = area.get_parent()
	if padre and is_instance_valid(padre) and padre.is_in_group("enemigos"):
		impactar(padre)

# Cuando colisiona con un cuerpo
func _on_body_entered(body):
	if is_instance_valid(body) and body.is_in_group("enemigos"):
		impactar(body)

# Hacer daño al impactar
func impactar(enemigo):
	if not enemigo or not is_instance_valid(enemigo):
		queue_free()
		return
	
	# Daño directo
	if enemigo.esta_vivo:
		enemigo.recibir_danio(danio)
	
	# Destruir el proyectil
	queue_free()
