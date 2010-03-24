#!/usr/bin/ruby1.9

class Lexer

  attr_accessor :string, :lexems

  def run
    split self.string 
  end

  private

  def initialize str
    self.string = str
  end

  def split string=nil
    string = self.string  if string.nil?
    string.scan( /\d+\.\d*|\d+|[+-\/\*^]|[\(\)]|\S[^+-\/\*^\(\)\s]*/ )
  end

end

