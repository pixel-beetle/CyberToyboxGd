class_name FslToken

enum Type {
	IDENTIFIER,
	NUMBER,
	OPERATOR,
	LPAREN,
	RPAREN,
	COMMA,
	QUESTION,
	COLON,
	EOF
}

var type: Type
var string_value: String
var position: int

func _init(t: Type, string: String, pos: int):
	type = t
	string_value = string
	position = pos

func _to_string() -> String:
	return "[%s: %s]" % [Type.keys()[type], string_value]

func to_glsl() -> String:
	match type:
		Type.COMMA:
			return ", "
		Type.NUMBER:
			return "float(%s)" % string_value
		Type.OPERATOR:
			return string_value
		Type.LPAREN:
			return "("
		Type.COLON:
			return ":"
		Type.IDENTIFIER:
			return string_value
		Type.RPAREN:
			return ")"
		Type.EOF:
			return ""
		Type.QUESTION:
			return "?"
	return ""