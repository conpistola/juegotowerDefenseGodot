extends Node

# Este script es un singleton (autoload) que gestiona el estado global del juego
# Controla: dinero, vidas, oleada actual, y comunicación entre escenas

# Señales para notificar cambios a la interfaz
signal dinero_cambiado(nuevo_dinero)
signal vidas_cambiadas(nuevas_vidas)
signal oleada_cambiada(numero_oleada)
signal enemigo_muerto(dinero_ganado)

# Variables de estado del juego
var dinero: int = 200
var vidas: int = 5
var oleada_actual: int = 1
var total_oleadas: int = 10

# Variables de control
var enemigos_vivos: int = 0
var juego_iniciado: bool = false

# Inicialización
func _ready():
	print("GestorJuego inicializado")
	reset_juego()

# Resetear el juego a valores iniciales
func reset_juego():
	dinero = 200
	vidas = 5
	oleada_actual = 1
	enemigos_vivos = 0
	juego_iniciado = false
	emit_signal("dinero_cambiado", dinero)
	emit_signal("vidas_cambiadas", vidas)
	emit_signal("oleada_cambiada", oleada_actual)

# Añadir dinero al jugador
func agregar_dinero(cantidad: int):
	dinero += cantidad
	emit_signal("dinero_cambiado", dinero)
	print("Dinero agregado: +", cantidad, " | Total: ", dinero)

# Gastar dinero (retorna true si había suficiente dinero)
func gastar_dinero(cantidad: int) -> bool:
	if dinero >= cantidad:
		dinero -= cantidad
		emit_signal("dinero_cambiado", dinero)
		print("Dinero gastado: -", cantidad, " | Restante: ", dinero)
		return true
	else:
		print("Dinero insuficiente. Necesitas: ", cantidad, " | Tienes: ", dinero)
		return false

# Verificar si hay suficiente dinero
func tiene_dinero(cantidad: int) -> bool:
	return dinero >= cantidad

# Perder una vida
func perder_vida():
	vidas -= 1
	emit_signal("vidas_cambiadas", vidas)
	print("Vida perdida | Vidas restantes: ", vidas)
	
	# Verificar derrota
	if vidas <= 0:
		game_over()

# Avanzar a la siguiente oleada
func siguiente_oleada():
	if oleada_actual < total_oleadas:
		oleada_actual += 1
		emit_signal("oleada_cambiada", oleada_actual)
		print("Oleada ", oleada_actual, "/", total_oleadas)
	else:
		victoria()

# Registrar cuando un enemigo es generado
func registrar_enemigo_spawneado():
	enemigos_vivos += 1
	print("Enemigo spawneado | Enemigos vivos: ", enemigos_vivos)

# Registrar cuando un enemigo muere
func registrar_enemigo_muerto(dinero_drop: int):
	enemigos_vivos -= 1
	agregar_dinero(dinero_drop)
	emit_signal("enemigo_muerto", dinero_drop)
	print("Enemigo eliminado | Enemigos vivos: ", enemigos_vivos)

# Obtener cantidad de enemigos vivos
func obtener_enemigos_vivos() -> int:
	return enemigos_vivos

# Victoria - completar todas las oleadas
func victoria():
	print("VICTORIA - Todas las oleadas completadas")
	juego_iniciado = false
	# Aquí se mostraría panel de victoria
	# Por ahora solo imprimimos mensaje
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://menu.tscn")

# Derrota - se acabaron las vidas
func game_over():
	print("GAME OVER - Sin vidas")
	juego_iniciado = false
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://menu.tscn")
