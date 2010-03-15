#!/usr/bin/ruby1.9

require "ast_term"

class Interpreter 
  attr_accessor :named, :ast
  
  def substitution(ast=nil, named=nil)
    @named.merge! named  unless named.nil?
    ast = @ast  if ast.nil?
    if ast.class == FunctionApplication
      fun = @named[ ast.function.name ].detect do |e| 
        e.arity == ast.args.length  if e.class == Function
      end
      fun.name = ast.function.name
      ast.function = fun
      ast.args = ast.args.map { |e| substitution e}
      ast
    elsif ast.class == Named
      @named[ ast.name ].detect { |e| e.class == Constant }
    elsif ast.class == Constant
      ast
    end    
  end
  
  def eval(ast=nil)
    ast = @ast  if ast.nil?
    if ast.class == FunctionApplication
      raise "Unknow function when try to eval"  unless ast.function.class == Function
      args = ast.args.map do |e|
        tmp = ( eval e )
        if tmp.class == Constant
        then tmp.value
        else tmp
        end
      end
      ast.function.function.call args
    elsif ast.class == Named
      raise "Unknow data when try to eval"
    elsif ast.class == Constant
      ast
    end    
    
  end

  def initialize(ast=nil, named=nil)
    @ast = ast
    @named = { 
      "pi"   => [ Constant.new( Math::PI ) ],
      "x"   => [ Constant.new( 10 ) ],
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
