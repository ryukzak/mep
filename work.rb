#!/usr/bin/ruby1.9

require "lexer"
require "parser"
require "interpreter"
require "optimizer"

ast = Parser.new( Lexer.new( "2 + 2 - pi + 2*4/2" ).run ).run
# ast = Parser.run(  Lexer.run "2*4" )

opt = Optimizer.new ast
opt.ast.to_gv_file "out1.gv", "out1.png"

# opt.substitution!
# opt.ast.to_gv_file "out2.gv", "out2.png"

# opt.sort_function!
# opt.ast.to_gv_file "out3.gv", "out3.png"

# opt.reduce!
# # puts opt.ast.inspect
# opt.ast.to_gv_file "out4.gv", "out4.png"

# opt.part_eval!
# opt.ast.to_gv_file "out5.gv", "out5.png"

int = Interpreter.new opt.run.ast
puts int.eval
