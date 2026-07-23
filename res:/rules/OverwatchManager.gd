extends Node

# OverwatchManager.gd
# Presents a popup to the player allowing them to select which defender units will perform Overwatch.

signal overwatch_confirmed(selected_units)

func prompt_overwatch(defenders:Array) -> Node:
	# Build a WindowDialog with a list of checkboxes for each defender
	var popup = WindowDialog.new()
	popup.title = "Overwatch - Select defenders"
	popup.rect_min_size = Vector2(420, 300)

	var vbox = VBoxContainer.new()
	popup.add_child(vbox)

	var info = Label.new()
	info.text = "Select units to set Overwatch for this charge declaration:" 
	vbox.add_child(info)

	var scroll = ScrollContainer.new()
	scroll.v_size_flags = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	scroll.add_child(list)

	# store checkboxes mapping to units
	var entries := []
	for d in defenders:
		if d == null:
			continue
		var hb = HBoxContainer.new()
		var cb = CheckBox.new()
		cb.text = d.name
		# default to current meta if present
		var current = false
		if d.has_meta("overwatch"):
			current = bool(d.get_meta("overwatch"))
		cb.pressed = current
		hb.add_child(cb)
		list.add_child(hb)
		entries.append({"unit": d, "checkbox": cb})

	var btns = HBoxContainer.new()
	var confirm = Button.new()
	confirm.text = "Confirm"
	btns.add_child(confirm)
	var cancel = Button.new()
	cancel.text = "Cancel"
	btns.add_child(cancel)
	vbox.add_child(btns)

	confirm.connect("pressed", Callable(self, "_on_confirm_pressed"), [popup, entries])
	cancel.connect("pressed", Callable(self, "_on_cancel_pressed"), [popup])

	add_child(popup)
	popup.popup_centered()
	return self

func _on_confirm_pressed(popup:WindowDialog, entries:Array) -> void:
	var selected := []
	for e in entries:
		var cb = e["checkbox"]
		if cb and cb.pressed:
			selected.append(e["unit"])
		# update meta on unit immediately so TurnManager can read it
		if e["unit"] != null:
			e["unit"].set_meta("overwatch", cb.pressed)
	popup.queue_free()
	emit_signal("overwatch_confirmed", selected)

func _on_cancel_pressed(popup:WindowDialog) -> void:
	# On cancel, emit empty list and close
	popup.queue_free()
	emit_signal("overwatch_confirmed", [])
