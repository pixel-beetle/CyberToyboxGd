extends Node
class_name FunctionVisualizer2D

@export var DisplayItem : FunctionVisualizer2DDisplayCanvas

var m_RenderMaterial : ShaderMaterial;
var m_DynamicShader : Shader;
var m_DynamicShader2 : Shader;

# weak ref
var m_CurrentDynamicShader : Shader;
# weak ref
var m_DummyShaderForCompileCheck : Shader;

var m_Time : float = 0.0;
var m_IsPausingTime : bool = false

var m_FuncUnitsPerPixel : float = 0.01;
var m_FunctionCoordBoundsMin : Vector2 = Vector2(-2, -2);
var m_FunctionCoordBoundsMax : Vector2 = Vector2(2, 2);
var m_ZoomLevel : float = 0.0;

var m_MousePos : Vector2 = Vector2(0, 0);

var m_FunctionInputEdits : Array[FunctionInputEdit] = [];
var m_FunctionVariableInputEdits : Array[FunctionVariableInputEdit] = [];
var m_ParamsInitialized : bool = false;

var m_LastDynamicShaderCode : String = "";

const MaxTime := 1000.0

func SetCurrentTime(t: float) -> void:
	m_Time = clamp(t, 0.0, MaxTime)

func GetCurrentTime() -> float:
	return m_Time;

func ResetTime() -> void:
	m_Time = 0.0;
	m_IsPausingTime = false;

func PauseTime() -> void:
	m_IsPausingTime = true;	

func ResumeTime() -> void:
	m_IsPausingTime = false;	
	
func IsPausingTime() -> bool:
	return m_IsPausingTime;
	
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
	m_FunctionVariableInputEdits = []
	m_FuncUnitsPerPixel = 0.005;
	m_MousePos = Vector2(0, 0);
	m_ZoomLevel = 1.0;
	m_FunctionCoordBoundsMin = DisplayItem.size * Vector2(-0.5, -0.5) * m_FuncUnitsPerPixel;
	m_FunctionCoordBoundsMax = DisplayItem.size * Vector2(0.5, 0.5) * m_FuncUnitsPerPixel;
	var children := find_children("","Node",true,true);
	for child in children:
		var funcInputEdit := child as FunctionInputEdit
		if funcInputEdit != null:
			funcInputEdit.Visualizer = self;
			m_FunctionInputEdits.append(funcInputEdit);
			
		var funcVariableInputEdit := child as FunctionVariableInputEdit
		if funcVariableInputEdit != null:
			m_FunctionVariableInputEdits.append(funcVariableInputEdit);
		
	SetFunctionInputs(FunctionPreset.DefaultInputs);
	for funcInputEdit in m_FunctionInputEdits:
		funcInputEdit.fsl_changed.connect(_on_FunctionInputEdit_fsl_changed);
	
	m_ParamsInitialized = true;
	
func IsShaderValid(shader : Shader) -> bool:
	return shader != null and not shader.get_shader_uniform_list().is_empty()
	
func _on_FunctionInputEdit_fsl_changed(textEdit: FunctionInputEdit, index :int, content : String) -> void:
	var shaderContent: String = GenerateDynamicFunctionShaderCode()
	if not UpdateDynamicShaderCode(shaderContent):
		textEdit.MarkContentValid(false);
	else:
		textEdit.MarkContentValid(true);
	
func UpdateDynamicShaderCode(shaderContent : String) -> bool:
	if m_LastDynamicShaderCode == shaderContent:
		return true;
	print("UpdateDynamicShaderCode,Current = %s, Dummy = %s" %\
		[m_CurrentDynamicShader.get_name(),  m_DummyShaderForCompileCheck.get_name()]);
	m_DummyShaderForCompileCheck.code = shaderContent
	if not IsShaderValid(m_DummyShaderForCompileCheck):
		print("Invalid Shader Code!")
		return false;
	var temp := m_CurrentDynamicShader;
	m_CurrentDynamicShader = m_DummyShaderForCompileCheck;
	m_DummyShaderForCompileCheck = temp;
	m_RenderMaterial.shader = m_CurrentDynamicShader;
	m_LastDynamicShaderCode = shaderContent;
	print("Valid Shader Code, Current = %s" % m_CurrentDynamicShader.get_name())
	return true;

func SetFunctionInputs(inputs : Array[String]):
	for i in range(len(inputs)):
		if i >= len(m_FunctionInputEdits):
			break;
		var textEdit := m_FunctionInputEdits[i];
		textEdit.Content = inputs[i];
	var shaderContent := GenerateDynamicFunctionShaderCode();
	UpdateDynamicShaderCode(shaderContent);

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
	if not m_CurrentDynamicShader or not m_DummyShaderForCompileCheck:
		if not m_DynamicShader:
			m_DynamicShader = Shader.new();
			m_DynamicShader.set_name("DynamicShader");
		if not m_DynamicShader2:
			m_DynamicShader2 = Shader.new();
			m_DynamicShader2.set_name("DynamicShader2");
		
		m_DynamicShader.code = SHADER_CODE_TEMPLATE\
					.replace("//<DynamicGeneratedFunctions>", SHADER_DYNAMIC_FUNCTIONS_DEFAULT);
		m_DynamicShader2.code = SHADER_CODE_COMPILE_DUMMY_DEFAULT
		
		m_CurrentDynamicShader = m_DynamicShader;
		m_DummyShaderForCompileCheck = m_DynamicShader2;

	if not m_RenderMaterial:
		m_RenderMaterial = ShaderMaterial.new();
		m_RenderMaterial.shader = m_CurrentDynamicShader;
	
	InitializeParamatersIfNeeded();

