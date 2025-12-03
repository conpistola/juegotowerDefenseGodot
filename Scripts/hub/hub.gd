extends CanvasLayer

# Script que controla toda la interfaz del juego (HUD)
# Muestra dinero, vidas, oleada y los paneles de construcción/mejora de torres


# Panel superior - Indicadores principales
@onready var label_oleada = $PanelSuperior/MarginContainer/HBoxContainer/ContenedorOleada/IconoOleada/LabelOleada
@onready var label_dinero = $PanelSuperior/MarginContainer/HBoxContainer/ContenedorDinero/iconoDinero/LabelDinero
@onready var label_vidas = $PanelSuperior/MarginContainer/HBoxContainer/Separador2/ContenedorVidas/IconoVidas/LabelVidas
@onready var label_cuenta_regresiva = $PanelSuperior/LabelPrecioVender

# Paneles
@onready var panel_construccion = $PanelConstruccion
@onready var panel_mejora = $PanelMejora

# Botones de construcción de torres
@onready var boton_arquero = $"PanelConstruccion/GridContainer/ContenedorArquero/BotonArquero"
@onready var boton_bomber = $"PanelConstruccion/GridContainer/ContenedorBomber/BotonBomber"
@onready var boton_electrica = $"PanelConstruccion/GridContainer/ContenedorElectrica/BotonElectrica"
@onready var boton_sniper = $"PanelConstruccion/GridContainer/ContenedorSniper/BotonSniper"

# Labels de precios de construcción
@onready var label_precio_arquero = $"PanelConstruccion/GridContainer/ContenedorArquero/BotonArquero/LabelPrecioArquero"
@onready var label_precio_bomber = $"PanelConstruccion/GridContainer/ContenedorBomber/BotonBomber/LabelPrecioBomber"
@onready var label_precio_electrica = $"PanelConstruccion/GridContainer/ContenedorElectrica/BotonElectrica/LabelPrecioElectrica"
@onready var label_precio_sniper = $"PanelConstruccion/GridContainer/ContenedorSniper/BotonSniper/LabelPrecioSniper"

# Botón cerrar del panel de construcción
@onready var boton_cerrar_construccion = $PanelConstruccion/BotonCerrar

# Botones de mejora/venta
@onready var boton_mejorar = $PanelMejora/ContenedorBotones/ContenedorMejorar/BotonMejorar
@onready var boton_vender = $PanelMejora/ContenedorBotones/ContenedorVender/BotonVender
@onready var boton_cerrar_mejora = $PanelMejora/BotonCerrar

# Labels de precios en panel mejora
@onready var label_precio_mejorar = $PanelMejora/ContenedorBotones/ContenedorMejorar/BotonMejorar/LabelPrecioMejorar
@onready var label_precio_vender = $PanelMejora/ContenedorBotones/ContenedorVender/BotonVender/LabelPrecioVender

# Contenedor de botones de mejora
@onready var contenedor_botones_mejora = $PanelMejora/ContenedorBotones


# Diccionario con todos los precios de cada torre
const DATOS_TORRES = {
	"arquero": {
		"precio_construccion": 100,
		"precio_mejora": 100,
		"precio_venta": 75
	},
	"bomber": {
		"precio_construccion": 150,
		"precio_mejora": 150,
		"precio_venta": 110
	},
	"electrica": {
		"precio_construccion": 300,
		"precio_mejora": 300,
		"precio_venta": 225
	},
	"sniper": {
		"precio_construccion": 500,
		"precio_mejora": 500,
		"precio_venta": 375
	}
}

# Acceso rápido a precios de construcción
const PRECIO_ARQUERO = 100
const PRECIO_BOMBER = 150
const PRECIO_ELECTRICA = 300
const PRECIO_SNIPER = 500



var torre_seleccionada = null
var casilla_seleccionada = null
var mapa_referencia = null



func _ready():
	print("=== INICIALIZANDO HUD ===")
	GestorMusica.reproducir_musica("menu", true)
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel_construccion.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_mejora.process_mode = Node.PROCESS_MODE_ALWAYS
	
	panel_construccion.visible = false
	panel_mejora.visible = false
	contenedor_botones_mejora.visible = true
	label_cuenta_regresiva.visible = false
	
	GestorJuego.dinero_cambiado.connect(_actualizar_dinero)
	GestorJuego.vidas_cambiadas.connect(_actualizar_vidas)
	GestorJuego.oleada_cambiada.connect(_actualizar_oleada)
	
	boton_arquero.pressed.connect(_on_boton_arquero_pressed)
	boton_bomber.pressed.connect(_on_boton_bomber_pressed)
	boton_electrica.pressed.connect(_on_boton_electrica_pressed)
	boton_sniper.pressed.connect(_on_boton_sniper_pressed)
	boton_cerrar_construccion.pressed.connect(_on_boton_cerrar_construccion_pressed)
	
	boton_mejorar.pressed.connect(_on_boton_mejorar_pressed)
	boton_vender.pressed.connect(_on_boton_vender_pressed)
	boton_cerrar_mejora.pressed.connect(_on_boton_cerrar_mejora_pressed)
	
	_actualizar_dinero(GestorJuego.dinero)
	_actualizar_vidas(GestorJuego.vidas)
	_actualizar_oleada(GestorJuego.oleada_actual)
	
	print("HUD inicializado correctamente")
	print("Dinero inicial: ", GestorJuego.dinero)
	print("Vidas iniciales: ", GestorJuego.vidas)

