class_name FunctionLib2D
const Category_Arithmetic := "Arithmetic";
const Category_Trignometry := "Trignometry";
const Category_Trancendent := "Trancendent";
const Category_Power := "Power";
static var GLSLBuiltinFunctions : Array[FunctionDescriptor] = [
	FunctionDescriptor.Buitin_AllFloats("sin", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("cos", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("tan", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("asin", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("acos", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("atan", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("sinh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("cosh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("tanh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("asinh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("acosh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("atanh", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("degrees", ["x"]).MarkCategory(Category_Trignometry),
	FunctionDescriptor.Buitin_AllFloats("radians", ["x"]).MarkCategory(Category_Trignometry),
	
	FunctionDescriptor.Buitin_AllFloats("exp", ["x"]).MarkCategory(Category_Trancendent),
	FunctionDescriptor.Buitin_AllFloats("log", ["x"]).MarkCategory(Category_Trancendent),
	FunctionDescriptor.Buitin_AllFloats("exp2", ["x"]).MarkCategory(Category_Trancendent),
	FunctionDescriptor.Buitin_AllFloats("log2", ["x"]).MarkCategory(Category_Trancendent),
	
	FunctionDescriptor.Buitin_AllFloats("sqrt", ["x"]).MarkCategory(Category_Power),
	FunctionDescriptor.Buitin_AllFloats("inversesqrt", ["x"]).MarkCategory(Category_Power),
	FunctionDescriptor.Buitin_AllFloats("pow", ["x", "a"]).MarkCategory(Category_Power),
	
	FunctionDescriptor.Buitin_AllFloats("abs", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("sign", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("floor", ["x"]),

	FunctionDescriptor.Buitin_AllFloats("round", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("roundEven", ["x"]),

	FunctionDescriptor.Buitin_AllFloats("fract", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("frac", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("mod", ["x", "y"]),
	FunctionDescriptor.Buitin_AllFloats("modf", ["x", "y"]),
	FunctionDescriptor.Buitin_AllFloats("min", ["x", "y"]),
	FunctionDescriptor.Buitin_AllFloats("max", ["x", "y"]),
	FunctionDescriptor.Buitin_AllFloats("clamp", ["x", "min", "max"]), 
	FunctionDescriptor.Buitin_AllFloats("saturate", ["x"]),
	FunctionDescriptor.Buitin_AllFloats("trunc", ["x"]),

	FunctionDescriptor.Buitin_AllFloats("mix", ["a", "b", "x"]),
	FunctionDescriptor.Buitin_AllFloats("lerp", ["a", "b", "x"]),
	FunctionDescriptor.Buitin_AllFloats("step", ["edge", "x"]),
	FunctionDescriptor.Buitin_AllFloats("smoothstep", ["edge0", "edge1", "x"]),
	FunctionDescriptor.Buitin_AllFloats("linearstep", ["edge0", "edge1", "x"]),


	
	
]




