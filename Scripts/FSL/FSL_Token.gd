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

const TOKEN_PATTERNS: Array[Variant] = [
	# 运算符（双字符优先）
	{"regex": "^\\*\\*", "type": FslToken.Type.OPERATOR, "value": "**"},
	{"regex": "^&&", "type": FslToken.Type.OPERATOR, "value": "&&"},
	{"regex": "^\\|\\|", "type": FslToken.Type.OPERATOR, "value": "||"},
	{"regex": "^==", "type": FslToken.Type.OPERATOR, "value": "=="},
	{"regex": "^!=", "type": FslToken.Type.OPERATOR, "value": "!="},
	{"regex": "^<=", "type": FslToken.Type.OPERATOR, "value": "<="}, 
	{"regex": "^>=", "type": FslToken.Type.OPERATOR, "value": ">="},
	{"regex": "^[+\\-*/%<>=!&|^~]", "type": FslToken.Type.OPERATOR},

	# 数字字面量
	{"regex": "^\\d+\\.\\d*([eE][\\-+]?\\d+)?[fFhH]?", "type": FslToken.Type.NUMBER}, # 浮点数
	{"regex": "^\\.\\d+([eE][\\-+]?\\d+)?[fFhH]?", "type": FslToken.Type.NUMBER}, # .开头浮点数
	{"regex": "^\\d+[eE][\\-+]?\\d+[fFhH]?", "type": FslToken.Type.NUMBER}, # 科学计数法
	{"regex": "^\\d+", "type": FslToken.Type.NUMBER}, # 整数

	# 标识符
	{"regex": "^[a-zA-Z_][a-zA-Z0-9_]*", "type": FslToken.Type.IDENTIFIER},

	# 标点符号
	{"regex": "^\\(", "type": FslToken.Type.LPAREN, "value": "("},
	{"regex": "^\\)", "type": FslToken.Type.RPAREN, "value": ")"},
	{"regex": "^,", "type": FslToken.Type.COMMA, "value": ","},
	{"regex": "^\\?", "type": FslToken.Type.QUESTION, "value": "?"},
	{"regex": "^:", "type": FslToken.Type.COLON, "value": ":"},
]

var type: Type
var string_value: String
var position: int


func _init(t: Type, string: String, pos: int):
	type = t
	string_value = string
	position = pos


func _to_string() -> String:
	return "[%s: %s]" % [Type.keys()[type], string_value]

static var DefaultIdentifierRemapping: Dictionary = {
	"frac": "fract",
	"lerp": "mix",
	"float2": "vec2",
	"float3": "vec3",
	"float4": "vec4",
	"float4x4": "mat4",
}

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
			if string_value in DefaultIdentifierRemapping:
				return DefaultIdentifierRemapping[string_value];
			return string_value
		Type.RPAREN:
			return ")"
		Type.EOF:
			return ""
		Type.QUESTION:
			return "?"
	return ""