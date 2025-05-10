extends Node
class_name FunctionVisualizer2D

@export var m_FunctionCodeInput: TextEdit;
@export var m_DynamicShader : Shader;
@export var m_DisplayItem : CanvasItem

var m_RenderMaterial : ShaderMaterial;
var m_Time : float = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	m_Time = 0.0;
	
func InitializeIfNeeded() -> void:
	if not m_DynamicShader:
		m_DynamicShader = Shader.new();
		m_DynamicShader.code = m_FunctionCodeInput.text;
		
	if not m_RenderMaterial:
		m_RenderMaterial = ShaderMaterial.new();
		m_RenderMaterial.shader = m_DynamicShader;
		m_RenderMaterial.set_shader_parameter("u_Time", m_Time);

func ReleaseResourcesIfNeeded() -> void:
	if m_RenderMaterial:
		m_RenderMaterial.shader = null;
		m_RenderMaterial.free()
		m_RenderMaterial = null;
	if m_DynamicShader:
		m_DynamicShader.free()
		m_DynamicShader = null;
		
		
func UpdateMaterialProperties() -> void:
	if not m_RenderMaterial or not m_DynamicShader or not m_FunctionCodeInput or not m_DisplayItem:
		return;
	if not m_RenderMaterial.shader:
		return;
		
	m_RenderMaterial.set_shader_parameter("u_Time", m_Time);
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	m_Time += delta;
	InitializeIfNeeded();
	UpdateMaterialProperties();
	if m_DisplayItem:
		m_DisplayItem.material = m_RenderMaterial;
	
	
func _exit_tree() -> void:
	ReleaseResourcesIfNeeded();
	queue_free();
		
