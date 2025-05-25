class_name FunctionVisualizerTimeControlView
extends Node

@export
var FunctionVisualizer : FunctionVisualizer2D

@export
var TimeTextLabel : Label

@export
var TimeSlider : Slider

@export
var TimeResetButton : Button

@export
var TimePauseButton : Button

func _ready():
	TimeTextLabel.text = "t = %.3f" % (FunctionVisualizer.GetCurrentTime())
	TimeSlider.value = FunctionVisualizer.GetCurrentTime()
	TimeSlider.max_value = FunctionVisualizer.MaxTime
	TimeSlider.min_value = 0
	TimeSlider.step = 0.01
	TimeSlider.value_changed.connect(_on_TimeSlider_value_changed)
	TimeResetButton.pressed.connect(_on_TimeResetButton_pressed)
	TimePauseButton.pressed.connect(_on_TimePauseButton_pressed)
	
func _process(delta: float) -> void:
	TimeTextLabel.text = "t = %.3f" % (FunctionVisualizer.GetCurrentTime())
	TimeSlider.value = FunctionVisualizer.GetCurrentTime()

func _on_TimeSlider_value_changed(value):
	FunctionVisualizer.SetCurrentTime(value)

func _on_TimeResetButton_pressed():
	FunctionVisualizer.ResetTime()

func _on_TimePauseButton_pressed():
	if FunctionVisualizer.IsPausingTime():
		FunctionVisualizer.ResumeTime();
	else:
		FunctionVisualizer.PauseTime();	
		
		
func _exit_tree() -> void:
	TimeSlider.value_changed.disconnect(_on_TimeSlider_value_changed)
	TimeResetButton.pressed.disconnect(_on_TimeResetButton_pressed)
	TimePauseButton.pressed.disconnect(_on_TimePauseButton_pressed)