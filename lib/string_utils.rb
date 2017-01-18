class String
  def rchomp(sep = $/)
    self.start_with?(sep) ? self[sep.size..-1] : self
  end

  def chomp_both(sep = $/)
    self.rchomp(sep).chomp(sep)
  end
end
