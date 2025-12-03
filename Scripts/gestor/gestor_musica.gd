extends Node

# Script que gestiona toda la música del juego
# Maneja transiciones suaves entre pistas y cambios según el estado del juego

# Referencias a los AudioStreamPlayer
var reproductor_musica: AudioStreamPlayer
var reproductor_siguiente: AudioStreamPlayer  # Para crossfade

# Pistas de música precargadas
var musica_menu = preload("res://assets/musica/musica principal/menu.wav")
var musica_horda_1_9 = preload("res://assets/musica/musica principal/horda1-9.wav")
var musica_horda_10 = preload("res://assets/musica/musica principal/horda-10.wav")

# Estado actual
var pista_actual: String = ""
var volumen_objetivo: float = 0.2  # 80% del volumen máximo
var esta_en_transicion: bool = false

func _ready():
	# Crear los reproductores de audio
	reproductor_musica = AudioStreamPlayer.new()
	reproductor_musica.bus = "Master"
	add_child(reproductor_musica)
	
	reproductor_siguiente = AudioStreamPlayer.new()
	reproductor_siguiente.bus = "Master"
	reproductor_musica.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor_siguiente)
	
	# Conectar señales de GestorJuego para cambiar música automáticamente
	GestorJuego.oleada_cambiada.connect(_on_oleada_cambiada)
	
	print("GestorMusica inicializado")

# Reproducir música con transición suave
func reproducir_musica(nombre_pista: String, hacer_loop: bool = true):
	if pista_actual == nombre_pista and reproductor_musica.playing:
		print("Ya se está reproduciendo: ", nombre_pista)
		return
	
	print("Cambiando música a: ", nombre_pista)
	
	var nueva_pista: AudioStream = null
	
	match nombre_pista:
		"menu":
			nueva_pista = musica_menu
		"horda_1_9":
			nueva_pista = musica_horda_1_9
		"horda_10":
			nueva_pista = musica_horda_10
		_:
			print("ERROR: Pista no reconocida: ", nombre_pista)
			return
	
	# Si hay música sonando, hacer crossfade
	if reproductor_musica.playing:
		iniciar_crossfade(nueva_pista, hacer_loop)
	else:
		# Reproducir directamente
		reproductor_musica.stream = nueva_pista
		reproductor_musica.volume_db = linear_to_db(volumen_objetivo)
		reproductor_musica.play()
		
		# Configurar loop
		if nueva_pista is AudioStreamWAV:
			nueva_pista.loop_mode = AudioStreamWAV.LOOP_FORWARD if hacer_loop else AudioStreamWAV.LOOP_DISABLED
	
	pista_actual = nombre_pista

# Hacer transición suave entre pistas (crossfade)
func iniciar_crossfade(nueva_pista: AudioStream, hacer_loop: bool):
	if esta_en_transicion:
		return
	
	esta_en_transicion = true
	
	# Configurar el segundo reproductor con la nueva pista
	reproductor_siguiente.stream = nueva_pista
	reproductor_siguiente.volume_db = linear_to_db(0.0)  # Empezar en silencio
	
	# Configurar loop
	if nueva_pista is AudioStreamWAV:
		nueva_pista.loop_mode = AudioStreamWAV.LOOP_FORWARD if hacer_loop else AudioStreamWAV.LOOP_DISABLED
	
	reproductor_siguiente.play()
	
	# Hacer el fade durante 2 segundos
	var duracion_fade = 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out del reproductor actual
	tween.tween_method(
		func(vol): reproductor_musica.volume_db = linear_to_db(vol),
		volumen_objetivo,
		0.0,
		duracion_fade
	)
	
	# Fade in del nuevo reproductor
	tween.tween_method(
		func(vol): reproductor_siguiente.volume_db = linear_to_db(vol),
		0.0,
		volumen_objetivo,
		duracion_fade
	)
	
	# Cuando termine, intercambiar reproductores
	tween.finished.connect(_finalizar_crossfade)

func _finalizar_crossfade():
	# Detener el reproductor viejo
	reproductor_musica.stop()
	
	# Intercambiar referencias
	var temp = reproductor_musica
	reproductor_musica = reproductor_siguiente
	reproductor_siguiente = temp
	
	esta_en_transicion = false
	print("Crossfade completado")

# Detener toda la música
func detener_musica():
	var tween = create_tween()
	tween.tween_method(
		func(vol): reproductor_musica.volume_db = linear_to_db(vol),
		volumen_objetivo,
		0.0,
		1.0
	)
	tween.finished.connect(func(): reproductor_musica.stop())
	pista_actual = ""

# Callback cuando cambia la oleada
func _on_oleada_cambiada(nueva_oleada: int):
	print("GestorMusica: Oleada cambiada a ", nueva_oleada)
	
	if nueva_oleada >= 1 and nueva_oleada <= 9:
		reproducir_musica("horda_1_9", true)
	elif nueva_oleada == 10:
		reproducir_musica("horda_10", true)

# Funciones auxiliares
func establecer_volumen(volumen: float):
	volumen_objetivo = clamp(volumen, 0.0, 1.0)
	if reproductor_musica.playing:
		reproductor_musica.volume_db = linear_to_db(volumen_objetivo)

func obtener_volumen() -> float:
	return volumen_objetivo

# Convertir volumen lineal (0-1) a decibeles
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
