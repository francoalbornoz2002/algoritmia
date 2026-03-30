class_name EstadisticasModal extends CanvasLayer

# --- UI Referencias ---
@export var panel_principal: NinePatchRect
@export var lbl_campana: RichTextLabel
@export var lbl_estrellas: RichTextLabel
@export var lbl_exp: RichTextLabel
@export var lbl_intentos: RichTextLabel
@export var lista_dificultades: VBoxContainer
@export var btn_cerrar: Button

func _ready():
	hide()
	if btn_cerrar:
		btn_cerrar.pressed.connect(hide)

# --- API Pública ---
func mostrar(stats_progreso: Dictionary, dificultades_activas: Array):
	_poblar_progreso(stats_progreso)
	_poblar_dificultades(dificultades_activas)
	
	show()
	# Animación de entrada
	if is_instance_valid(panel_principal):
		panel_principal.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(panel_principal, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _poblar_progreso(stats: Dictionary):
	# --- Columna de Progreso ---
	var porcentaje = 0
	if stats.campana_total > 0:
		porcentaje = int(float(stats.campana_completadas) / stats.campana_total * 100)
	
	var prom_estrellas = 0.0
	if stats.total_partidas > 0:
		prom_estrellas = float(stats.total_estrellas) / stats.total_partidas
		
	var prom_intentos = 0.0
	if stats.total_partidas > 0:
		prom_intentos = float(stats.total_intentos) / stats.total_partidas
	
	# Usamos BBCode para colorear los números
	var color_valor = "[color=#FFD700]" # Dorado
	
	lbl_campana.text = "[center]🏆 [b]Campaña[/b] 🏆\n%s%d%%[/color] (%d/%d Misiones)[/center]" % [color_valor, porcentaje, stats.campana_completadas, stats.campana_total]
	lbl_estrellas.text = "[center]⭐ [b]Estrellas[/b] ⭐\n%s%d[/color] (Promedio: %.1f)[/center]" % [color_valor, stats.total_estrellas, prom_estrellas]
	lbl_exp.text = "[center]✨ [b]Experiencia[/b] ✨\n%s%d[/color] EXP[/center]" % [color_valor, stats.total_exp]
	lbl_intentos.text = "[center]🔄 [b]Intentos[/b] 🔄\n%s%d[/color] (Promedio: %.1f)[/center]" % [color_valor, stats.total_intentos, prom_intentos]

func _poblar_dificultades(dificultades: Array):
	# --- Columna de Dificultades ---
	# Limpiar lista anterior
	for child in lista_dificultades.get_children():
		child.queue_free()
		
	if dificultades.is_empty():
		var lbl_vacio = Label.new()
		lbl_vacio.text = "🎉 ¡Tu lógica es impecable!\nNo se han detectado dificultades."
		lbl_vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_vacio.autowrap_mode = TextServer.AUTOWRAP_WORD
		lista_dificultades.add_child(lbl_vacio)
		return
	
	# Crear un item por cada dificultad activa
	for dif in dificultades:
		var item = RichTextLabel.new()
		item.bbcode_enabled = true
		item.fit_content = true
		item.add_theme_font_size_override("normal_font_size", 16)
		item.add_theme_font_size_override("bold_font_size", 16)
		
		var emoji = "🟢" # Bajo
		if dif.grado == "Medio": emoji = "🟡"
		if dif.grado == "Alto": emoji = "🔴"
		
		item.text = "%s [b][%s][/b] %s" % [emoji, dif.grado, dif.nombre]
		item.tooltip_text = dif.descripcion # Tooltip para más info
		
		lista_dificultades.add_child(item)
