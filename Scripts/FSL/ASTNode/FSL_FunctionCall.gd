class_name FslFunctionCall extends FslASTNode
var funcName: String
var argList: Array[FslASTNode]

func _init(funcName : String, argList : Array[FslASTNode]):
	self.funcName = funcName
	self.argList = argList

func to_glsl() -> String:
	var ret: String = funcName + "("
	for i in range(argList.size()):
		ret += argList[i].to_glsl()
		if i != argList.size() - 1:
			ret += ", "
	ret += ")"
	return ret