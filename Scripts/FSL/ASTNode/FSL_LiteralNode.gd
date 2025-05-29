class_name FslLiteralNode extends FslASTNode
var token : FslToken

func _init(token : FslToken):
	self.token = token

func to_glsl() -> String:
	return token.to_glsl()