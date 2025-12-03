extends Node

# Gestor de Oleadas
# Controla el spawn de enemigos, progresión de oleadas y tiempos de descanso

# Señales para comunicar eventos
signal oleada_iniciada(numero_oleada)
signal oleada_completada(numero_oleada)
signal todas_oleadas_completadas

# Referencias a escenas de enemigos
var escena_zombie_normal = preload("res://escenas/Enemigo/zombie_normal.tscn")
var escena_zombie_escudo = preload("res://escenas/Enemigo/zombie_escudo.tscn")
var escena_zombie_gorro = preload("res://escenas/Enemigo/zombie_gorro.tscn")
var escena_zombie_volador = preload("res://escenas/Enemigo/zombie_volador.tscn")
var escena_zombie_volador_pro = preload("res://escenas/Enemigo/zombie_volador_pro.tscn")
var escena_zombie_cono = preload("res://escenas/Enemigo/zombie_cono.tscn")
var escena_zombie_cacerola = preload("res://escenas/Enemigo/zombie_cacerola.tscn")
var escena_zombie_futbol = preload("res://escenas/Enemigo/zombie_futbol.tscn")

# Variables de control de oleadas
var oleada_actual: int = 0
var oleadas_totales: int = 10
var oleada_en_progreso: bool = false
var enemigos_por_spawnear: Array = []
var indice_spawn_actual: int = 0

# Variables de tiempo
var tiempo_entre_spawns: float = 1.0
var tiempo_descanso: float = 10.0
var tiempo_descanso_restante: float = 0.0

# Referencias a nodos del mapa
var caminos: Array = []  # Array con todos los caminos del mapa
var hud: CanvasLayer = null  # Referencia al HUD
var indice_camino_actual: int = 0  # Para alternar entre caminos

# Timers
var timer_spawn: Timer
var timer_descanso: Timer

func _ready():
	# Crear timers
	timer_spawn = Timer.new()
	timer_spawn.one_shot = true
	add_child(timer_spawn)
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	
	timer_descanso = Timer.new()
	timer_descanso.one_shot = false
	add_child(timer_descanso)
	timer_descanso.timeout.connect(_on_timer_descanso_timeout)
	
	print("Gestor de Oleadas inicializado")

func inicializar(array_caminos: Array, hud_referencia = null):
	# Guardar todos los caminos en el array
	caminos = array_caminos
	hud = hud_referencia
	
	# Validar que haya al menos un camino
	if caminos.size() == 0:
		push_error("ERROR: No se proporcionaron caminos al gestor de oleadas")
		return
	
	print("=== GESTOR DE OLEADAS INICIALIZADO ===")
	print("Cantidad de caminos: ", caminos.size())
	for i in range(caminos.size()):
		print("  - Camino ", i + 1, ": ", caminos[i].name)
	
	if hud:
		print("HUD asignado al gestor de oleadas")

func iniciar_oleada(numero: int):
	if oleada_en_progreso:
		print("Ya hay una oleada en progreso")
		return
	
	oleada_actual = numero
	oleada_en_progreso = true
	indice_spawn_actual = 0
	
	print("▶▶▶ GESTOR_OLEADAS: Iniciando oleada ", numero)
	print("▶▶▶ Llamando a GestorJuego.cambiar_oleada(", numero, ")")
	
	# NUEVO: Actualizar GestorJuego para que emita la señal y actualice el HUD
	GestorJuego.cambiar_oleada(numero)
	
	print("▶▶▶ GestorJuego.oleada_actual ahora es: ", GestorJuego.oleada_actual)
	
	# Ocultar cuenta regresiva cuando inicia la oleada
	if hud:
		hud.ocultar_cuenta_regresiva()
	
	# Configurar enemigos de la oleada
	configurar_oleada(numero)
	
	# Emitir señal
	emit_signal("oleada_iniciada", numero)
	
	print("=== OLEADA ", numero, " INICIADA ===")
	print("Enemigos a spawnear: ", enemigos_por_spawnear.size())
	
	# Iniciar spawn del primer enemigo
	if enemigos_por_spawnear.size() > 0:
		timer_spawn.start(0.5)
		
