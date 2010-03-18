#!/usr/bin/ruby1.9

require "lexer"
require "parser"
require "interpreter"



# lexems = Lexer.new.run( "1, 2, 3" )
# lexems = Lexer.new.run( "a + ( b + f ( c1 , c2 , c3 ) + d ) + e" )
# #lexems = Lexer.new.run( "a + (b) + - c + d ( e, f) * g + h + i j" )
# #lexems = Lexer.new.run( "-x + b * c" )
# #                         0 1 2 3 4
# lexems = Lexer.new.run( "- x + ( 2 - ( 3 + c )  )  -  sin(x)*(1+2)" )
# #                        0 1 2 3 4 5 6 7 8 9


# ast = Parser.run( Lexer.run "- x + ( 2 - ( 3 + c )  )  -  sin(x)*(1+2)" )
ast = Parser.run(  Lexer.run "2 + 2 - pi + 2*4" )
# ast = Parser.run(  Lexer.run "2*4" )

ast.to_gv_file
# ast.to_gv_file "out2.gv", "out2.png"

int = Interpreter.new ast

int.substitution
puts ">", int.eval
puts int.part_eval!
puts int.ast.inspect

int.ast.to_gv_file "out2.gv", "out2.png"


# puts int.eval


# puts ast.to_gv_file
# puts ast.inspect

# puts Interpreter.new.named


# parser.get_atom( lexems )
# parser.get_expr

# puts parser.make_ast.to_gv_file


# puts parse("- x + ( 2 - ( 3 + c )  )  -  sin(x)*(1+2)"
#           0 1 2 3 4 5 6  7 8  9 0  1 2 3 4 5 6 7



# literals = 
#   [ Literal.new( "pi", [ Constant.new( Math::PI ) ] ),
#     Literal.new( "e", [ Constant.new( Math::E ) ] ),
#     Literal.new( "sqrt", [ Function.new( ->( x ) { Math.sqrt x }, 
#                                          ->( x ) { x >= 0 } )
#                          ] ),
#     Literal.new( "+", [ Function.new( ->( a, b ) { a + b }, nil, 0 ) ] ),
#     Literal.new( "-", [ Function.new( ->( x ) { -x } ),
#                         Function.new( ->( a, b ) { a - b }, nil, 0 ),
#                       ]),
#     Literal.new( "*", [ Function.new( ->( a, b ){ a * b }, nil, 1)]),
#     Literal.new( "/", [ Function.new( ->( a, b ){ a / b },
#                                       ->( a, b ){ b != 0 }, 1 )
#                       ]),
#     Literal.new( "^", [ Function.new( ->( a, b ){ a ** b }, nil, 2 ) ] ),
#   ]
