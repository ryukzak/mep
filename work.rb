#!/usr/bin/ruby1.9

require "lexer"
require "parser"
require "interpreter"
require "optimizer"

ast = Parser.new( Lexer.run "2 + 2 - pi + 2*4/2" ).run
# ast = Parser.run(  Lexer.run "2*4" )

opt = Optimizer.new ast
opt.ast.to_gv_file "out1.gv", "out1.png"

boxing = ->(f) do 
  puts f.function.name
  if f.function.name == "-" 
    puts "boxing"
    [f.args[0], FunctionApplication.new(->( x ){ - x[ 0 ] }, [f.args[1]])]
  else f 
  end
end

# puts opt.ast.get_operator_line(["+", "-"], boxing)

opt.substitution!
opt.ast.to_gv_file "out2.gv", "out2.png"

opt.part_eval!
opt.ast.to_gv_file "out3.gv", "out3.png"

int = Interpreter.new opt.ast
puts int.eval



