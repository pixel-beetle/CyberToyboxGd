extends Node
class_name FunctionVisualizer2D

@export var DisplayItem : FunctionVisualizer2DDisplayCanvas

var m_RenderMaterial : ShaderMaterial;
var m_DynamicShader : Shader;
var m_DummyShaderForCompileCheck : Shader;
var m_Time : float = 0.0;

var m_FuncUnitsPerPixel : float = 0.01;
var m_FunctionCoordBoundsMin : Vector2 = Vector2(-2, -2);
var m_FunctionCoordBoundsMax : Vector2 = Vector2(2, 2);
var m_ZoomLevel : float = 0.0;

var m_MousePos : Vector2 = Vector2(0, 0);

var m_FunctionInputEdits : Array[FunctionInputEdit] = [];
var m_ParamsInitialized : bool = false;

func GetCurrentTime() -> float:
	return m_Time;

func GetFunctionCoordBoundsMin() -> Vector2:
	return m_FunctionCoordBoundsMin;
	
func GetFunctionCoordBoundsMax() -> Vector2:
	return m_FunctionCoordBoundsMax;

func GetZoomLevel() -> float:
	return m_ZoomLevel;

func CalculateGridSpacing(scale : float) -> float:
	# 基础单位（大约在scale=1时显示10条格线）
	var baseUnit := 2.0 / 10.0;  # 2.0是因为我们的坐标范围是[-1,1]
	# 根据缩放级别调整间距
	var logScale : float = log(scale) / log(10.0);
	var power : float = floor(logScale);
	var fraction :float = logScale - power;
	
	# 选择1, 2或5作为乘数
	var multiplier := 1.0;
	if fraction > log(5.0)/log(10.0):
		multiplier = 5.0;
	elif fraction > log(2.0)/log(10.0):
		multiplier = 2.0;
	
	return baseUnit * pow(10.0, power) * multiplier;


func GetGridLineIntervals() -> Vector2:
	var primary := CalculateGridSpacing(m_ZoomLevel);
	return Vector2(primary, primary * 5);
	
func GetMousePosition() -> Vector2:
	return m_MousePos;
	
func ResetCurrentTime() -> void:
	m_Time = 0.0;	

func InitializeParamatersIfNeeded() -> void:
	if m_ParamsInitialized:
		return;
	ResetCurrentTime();
	DisplayItem.drag_moved.connect(_on_drag_moved);
	DisplayItem.zoom_changed.connect(_on_zoom_changed);
	DisplayItem.mouse_moved.connect(_on_mouse_position_got);
	m_FunctionInputEdits = []
	m_FuncUnitsPerPixel = 0.005;
	m_MousePos = Vector2(0, 0);
	m_ZoomLevel = 1.0;
	m_FunctionCoordBoundsMin = DisplayItem.size * Vector2(-0.5, -0.5) * m_FuncUnitsPerPixel;
	m_FunctionCoordBoundsMax = DisplayItem.size * Vector2(0.5, 0.5) * m_FuncUnitsPerPixel;
	var children := find_children("","FunctionInputEdit",true,true);
	for child in children:
		var tryCast := child as FunctionInputEdit
		if tryCast != null:
			m_FunctionInputEdits.append(tryCast);
			tryCast.text_changed.connect(_on_FunctionInputEdit_text_changed);
	m_ParamsInitialized = true;

func _on_FunctionInputEdit_text_changed(textEdit: FunctionInputEdit, index :int, content : String) -> void:
	if RecompileForFunctionTextEditValidation(index, content):
		print("Invalid Input %s" % content)
		textEdit.MarkContentValid(true);
	else:
		print("Valid Input %s" % content)
		textEdit.MarkContentValid(false);
	print("FunctionInputEdit_text_changed: ", index, content)
	var shaderContent: String = GenerateDynamicFunctionShaderCode()
	print("Generated Shader Code: ", shaderContent)
	m_DynamicShader.code = shaderContent

func _on_drag_moved(canvasDelta: Vector2) -> void:
	var funcCoordDelta := canvasDelta;
	funcCoordDelta.y = -funcCoordDelta.y;
	funcCoordDelta *= m_FuncUnitsPerPixel;
	m_FunctionCoordBoundsMin -= funcCoordDelta
	m_FunctionCoordBoundsMax -= funcCoordDelta
	
func _on_zoom_changed(zoomDelta: float) -> void:
	var zoomFactor : float = 1.05
	if zoomDelta < 0:
		m_ZoomLevel *= zoomFactor;
		m_FuncUnitsPerPixel *= zoomFactor;
		m_FunctionCoordBoundsMin *= zoomFactor;
		m_FunctionCoordBoundsMax *= zoomFactor;
	else:
		m_ZoomLevel /= zoomFactor;
		m_FuncUnitsPerPixel /= zoomFactor;
		m_FunctionCoordBoundsMin /= zoomFactor;
		m_FunctionCoordBoundsMax /= zoomFactor;
		
