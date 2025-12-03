extends Area2D

# Variables del proyectil
var objetivo = null
var danio: float = 25.0
var velocidad: float = 400.0
var danio_area: bool = true
var radio_area: float = 200.0
var ha_explotado: bool = false

func _ready():
	# Configurar colisiones
	collision_layer = 4  # Capa de proyectiles
	collision_mask = 2   # Máscara de enemigos
	
	# Conectar señal de colisión
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	print("Proyectil bomba creado")

func configurar(enemigo_objetivo, danio_torre: float, area: bool = true, radio: float = 200.0):
	objetivo = enemigo_objetivo
	danio = danio_torre
	danio_area = area
	radio_area = radio
	

func _process(delta):
	if ha_explotado:
		return
	
	# Verificar si el objetivo sigue siendo válido
	if not objetivo or not is_instance_valid(objetivo) or not objetivo.esta_vivo:
		print("Objetivo perdido, destruyendo bomba")
		queue_free()
		return
	
	# Calcular dirección hacia el objetivo
	var direccion = global_position.direction_to(objetivo.global_position)
	
	# Mover el proyectil
	global_position += direccion * velocidad * delta
	
	# Rotar el proyectil hacia el objetivo
	rotation = direccion.angle()
	
	# Verificar si llegó al objetivo (distancia menor a 50 píxeles)
	var distancia = global_position.distance_to(objetivo.global_position)
	if distancia < 50:
		explotar()

func _on_body_entered(body):
	if ha_explotado:
		return
	
	if body.is_in_group("enemigos"):
		print("Bomba impactó directamente con enemigo")
		explotar()

func explotar():
	if ha_explotado:
		return
	
	ha_explotado = true
	
	
	# Crear efecto visual de explosión
	crear_efecto_explosion()
	
	if danio_area:
		# Buscar enemigos en área
		var enemigos_afectados = buscar_enemigos_en_area()
		print("Enemigos encontrados en radio: ", enemigos_afectados.size())
		
		for enemigo in enemigos_afectados:
			if is_instance_valid(enemigo) and enemigo.esta_vivo:
				var distancia = global_position.distance_to(enemigo.global_position)
				print("  - Enemigo a ", distancia, "px - Aplicando daño: ", danio)
				if enemigo.has_method("recibir_danio"):
					enemigo.recibir_danio(danio)
	else:
		# Solo dañar al objetivo directo
		if objetivo and is_instance_valid(objetivo) and objetivo.esta_vivo:
			if objetivo.has_method("recibir_danio"):
				objetivo.recibir_danio(danio)
	
	
	# Destruir el proyectil después de un breve delay
	await get_tree().create_timer(0.3).timeout
	queue_free()

func buscar_enemigos_en_area():
	var enemigos_cercanos = []
	var todos_enemigos = get_tree().get_nodes_in_group("enemigos")
	
	for enemigo in todos_enemigos:
		if is_instance_valid(enemigo) and enemigo.esta_vivo:
			var distancia = global_position.distance_to(enemigo.global_position)
			if distancia <= radio_area:
				enemigos_cercanos.append(enemigo)
	
	return enemigos_cercanos

func crear_efecto_explosion():
	# Crear círculo naranja (explosión externa)
	var circulo_externo = MeshInstance2D.new()
	var mesh_externo = QuadMesh.new()
	mesh_externo.size = Vector2(radio_area * 2, radio_area * 2)
	circulo_externo.mesh = mesh_externo
	
	var material_externo = CanvasItemMaterial.new()
	material_externo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	circulo_externo.material = material_externo
	circulo_externo.modulate = Color(1.0, 0.5, 0.0, 0.6)  # Naranja
	
	get_parent().add_child(circulo_externo)
	circulo_externo.global_position = global_position
	
	# Crear círculo verde (área de daño)
	var circulo_interno = MeshInstance2D.new()
	var mesh_interno = QuadMesh.new()
	mesh_interno.size = Vector2(radio_area * 2, radio_area * 2)
	circulo_interno.mesh = mesh_interno
	
	var material_interno = CanvasItemMaterial.new()
	material_interno.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	circulo_interno.material = material_interno
	circulo_interno.modulate = Color(0.0, 1.0, 0.0, 0.4)  # Verde
	
	get_parent().add_child(circulo_interno)
	circulo_interno.global_position = global_position
	
	print("Efecto visual creado - Radio: ", radio_area, "px")
	
	# Animar y destruir efectos
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(circulo_externo, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(circulo_externo, "modulate:a", 0.0, 0.3)
	tween.tween_property(circulo_interno, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_property(circulo_interno, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	circulo_externo.queue_free()
	circulo_interno.queue_free()