func ReleaseResourcesIfNeeded() -> void:
	if m_RenderMaterial:
		m_RenderMaterial.shader = null;
		m_RenderMaterial.unreference()
		m_RenderMaterial = null;
	if m_DynamicShader:
		m_DynamicShader.unreference()
		m_DynamicShader = null;
	if m_DynamicShader2:
		m_DynamicShader2.unreference()
		m_DynamicShader2 = null; 
	m_CurrentDynamicShader = null;
	m_DummyShaderForCompileCheck = null;
	m_LastDynamicShaderCode = "";
	for input in m_FunctionInputEdits:
		input.fsl_changed.disconnect(_on_FunctionInputEdit_fsl_changed);	
	m_FunctionInputEdits.clear()
	DisplayItem.drag_moved.disconnect(_on_drag_moved);
	DisplayItem.zoom_changed.disconnect(_on_zoom_changed);
	DisplayItem.mouse_moved.disconnect(_on_mouse_position_got);
	
func UpdateMaterialProperties() -> void:
	if not m_RenderMaterial or not DisplayItem:
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
	for customVariable in m_FunctionVariableInputEdits:
		var variableName : String = customVariable.VarName;
		if variableName == "":
			continue
		m_RenderMaterial.set_shader_parameter(variableName, customVariable.VarValue);	
		
func GenerateDynamicFunctionShaderCode() -> String:
	var uniformAndFunction_Define : String = ""
	var appyFunctionGraphs_Body : String = ""
	for input in m_FunctionInputEdits:
		if not input.IsContentValid:
			continue;
		uniformAndFunction_Define += """
			uniform vec4 _Color<i>;
			float f<i>(float x, float t)
			{
				return <c>;
			}
			
			float GetmixFactor<i>(vec2 coord, float funcY, float funcSlope) 
			{
				float minDist = 1000.0;
				float unitsPerPixel = dFdx(coord.x);
				float xMin = coord.x - unitsPerPixel * 16.0;
				float xMax = coord.x + unitsPerPixel * 16.0;
				int steps = 128;
				float dx = (xMax - xMin) / float(steps);
				for (int i = 0; i < steps; ++i)
				{
					float x = xMin + float(i) * dx;
					float y = f<i>(x, _Time);
					float dist = length(coord - vec2(x, y));
					dist = dist / unitsPerPixel;
					minDist = min(minDist, dist);
				}
				return smoothstep(2.0, 1.0, minDist);
			}
		
			vec4 ApplyFunctionGraph_<i>(vec4 inColor, vec4 funcGraphColor, vec2 coord) 
			{
				float epsilon = 0.000001f;
				float funcValue 	 = f<i>(coord.x, _Time);
				float funcValueLeft  = f<i>(coord.x - epsilon, _Time);
				float funcValueRight = f<i>(coord.x + epsilon, _Time);
				float slope = (funcValueRight - funcValueLeft) / epsilon;
				float factor = GetmixFactor<i>(coord, funcValue, slope);
				return mix(inColor, funcGraphColor, factor);
			}	
			""".replace("<i>", str(input.Index)).replace("<c>", input.Content);
		appyFunctionGraphs_Body += """
			
			finalColor = ApplyFunctionGraph_<i>(finalColor, _Color<i>, coord);
			
			""".replace("<i>", str(input.Index));
	var dynamicContent: String = uniformAndFunction_Define + """
	
	vec4 AppyFunctionGraphs(vec4 inColor, vec2 coord)
	{
		vec4 finalColor = inColor;
		<BODY>
		return finalColor;
	}

	""".replace("<BODY>", appyFunctionGraphs_Body);
	return SHADER_CODE_TEMPLATE\
				.replace("//<DynamicGeneratedFunctions>", dynamicContent)\
				.replace("//<CommonDefines>", GetShaderCommonDefines())

func GetShaderCommonDefines() -> String:
	return GetShaderCustomVariableUniformDeclarations() + "\n";
	
func GetShaderCustomVariableUniformDeclarations() -> String:
	var result : String = ""
	for input in m_FunctionVariableInputEdits:
		if input.VarName == "":
			continue;
		result += """
			uniform highp float <VarName>;
			""".replace("<VarName>", input.VarName);
	return result;

func GetValidVariableNames() -> Array[String]:
	var result : Array[String] = ["x", "t"];
	for input in m_FunctionVariableInputEdits:
		if input.VarName == "":
			continue;
		result.append(input.VarName);
	return result;

