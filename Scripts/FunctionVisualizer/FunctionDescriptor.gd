class_name FunctionDescriptor

var Category: String
var ReturnType: String
var Name: String
var ParamList: Array[FunctionParameter] = []
var CustomBodyContent: String
var IsBuiltin: bool


func GetFunctionSignature() -> String:
	var result: String = ReturnType + " " + Name + "(";
	for i in range(ParamList.size()):
		result += ParamList[i]._to_string();
		if i < ParamList.size() - 1:
			result += ", ";
	result += ")";
	return result;

func GetFunctionCallPattern() -> String:
	var result: String = Name + "(";
	for i in range(ParamList.size()):
		result += ParamList[i].Name;
		if i < ParamList.size() - 1:
			result += ", ";
	result += ")";
	return result;


func _to_string() -> String:
	var result: String = GetFunctionSignature()
	if IsBuiltin:
		result += "(GLSL Builtin)";
	return result;


static func Buitin(return_type: String, name: String, param_list: Array[FunctionParameter]) -> FunctionDescriptor:
	var result = FunctionDescriptor.new();
	result.ReturnType = return_type;
	result.Name = name;
	result.ParamList = param_list;
	result.IsBuiltin = true;
	return result;


static func Buitin_AllFloats(name: String, param_list: Array[String]) -> FunctionDescriptor:
	var result = FunctionDescriptor.new();
	result.ReturnType = "float";
	result.Name = name;
	for param in param_list:
		result.ParamList.append(FunctionParameter.new("float", param));
	result.IsBuiltin = true;
	return result;


static func Custom_AllFloats(name: String, param_list: Array[String], body_content: String) -> FunctionDescriptor:
	var result = FunctionDescriptor.new();
	result.ReturnType = "float";
	result.Name = name;
	for param in param_list:
		result.ParamList.append(FunctionParameter.new("float", param));
	result.IsBuiltin = false;
	result.CustomBodyContent = body_content;
	return result;


func MarkCategory(category: String) -> FunctionDescriptor:
	Category = category
	return self;


class FunctionParameter:
	var Type: String
	var Name: String


	func _init(type, name):
		Type = type
		Name = name


	func _to_string() -> String:
		return Type + " " + Name;
