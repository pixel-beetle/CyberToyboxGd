shader_type canvas_item;

float CalculateFunction_1(float x)
{
	return x * x;
}

float CalculateFunction_2(float x)
{
	return x * x * x;
}

float CalculateFunction_3(float x)
{
	return smoothstep(0,1,x);
}

float CalculateFunction_4(float x)
{
	return smoothstep(0,1,x);
}

float CalculateFunction_5(float x)
{
	return smoothstep(0,1,x);
}

float CalculateFunction_6(float x)
{
	return smoothstep(0,1,x);
}

float GetLerpFactor(vec2 coord, float funcY, float funcSlope)
{
	float dist = abs(coord.y - funcY);
	float upper = mix(0.001, 0.05, clamp(abs(funcSlope) * 0.01f, 0, 1));
	return smoothstep(upper, 0, dist);
}

#define DECLARE_FUNC_ApplyFunctionGraph(index) vec4 ApplyFunctionGraph_##index(vec4 inColor, vec4 funcGraphColor, vec2 coord) { \
	float epsilon = 0.0001f; \
	float funcValue 	 = CalculateFunction_##index(coord.x); \
	float funcValueLeft  = CalculateFunction_##index(coord.x - epsilon); \
	float funcValueRight = CalculateFunction_##index(coord.x + epsilon); \
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

void fragment() 
{
	vec4 backgroundColor = vec4(0.16, 0.16, 0.16, 1);
	vec4 functionGraphColor = vec4(1,0,0,1);
	vec2 uv = UV;
	uv.y = 1.0f - uv.y;
	
	vec4 finalColor = backgroundColor;
	finalColor = ApplyFunctionGraph_1(finalColor, functionGraphColor, uv);
	finalColor = ApplyFunctionGraph_2(finalColor, functionGraphColor * 0.5, uv);
	finalColor = ApplyFunctionGraph_3(finalColor, functionGraphColor * 0.3, uv);
	finalColor.a = 1.0f;
	COLOR = finalColor;
}