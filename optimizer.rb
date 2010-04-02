require "ast_term"
require "ast_term_util"
require "ast_inspect"

class Optimizer
  attr_accessor :ast, :named, :reduce_rule

  def run named=nil
    substitution( named ).sort_function.reduce( self.reduce_rule ).part_eval
  end

  def reduce reduce_rule=nil
    reduce_rule = self.reduce_rule  if reduce_rule.nil?
    Optimizer.new self.ast.reduce( reduce_rule ), self.named
  end

  def sort_function
    Optimizer.new self.ast.sort_function( [ "+", "*" ] ), self.named
  end
  
  def substitution named=nil
    named = self.named  if named.nil?
    Optimizer.new self.ast.substitution( named ), self.named
  end
  
  def part_eval
    Optimizer.new self.ast.part_eval, self.named
  end

  private
  
  def initialize ast, named=nil, rules=nil
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
                                ->( x ){ x[ 1 ] != 0 } ),
                  Function.new( ->( x ){ 1 / x[ 0 ] }, 1,
                                ->( x ){ x[ 0 ] != 0 } ),
                ],
      "^"    => [ Function.new( ->( x ){ x[ 0 ] ** x[ 1 ] }, 2 ) ],
    }  if named.nil?
    self.reduce_rule = 
      [ ReduceRule.new(-> f { f.function.name == "+" and not f.find_fun( "-", 1 ).nil? },
                       -> f do 
                         fun = Function.new( ->( x ){ x[ 0 ] - x[ 1 ] }, 2 )
                         fun.name = "-"
                         a1 = f.find_other_fun( "-", 1 )
                         a2 = f.find_fun( "-", 1 ).args[0]
                         FunctionApplication.new( fun, [ a1, a2 ] )
                       end, "a + -b = a - b" ),
        ReduceRule.new(-> f { f.function.name == "*" and not f.find_fun("/", 1).nil? },
                       -> f do 
                         fun = Function.new( ->( x ){ x[ 0 ] / x[ 1 ] }, 2,
                                             ->( x ){ x[ 1 ] != 0 } )
                         fun.name = "/"
                         a1 = f.find_other_fun( "/", 1 )
                         a2 = f.find_fun( "/", 1 ).args[0]
                         FunctionApplication.new( fun, [ a1, a2 ] )
                       end, "a * 1/b = a / b" )
      ]  if rules.nil?
  end
  
end


class ReduceRule
  attr_accessor :conduction, :reduce, :comment

  def initialize c, r, t
    self.conduction = c
    self.reduce = r
    self.comment = t
  end

end


class FunctionApplication

  def reduce rules, recursion=false
    new = self.clone

    new.args = new.args.map { |e| e.reduce rules }  unless recursion
    apply_rule = rules.find { |e| e.conduction.call new }

    if apply_rule.nil?
      return new
    else             
      new = apply_rule.reduce.call new 
      return new.reduce rules, true 
    end
  end

  def find_fun fun_name, arity
    # use in reduce function
    self.args.find do |e| 
      if e.class == FunctionApplication
        e.function.name == fun_name and e.function.arity == arity
      else 
        false 
      end
    end
  end

  def find_other_fun fun_name, arity
    # use in reduce function
    self.args.find do |e| 
      if e.class == FunctionApplication
        not( e.function.name == fun_name and e.function.arity == arity )
      else 
        false 
      end
    end
  end

  def sort_function ops
    if ops.include? self.function.name
      args = self.get_operator_line self.function.name
      self.args = self.args.map { |e| e.sort_function ops }  if args.length == 1
      args = args.find_all { |e| e.constant? } + args.find_all { |e| not e.constant? }
      args = args.map { |e| e.sort_function ops }
      args.last( args.length - 1 ).reduce args.first do |node, a|
        FunctionApplication.new self.function.clone, [node, a]
      end 
    else
      self.args = self.args.map { |e| e.sort_function ops }
      self
    end
  end
  
  def get_operator_line op, child=false
    if op == self.function.name
      self.args.map { |e| e.get_operator_line op, true }.flatten
    else
      if child
        self
      else
        nil
      end
    end
  end

  def part_eval
    self.args = self.args.map { |e| e.part_eval }
    if self.args.all? { |e| e.class == Constant } and 
        self.function.class == Function
      self.args = self.args.map { |e| e.value }
      return Constant.new( self.function.function.call args )
    end
    self
  end

  def constant?
    self.args.all? { |e| e.constant? }
  end

end



class ASTTermLeaf

  def reduce rule
    self
  end

  def part_eval
    self
  end

  def sort_function ops
    self
  end

  def get_operator_line op, child=false
    if child
      self
    else
      nil
    end
  end

end



class Named
  
  def constant?
    false
  end
  
end



class Constant
  
  def constant?
    true
  end
  
end



class Function
end

