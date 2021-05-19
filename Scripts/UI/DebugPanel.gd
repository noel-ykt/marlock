class_name DebugPanel
extends Control


func _on_tree_entered():
	GameState.register_debug_node(self)

func _on_tree_exiting():
	GameState.unregister_debug_node(self)

func add_label(label_name: String, text: String = "", align: int = Label.ALIGN_CENTER, valign: int = Label.VALIGN_CENTER):
	var label = Label.new()
	label.set_name(label_name)
	label.text = text
	label.anchor_left = 0
	label.anchor_right = 1
	label.rect_size.y = 20
	label.margin_top = $Labels.get_child_count() * label.rect_size.y

	if not align in [Label.ALIGN_CENTER, Label.ALIGN_FILL, Label.ALIGN_LEFT, Label.ALIGN_RIGHT]:
		align = Label.ALIGN_CENTER
	label.align = align
	match label.align:
		Label.ALIGN_RIGHT:
			label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		Label.ALIGN_LEFT:
			label.grow_horizontal = Control.GROW_DIRECTION_END
		_:
			label.grow_horizontal = Control.GROW_DIRECTION_BOTH

	if not valign in [Label.VALIGN_BOTTOM, Label.VALIGN_CENTER, Label.VALIGN_FILL, Label.VALIGN_TOP]:
		valign = Label.VALIGN_CENTER
	label.valign = valign
	match label.valign:
		Label.VALIGN_BOTTOM:
			label.grow_vertical = Control.GROW_DIRECTION_BEGIN
		Label.VALIGN_TOP:
			label.grow_vertical = Control.GROW_DIRECTION_END
		_:
			label.grow_vertical = Control.GROW_DIRECTION_BOTH

	$Labels.add_child(label)

func set_label_text(label_name: String, text: String):
	if $Labels.has_node(label_name):
		$Labels.get_node(label_name).text = text
	else:
		push_warning("Debug label %s is not regiestered for path %s" % [label_name, get_path()])
