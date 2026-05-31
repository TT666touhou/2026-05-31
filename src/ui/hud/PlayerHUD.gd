extends Control
class_name PlayerHUD

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaBar

var _health_comp: Node = null
var _stamina_comp: Node = null
var _mana_comp: Node = null

func setup(health: Node, stamina: Node, mana: Node) -> void:
	_health_comp = health
	_stamina_comp = stamina
	_mana_comp = mana
	
	if _health_comp:
		health_bar.max_value = _health_comp.max_health
		health_bar.value = _health_comp.current_health
		_health_comp.health_changed.connect(_on_health_changed)
		
	if _stamina_comp:
		stamina_bar.max_value = _stamina_comp.max_stamina
		stamina_bar.value = _stamina_comp.current_stamina
		_stamina_comp.stamina_changed.connect(_on_stamina_changed)
		
	if _mana_comp:
		mana_bar.max_value = _mana_comp.max_mana
		mana_bar.value = _mana_comp.current_mana
		_mana_comp.mana_changed.connect(_on_mana_changed)

func _on_health_changed(_old_val: float, new_val: float) -> void:
	_tween_bar(health_bar, new_val)

func _on_stamina_changed(_old_val: float, new_val: float) -> void:
	stamina_bar.value = new_val # Stamina usually doesn't tween to feel responsive

func _on_mana_changed(_old_val: float, new_val: float) -> void:
	_tween_bar(mana_bar, new_val)

func _tween_bar(bar: ProgressBar, target: float) -> void:
	var tween = create_tween()
	tween.tween_property(bar, "value", target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
