extends Node

@export
var FuncVisualizer2D : FunctionVisualizer2D

@export
var MousePosLabel: Label

@export
var TimeLabel: Label

@export
var ZoomInfoLevel: Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not FuncVisualizer2D:
		return
	if MousePosLabel:
		MousePosLabel.text = "Mouse Pos: " + str(FuncVisualizer2D.GetMousePosition())
	if TimeLabel:
		TimeLabel.text = "t = " + str(FuncVisualizer2D.GetCurrentTime())
	if ZoomInfoLevel:
		ZoomInfoLevel.text = "BoundsMin = " + str(FuncVisualizer2D.GetFunctionCoordBoundsMin()) + "\n" + \
 		" BoundsMax = " + str(FuncVisualizer2D.GetFunctionCoordBoundsMax()) + "\n" +  \
		" ZoomLevel = " + str(FuncVisualizer2D.GetZoomLevel()) + "\n" +  \
		" GridLineIntervals = " + str(FuncVisualizer2D.GetGridLineIntervals());