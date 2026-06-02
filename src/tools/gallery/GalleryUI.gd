extends Control

@onready var search_box = $TopBar/SearchBox
@onready var pack_dropdown = $TopBar/PackDropdown
@onready var generator = $"../../Generator"
@onready var camera = $"../../FlyCamera"

@onready var info_panel = $InfoPanel
@onready var model_name_label = $InfoPanel/NameLabel
@onready var model_pack_label = $InfoPanel/PackLabel
@onready var model_path_label = $InfoPanel/PathLabel
@onready var copy_button = $InfoPanel/CopyButton

@onready var status_bar = $StatusBar
@onready var progress_bar = $StatusBar/ProgressBar
@onready var progress_label = $StatusBar/ProgressLabel

var hovered_model_path: String = ""

func _ready():
    # Setup dropdown
    pack_dropdown.clear()
    var packs = generator.get_pack_list()
    for p in packs:
        pack_dropdown.add_item(p)
        
    # Connect UI signals
    search_box.text_changed.connect(_on_search_changed)
    pack_dropdown.item_selected.connect(_on_pack_selected)
    copy_button.pressed.connect(_on_copy_pressed)
    
    # Connect generator & camera signals
    generator.loading_progress.connect(_on_loading_progress)
    generator.loading_completed.connect(_on_loading_completed)
    camera.model_hovered.connect(_on_model_hovered)
    
    # Hide info panel by default
    info_panel.visible = false
    status_bar.visible = false

func _on_search_changed(new_text: String):
    var selected_idx = pack_dropdown.selected
    var pack_filter = pack_dropdown.get_item_text(selected_idx)
    generator.generate_gallery(new_text, pack_filter)

func _on_pack_selected(index: int):
    var search_text = search_box.text
    var pack_filter = pack_dropdown.get_item_text(index)
    generator.generate_gallery(search_text, pack_filter)

func _on_copy_pressed():
    if hovered_model_path != "":
        DisplayServer.clipboard_set(hovered_model_path)
        # Briefly change button text to indicate success
        copy_button.text = "Copied!"
        await get_tree().create_timer(1.0).timeout
        copy_button.text = "Copy Path"

func _on_model_hovered(info: Dictionary):
    if info.is_empty():
        info_panel.visible = false
        hovered_model_path = ""
    else:
        info_panel.visible = true
        model_name_label.text = "Name: " + info.name
        model_pack_label.text = "Pack: " + info.pack
        model_path_label.text = "Path: " + info.path
        hovered_model_path = info.path

func _on_loading_progress(current: int, total: int):
    status_bar.visible = true
    progress_bar.max_value = total
    progress_bar.value = current
    progress_label.text = "Loading models: %d / %d" % [current, total]

func _on_loading_completed():
    status_bar.visible = false
