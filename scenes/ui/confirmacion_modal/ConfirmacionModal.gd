class_name ConfirmacionModal extends CanvasLayer

signal confirmed
signal force_action
signal cancelled

@export var panel_principal: NinePatchRect
@export var lbl_titulo: Label
@export var lbl_mensaje: RichTextLabel
@export var btn_confirmar: Button
@export var btn_forzar: Button
@export var btn_cancelar: Button

func _ready():
	hide()
	if btn_confirmar:
		btn_confirmar.pressed.connect(func(): confirmed.emit(); hide())
	if btn_forzar:
		btn_forzar.pressed.connect(func(): force_action.emit(); hide())
	if btn_cancelar:
		btn_cancelar.pressed.connect(func(): cancelled.emit(); hide())

func mostrar(titulo: String, mensaje: String, texto_confirmar: String, show_force_button: bool = false, texto_forzar: String = ""):
	lbl_titulo.text = titulo
	lbl_mensaje.text = mensaje
	btn_confirmar.text = texto_confirmar
	
	if show_force_button:
		btn_forzar.visible = true
		btn_forzar.text = texto_forzar
	else:
		btn_forzar.visible = false

	show()
	if is_instance_valid(panel_principal):
		panel_principal.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(panel_principal, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)