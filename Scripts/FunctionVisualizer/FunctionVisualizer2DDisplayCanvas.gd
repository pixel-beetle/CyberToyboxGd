extends TextureRect
class_name FunctionVisualizer2DDisplayCanvas

signal drag_moved(deltaPos : Vector2)
signal zoom_changed(deltaZoom : float)
signal mouse_moved(mousePos : Vector2)

var m_PrevDragPos : Vector2 = Vector2()
var m_IsDragging : bool = false

# Handle Input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not m_IsDragging:
					m_PrevDragPos = event.position
					m_IsDragging = true
					#print("Started dragging", event.position)
				else:
					var delta: Vector2 = event.position - m_PrevDragPos
					#print("Dragging", delta)
					m_PrevDragPos = event.position
					drag_moved.emit(delta)
			else:
				m_IsDragging = false
				#print("Stopped dragging", event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_changed.emit(1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_changed.emit(-1.0)
	if event is InputEventMouseMotion:
		mouse_moved.emit(event.position)
		if m_IsDragging:
			var delta: Vector2 = event.position - m_PrevDragPos
			#print("Dragging", delta)
			m_PrevDragPos = event.position
			drag_moved.emit(delta)