func _actualizar_dinero(nuevo_dinero: int):
	label_dinero.text = str(nuevo_dinero)
	print("Dinero actualizado: ", nuevo_dinero)
	_actualizar_botones_construccion()
	
	if panel_mejora.visible:
		_actualizar_boton_mejorar()

func _actualizar_vidas(nuevas_vidas: int):
	label_vidas.text = str(nuevas_vidas)
	print("Vidas actualizadas: ", nuevas_vidas)

func _actualizar_oleada(numero_oleada: int):
	label_oleada.text = "Oleada: " + str(numero_oleada) + "/10"

	
func actualizar_oleada(numero_oleada: int):
	_actualizar_oleada(numero_oleada)

func mostrar_cuenta_regresiva(segundos: int):
	label_cuenta_regresiva.text = "Proxima oleada en: " + str(segundos)
	label_cuenta_regresiva.visible = true
	print("Cuenta regresiva: ", segundos)

func ocultar_cuenta_regresiva():
	label_cuenta_regresiva.visible = false
	print("Cuenta regresiva ocultada")

func mostrar_panel_construccion(posicion_pantalla: Vector2):
	panel_mejora.visible = false
	panel_construccion.visible = true
	
	get_tree().paused = true
	print(">>> JUEGO PAUSADO <<<")
	
	var ancho_panel = 600.0
	var alto_panel = 380.0
	
	var pos_panel = Vector2()
	pos_panel.x = posicion_pantalla.x - (ancho_panel / 2.0)
	pos_panel.y = posicion_pantalla.y - alto_panel
	
	var viewport_size = get_viewport().get_visible_rect().size
	pos_panel.x = clamp(pos_panel.x, 10, viewport_size.x - ancho_panel - 10)
	pos_panel.y = clamp(pos_panel.y, 10, viewport_size.y - alto_panel - 10)
	
	panel_construccion.offset_left = pos_panel.x
	panel_construccion.offset_top = pos_panel.y
	panel_construccion.offset_right = pos_panel.x + ancho_panel
	panel_construccion.offset_bottom = pos_panel.y + alto_panel
	
	_actualizar_botones_construccion()
	print("Panel construcción centrado: X=", pos_panel.x, " Y=", pos_panel.y)

func mostrar_panel_mejora(posicion_global: Vector2, torre):
	print("=== MOSTRAR PANEL MEJORA ===")
	print("Torre: ", torre.tipo_torre)
	print("Nivel: ", torre.nivel_actual, "/", torre.nivel_maximo)
	
	panel_construccion.visible = false
	panel_mejora.visible = true
	torre_seleccionada = torre
	
	get_tree().paused = true
	
	contenedor_botones_mejora.visible = true
	
	var ancho_panel = 450.0
	var alto_panel = 380.0
	
	var viewport = get_viewport()
	var posicion_pantalla = viewport.get_canvas_transform() * posicion_global
	
	var pos_panel = Vector2()
	pos_panel.x = posicion_pantalla.x - (ancho_panel / 2.0)
	pos_panel.y = posicion_pantalla.y - alto_panel
	
	var viewport_size = viewport.get_visible_rect().size
	pos_panel.x = clamp(pos_panel.x, 10, viewport_size.x - ancho_panel - 10)
	pos_panel.y = clamp(pos_panel.y, 10, viewport_size.y - alto_panel - 10)
	
	panel_mejora.offset_left = pos_panel.x
	panel_mejora.offset_top = pos_panel.y
	panel_mejora.offset_right = pos_panel.x + ancho_panel
	panel_mejora.offset_bottom = pos_panel.y + alto_panel
	
	_actualizar_panel_mejora()
	print("Panel mejora centrado: X=", pos_panel.x, " Y=", pos_panel.y)

func ocultar_panel_construccion():
	panel_construccion.visible = false
	casilla_seleccionada = null
	mapa_referencia = null
	
	get_tree().paused = false
	print("Panel de construcción ocultado")

func _actualizar_botones_construccion():
	var dinero_actual = GestorJuego.dinero
	
	if dinero_actual >= PRECIO_ARQUERO:
		boton_arquero.disabled = false
		boton_arquero.modulate.a = 1.0
	else:
		boton_arquero.disabled = true
		boton_arquero.modulate.a = 0.5
	
	if dinero_actual >= PRECIO_BOMBER:
		boton_bomber.disabled = false
		boton_bomber.modulate.a = 1.0
	else:
		boton_bomber.disabled = true
		boton_bomber.modulate.a = 0.5
	
	if dinero_actual >= PRECIO_ELECTRICA:
		boton_electrica.disabled = false
		boton_electrica.modulate.a = 1.0
	else:
		boton_electrica.disabled = true
		boton_electrica.modulate.a = 0.5
	
	if dinero_actual >= PRECIO_SNIPER:
		boton_sniper.disabled = false
		boton_sniper.modulate.a = 1.0
	else:
		boton_sniper.disabled = true
		boton_sniper.modulate.a = 0.5

