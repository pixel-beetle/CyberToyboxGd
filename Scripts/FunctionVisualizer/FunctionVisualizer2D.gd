extends Node
class_name FunctionVisualizer2D


var m_DynamicShader : Shader;

@export var FunctionCoordBoundsMin : Vector2 = Vector2(-2, -2);
@export var FunctionCoordBoundsMax : Vector2 = Vector2(2, 2);


@export var DisplayItem : FunctionVisualizer2DDisplayCanvas


var m_RenderMaterial : ShaderMaterial;
var m_Time : float = 0.0;

var m_FunctionCoordOffset : Vector2 = Vector2(0, 0);
var m_FunctionInputEdits : Array[FunctionInputEdit] = [];

func GetCurrentTime() -> float:
	return m_Time;

func ResetCurrentTime() -> void:
	m_Time = 0.0;	

func _ready() -> void:
	ResetCurrentTime();
	
	DisplayItem.drag_moved.connect(_on_drag_moved)
	
	m_FunctionInputEdits = [];
	var children := find_children("","FunctionInputEdit",true,true);
	for child in children:
		var tryCast := child as FunctionInputEdit
		if tryCast != null:
			m_FunctionInputEdits.append(tryCast);
			tryCast.text_changed.connect(_on_FunctionInputEdit_text_changed)

func _on_FunctionInputEdit_text_changed(index :int, content : String) -> void:
	print("FunctionInputEdit_text_changed: ", index, content)

func _on_drag_moved(canvasDelta: Vector2) -> void:
	var funcCoordDelta := canvasDelta;
	funcCoordDelta.y = -funcCoordDelta.y;
	
	var canvasSize := DisplayItem.size;
	var factor := (FunctionCoordBoundsMax - FunctionCoordBoundsMin) / canvasSize;
	funcCoordDelta *= factor;
	
	m_FunctionCoordOffset -= funcCoordDelta;

func InitializeIfNeeded() -> void:
	if not m_DynamicShader:
		m_DynamicShader = Shader.new();
		m_DynamicShader.code = SHADER_CODE_TEMPLATE;
		
	if not m_RenderMaterial:
		m_RenderMaterial = ShaderMaterial.new();
		m_RenderMaterial.shader = m_DynamicShader;
		m_RenderMaterial.set_shader_parameter("_Time", m_Time);

func ReleaseResourcesIfNeeded() -> void:
	if m_RenderMaterial:
		m_RenderMaterial.shader = null;
		m_RenderMaterial.unreference()
		m_RenderMaterial = null;
	if m_DynamicShader:
		m_DynamicShader.unreference()
		m_DynamicShader = null;
	m_FunctionInputEdits.clear()
		
func UpdateMaterialProperties() -> void:
	if not m_RenderMaterial or not m_DynamicShader or not DisplayItem:
		return;
	if not m_RenderMaterial.shader:
		return;
		
	m_RenderMaterial.set_shader_parameter("_Time", m_Time);
	var funcCoordBounds := Vector4(FunctionCoordBoundsMin.x, FunctionCoordBoundsMin.y, FunctionCoordBoundsMax.x, FunctionCoordBoundsMax.y)
	funcCoordBounds.x += m_FunctionCoordOffset.x;
	funcCoordBounds.y += m_FunctionCoordOffset.y;
	funcCoordBounds.z += m_FunctionCoordOffset.x;
	funcCoordBounds.w += m_FunctionCoordOffset.y;
	m_RenderMaterial.set_shader_parameter("_FunctionCoordBoundsMinMax", funcCoordBounds);
	for input in m_FunctionInputEdits:
		m_RenderMaterial.set_shader_parameter("_Color" + str(input.Index), input.m_ColorPickerButton.color);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	m_Time += delta;
	InitializeIfNeeded();
	UpdateMaterialProperties();
	if DisplayItem:
		DisplayItem.material = m_RenderMaterial;
	
	
func _exit_tree() -> void:
	ReleaseResourcesIfNeeded();
	queue_free();

