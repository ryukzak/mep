#!/usr/bin/ruby1.9

require "ast_term"
require "ast_term_util"

class Interpreter 
  attr_accessor :named, :ast
  
  def substitution!(named=nil)
    named = self.named  if named.nil?
    raise "Interpreter:undefine ast"  if self.ast.nil?
    self.ast = self.ast.substitution! named
  end
  
  def eval(named=nil)
    ast = self.ast
    ast.substitution!  unless named.nil?
    ast.eval.value
  end
  
  def initialize(ast=nil)
    self.ast = ast
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

end


class ASTTermLeaf
end


class Named
  
  def eval
    raise "Unknow data when try to eval"
  end
  
end


class Constant
  
  def eval
    self
  end
  
end


class Function
end