func _on_mouse_position_got(mousePos: Vector2) -> void:
	m_MousePos = mousePos;
	
func InitializeIfNeeded() -> void:
	InitializeParamatersIfNeeded();
	if not m_DummyShaderForCompileCheck:
		m_DummyShaderForCompileCheck = Shader.new();
		m_DummyShaderForCompileCheck.code = SHADER_CODE_COMPILE_DUMMY_DEFAULT
		
	if not m_DynamicShader:
		m_DynamicShader = Shader.new();
		m_DynamicShader.code = SHADER_CODE_TEMPLATE.replace("//<DynamicGeneratedFunctions>", SHADER_DYNAMIC_FUNCTIONS_DEFAULT);
		
	if not m_RenderMaterial:
		m_RenderMaterial = ShaderMaterial.new();
		m_RenderMaterial.shader = m_DynamicShader;

func ReleaseResourcesIfNeeded() -> void:
	if m_RenderMaterial:
		m_RenderMaterial.shader = null;
		m_RenderMaterial.unreference()
		m_RenderMaterial = null;
	if m_DynamicShader:
		m_DynamicShader.unreference()
		m_DynamicShader = null;
	if m_DummyShaderForCompileCheck:
		m_DummyShaderForCompileCheck.unreference()
		m_DummyShaderForCompileCheck = null; 
	for input in m_FunctionInputEdits:
		input.text_changed.disconnect(_on_FunctionInputEdit_text_changed);	
	m_FunctionInputEdits.clear()
	DisplayItem.drag_moved.disconnect(_on_drag_moved);
	DisplayItem.zoom_changed.disconnect(_on_zoom_changed);
	DisplayItem.mouse_moved.disconnect(_on_mouse_position_got);
	
func UpdateMaterialProperties() -> void:
	if not m_RenderMaterial or not m_DynamicShader or not DisplayItem:
		return;
	if not m_RenderMaterial.shader:
		return;
		
	m_RenderMaterial.set_shader_parameter("_Time", m_Time);
	var funcCoordBounds := Vector4(m_FunctionCoordBoundsMin.x, m_FunctionCoordBoundsMin.y, m_FunctionCoordBoundsMax.x, m_FunctionCoordBoundsMax.y)
	m_RenderMaterial.set_shader_parameter("_FunctionCoordBoundsMinMax", funcCoordBounds);
	for input in m_FunctionInputEdits:
		m_RenderMaterial.set_shader_parameter("_Color" + str(input.Index), input.m_ColorPickerButton.color);
	var posSize := Vector4()
	posSize.x = DisplayItem.global_position.x;
	posSize.y = DisplayItem.global_position.y;
	posSize.z = DisplayItem.size.x;
	posSize.w = DisplayItem.size.y;
	m_RenderMaterial.set_shader_parameter("_CanvasItemPositionSize", posSize);
	m_RenderMaterial.set_shader_parameter("_FuncUnitsPerPixel", m_FuncUnitsPerPixel);
	var gridLineIntervals : Vector2 = GetGridLineIntervals();
	m_RenderMaterial.set_shader_parameter("_GridLineInterval", gridLineIntervals);

	
func RecompileForFunctionTextEditValidation(index :int, content : String) -> bool: 
	m_DummyShaderForCompileCheck.code = """
		shader_type canvas_item;
		uniform vec4 _Color;
		float fx(float x, float t){
			return <BODY>;
		}
		void fragment() {
			float f = fx(0.0, 0.0);
			COLOR = _Color;
		}
		""".replace("<BODY>", content);
	return not m_DummyShaderForCompileCheck.get_shader_uniform_list().is_empty()


func GenerateDynamicFunctionShaderCode() -> String:
	var uniformAndFunction_Define : String = ""
	var appyFunctionGraphs_Body : String = ""
	for input in m_FunctionInputEdits:
		if not input.IsContentValid:
			continue;
		uniformAndFunction_Define += """
			
			uniform float4 _Color<i>;
			float f<i>(float x, float t)
			{
				return <c>;
			}
			
			DECLARE_FUNC_GetLerpFactor(<i>)
			
			DECLARE_FUNC_ApplyFunctionGraph(<i>)
			
			""".replace("<i>", str(input.Index)).replace("<c>", input.Content);
		appyFunctionGraphs_Body += """
			
			finalColor = ApplyFunctionGraph_<i>(finalColor, _Color<i>, coord);
			
			""".replace("<i>", str(input.Index));
	var dynamicContent: String = uniformAndFunction_Define + """
	
	float4 AppyFunctionGraphs(float4 inColor, float2 coord)
	{
		float4 finalColor = inColor;
		<BODY>
		return finalColor;
	}

	""".replace("<BODY>", appyFunctionGraphs_Body);
	return SHADER_CODE_TEMPLATE.replace("//<DynamicGeneratedFunctions>", dynamicContent);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	m_Time += delta;
	if m_Time > 10000:
		m_Time = 0.0;
	InitializeIfNeeded();
	UpdateMaterialProperties();
	if DisplayItem:
		DisplayItem.material = m_RenderMaterial;
	
	