const SHADER_CODE_TEMPLATE = """
shader_type canvas_item;

uniform float _Time;
uniform vec4 _FunctionCoordBoundsMinMax;
varying flat mat4 _WorldToScreenMatrix; 

uniform vec4 _Color1;
uniform vec4 _Color2;
uniform vec4 _Color3;
uniform vec4 _Color4;
uniform vec4 _Color5;
uniform vec4 _Color6;

vec2 UVToFuncSpaceCoord(vec2 uv)
{
	vec2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	vec2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return mix(boundsMin, boundsMax, uv);
}

vec2 FuncSpaceCoordToUV(vec2 coord)
{
	vec2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	vec2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return (coord - boundsMin) / (boundsMax - boundsMin);
}

vec2 FuncSpaceCoordToScreenUV(vec2 coord)
{
	vec2 uv = FuncSpaceCoordToUV(coord);
	vec2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	vec2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return (coord - boundsMin) / (boundsMax - boundsMin);
}

float f1(float x)
{
	return x * x;
}

float f2(float x)
{
	return x * x * x;
}

float f3(float x)
{
	return smoothstep(0,1,x);
}

float f4(float x)
{
	return sin(x + _Time);
}

float f5(float x)
{
	return x;
}

float f6(float x)
{
	return abs(x) < 1e-6f ? 0.0f : 1.0f / x;
}

float GetLerpFactor(vec2 coord, float funcY, float funcSlope)
{
	float dist = abs(coord.y - funcY);
	float scaler = length(vec2(dFdx(coord.x), dFdy(coord.y))) * 1000.0f;
	float upper = mix(0.001, 0.05, clamp(abs(funcSlope) * 0.01f, 0, 1));
	return smoothstep(upper * scaler, 0, dist);
}

#define DECLARE_FUNC_ApplyFunctionGraph(index) vec4 ApplyFunctionGraph_##index(vec4 inColor, vec4 funcGraphColor, vec2 coord) { \
	float epsilon = 0.0001f; \
	float funcValue 	 = f##index(coord.x); \
	float funcValueLeft  = f##index(coord.x - epsilon); \
	float funcValueRight = f##index(coord.x + epsilon); \
	float slope = (funcValueRight - funcValueLeft) / epsilon; \
	float factor = GetLerpFactor(coord, funcValue, slope); \
	return mix(inColor, funcGraphColor, factor); \
}

DECLARE_FUNC_ApplyFunctionGraph(1)
DECLARE_FUNC_ApplyFunctionGraph(2)
DECLARE_FUNC_ApplyFunctionGraph(3)
DECLARE_FUNC_ApplyFunctionGraph(4)
DECLARE_FUNC_ApplyFunctionGraph(5)
DECLARE_FUNC_ApplyFunctionGraph(6)



void vertex()
{
	_WorldToScreenMatrix = SCREEN_MATRIX * CANVAS_MATRIX;
}

vec4 ApplyGridLines(vec4 inColor, vec4 gridColor, vec2 coord, float gridSize, float gridLinePixelWidth)
{
	vec2 gridSize2D = vec2(gridSize, gridSize);
	vec2 gridId = floor(coord / gridSize2D);
	vec2 gridMin = gridId * gridSize2D;
	vec2 gridMax = gridMin + gridSize2D;
	
	float pixelToFuncCoordFactor = dFdx(coord.x);
	float halfGridLineWidth = gridLinePixelWidth * 0.5f * pixelToFuncCoordFactor;

	bool isLine = (abs(coord.x - gridMin.x) < halfGridLineWidth) 
					|| (abs(coord.x - gridMax.x) < halfGridLineWidth)
					|| (abs(coord.y - gridMin.y) < halfGridLineWidth)
					|| (abs(coord.y - gridMax.y) < halfGridLineWidth);
	float factor = isLine ? 1.0 : 0.0;
	return mix(inColor, gridColor, factor);
}

void fragment() 
{	
	vec4 backgroundColor = vec4(0.16, 0.16, 0.16, 1);
	vec2 uv = UV;
	uv.y = 1.0f - uv.y;
	
	vec2 coord = UVToFuncSpaceCoord(uv);
	
	vec4 finalColor = backgroundColor;
	
	
	finalColor = ApplyGridLines(finalColor, vec4(0.25, 0.25, 0.25, 1), coord, 0.1, 1);
	finalColor = ApplyGridLines(finalColor, vec4(0.45, 0.45, 0.45, 1), coord, 0.5, 1.5);
	finalColor = ApplyFunctionGraph_1(finalColor, _Color1, coord);
	finalColor = ApplyFunctionGraph_2(finalColor, _Color2, coord);
	finalColor = ApplyFunctionGraph_3(finalColor, _Color3, coord);
	finalColor = ApplyFunctionGraph_4(finalColor, _Color4, coord);
	finalColor = ApplyFunctionGraph_5(finalColor, _Color5, coord);
	finalColor = ApplyFunctionGraph_6(finalColor, _Color6, coord);
	finalColor.a = 1.0f;
	COLOR = finalColor;
}
"""