func GetValidFunctionNames() -> Array[String]:
	var result : Array[String] = []
	for function in FunctionLib2D.BuiltinFunctions:
		result.append(function.Name);
	return result;	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not IsPausingTime():
		m_Time += delta;
	if m_Time > MaxTime:
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
vec4 AppyFunctionGraphs(vec4 inColor, vec2 coord)
{
	vec4 finalColor = inColor;
	return finalColor;
}

"""

const SHADER_CODE_TEMPLATE : String = """
shader_type canvas_item;

//<CommonDefines>

uniform float _Time;
uniform vec4 _FunctionCoordBoundsMinMax;
uniform vec4 _CanvasItemPositionSize;
uniform vec2 _GridLineInterval;

varying flat mat4 _WorldToScreenMatrix; 

vec2 UVToFuncSpaceCoord(vec2 uv)
{
	vec2 boundsMin = _FunctionCoordBoundsMinMax.xy;
	vec2 boundsMax = _FunctionCoordBoundsMinMax.zw;
	
	return mix(boundsMin, boundsMax, uv);
}

vec2 UVToFuncSpaceCoord2(vec2 uv)
{
	uv = uv - 0.5f;
	float aspectRatio = (_CanvasItemPositionSize.z / _CanvasItemPositionSize.w);
	uv.x *= aspectRatio;
	
	return uv * 5.0;
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
	vec2 uv_TopIs0 = uv;
	uv_TopIs0.y = 1.0 - uv_TopIs0.y;
	
	vec2 worldPosLeftTop = _CanvasItemPositionSize.xy;
	vec2 worldSize = _CanvasItemPositionSize.zw;
	vec2 worldPos = worldPosLeftTop + worldSize * uv_TopIs0;
	
	vec4 clipPos = _WorldToScreenMatrix * vec4(worldPos, 0, 1);
	vec2 screenUV = clipPos.xy * 0.5f + 0.5f;
	return screenUV;
}

vec2 FuncSpaceCoordToScreenPos(vec2 coord, vec2 screenSize)
{
	vec2 screenUV = FuncSpaceCoordToScreenUV(coord);
	return screenUV * screenSize;
}

//<DynamicGeneratedFunctions>

void vertex()
{
	_WorldToScreenMatrix = SCREEN_MATRIX * CANVAS_MATRIX;
}

vec4 ApplyGridLines(vec4 inColor, vec4 gridColor, vec2 coord, vec2 screenSize, float gridSize, float gridLinePixelWidth)
{
	vec2 gridSize2D = vec2(gridSize, gridSize);
	vec2 gridId = floor(coord / gridSize2D);
	vec2 gridMin = gridId * gridSize2D;
	
	float halfGridLineWidth = gridLinePixelWidth * 0.5f;

	bool isLine = (abs(coord.x - gridMin.x) < halfGridLineWidth * dFdx(coord.x)) 
					|| (abs(coord.y - gridMin.y) < halfGridLineWidth * dFdx(coord.x));
					
	float factor = isLine ? 1.0 : 0.0;
	return mix(inColor, gridColor, factor);
}

vec4 ApplyHorizontalLine(vec4 inColor, vec4 lineColor, vec2 coord, float Y, float linePixelWidth)
{
	float halfLineWidth = linePixelWidth * 0.5f;

	bool isLine = (abs(coord.y - Y) < halfLineWidth * dFdx(coord.x));
	
	float factor = isLine ? 1.0 : 0.0;
	return mix(inColor, lineColor, factor);
}

vec4 ApplyVerticalLine(vec4 inColor, vec4 lineColor, vec2 coord, float X, float linePixelWidth)
{
	float halfLineWidth = linePixelWidth * 0.5f;

	bool isLine = (abs(coord.x - X) < halfLineWidth * dFdx(coord.x));
	
	float factor = isLine ? 1.0 : 0.0;
	return mix(inColor, lineColor, factor);
}

void fragment() 
{	
	vec4 backgroundColor = vec4(0.16, 0.16, 0.16, 1);
	vec2 uv = UV;
	uv.y = 1.0f - uv.y;
	
	vec2 coord = UVToFuncSpaceCoord(uv);
	
	vec4 finalColor = backgroundColor;
	
	vec2 screenSize = 1.0f / SCREEN_PIXEL_SIZE;
	
	finalColor = ApplyGridLines(finalColor, vec4(0.25, 0.25, 0.25, 1), coord, screenSize, _GridLineInterval.x, 2);
	finalColor = ApplyGridLines(finalColor, vec4(0.45, 0.45, 0.45, 1), coord, screenSize, _GridLineInterval.y, 4);
	finalColor = ApplyHorizontalLine(finalColor, vec4(0.65, 0.65, 0.65, 1), coord, 0.0, 4);
	finalColor = ApplyVerticalLine(finalColor, vec4(0.65, 0.65, 0.65, 1), coord, 0.0, 4);
	finalColor = AppyFunctionGraphs(finalColor, coord);
	finalColor.a = 1.0f;
	COLOR = finalColor;
}
"""
