#!/usr/bin/ruby1.9

require "ast_term"

class Interpreter 
  attr_accessor :named, :ast
  
  def substitution(ast=nil, named=nil)
    named = self.named  if named.nil?
    ast = self.ast  if ast.nil?
    @ast = ast.substitution! @named
  end
  
  def eval(ast=nil)
    ast = @ast  if ast.nil?
    ast.eval
  end
  
  def part_eval!
    self.ast = self.ast.part_eval!
  end
  
  def initialize(ast=nil, named=nil)
    @ast = ast
    @named = { 
      "pi"   => [ Constant.new( Math::PI ) ],
      "x"    => [ Constant.new( 10 ) ],
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
                                ->( x ){ x[ 1 ] != 0 }
                                )
                ],
      "^"    => [ Function.new( ->( x ){ x[ 0 ] ** x[ 1 ] }, 2 ) ],
    }  if named.nil?
  end
  
end



class FunctionApplication

  def eval
    raise "Unknow function when try to eval"  unless self.function.class == Function
    args = self.args.map do |e|
      tmp = ( e.eval )
      if tmp.class == Constant
      then tmp.value
      else tmp
      end
    end
    self.function.function.call args
  end
  
  def part_eval!
    self.args = self.args.map { |e| e.part_eval! }
    if self.args.all? { |e| e.class == Constant } and 
        self.function.class == Function
      self.args = self.args.map { |e| e.value }
      return Constant.new( self.function.function.call args )
    end
    self
  end

  def substitution!(named)
    fun = named[ self.function.name ].detect do |e|
      e.arity == self.args.length  if e.class == Function
    end
    fun.name = self.function.name
    self.function = fun.clone
    self.args = self.args.map { |e| e.substitution! named }
    self    
  end

end


class ASTTermLeaf
end


class Named
  
  def eval
    raise "Unknow data when try to eval"
  end
  
  def part_eval!
    self
  end
  
  def substitution!(named)
    constant = named[ self.name ].detect { |e| e.class == Constant }
    return self  if constant.nil?
    return constant  if constant.class == Constant
    Constant.new constant
  end
  
end


class Constant
  
  def eval
    self
  end

  def part_eval!
    self
  end
  
  def substitution!(named)
    self
  end
  
end


class Function
end

