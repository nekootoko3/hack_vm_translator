class VmHackTranslator::MemoryAccessor
  SEGMENT_SYMBOL_MAPPING = {
    local: "LCL",
    argument: "ARG",
    this: "THIS",
    that: "THAT",
    temp: "5"
  }

  VALID_SEGMENTS = [
    :local,
    :argument,
    :this,
    :that,
    :temp,
    :pointer,
  ]

  INITIAL_TEMP_ADDRESS = 5

  def self.symbol_from(segment)
    raise "Invalid segment #{segment}" unless VALID_SEGMENTS.include?(segment.to_sym)

    case segment.to_sym
    when :temp
      INITIAL_TEMP_ADDRESS
    else
      SEGMENT_SYMBOL_MAPPING[segment.to_sym]
    end
  end
end
