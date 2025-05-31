@tool
class_name FunctionInputEdit
extends Control

@export
var Index: int = 0
@export
var DefaultColor: Color = Color(0.5, 0.5, 0.5)

@export
var SyntaxHighligherResourceTemplate: SyntaxHighlighter
@export
var FuncLabelTemplate: String = "f<i>(x, t) = "

@onready
var m_FuncNameLabel : RichTextLabel = $HBox/RichTextLabel
@onready
var m_ErrorMessageLabel :Label = $HBox/CodeEdit/ErrorLabel

var m_ColorPickerButton: ColorPickerButton
var m_CodeEdit: CodeEdit
var SyntaxHighligherInstance: SyntaxHighlighter
signal fsl_changed(textEdit: FunctionInputEdit, index: int, text: String)
var m_IsContentValid: bool

var m_HeightBeforeFocus : float
var m_DefaultLineBackGroundColor: Color

var m_CurrentGLSLCode: String = ""
const s_ErrorLineColor: Color = Color(0.78039217, 0.36078432, 0.36078432)

var Visualizer : FunctionVisualizer2D = null

var IsContentValid:
	get:
		return m_IsContentValid

var Content:
	get:
		return m_CurrentGLSLCode
	set(value):
		m_CodeEdit.set_text(value);
		ReValidateInput();

var m_FslParser : FslParser = FslParser.new()
var m_ValidIdentifiers : Array[String] = []

func _ready():
	m_FuncNameLabel.text = FuncLabelTemplate.replace("<i>", str(Index))
	m_ColorPickerButton = $HBox/ColorPickerButton
	m_ColorPickerButton.color = DefaultColor
	m_CodeEdit = $HBox/CodeEdit
	m_DefaultLineBackGroundColor = m_CodeEdit.get_line_background_color(0)
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
		"U", "V", "W", "X", "Y", "Z", "\t"
	]
	m_CodeEdit.focus_entered.connect(_on_focus_entered)
	m_CodeEdit.focus_exited.connect(_on_focus_exited)
	m_CodeEdit.code_completion_requested.connect(_on_code_completion_requested)

func ReValidateInput() -> bool:
	var content                         := m_CodeEdit.text
	var result : FslParser.ParseContext =  m_FslParser.parse(content, Visualizer.GetValidFunctionNames() , Visualizer.GetValidVariableNames())
	if result == null or not result.success:
		print("Error parsing function expression: " + content);
		print(result.message);
		m_ErrorMessageLabel.text = result.message;
		MarkContentValid(false);
		return false;
	else:
		print("Successfully parsed function expression: " + content)
		m_CurrentGLSLCode = result.ast.to_glsl();
		print(m_CurrentGLSLCode);
		MarkContentValid(true);
		m_ErrorMessageLabel.text = "";
		return true;

func _on_text_changed():
	if ReValidateInput():
		fsl_changed.emit(self, Index, m_CurrentGLSLCode);
	m_CodeEdit.request_code_completion()

func _on_code_completion_requested():
	var allFunctions := FunctionLib2D.BuiltinFunctions
	var word := m_CodeEdit.get_word_under_caret(0)
	for function in allFunctions:
		if function.Name.begins_with(word):
			var functionCall := function.GetFunctionCallPattern()
			m_CodeEdit.add_code_completion_option(CodeEdit.KIND_FUNCTION, functionCall, functionCall)
	m_CodeEdit.update_code_completion_options(false)

func _on_focus_entered():
	var customMinSize := self.custom_minimum_size
	m_HeightBeforeFocus = customMinSize.y
	self.custom_minimum_size = Vector2(customMinSize.x, m_HeightBeforeFocus + 120)

func _on_focus_exited():
	var customMinSize := self.custom_minimum_size
	self.custom_minimum_size = Vector2(customMinSize.x, m_HeightBeforeFocus)

func _exit_tree() -> void:
	if SyntaxHighligherInstance != null:
		m_CodeEdit.set_syntax_highlighter(null)
		SyntaxHighligherInstance = null


func MarkContentValid(valid: bool) -> void:
	m_IsContentValid = valid
	# Make label red if invalid
	if not valid:
		m_ErrorMessageLabel.visible = true
		for i in range(m_CodeEdit.get_line_count()):
			m_CodeEdit.set_line_background_color(i, s_ErrorLineColor)
	else:
		m_ErrorMessageLabel.visible = false
		for i in range(m_CodeEdit.get_line_count()):
			m_CodeEdit.set_line_background_color(i, m_DefaultLineBackGroundColor)