func _exit_tree() -> void:
	m_ParamsInitialized = false;
	ReleaseResourcesIfNeeded();
	queue_free();

const SHADER_CODE_COMPILE_DUMMY_DEFAULT :String = """
shader_type canvas_item;
uniform vec4 _Color;
void fragment() {
	COLOR = _Color;
}
"""

const SHADER_DYNAMIC_FUNCTIONS_DEFAULT : String = """

uniform float4 _Color1;
uniform float4 _Color2;
uniform float4 _Color3;
uniform float4 _Color4;
uniform float4 _Color5;
uniform float4 _Color6;

float f1(float x, float t)
{
	return x * x;
}

float f2(float x, float t)
{
	return x * x * x;
}

float f3(float x, float t)
{
	return smoothstep(0,1,x);
}

float f4(float x, float t)
{
	return sin(x + t);
}

float f5(float x, float t)
{
	return x;
}

float f6(float x, float t)
{
	return abs(x) < 1e-6f ? 0.0f : 1.0f / x;
}

DECLARE_FUNC_GetLerpFactor(1)
DECLARE_FUNC_GetLerpFactor(2)
DECLARE_FUNC_GetLerpFactor(3)
DECLARE_FUNC_GetLerpFactor(4)
DECLARE_FUNC_GetLerpFactor(5)
DECLARE_FUNC_GetLerpFactor(6)

DECLARE_FUNC_ApplyFunctionGraph(1)
DECLARE_FUNC_ApplyFunctionGraph(2)
DECLARE_FUNC_ApplyFunctionGraph(3)
DECLARE_FUNC_ApplyFunctionGraph(4)
DECLARE_FUNC_ApplyFunctionGraph(5)
DECLARE_FUNC_ApplyFunctionGraph(6)

float4 AppyFunctionGraphs(float4 inColor, float2 coord)
{
	float4 finalColor = inColor;
	finalColor = ApplyFunctionGraph_1(finalColor, _Color1, coord);
	finalColor = ApplyFunctionGraph_2(finalColor, _Color2, coord);
	finalColor = ApplyFunctionGraph_3(finalColor, _Color3, coord);
	finalColor = ApplyFunctionGraph_4(finalColor, _Color4, coord);
	finalColor = ApplyFunctionGraph_5(finalColor, _Color5, coord);
	finalColor = ApplyFunctionGraph_6(finalColor, _Color6, coord);
	return finalColor;
}


"""



