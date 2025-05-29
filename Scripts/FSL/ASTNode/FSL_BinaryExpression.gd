class_name FslBinaryExpression
extends FslASTNode
var operator: FslToken
var left: FslASTNode
var right: FslASTNode

func _init(operator: FslToken, left: FslASTNode, right: FslASTNode):
	self.operator = operator
	self.left = left
	self.right = right
	
func to_glsl() -> String:
	if operator.string_value == "**":
		return "pow(%s, %s)" % [left.to_glsl(), right.to_glsl()]
	return "%s %s %s" % [left.to_glsl(), operator.string_value, right.to_glsl()]
