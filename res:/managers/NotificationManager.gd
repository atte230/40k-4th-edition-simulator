extends CanvasLayer

# NotificationManager.gd
# Simple popup/toast system for displaying short rule notifications (e.g., "Hammer of Wrath", "Furious Charge").
# Attach as a child of the root viewport (autoload-like) or let callers instantiate it on demand.

class_name NotificationManager

@export var font: Font
@export var default_color: Color = Color(1, 0.95, 0.6)
@export var duration: float = 2.0
@export var rise_distance: float = 40.0

func _ready() -> void:
	# Make sure this layer is on top
	self.layer = 1

func show_message(text: String, color: Color = null, time: float = -1.0) -> void:
	if color == null:
		color = default_color
	if time <= 0.0:
		time = duration

	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	if font != null:
		lbl.add_theme_font_override("font", font)
	lbl.horizontal_alignment = Label.HorizontalAlignment.CENTER
	lbl.anchors_preset = Control.PRESET_TOP_WIDE
	lbl.margin_top = 10
	lbl.margin_left = 0
	lbl.margin_right = 0
	lbl.margin_bottom = 30
	add_child(lbl)

	# Animate: fade out and move up
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# move up
	var start_y = lbl.margin_top
	var end_y = start_y - rise_distance
	tween.tween_property(lbl, "margin_top", end_y, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Queue free after tween
	tween.connect("finished", Callable(self, "_on_tween_finished"), [lbl])

func _on_tween_finished(lbl: Label) -> void:
	if is_instance_valid(lbl):
		lbl.queue_free()
