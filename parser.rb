#!/usr/bin/ruby1.9

require "ast_term"

class ParserTerm 
  def to_a
    [ self ]
  end
  
  def priority
    nil
  end

  def open?
    false
  end
  
  def close?
    false
  end
  
  def comma?
    false
  end

  def operator?
    false
  end

end



class Expression < ParserTerm
  attr_accessor :expr
  
  def initialize e
    self.expr = e
  end
  
  def reverse!
    self.expr.reverse!
  end

  def make_ast
    return self.expr[0].make_ast  if self.expr.length == 1
    
    expr = self.expr
    until ( i = find_function_application expr ).nil?
      pre = if i == 0 then []
            else expr[ 0 .. ( i - 1 ) ]
            end
      fa = FunctionApplication.new( expr[ i ].make_ast, expr[ i + 1 ].make_ast )
      post = expr[ ( i + 2 ) .. expr.length ]
      expr = pre.to_a + fa.to_a + post.to_a
    end
    
    until ( i = find_operator expr ).nil?
      pre = if i == 1 then []
            else expr[ 0 .. ( i - 2 ) ]
            end
      fa = FunctionApplication.new( expr[ i ].make_ast, 
                                    [expr[ i - 1 ].make_ast,
                                     expr[ i + 1 ].make_ast 
                                    ] )
      
      if BOXING_OPERATOR.include? fa.function.name
        fa = BOXING_OPERATOR[ fa.function.name ].call fa
      end
      
      post = if i == expr.length - 2 then []
             else expr[ ( i + 2 ) .. expr.length ]
             end
      expr = pre.to_a + fa.to_a + post.to_a
    end
    expr = expr[0]  if expr.length == 1
    self.ast = expr
  end

end



class ExpressionList < ParserTerm
  attr_accessor :exprs
  
  def initialize e=[]
    self.exprs = e
  end  
  
  def push e
    self.exprs << e
    self
  end

  def make_ast
    expr.exprs.map { |e| e.make_ast }    
  end

end

class Atom < ParserTerm
  attr_accessor :value
  
  def initialize l
    self.value = case l
             when "(" then :open
             when ")" then :close
             when "," then :comma
             else l
             end
  end
  
  def open?
    self.value == :open
  end
  
  def close?
    self.value == :close
  end
  
  def comma?
    self.value == :comma
  end

  def operator?
    not self.priority.nil?
  end

  def priority
    Parser::OPERATORS[ value ]
  end
  
  def to_s
    value.to_s
  end

  def to_ast
    if self.value =~ /\d+\.\d+|\d+/
      Constant.new self.value.to_f
    else
      Named.new self.value
    end
  end

  def make_ast
    expr.to_ast
  end
  
end

class Parser
  attr_accessor :lexems, :atoms, :expr, :ast

  OPERATORS = {
    "+" => 1,
    "-" => 1,
    "*" => 2,
    "/" => 2,
    "^" => 3,
  } 

  BOXING_OPERATOR = {
    "-" => ->f do 
      FunctionApplication.new( Named.new("+"), 
                               [ f.args[ 0 ], FunctionApplication.new( Named.new( "-" ), [ f.args[ 1 ] ] ) ] )
    end,
    "/" => ->f do 
      FunctionApplication.new( Named.new("*"), 
                               [ f.args[ 0 ], FunctionApplication.new( Named.new( "/" ), [ f.args[ 1 ] ] ) ] )
    end,
  }
  
  def initialize lexems
    self.lexems = lexems
  end

  def run
    self.make_atom self.lexems
    self.make_expr self.atoms
    self.expr.make_ast
  end
  
  def make_atom lexems
    self.atoms = self.lexems.map { |e| Atom.new e  }
  end
  


  def make_expr atoms
    atoms = ( make_expr_list atoms ).to_a  if expr_list? atoms
    atoms = parentheses_to_expr atoms
    unless atoms.length == 1 and atoms[ 0 ].class == ExpressionList
      atoms = Expression.new atoms
    end
    self.expr = atoms
  end
  
  def expr_list? atoms
    not comma_position( atoms ).nil?
  end
  
  def comma_position atoms
    n = i = 0
    while i < atoms.length and not( atoms[ i ].comma? and n == 0 )
      n += 1  if atoms[ i ].open?
      n -= 1  if atoms[ i ].close?
      i += 1
    end
    raise "Un balance parentheses"  if n != 0    
    return nil  if i == 0 or i == atoms.length 
    return i
  end
  
  def make_expr_list atoms
    # Split atom list by comma in Expression
    expr_list = ExpressionList.new
    until ( i = comma_position( atoms ) ).nil?
      expr_list.push make_expr( atoms[ 0 .. ( i - 1 ) ] )
      atoms = atoms[ ( i + 1 ) .. atoms.length ]
    end 
    expr_list.push make_expr( atoms )
  end
  
  def parentheses? atoms
    atoms.each { |e| return true  if e.class == Atom and e.open? }
    false
  end
    
  def parentheses_to_expr atoms
    raise "Empty parentheses"  if atoms.empty?
    while parentheses? atoms
      i1 = 0
      i1 += 1  until atoms[ i1 ].open?      
      i2 = i1; n = 1
      begin
        i2 += 1
        n += 1  if atoms[ i2 ].open?
        n -= 1  if atoms[ i2 ].close?
      end until n == 0
      expr = make_expr( atoms[ ( i1 + 1 ) .. ( i2 - 1 ) ] )
      atoms = atoms[ 0 .. ( i1 - 1 ) ].to_a +
        expr.to_a  +
        atoms[ ( i2 + 1 ) .. ( atoms.length ) ].to_a
    end
    atoms
  end


  def find_operator expr
    acc = place = nil
    return nil  unless expr.class == Array
    for i in ( 0 .. expr.length - 1 ) do
      if expr[ i ].operator?
        p = expr[ i ].priority
        if acc.nil? or acc < p
          acc = p
          place = i
        end
      end
    end
    place
  end

  def find_function_application expr
    i = 0
    while i < expr.length - 1
        if expr[ i ].class == Expression and expr[ i + 1].class == Expression
          raise "Statement error"
        elsif not expr[ i ].operator? and not expr[ i + 1 ].operator? and
            not expr[ i ].class == Expression
          return i
        elsif expr[ i ].operator? and expr[ i + 1 ].class == Atom and 
            not expr[ i + 2 ].nil? and not expr[ i + 2 ].operator?
          return i + 1
        elsif i == 0 and expr[ i ].operator? and expr[ i + 1 ].class == Atom
          return i
        end
      i += 1      
    end    
  end
  
end
