class_name FeedbackFormativo extends CanvasLayer

signal feedback_completado

# --- UI Referencias ---
@export var panel_principal: PanelContainer
@export var lbl_titulo: Label
@export var lbl_texto_formativo: RichTextLabel
@export var code_edit_incorrecto: CodeEdit
@export var code_edit_correcto: CodeEdit
@export var btn_entendido: Button

# --- Estado Interno ---
var _feedback_queue: Array[FeedbackDificultad] = []

func _ready():
	# Oculto por defecto
	hide()

	if btn_entendido:
		btn_entendido.pressed.connect(_on_boton_entendido_pressed)

	# Configurar los CodeEdit para que sean de solo lectura y usen el resaltador
	if code_edit_incorrecto:
		code_edit_incorrecto.editable = false
		code_edit_incorrecto.syntax_highlighter = _crear_resaltador_configurado()
		# Forzar color de texto normal y fondo normal para el estado Solo Lectura
		code_edit_incorrecto.add_theme_color_override("font_readonly_color", Color("24292e"))
		code_edit_incorrecto.add_theme_stylebox_override("read_only", code_edit_incorrecto.get_theme_stylebox("normal", "CodeEdit"))

	if code_edit_correcto:
		code_edit_correcto.editable = false
		code_edit_correcto.syntax_highlighter = _crear_resaltador_configurado()
		# Forzar color de texto normal y fondo normal para el estado Solo Lectura
		code_edit_correcto.add_theme_color_override("font_readonly_color", Color("24292e"))
		code_edit_correcto.add_theme_stylebox_override("read_only", code_edit_correcto.get_theme_stylebox("normal", "CodeEdit"))

# --- API Pública ---
func mostrar_feedbacks(codigos_dificultad: Array):
	if codigos_dificultad.is_empty():
		feedback_completado.emit()
		return

	_feedback_queue.clear()

	for codigo in codigos_dificultad:
		var feedback_data = GestorFeedback.obtener_feedback_por_codigo(codigo)
		if feedback_data:
			_feedback_queue.append(feedback_data)

	if _feedback_queue.is_empty():
		feedback_completado.emit()
		return
		
	_mostrar_siguiente_feedback()
	show()
	
	if is_instance_valid(panel_principal):
		panel_principal.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(panel_principal, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_boton_entendido_pressed():
	_mostrar_siguiente_feedback()

func _mostrar_siguiente_feedback():
	if _feedback_queue.is_empty():
		hide()
		feedback_completado.emit()
		return
		
	var feedback_actual = _feedback_queue.pop_front()
	_poblar_ui_con_feedback(feedback_actual)

func _poblar_ui_con_feedback(data: FeedbackDificultad):
	if lbl_titulo: lbl_titulo.text = data.titulo
	if lbl_texto_formativo: lbl_texto_formativo.text = data.texto_formativo
	if code_edit_incorrecto: code_edit_incorrecto.text = data.codigo_incorrecto
	if code_edit_correcto: code_edit_correcto.text = data.codigo_correcto

func _crear_resaltador_configurado() -> CodeHighlighter:
	# Reutilizamos la misma configuración de colores que en code_edit.gd
	var highlighter = CodeHighlighter.new()
	
	highlighter.symbol_color = Color("d73a49")
	highlighter.number_color = Color("005cc5")
	highlighter.member_variable_color = Color("24292e")
	
	var color_estructura = Color("502b90ff")
	for kw in ["Inicio", "Fin", "Si", "Sino", "entonces", "Mientras", "hacer", "Repetir", "var", "proceso"]:
		highlighter.add_keyword_color(kw, color_estructura)
	
	var color_tipos = Color("22863a")
	for kw in ["entero", "real"]:
		highlighter.add_keyword_color(kw, color_tipos)

	var color_accion = Color("0050a1")
	for kw in ["avanzar", "derecha", "saltar", "atacar", "recogerMoneda", "recogerLlave", "abrirCofre", "activarPuente"]:
		highlighter.add_keyword_color(kw, color_accion)
	
	var color_sensor = Color("a04100")
	for kw in ["hayMoneda", "hayLlave", "hayCofre", "hayEnemigo", "hayObstaculo", "hayPuente", "posSendero", "posValle", "tengoMoneda", "tengoLlave"]:
		highlighter.add_keyword_color(kw, color_sensor)

	highlighter.add_color_region("--", "", Color("6a737d"), true)
	
	return highlighter
