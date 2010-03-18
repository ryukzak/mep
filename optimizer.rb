require "ast_term"
require "ast_term_util"

class Optimizer
  attr_accessor :ast, :named

  def substitution!(named=nil)
    named = self.named  if named.nil?
    raise "Interpreter:undefine ast"  if self.ast.nil?
    self.ast = self.ast.substitution! named
  end
  
  def part_eval!
    self.ast = self.ast.part_eval!
  end

  def initialize(ast=nil, named=nil)
    self.ast = ast
    self.named = { 
      "pi"   => [ Constant.new( Math::PI ) ],
      "e"    => [ Constant.new( Math::E ) ],
      "sqrt" => [ Function.new( ->( x ){ Math.sqrt x[ 0 ] }, 1,
                                ->( x ){ x[ 0 ] >= 0 } )
                ],
      "+"    => [ Function.new( ->( x ){ x[ 0 ] + x[ 1 ] }, 2 ) ],
      "-"    => [ Function.new( ->( x ){ - x[ 0 ] } ),
                  Function.new( ->( x ){ x[ 0 ] - x[ 1 ] }, 2 ),
                ],
      "*"    => [ Function.new( ->( x ){ x[ 0 ] * x[ 1 ] }, 2 ) ],
      "/"    => [ Function.new( ->( x ){ x[ 0 ] / x[ 1 ] }, 2,
                                ->( x ){ x[ 1 ] != 0 } )
                ],
      "^"    => [ Function.new( ->( x ){ x[ 0 ] ** x[ 1 ] }, 2 ) ],
    }  if named.nil?
  end
  
end

class FunctionApplication

  def part_eval!
    self.args = self.args.map { |e| e.part_eval! }
    if self.args.all? { |e| e.class == Constant } and 
        self.function.class == Function
      self.args = self.args.map { |e| e.value }
      return Constant.new( self.function.function.call args )
    end
    self
  end

end


class ASTTermLeaf
end


class Named
  
  def part_eval!
    self
  end
  
end


class Constant
  
  def part_eval!
    self
  end
  
end


class Function
end

