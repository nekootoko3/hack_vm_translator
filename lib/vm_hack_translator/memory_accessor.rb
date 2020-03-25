class VmHackTranslator::MemoryAccessor
  SEGMENT_SYMBOL_MAPPING = {
    local: "LCL",
    argument: "ARG",
    this: "THIS",
    that: "THAT",
    temp: "5",
    pointer: "3",
  }

  def self.symbol_from(segment)
    raise "Invalid segment #{segment}" unless SEGMENT_SYMBOL_MAPPING.keys.include?(segment.to_sym)

    SEGMENT_SYMBOL_MAPPING[segment.to_sym]
  end
end
