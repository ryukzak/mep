#!/usr/bin/ruby1.9

class ASTTerm  

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
    @function = fun
    args = args.to_a  unless args.class == Array
    @args = args  
  end
  
  def to_gv(f=$>)
    f.puts @args.map { |e| "\"#{ function.to_gv f }\" -> \"#{ e.to_gv f }\";" }
    function.to_gv
  end

  def reset_gv_flag
    @args.map { |e| e.reset_gv_flag }
    function.reset_gv_flag    
  end

end


class ASTTermLeaf < ASTTerm

  def initialize
    @gv = true
  end

  def reset_gv_flag
    @gv = true
  end

  def leaf_to_gv(f, str)
    if @gv
      f.puts "#{ self.object_id } [label = \"#{ str }\"];"
      @gv = false
    end    
    "#{ self.object_id }"
  end

end

class Named < ASTTermLeaf
  attr_accessor :name

  def initialize(n)
    super()
    @name = n
  end

  def to_gv(f=$>)
    leaf_to_gv f, @name
  end

end


class Constant < ASTTermLeaf
  attr_accessor :value

  def initialize(v)
    super()
    @value = v
  end

  def to_gv(f=$>)
    leaf_to_gv f, @value
  end
  
end


class Function < ASTTermLeaf
  attr_accessor :function, :condition, :arity, :name

  def initialize(f, a=1, c=nil)
    super()
    @function = f
    @arity = a
    @condition = c
  end

  def to_gv(f=$>)
    leaf_to_gv f, @name
  end

end


