extends Node

@export
var VarName : String = "A";
@export
var VarValue : float = 0;
@export
var MinValue : float = -10;
@export
var MaxValue : float = 10;


@onready
var NameInput : LineEdit = $Layout/NameInput;
@onready
var ValueSlider : HSlider = $Layout/ValueSlider;
@onready
var ValueInput : LineEdit = $Layout/ValueInput;
@onready
var MinValueInput : LineEdit = $Layout/MinValueInput;
@onready
var MaxValueInput : LineEdit = $Layout/MaxValueInput;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NameInput.text = VarName;
	ValueInput.text = str(VarValue);
	ValueSlider.value = VarValue;
	ValueSlider.min_value = MinValue;
	ValueSlider.max_value = MaxValue;
	ValueSlider.step = 0.001;
	MinValueInput.text = str(MinValue);
	MaxValueInput.text = str(MaxValue);
	ValueInput.text_changed.connect(_on_ValueInput_text_changed)
	ValueSlider.value_changed.connect(_on_ValueSlider_value_changed)
	MinValueInput.text_changed.connect(_on_MinValueInput_text_changed)
	MaxValueInput.text_changed.connect(_on_MaxValueInput_text_changed)

func _on_ValueInput_text_changed(newString : String) -> void:
	if newString.is_valid_float():
		VarValue = newString.to_float();
		ValueSlider.value = VarValue;

func _on_ValueSlider_value_changed(newValue : float) -> void:
	VarValue = newValue;
	ValueInput.text = str(VarValue);

func _on_MinValueInput_text_changed(newString : String) -> void:
	if newString.is_valid_float():
		MinValue = newString.to_float();
		ValueSlider.min_value = MinValue;	
	
func _on_MaxValueInput_text_changed(newString : String) -> void:
	if newString.is_valid_float():
		MaxValue = newString.to_float();
		ValueSlider.max_value = MaxValue;

func _exit_tree() -> void:
	ValueInput.text_changed.disconnect(_on_ValueInput_text_changed)
	ValueSlider.value_changed.disconnect(_on_ValueSlider_value_changed)
	MinValueInput.text_changed.disconnect(_on_MinValueInput_text_changed)
	MaxValueInput.text_changed.disconnect(_on_MaxValueInput_text_changed)