func ocultar_panel_mejora():
	panel_mejora.visible = false
	torre_seleccionada = null
	
	get_tree().paused = false
	print(">>> JUEGO REANUDADO <<<")
	print("Panel de mejora ocultado")

func _actualizar_panel_mejora():
	if not torre_seleccionada:
		return
	
	var tipo_torre = torre_seleccionada.tipo_torre
	var datos = DATOS_TORRES[tipo_torre]
	
	var dinero_invertido = torre_seleccionada.precio_base * torre_seleccionada.nivel_actual
	var precio_venta = int(dinero_invertido * 0.75)
	
	label_precio_mejorar.text = str(datos["precio_mejora"])
	label_precio_vender.text = "+" + str(precio_venta)
	
	_actualizar_boton_mejorar()
	
	print("Panel actualizado - Mejora: ", datos["precio_mejora"], " Venta: ", precio_venta)

func _actualizar_boton_mejorar():
	if not torre_seleccionada:
		return
	
	var tipo_torre = torre_seleccionada.tipo_torre
	var datos = DATOS_TORRES[tipo_torre]
	var precio_mejora = datos["precio_mejora"]
	var dinero_actual = GestorJuego.dinero
	
	var ya_en_nivel_maximo = torre_seleccionada.nivel_actual >= torre_seleccionada.nivel_maximo
	
	if ya_en_nivel_maximo:
		boton_mejorar.disabled = true
		boton_mejorar.modulate = Color(0.5, 1.0, 0.5, 1.0)
		label_precio_mejorar.text = "MAX"
		label_precio_mejorar.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		print("Torre en nivel máximo")
	elif dinero_actual >= precio_mejora:
		boton_mejorar.disabled = false
		boton_mejorar.modulate = Color(1.0, 1.0, 1.0, 1.0)
		label_precio_mejorar.text = str(precio_mejora)
		label_precio_mejorar.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		print("Puede mejorar - Precio: ", precio_mejora)
	else:
		boton_mejorar.disabled = true
		boton_mejorar.modulate = Color(0.7, 0.7, 0.7, 1.0)
		label_precio_mejorar.text = str(precio_mejora)
		label_precio_mejorar.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		print("Sin dinero - Necesita: ", precio_mejora)

func _on_boton_arquero_pressed():
	print("=== BOTÓN ARQUERO PRESIONADO ===")
	if GestorJuego.gastar_dinero(PRECIO_ARQUERO):
		if mapa_referencia and casilla_seleccionada:
			mapa_referencia.construir_torre("arquero", casilla_seleccionada)
	ocultar_panel_construccion()

func _on_boton_bomber_pressed():
	print("=== BOTÓN BOMBER PRESIONADO ===")
	if GestorJuego.gastar_dinero(PRECIO_BOMBER):
		if mapa_referencia and casilla_seleccionada:
			mapa_referencia.construir_torre("bomber", casilla_seleccionada)
	ocultar_panel_construccion()

func _on_boton_electrica_pressed():
	print("=== BOTÓN ELÉCTRICA PRESIONADO ===")
	if GestorJuego.gastar_dinero(PRECIO_ELECTRICA):
		if mapa_referencia and casilla_seleccionada:
			mapa_referencia.construir_torre("electrica", casilla_seleccionada)
	ocultar_panel_construccion()

func _on_boton_sniper_pressed():
	print("=== BOTÓN SNIPER PRESIONADO ===")
	if GestorJuego.gastar_dinero(PRECIO_SNIPER):
		if mapa_referencia and casilla_seleccionada:
			mapa_referencia.construir_torre("sniper", casilla_seleccionada)
	ocultar_panel_construccion()

func _on_boton_cerrar_construccion_pressed():
	print("Cerrar panel construcción")
	ocultar_panel_construccion()

func _on_boton_mejorar_pressed():
	print("=== BOTÓN MEJORAR PRESIONADO ===")
	
	if not torre_seleccionada:
		print("ERROR: No hay torre seleccionada")
		return
	
	if not torre_seleccionada.has_method("mejorar"):
		print("ERROR: Torre no tiene método mejorar()")
		return
	
	var exito = torre_seleccionada.mejorar()
	
	if exito:
		print("Torre mejorada exitosamente")
		_actualizar_panel_mejora()
	else:
		print("No se pudo mejorar la torre")
		ocultar_panel_mejora()

func _on_boton_vender_pressed():
	print("=== BOTÓN VENDER PRESIONADO ===")
	
	if not torre_seleccionada:
		print("ERROR: No hay torre seleccionada")
		return
	
	if not torre_seleccionada.has_method("vender"):
		print("ERROR: Torre no tiene método vender()")
		return
	
	torre_seleccionada.vender()
	print("Torre vendida")
	
	ocultar_panel_mejora()

func _on_boton_cerrar_mejora_pressed():
	print("Cerrar panel mejora")
	ocultar_panel_mejora()
