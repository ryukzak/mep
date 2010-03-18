require "ast_term"

class FunctionApplication

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
  
  def substitution!(named)
    constant = named[ self.name ].detect { |e| e.class == Constant }
    return self  if constant.nil?
    return constant  if constant.class == Constant
    Constant.new constant
  end
  
end


class Constant
  
  def substitution!(named)
    self
  end
  
end


class Function
end


