extends Control


func _on_registrar_mision_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/registrar_mision/registrar_mision.tscn")


func _on_registrar_dificultad_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/registrar_dificultad/registrar_dificultad.tscn")


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")
