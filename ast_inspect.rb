require "ast_term"

class FunctionApplication

  def inspect
    "#{ self.function.inspect }#{ self.args.inspect }"
  end

end


class ASTTermLeaf
end


class Named

  def inspect
    "#{ self.name }"    
  end

end


class Constant

  def inspect
    "#{ self.value }"
  end

end


class Function

  def inspect
    "#{ self.name }"
  end

end
