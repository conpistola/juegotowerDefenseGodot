extends Node

# Gestor de efectos de sonido del juego
# Maneja reproducción de sonidos de zombies y torres con pool de reproductores

# Pool de reproductores de audio para sonidos simultáneos
var reproductores_pool: Array[AudioStreamPlayer] = []
var max_reproductores: int = 20  # Máximo de sonidos simultáneos

# Sonidos de zombies precargados
var sonido_zombies_coming: AudioStream
var sonido_zombie_idle: AudioStream
var sonido_zombie_hurt: AudioStream
var sonido_zombie_death: AudioStream

# Sonidos de torres precargados
var sonido_flecha: AudioStream
var sonido_bomba: AudioStream
var sonido_electrico: AudioStream
var sonido_disparo_sniper: AudioStream

# Control de sonido zombies_coming (solo una vez al inicio)
var zombies_coming_reproducido: bool = false

func _ready():
	
	# Crear pool de reproductores
	for i in range(max_reproductores):
		var reproductor = AudioStreamPlayer.new()
		reproductor.bus = "Master"
		reproductor.volume_db = 0.0
		reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(reproductor)
		reproductores_pool.append(reproductor)
	
	print(" Pool de ", max_reproductores, " reproductores creado")
	
	# Cargar sonidos de zombies
	print("Cargando sonidos de zombies...")
	sonido_zombies_coming = load("res://assets/musica/zombies/zombies_are_coming.mp3")
	sonido_zombie_idle = load("res://assets/musica/zombies/Zombie_idle1.mp3")
	sonido_zombie_hurt = load("res://assets/musica/zombies/Zombie_hurt2.mp3")
	sonido_zombie_death = load("res://assets/musica/zombies/Zombie_death.mp3")
	
	if sonido_zombies_coming:
		print("zombies_are_coming.mp3")
	else:
		print("zombies_are_coming.mp3")
	
	if sonido_zombie_idle:
		print("Zombie_idle1.mp3")
	else:
		print("Zombie_idle1.mp3")
	
	if sonido_zombie_hurt:
		print("Zombie_hurt2.mp3")
	else:
		print("Zombie_hurt2.mp3")
	
	if sonido_zombie_death:
		print("Zombie_death.mp3")
	else:
		print("Zombie_death.mp3")
	
	# Cargar sonidos de torres
	print("Cargando sonidos de torres...")
	sonido_flecha = load("res://assets/musica/torre/flecha.mp3")
	sonido_bomba = load("res://assets/musica/torre/disparo_morteo.mp3")
	sonido_electrico = load("res://assets/musica/torre/electrico.mp3")
	sonido_disparo_sniper = load("res://assets/musica/torre/disparo.mp3")
	
	if sonido_flecha:
		print("flecha.mp3")
	else:
		print("flecha.mp3")
	
	if sonido_bomba:
		print("disparo_morteo.mp3")
	else:
		print("disparo_morteo.mp3")
	
	if sonido_electrico:
		print("electrico.mp3")
	else:
		print("electrico.mp3")
	
	if sonido_disparo_sniper:
		print("disparo.mp3")
	else:
		print("disparo.mp3")
	
	# Conectar señal de oleada para reproducir zombies_coming
	if GestorJuego:
		GestorJuego.oleada_cambiada.connect(_on_oleada_cambiada)
		print(" Conectado a señal oleada_cambiada")
	else:
		print(" ERROR: GestorJuego no existe")
	
	print("========================================")
	print("GestorSonidos LISTO")
	print("========================================")

# Reproducir un sonido usando el pool de reproductores
func reproducir_sonido(sonido: AudioStream, volumen_db: float = 0.0):
	if sonido == null:
		return
	
	# Buscar un reproductor disponible
	for reproductor in reproductores_pool:
		if not reproductor.playing:
			reproductor.stream = sonido
			reproductor.volume_db = volumen_db
			reproductor.play()
			return
	
	# Si todos están ocupados, usar el primero (interrumpir)
	reproductores_pool[0].stream = sonido
	reproductores_pool[0].volume_db = volumen_db
	reproductores_pool[0].play()

# Sonidos de zombies
func reproducir_zombies_coming():
	if not zombies_coming_reproducido:
		reproducir_sonido(sonido_zombies_coming, -5.0)
		zombies_coming_reproducido = true
		print("♪ Zombies are coming!")

func reproducir_zombie_idle():
	reproducir_sonido(sonido_zombie_idle, -10.0)

func reproducir_zombie_hurt():
	reproducir_sonido(sonido_zombie_hurt, -5.0)

func reproducir_zombie_death():
	reproducir_sonido(sonido_zombie_death, -3.0)

# Sonidos de torres
func reproducir_disparo_arquero():
	reproducir_sonido(sonido_flecha, -8.0)

func reproducir_disparo_bomber():
	reproducir_sonido(sonido_bomba, -5.0)

func reproducir_disparo_electrico():
	reproducir_sonido(sonido_electrico, -16.0)

func reproducir_disparo_sniper():
	reproducir_sonido(sonido_disparo_sniper, -5.0)

# Cuando cambia la oleada
func _on_oleada_cambiada(nueva_oleada: int):
	# Solo reproducir zombies_coming en la oleada 1
	if nueva_oleada == 1:
		reproducir_zombies_coming()
	
	# Resetear flag si se reinicia el juego
	if nueva_oleada == 1:
		zombies_coming_reproducido = false
		reproducir_zombies_coming()
