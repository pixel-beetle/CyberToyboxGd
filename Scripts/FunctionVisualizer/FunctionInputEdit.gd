@tool
extends Node
class_name FunctionInputEdit

@export
var Index : int = 0

@export
var DefaultColor : Color = Color(0.5, 0.5, 0.5)

@export
var SyntaxHighligherResourceTemplate : SyntaxHighlighter

var m_ColorPickerButton : ColorPickerButton
var m_CodeEdit : CodeEdit
var SyntaxHighligherInstance : SyntaxHighlighter

signal color_changed(color: Color)
signal text_changed(text: String)

func _ready():
	m_ColorPickerButton = $HBox/ColorPickerButton
	m_ColorPickerButton.color = DefaultColor
	m_CodeEdit = $HBox/CodeEdit
	if SyntaxHighligherResourceTemplate != null:
		SyntaxHighligherInstance = SyntaxHighligherResourceTemplate.duplicate()
		m_CodeEdit.set_syntax_highlighter(SyntaxHighligherInstance)
	m_CodeEdit.text_changed.connect(_on_text_changed)

func _on_text_changed():
	text_changed.emit(Index, m_CodeEdit.get_text())
	
func _exit_tree() -> void:
	if SyntaxHighligherInstance != null:
		m_CodeEdit.set_syntax_highlighter(null)
		SyntaxHighligherInstance = null
