extends Control

# Faction Selector Modal
# Allows player to choose between Space Marines and Orks

signal faction_selected(faction_name: String)

@onready var space_marines_btn = $VBoxContainer/SpaceMarinesBtn
@onready var orks_btn = $VBoxContainer/OrksBtn
@onready var title_label = $VBoxContainer/TitleLabel
@onready var description_label = $VBoxContainer/DescriptionLabel

func _ready():
	# Connect button signals
	space_marines_btn.pressed.connect(_on_space_marines_selected)
	orks_btn.pressed.connect(_on_orks_selected)
	
	# Make this modal (blocks input to background)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_space_marines_selected():
	faction_selected.emit("space_marines")
	queue_free()

func _on_orks_selected():
	faction_selected.emit("orks")
	queue_free()
