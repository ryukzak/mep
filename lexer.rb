#!/usr/bin/ruby1.9

class Lexer

  attr_accessor :string, :lexems

  def self.run(string)
    l = self.new    
    l.split( string )
  end

  def split(str)
    self.lexems = str.scan( /\d+\.\d*|\d+|[+-\/\*^]|[\(\)]|\S[^+-\/\*^\(\)\s]*/ )
  end

end

