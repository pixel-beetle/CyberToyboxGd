shader_type canvas_item;

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
	float scaler = 10.0f;
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

varying flat mat4 _LocalToScreenMatrix; 

void vertex()
{
	_LocalToScreenMatrix = SCREEN_MATRIX * CANVAS_MATRIX * MODEL_MATRIX;
}

void fragment() 
{
	vec4 backgroundColor = vec4(0.16, 0.16, 0.16, 1);
	vec2 uv = UV;
	uv.y = 1.0f - uv.y;
	
	vec2 boundsMin = vec2(-2);
	vec2 boundsMax = vec2(2);
	
	vec2 coord = mix(boundsMin, boundsMax, uv);
	
	vec4 finalColor = backgroundColor;
	finalColor = ApplyFunctionGraph_1(finalColor, vec4(1,0,0,1), coord);
	finalColor = ApplyFunctionGraph_2(finalColor, vec4(1,1,0,1), coord);
	finalColor = ApplyFunctionGraph_3(finalColor, vec4(1,1,1,1), coord);
	finalColor = ApplyFunctionGraph_4(finalColor, vec4(0,1,0,1), coord);
	finalColor = ApplyFunctionGraph_5(finalColor, vec4(0,1,1,1), coord);
	finalColor = ApplyFunctionGraph_6(finalColor, vec4(0,0,1,1), coord);
	finalColor.a = 1.0f;
	COLOR = finalColor;
}