func configurar_oleada(numero: int):
	enemigos_por_spawnear.clear()
	
	match numero:
		1:
			# Oleada 1: 10 zombies normales
			tiempo_entre_spawns = 1.0
			for i in range(10):
				enemigos_por_spawnear.append(escena_zombie_normal)
		
		2:
			# Oleada 2: 15 zombies normales
			tiempo_entre_spawns = 0.9
			for i in range(15):
				enemigos_por_spawnear.append(escena_zombie_normal)
		
		3:
			# Oleada 3: 12 normales + 3 escudo
			tiempo_entre_spawns = 0.8
			for i in range(12):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(3):
				enemigos_por_spawnear.append(escena_zombie_escudo)
		
		4:
			# Oleada 4: 10 normales + 5 gorro
			tiempo_entre_spawns = 0.8
			for i in range(10):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(5):
				enemigos_por_spawnear.append(escena_zombie_gorro)
		
		5:
			# Oleada 5: 8 normales + 4 volador
			tiempo_entre_spawns = 0.7
			for i in range(8):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(4):
				enemigos_por_spawnear.append(escena_zombie_volador)
		
		6:
			# Oleada 6: 15 normales + 5 escudo + 3 volador
			tiempo_entre_spawns = 0.7
			for i in range(15):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(5):
				enemigos_por_spawnear.append(escena_zombie_escudo)
			for i in range(3):
				enemigos_por_spawnear.append(escena_zombie_volador)
		
		7:
			# Oleada 7: 10 normales + 6 cono
			tiempo_entre_spawns = 0.6
			for i in range(10):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(6):
				enemigos_por_spawnear.append(escena_zombie_cono)
		
		8:
			# Oleada 8: 8 normales + 5 cacerola + 3 volador pro
			tiempo_entre_spawns = 0.6
			for i in range(8):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(5):
				enemigos_por_spawnear.append(escena_zombie_cacerola)
			for i in range(3):
				enemigos_por_spawnear.append(escena_zombie_volador_pro)
		
		9:
			# Oleada 9: 20 normales + 8 cono + 5 cacerola
			tiempo_entre_spawns = 0.5
			for i in range(20):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(8):
				enemigos_por_spawnear.append(escena_zombie_cono)
			for i in range(5):
				enemigos_por_spawnear.append(escena_zombie_cacerola)
		
		10:
			# Oleada 10 FINAL: 15 normales + 10 futbol + 5 volador pro
			tiempo_entre_spawns = 0.5
			for i in range(15):
				enemigos_por_spawnear.append(escena_zombie_normal)
			for i in range(10):
				enemigos_por_spawnear.append(escena_zombie_futbol)
			for i in range(5):
				enemigos_por_spawnear.append(escena_zombie_volador_pro)
	
	# Mezclar el orden de spawn para variedad
	enemigos_por_spawnear.shuffle()

func spawnear_siguiente_enemigo():
	if indice_spawn_actual >= enemigos_por_spawnear.size():
		# Ya se spawnearon todos los enemigos de esta oleada
		print("Todos los enemigos de la oleada ", oleada_actual, " han sido spawneados")
		return
	
	# Validar que haya caminos disponibles
	if caminos.size() == 0:
		push_error("ERROR: No hay caminos disponibles para spawnear enemigos")
		return
	
	# Obtener la escena del enemigo
	var escena_enemigo = enemigos_por_spawnear[indice_spawn_actual]
	
	# Instanciar enemigo
	var enemigo = escena_enemigo.instantiate()
	
	# Seleccionar camino (rotar entre todos los caminos disponibles)
	var camino_seleccionado = caminos[indice_camino_actual]
	indice_camino_actual = (indice_camino_actual + 1) % caminos.size()  # Rotar al siguiente
	
	# Agregar el enemigo al camino seleccionado
	camino_seleccionado.add_child(enemigo)
	
	print("Enemigo spawneado en ", camino_seleccionado.name, " (", indice_spawn_actual + 1, "/", enemigos_por_spawnear.size(), ")")
	
	# Incrementar índice
	indice_spawn_actual += 1
	
	# Si quedan más enemigos, programar el siguiente spawn
	if indice_spawn_actual < enemigos_por_spawnear.size():
		timer_spawn.start(tiempo_entre_spawns)

func verificar_oleada_completada():
	# Verificar si quedan enemigos vivos en el mapa
	var enemigos_vivos = get_tree().get_nodes_in_group("enemigos")
	
	if enemigos_vivos.size() == 0 and indice_spawn_actual >= enemigos_por_spawnear.size():
		# Oleada completada
		oleada_en_progreso = false
		emit_signal("oleada_completada", oleada_actual)
		print("=== OLEADA ", oleada_actual, " COMPLETADA ===")
		
		# Verificar si era la última oleada
		if oleada_actual >= oleadas_totales:
			print("¡¡¡TODAS LAS OLEADAS COMPLETADAS!!!")
			emit_signal("todas_oleadas_completadas")
			
			# NUEVO: Llamar a GestorJuego para verificar victoria o siguiente mapa
			GestorJuego.verificar_victoria_oleada()
		else:
			# Iniciar descanso antes de la siguiente oleada
			iniciar_descanso()

func iniciar_descanso():
	tiempo_descanso_restante = tiempo_descanso
	timer_descanso.start(1.0)  # Tick cada segundo
	
	# Mostrar cuenta regresiva en el HUD
	if hud:
		hud.mostrar_cuenta_regresiva(int(tiempo_descanso_restante))
	
	print("Descanso iniciado: ", tiempo_descanso, " segundos")

func _on_timer_spawn_timeout():
	spawnear_siguiente_enemigo()

func _on_timer_descanso_timeout():
	tiempo_descanso_restante -= 1.0
	
	# Actualizar cuenta regresiva en el HUD
	if hud and tiempo_descanso_restante > 0:
		hud.mostrar_cuenta_regresiva(int(tiempo_descanso_restante))
	
	if tiempo_descanso_restante <= 0:
		timer_descanso.stop()
		
		# Ocultar cuenta regresiva
		if hud:
			hud.ocultar_cuenta_regresiva()
		
		# Iniciar siguiente oleada automáticamente
		iniciar_oleada(oleada_actual + 1)

func _process(_delta):
	# Verificar si la oleada está completa
	if oleada_en_progreso:
		verificar_oleada_completada()

func obtener_tiempo_descanso_restante() -> float:
	return tiempo_descanso_restante

func obtener_oleada_actual() -> int:
	return oleada_actual

func obtener_oleadas_totales() -> int:
	return oleadas_totales

func esta_en_descanso() -> bool:
	return timer_descanso.time_left > 0

func iniciar_juego():
	print("=== INICIANDO JUEGO ===")
	# Resetear variables
	oleada_actual = 0
	oleada_en_progreso = false
	enemigos_por_spawnear.clear()
	indice_spawn_actual = 0
	
	iniciar_oleada(1)
