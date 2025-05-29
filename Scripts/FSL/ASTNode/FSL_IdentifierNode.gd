class_name FslIdentifierNode extends FslASTNode
var token : FslToken

func _init(token : FslToken) -> void:
	self.token = token
	
func to_glsl() -> String:
	return token.to_glsl()	