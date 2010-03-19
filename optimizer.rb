require "ast_term"
require "ast_term_util"

class Optimizer
  attr_accessor :ast, :named, :reduce_rule

  def reduce!
    self.ast = self.ast.reduce reduce_rule
  end

  def sort_function!
    self.ast = self.ast.sort_function [ "+", "*" ]
  end
  
  def substitution! named=nil
    named = self.named  if named.nil?
    raise "Interpreter:undefine ast"  if self.ast.nil?
    self.ast = self.ast.substitution! named
  end
  
  def part_eval!
    self.ast = self.ast.part_eval!
  end
  
  def initialize ast=nil, named=nil
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
      [ReduceRule.new(-> f {f.function.name == "+" and not f.find_fun("-").nil? },
                      -> f do 
                        fun = Function.new( ->( x ){ x[ 0 ] - x[ 1 ] }, 2 )
                        fun.name = "-"
                        a1 = f.find_other_fun("-")
                        a2 = f.find_fun("-").args[0]
                        FunctionApplication.new( fun, [ a1, a2 ] )
                      end ),
       ReduceRule.new(-> f {f.function.name == "*" and not f.find_fun("/").nil? },
                      -> f do 
                        fun = Function.new( ->( x ){ x[ 0 ] / x[ 1 ] }, 2,
                                            ->( x ){ x[ 1 ] != 0 } )
                        fun.name = "/"
                        a1 = f.find_other_fun("/")
                        a2 = f.find_fun("/").args[0]
                        FunctionApplication.new( fun, [ a1, a2 ] )
                      end )
      ]
  end
  
end


class ReduceRule
  attr_accessor :conduction, :reduce

  def initialize c, r
    self.conduction = c
    self.reduce = r
  end

end


class FunctionApplication

  def reduce rules
    rule = rules.find { |e| e.conduction.call self }
    if rule.nil?
      self.args = self.args.map { |e| e.reduce rules }
      self
    else
      new = rule.reduce.call self
      new.args = new.args.map { |e| e.reduce rules }
      new.reduce rules
    end
  end

  def find_fun fun_name
    # use for reduction rule
    self.args.find do |e| 
      if e.class == FunctionApplication
        e.function.name == fun_name 
      else 
        false 
      end
    end
  end

  def find_other_fun fun_name
    # use for reduction rule
    self.args.find do |e| 
      if e.class == FunctionApplication
        e.function.name != fun_name 
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
      args.last( args.length - 1).reduce args.first do |node, a|
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

  def part_eval!
    self.args = self.args.map { |e| e.part_eval! }
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

  def part_eval!
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

