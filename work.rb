#!/usr/bin/ruby1.9

require "lexer"
require "parser"
require "interpreter"
require "optimizer"





ast = Parser.run(  Lexer.run "2 + 2 - pi + 2*4" )
# ast = Parser.run(  Lexer.run "2*4" )

opt = Optimizer.new ast
opt.ast.to_gv_file "out1.gv", "out1.png"

puts opt.ast.get_operator_line(["+", "-"]).map { |e| e.function.name }

opt.substitution!
opt.ast.to_gv_file "out2.gv", "out2.png"

opt.part_eval!
opt.ast.to_gv_file "out3.gv", "out3.png"

int = Interpreter.new opt.ast
puts int.eval



