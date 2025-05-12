shader_type canvas_item;

varying flat mat4 _WorldToScreenMatrix; 

vec2 UVToFuncSpaceCoord(vec2 uv)
{
	vec2 boundsMin = vec2(-2);
	vec2 boundsMax = vec2(2);
	
	return mix(boundsMin, boundsMax, uv);
}

vec2 FuncSpaceCoordToUV(vec2 coord)
{
	vec2 boundsMin = vec2(-2);
	vec2 boundsMax = vec2(2);
	
	return (coord - boundsMin) / (boundsMax - boundsMin);
}

vec2 FuncSpaceCoordToScreenUV(vec2 coord)
{
	vec2 uv = FuncSpaceCoordToUV(coord);
	vec2 boundsMin = vec2(-2);
	vec2 boundsMax = vec2(2);
	
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
	return sin(x + TIME);
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
	finalColor = ApplyFunctionGraph_1(finalColor, vec4(1,0,0,1), coord);
	finalColor = ApplyFunctionGraph_2(finalColor, vec4(1,1,0,1), coord);
	finalColor = ApplyFunctionGraph_3(finalColor, vec4(1,1,1,1), coord);
	finalColor = ApplyFunctionGraph_4(finalColor, vec4(0,1,0,1), coord);
	finalColor = ApplyFunctionGraph_5(finalColor, vec4(0,1,1,1), coord);
	finalColor = ApplyFunctionGraph_6(finalColor, vec4(0,0,1,1), coord);
	finalColor.a = 1.0f;
	COLOR = finalColor;
	
	//vec3 clipPos = (_WorldToScreenMatrix * vec4(VERTEX, 0,1)).xyz;
	//clipPos = vec3(clipPos.xy * 0.5 + 0.5, 0);
	//clipPos.y = 1.0f - clipPos.y;
	//COLOR = vec4(clipPos, 1);
}