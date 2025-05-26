@tool
extends Control
class_name FunctionInputEdit

@export
var Index: int = 0
@export
var DefaultColor: Color = Color(0.5, 0.5, 0.5)

@export
var SyntaxHighligherResourceTemplate: SyntaxHighlighter
@export
var FuncLabelTemplate: String = "f<i>(x, t) = "

@onready
var m_FuncNameLabel = $HBox/RichTextLabel

var m_ColorPickerButton: ColorPickerButton
var m_CodeEdit: CodeEdit
var SyntaxHighligherInstance: SyntaxHighlighter
signal text_changed(textEdit: FunctionInputEdit, index: int, text: String)
var m_IsContentValid: bool

var m_HeightBeforeFocus : float

var IsContentValid:
	get:
		return m_IsContentValid

var Content:
	get:
		return m_CodeEdit.get_text()


func _ready():
	m_FuncNameLabel.text = FuncLabelTemplate.replace("<i>", str(Index))
	m_ColorPickerButton = $HBox/ColorPickerButton
	m_ColorPickerButton.color = DefaultColor
	m_CodeEdit = $HBox/CodeEdit
	if SyntaxHighligherResourceTemplate != null:
		SyntaxHighligherInstance = SyntaxHighligherResourceTemplate.duplicate()
		m_CodeEdit.set_syntax_highlighter(SyntaxHighligherInstance)
	m_CodeEdit.text_changed.connect(_on_text_changed)
	m_CodeEdit.code_completion_prefixes = [".", 
		"a", "b", "c", "d", "e", "f", "g", 
		"h", "i", "j", "k", "l", "m", "n", 
		"o", "p", "q", "r", "s", "t", 
		"u", "v", "w", "x", "y", "z", 
		"A", "B", "C", "D", "E", "F", "G",
		"H", "I", "J", "K", "L", "M", "N", 
		"O", "P", "Q", "R", "S", "T", 
		"U", "V", "W", "X", "Y", "Z"
	]
	m_CodeEdit.focus_entered.connect(_on_focus_entered)
	m_CodeEdit.focus_exited.connect(_on_focus_exited)
	m_CodeEdit.code_completion_requested.connect(_on_code_completion_requested)

func _on_text_changed():
	text_changed.emit(self, Index, m_CodeEdit.get_text())
	m_CodeEdit.request_code_completion()

func _on_code_completion_requested():
	var allFunctions := FunctionLib2D.BuiltinFunctions
	var word := m_CodeEdit.get_word_under_caret()
	for function in allFunctions:
		if function.Name.begins_with(word):
			var functionCall := function.GetFunctionCallPattern()
			m_CodeEdit.add_code_completion_option(CodeEdit.KIND_FUNCTION, functionCall, functionCall)
	m_CodeEdit.update_code_completion_options(false)

func _on_focus_entered():
	var customMinSize := self.custom_minimum_size
	m_HeightBeforeFocus = customMinSize.y
	self.custom_minimum_size = Vector2(customMinSize.x, m_HeightBeforeFocus + 150)

func _on_focus_exited():
	var customMinSize := self.custom_minimum_size
	self.custom_minimum_size = Vector2(customMinSize.x, m_HeightBeforeFocus)

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
