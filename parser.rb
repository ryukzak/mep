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
  
  def initialize(e)
    @expr = e
  end
  
  def reverse!
    @expr.reverse!
  end

end

class ExpressionList < ParserTerm
  attr_accessor :exprs
  
  def initialize(e=[])
    @exprs = e
  end  
  
  def push(e)
    @exprs << e
    self
  end
  
end

class Atom < ParserTerm
  attr_accessor :value
  
  def initialize(l)
    @value = case l
             when "(" then :open
             when ")" then :close
             when "," then :comma
             else l
             end
  end
  
  def open?
    @value == :open
  end
  
  def close?
    @value == :close
  end
  
  def comma?
    @value == :comma
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
    if @value =~ /\d+\.\d+|\d+/
      Constant.new @value.to_f
    else
      Named.new @value
    end
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
  
  def self.run(lexems)
    p = self.new
    p.make_atom lexems
    p.make_expr
    p.make_ast
  end
 
  def make_atom(lexems=nil)
    @lexems = lexems  unless lexems.nil?
    @atoms = @lexems.map { |e| Atom.new e  }
  end
  
  def make_expr(atoms=nil)
    atoms = @atoms  if atoms.nil?
    atoms = ( make_expr_list atoms ).to_a  if expr_list? atoms
    atoms = parentheses_to_expr atoms
    unless atoms.length == 1 and atoms[0].class == ExpressionList
      atoms = Expression.new atoms
    end
    @expr = atoms
  end
  
  def expr_list?(atoms)
    not comma_position( atoms ).nil?
  end
  
  def comma_position(atoms)
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
  
  def make_expr_list(atoms)
    expr_list = ExpressionList.new
    until ( i = comma_position( atoms ) ).nil?
      expr_list.push make_expr( atoms[ 0 .. ( i - 1 ) ] )
      atoms = atoms[ ( i + 1 ) .. atoms.length ]
    end 
    expr_list.push make_expr( atoms )
  end
  
  def parentheses?(atoms)    
    atoms.each { |e| return true  if e.class == Atom and e.open? }
    false
  end
    
  def parentheses_to_expr(atoms)
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

  def make_ast(expr=nil)
    expr = @expr  if expr.nil?

    if expr.class == Expression
      return make_ast expr.expr[0]  if expr.expr.length == 1


      expr = expr.expr
      until ( i = find_function_application expr ).nil?
        pre = if i == 0 then []
              else expr[ 0 .. ( i - 1 ) ]
              end
        fa = FunctionApplication.new( make_ast( expr[ i ] ), make_ast( expr[ i + 1 ] ))
        post = expr[ ( i + 2 ) .. expr.length ]
        expr = pre.to_a + fa.to_a + post.to_a
      end

      until ( i = find_operator expr ).nil?
        pre = if i == 1 then []
              else expr[ 0 .. ( i - 2 ) ]
              end
        fa = FunctionApplication.new( make_ast( expr[ i ] ), 
                                        [make_ast( expr[ i - 1 ] ),
                                         make_ast( expr[ i + 1 ] ) 
                                        ] )
        post = if i == expr.length - 2 then []
               else expr[ ( i + 2 ) .. expr.length ]
               end
        expr = pre.to_a + fa.to_a + post.to_a
      end
      expr = expr[0]  if expr.length == 1
      @ast = expr
    elsif expr.class == Atom
      expr.to_ast
    elsif expr.class == ExpressionList
      expr.exprs.map { |e| make_ast e }
    else expr
    end
  end

  
  def find_operator(expr)
    acc = place = nil
    return nil  unless expr.class == Array
    for i in ( 0 .. expr.length - 1 ) do
      if expr[i].operator?
        p = expr[i].priority
        if acc.nil? or acc < p
          acc = p
          place = i
        end
      end
    end
    place
  end

  def find_function_application(expr)
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

