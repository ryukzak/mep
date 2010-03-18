#!/usr/bin/ruby1.9



class ASTTerm  
  attr_accessor :gv

  def to_a
    [self]
  end

  def operator?
    false
  end

  def priority
    nil
  end

  def to_gv_file(gv_file="out.gv", png_file="out.png")    
    f = File.new(gv_file,  "w")
    f.puts "digraph G {"
    f.puts "size = \"3,3\""
    self.to_gv f
    f.puts "}"
    f.close
    self.reset_gv_flag
    system "dot -Tpng #{ gv_file } -o #{ png_file }"
  end

end



class FunctionApplication < ASTTerm
  attr_accessor :function, :args

  def initialize(fun, args)
    self.function = fun
    args = args.to_a  unless args.class == Array
    self.args = args  
  end
  
  def to_gv(f=$>)
    f.puts self.args.map { |e| "\"#{ function.to_gv f }\" -> \"#{ e.to_gv f }\";" }
    function.to_gv
  end

  def reset_gv_flag
    self.args.map { |e| e.reset_gv_flag }
    function.reset_gv_flag    
  end

end



class ASTTermLeaf < ASTTerm

  def initialize
    self.gv = true
  end

  def reset_gv_flag
    self.gv = true
  end

  def leaf_to_gv(f, str)
    if self.gv
      f.puts "#{ self.object_id } [label = \"#{ str }\"];"
      self.gv = false
    end    
    "#{ self.object_id }"
  end

end



class Named < ASTTermLeaf
  attr_accessor :name

  def initialize(n)
    super()
    self.name = n
  end

  def to_gv(f=$>)
    leaf_to_gv f, self.name
  end

end



class Constant < ASTTermLeaf
  attr_accessor :value

  def initialize(v)
    super()
    self.value = v
  end

  def to_gv(f=$>)
    leaf_to_gv f, self.value
  end
  
end



class Function < ASTTermLeaf
  attr_accessor :function, :condition, :arity, :name

  def initialize(f, a=1, c=nil)
    super()
    self.function = f
    self.arity = a
    self.condition = c
  end

  def to_gv(f=$>)
    leaf_to_gv f, self.name
  end

end
