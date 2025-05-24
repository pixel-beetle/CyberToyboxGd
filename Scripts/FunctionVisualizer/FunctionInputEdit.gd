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

signal text_changed(textEdit: FunctionInputEdit, index: int, text: String)

var m_IsContentValid : bool
var IsContentValid:
	get:
		return m_IsContentValid

var Content:
	get:
		return m_CodeEdit.get_text()

func _ready():
	m_ColorPickerButton = $HBox/ColorPickerButton
	m_ColorPickerButton.color = DefaultColor
	m_CodeEdit = $HBox/CodeEdit
	if SyntaxHighligherResourceTemplate != null:
		SyntaxHighligherInstance = SyntaxHighligherResourceTemplate.duplicate()
		m_CodeEdit.set_syntax_highlighter(SyntaxHighligherInstance)
	m_CodeEdit.text_changed.connect(_on_text_changed)

func _on_text_changed():
	text_changed.emit(self, Index, m_CodeEdit.get_text())
	
func _exit_tree() -> void:
	if SyntaxHighligherInstance != null:
		m_CodeEdit.set_syntax_highlighter(null)
		SyntaxHighligherInstance = null
		
func MarkContentValid(valid: bool) -> void:
	m_IsContentValid = valid
	if valid:
		m_ColorPickerButton.color = DefaultColor
	else:
		m_ColorPickerButton.color = Color(1, 0, 0)