const SHADER_CODE_TEMPLATE : String = """
shader_type canvas_item;

#define float2 vec2
#define float3 vec3
#define float4 vec4

#define float4x4 mat4
#define lerp mix


uniform float _Time;
uniform float4 _FunctionCoordBoundsMinMax;
uniform float4 _CanvasItemPositionSize;
uniform float2 _GridLineInterval;

varying flat float4x4 _WorldToScreenMatrix; 

float2 UVToFuncSpaceCoord(float2 uv)
{
	float2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	float2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return lerp(boundsMin, boundsMax, uv);
}

float2 UVToFuncSpaceCoord2(float2 uv)
{
	uv = uv - 0.5f;
	float aspectRatio = (_CanvasItemPositionSize.z / _CanvasItemPositionSize.w);
	uv.x *= aspectRatio;
	
	return uv * 5.0;
}

float2 FuncSpaceCoordToUV(float2 coord)
{
	float2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	float2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return (coord - boundsMin) / (boundsMax - boundsMin);
}

float2 FuncSpaceCoordToScreenUV(float2 coord)
{
	float2 uv = FuncSpaceCoordToUV(coord);
	float2 uv_TopIs0 = uv;
	uv_TopIs0.y = 1.0 - uv_TopIs0.y;
	
	float2 worldPosLeftTop = _CanvasItemPositionSize.xy;
	float2 worldSize = _CanvasItemPositionSize.zw;
	float2 worldPos = worldPosLeftTop + worldSize * uv_TopIs0;
	
	float4 clipPos = _WorldToScreenMatrix * float4(worldPos, 0, 1);
	float2 screenUV = clipPos.xy * 0.5f + 0.5f;
	return screenUV;
}

float2 FuncSpaceCoordToScreenPos(float2 coord, float2 screenSize)
{
	float2 screenUV = FuncSpaceCoordToScreenUV(coord);
	return screenUV * screenSize;
}

#define DECLARE_FUNC_GetLerpFactor(index) float GetLerpFactor##index(float2 coord, float funcY, float funcSlope) { \
	float minDist = 1e10; \
	float unitsPerPixel = dFdx(coord.x); \
	float xMin = coord.x - unitsPerPixel * 4.0; \
	float xMax = coord.x + unitsPerPixel * 4.0; \
	int steps = 128; \
	float dx = (xMax - xMin) / float(steps); \
	for (int i = 0; i < steps; ++i) \
	{ \
		float x = xMin + float(i) * dx; \
		float y = f##index(x, _Time); \
		float dist = length(coord - vec2(x, y)); \
		minDist = min(minDist, dist); \
	} \
	float pixelDist = minDist / unitsPerPixel; \
	return smoothstep(3, 2, pixelDist); \
}

#define DECLARE_FUNC_ApplyFunctionGraph(index) float4 ApplyFunctionGraph_##index(float4 inColor, float4 funcGraphColor, float2 coord) { \
	float epsilon = 0.000001f; \
	float funcValue 	 = f##index(coord.x, _Time); \
	float funcValueLeft  = f##index(coord.x - epsilon, _Time); \
	float funcValueRight = f##index(coord.x + epsilon, _Time); \
	float slope = (funcValueRight - funcValueLeft) / epsilon; \
	float factor = GetLerpFactor##index(coord, funcValue, slope); \
	return lerp(inColor, funcGraphColor, factor); \
}


//<DynamicGeneratedFunctions>

void vertex()
{
	_WorldToScreenMatrix = SCREEN_MATRIX * CANVAS_MATRIX;
}

float4 ApplyGridLines(float4 inColor, float4 gridColor, float2 coord, float2 screenSize, float gridSize, float gridLinePixelWidth)
{
	float2 gridSize2D = float2(gridSize, gridSize);
	float2 gridId = floor(coord / gridSize2D);
	float2 gridMin = gridId * gridSize2D;
	
	float halfGridLineWidth = gridLinePixelWidth * 0.5f;

	bool isLine = (abs(coord.x - gridMin.x) < halfGridLineWidth * dFdx(coord.x)) 
					|| (abs(coord.y - gridMin.y) < halfGridLineWidth * dFdx(coord.x));
					
	float factor = isLine ? 1.0 : 0.0;
	return lerp(inColor, gridColor, factor);
}

float4 ApplyHorizontalLine(float4 inColor, float4 lineColor, float2 coord, float Y, float linePixelWidth)
{
	float halfLineWidth = linePixelWidth * 0.5f;

	bool isLine = (abs(coord.y - Y) < halfLineWidth * dFdx(coord.x));
	
	float factor = isLine ? 1.0 : 0.0;
	return lerp(inColor, lineColor, factor);
}

float4 ApplyVerticalLine(float4 inColor, float4 lineColor, float2 coord, float X, float linePixelWidth)
{
	float halfLineWidth = linePixelWidth * 0.5f;

	bool isLine = (abs(coord.x - X) < halfLineWidth * dFdx(coord.x));
	
	float factor = isLine ? 1.0 : 0.0;
	return lerp(inColor, lineColor, factor);
}

void fragment() 
{	
	float4 backgroundColor = float4(0.16, 0.16, 0.16, 1);
	float2 uv = UV;
	uv.y = 1.0f - uv.y;
	
	float2 coord = UVToFuncSpaceCoord(uv);
	
	float4 finalColor = backgroundColor;
	
	float2 screenSize = 1.0f / SCREEN_PIXEL_SIZE;
	
	finalColor = ApplyGridLines(finalColor, float4(0.25, 0.25, 0.25, 1), coord, screenSize, _GridLineInterval.x, 2);
	finalColor = ApplyGridLines(finalColor, float4(0.45, 0.45, 0.45, 1), coord, screenSize, _GridLineInterval.y, 4);
	finalColor = ApplyHorizontalLine(finalColor, float4(0.65, 0.65, 0.65, 1), coord, 0.0, 4);
	finalColor = ApplyVerticalLine(finalColor, float4(0.65, 0.65, 0.65, 1), coord, 0.0, 4);
	finalColor = AppyFunctionGraphs(finalColor, coord);
	finalColor.a = 1.0f;
	COLOR = finalColor;
}
"""
