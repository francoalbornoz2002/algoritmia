extends Control

@export var grid_container: GridContainer

# --- REFERENCIAS UI MODAL ---
@export_group("Modal Misión")
@export var modal_control: Control
@export var lbl_titulo: Label
@export var lbl_dificultad: Label
@export var lbl_descripcion: Label
@export var btn_jugar_modal: Button

# --- TEXTURAS PERSONALIZADAS ---
@export_group("Estilo Visual")
@export var tex_nivel_icono: Texture2D # El círculo de grilla_niveles.png
@export var tex_nivel_hover: Texture2D # Cuando pasas el mouse
@export var tex_nivel_pressed: Texture2D # Cuando haces clic
@export var tex_nivel_bloqueado: Texture2D # Opcional
@export_group("Estilo Texto")
@export var tamano_fuente: int = 32
@export var color_texto: Color = Color.WHITE

var _mision_seleccionada_temp: DefinicionMision = null

func _ready():
	if modal_control: modal_control.hide()
	_cargar_misiones()

func _cargar_misiones():
	# Limpiar hijos previos si los hubiera
	for child in grid_container.get_children():
		child.queue_free()
	
	# Obtener todas las misiones del catálogo
	var misiones_db = DatabaseManager.obtener_misiones()
	# Obtener lista de IDs completados para verificar desbloqueos
	var completadas = DatabaseManager.obtener_ids_misiones_completadas()
	
	for i in range(misiones_db.size()):
		var datos_mision = misiones_db[i]
		# Cargamos el recurso real usando el ID de la base de datos
		var mision_recurso = GestorCatalogo.obtener_mision_por_id(datos_mision["id"])
		
		if not mision_recurso:
			print("Selector: Advertencia, misión en BD no encontrada en recursos: ", datos_mision["id"])
			continue

		# Lógica de Bloqueo Secuencial
		var esta_bloqueada = false
		if i > 0:
			# Si no es la primera, verificamos si la ANTERIOR está completada
			var id_anterior = misiones_db[i - 1]["id"]
			if not id_anterior in completadas:
				esta_bloqueada = true

		var btn = TextureButton.new()
		btn.focus_mode = Control.FOCUS_NONE
		
		# 1. Configurar Textura (Círculo)
		if tex_nivel_icono:
			if esta_bloqueada and tex_nivel_bloqueado:
				btn.texture_normal = tex_nivel_bloqueado
			else:
				btn.texture_normal = tex_nivel_icono
				if tex_nivel_hover: btn.texture_hover = tex_nivel_hover
				if tex_nivel_pressed: btn.texture_pressed = tex_nivel_pressed
			
			# Ajustamos el tamaño mínimo para que no se aplaste
			btn.ignore_texture_size = true
			btn.stretch_mode = TextureButton.STRETCH_SCALE
			btn.custom_minimum_size = Vector2(85, 85)
		else:
			# Fallback si no hay textura asignada
			btn.custom_minimum_size = Vector2(80, 80)
		
		# 2. Número de Nivel (Label)
		var lbl_num = Label.new()
		lbl_num.text = str(mision_recurso.numero)
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_num.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_num.add_theme_font_size_override("font_size", tamano_fuente)
		lbl_num.add_theme_color_override("font_color", color_texto)
		lbl_num.add_theme_constant_override("outline_size", 8)
		lbl_num.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_child(lbl_num)

		if esta_bloqueada:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7) # Efecto visual de "apagado"
			# Opcional: Podrías ocultar el número lbl_num.hide() si prefieres
		else:
			# Conectar señal pasando la misión como argumento
			btn.pressed.connect(_abrir_modal.bind(mision_recurso))
		
		grid_container.add_child(btn)

func _abrir_modal(mision: DefinicionMision) -> void:
	_mision_seleccionada_temp = mision
	
	# Llenar datos
	if lbl_titulo: lbl_titulo.text = mision.titulo
	if lbl_dificultad: lbl_dificultad.text = "Dificultad: " + mision.dificultad_mision
	if lbl_descripcion: lbl_descripcion.text = mision.descripcion
	
	# Mostrar animación simple
	if modal_control:
		modal_control.show()
		# Pequeño pop-up effect
		modal_control.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(modal_control, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_cerrar_modal_pressed():
	if modal_control: modal_control.hide()
	_mision_seleccionada_temp = null

func _on_jugar_modal_pressed():
	if _mision_seleccionada_temp == null: return
	
	GameData.mision_seleccionada = _mision_seleccionada_temp
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
