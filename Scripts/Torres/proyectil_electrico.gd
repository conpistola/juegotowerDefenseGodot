extends Area2D

# Proyectil eléctrico que salta entre enemigos creando efecto de cadena

var velocidad: float = 600.0
var danio: float = 15.0
var objetivo_actual = null
var objetivos_alcanzados = []
var max_saltos: int = 3
var radio_salto: float = 200.0
var saltos_realizados: int = 0

var sprite = null

func _ready():
	# Buscar el sprite manualmente
	sprite = get_node_or_null("SpriteBomba")
	
	if not sprite:
		print("ERROR: No se encontró SpriteBomba")
		print("Hijos disponibles:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("Sprite encontrado: ", sprite.name)
	
	# Configurar colisión
	set_collision_layer_value(3, true)  # Capa de proyectiles
	set_collision_mask_value(2, true)   # Detecta enemigos
	
	# Añadir al grupo de proyectiles
	add_to_group("proyectiles")
	
	print("Proyectil eléctrico creado")

func configurar(objetivo, danio_torre: float, _danio_area: bool = false, _radio_area: float = 0):
	self.objetivo_actual = objetivo
	self.danio = danio_torre
	
	# Añadir el primer objetivo a la lista de alcanzados
	if objetivo:
		objetivos_alcanzados.append(objetivo)
	
	print("Proyectil eléctrico configurado hacia: ", objetivo.name if objetivo else "null")

func _process(delta):
	# Verificar que el sprite esté cargado
	if not sprite:
		sprite = get_node_or_null("SpriteBomba")
	
	if not objetivo_actual or not is_instance_valid(objetivo_actual):
		# Si no hay objetivo, destruir el proyectil
		queue_free()
		return
	
	# Verificar si el objetivo sigue vivo
	if not objetivo_actual.esta_vivo:
		# Buscar siguiente objetivo
		buscar_siguiente_objetivo()
		return
	
	# Calcular dirección hacia el objetivo
	var direccion = global_position.direction_to(objetivo_actual.global_position)
	
	# Mover el proyectil
	global_position += direccion * velocidad * delta
	
	# Rotar el sprite hacia el objetivo
	if sprite and is_instance_valid(sprite):
		sprite.rotation = direccion.angle()
	
	# Verificar si llegó al objetivo
	var distancia = global_position.distance_to(objetivo_actual.global_position)
	if distancia < 40:  # Aumentado a 40px para mejor detección
		impactar_objetivo()

func impactar_objetivo():
	if not objetivo_actual or not is_instance_valid(objetivo_actual):
		queue_free()
		return
	
	print("⚡ Proyectil eléctrico impactó objetivo")
	
	# Hacer daño al objetivo actual
	if objetivo_actual.has_method("recibir_danio"):
		objetivo_actual.recibir_danio(danio)
	
	# Crear efecto visual de destello en el impacto
	crear_destello_impacto()
	
	# Incrementar contador de saltos
	saltos_realizados += 1
	
	# Verificar si puede seguir saltando
	if saltos_realizados >= max_saltos:
		print("Proyectil eléctrico alcanzó máximo de saltos (", max_saltos, ")")
		queue_free()
		return
	
	# Buscar siguiente objetivo cercano
	buscar_siguiente_objetivo()

func buscar_siguiente_objetivo():
	if not objetivo_actual or not is_instance_valid(objetivo_actual):
		queue_free()
		return
	
	var posicion_busqueda = objetivo_actual.global_position
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	var enemigo_mas_cercano = null
	var distancia_minima = radio_salto
	
	for enemigo in enemigos:
		# Verificar que el enemigo está vivo
		if not enemigo.esta_vivo:
			continue
		
		# Verificar que no lo hemos alcanzado ya
		if enemigo in objetivos_alcanzados:
			continue
		
		# Calcular distancia desde la posición del objetivo actual
		var distancia = posicion_busqueda.distance_to(enemigo.global_position)
		
		# Buscar el más cercano dentro del radio de salto
		if distancia < distancia_minima:
			distancia_minima = distancia
			enemigo_mas_cercano = enemigo
	
	if enemigo_mas_cercano:
		print("⚡ Proyectil saltando a nuevo objetivo (salto ", saltos_realizados + 1, "/", max_saltos, ")")
		
		# Crear efecto visual de rayo entre objetivos
		crear_rayo_entre_objetivos(objetivo_actual, enemigo_mas_cercano)
		
		# Actualizar objetivo
		objetivo_actual = enemigo_mas_cercano
		objetivos_alcanzados.append(enemigo_mas_cercano)
	else:
		# No hay más objetivos cercanos
		print("Proyectil eléctrico: no hay más objetivos cerca")
		queue_free()

func crear_rayo_entre_objetivos(origen, destino):
	if not origen or not destino:
		return
	
	if not is_instance_valid(origen) or not is_instance_valid(destino):
		return
	
	var linea = Line2D.new()
	get_parent().add_child(linea)
	
	# Configurar el rayo eléctrico
	linea.add_point(origen.global_position)
	linea.add_point(destino.global_position)
	linea.width = 5.0
	linea.default_color = Color(0.4, 0.8, 1.0, 1.0)  # Azul eléctrico brillante
	linea.z_index = 10
	
	# Efecto de parpadeo rápido
	var tween = create_tween()
	tween.tween_property(linea, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): 
		if is_instance_valid(linea):
			linea.queue_free()
	)

func crear_destello_impacto():
	# Crear un círculo brillante temporal en el punto de impacto
	var destello = Node2D.new()
	get_parent().add_child(destello)
	destello.global_position = global_position
	destello.z_index = 11
	
	# Usar queue_redraw para dibujar el círculo
	var circle_sprite = Sprite2D.new()
	destello.add_child(circle_sprite)
	circle_sprite.modulate = Color(0.5, 0.9, 1.0, 0.8)
	circle_sprite.scale = Vector2(2, 2)
	
	# Animar y eliminar
	var tween = create_tween()
	tween.tween_property(circle_sprite, "scale", Vector2(4, 4), 0.2)
	tween.parallel().tween_property(circle_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(destello):
			destello.queue_free()
	)

func _on_body_entered(body):
	pass
