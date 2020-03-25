require "vm_hack_translator/command_type"
require "vm_hack_translator/arithmetic_command"
require "vm_hack_translator/memory_accessor"

class VmHackTranslator::CodeWriter
  INITIAL_STACK_POINTER = 256
  LOCAL_BASE = 300
  ARGUMENT_BASE = 400
  THIS_BASE = 3000
  THAT_BASE = 3010

  # @param output [String]
  def initialize(output)
    @output = output.nil? ?
      $stdout : File.open(output, "w+")
    @cmp_count = 0

    output_initialize!
  end

  # @param file_name [String]
  def set_file_name(file_name)
    @file_name = file_name
  end

  # @param command [String]
  def write_arithmetic!(command)
    arithmetic = VmHackTranslator::ArithmeticCommand.new(command)

    if arithmetic.unary_function?
      @output.puts(
        "@SP",
        "A=M-1  // A <- SP-1",
        "M=#{arithmetic.operator}M // M <- [!|-]M"
      )
    else
      @output.puts(
        "@SP",
        "A=M-1",
        "D=M    // D <- Stack Top",
        "@SP",
        "M=M-1  // SP--",
        "A=M-1  // A <- Stack top address"
      )
      if arithmetic.comparison?
        @output.puts(
          "D=M-D",
          "@CMP_TRUE_#{@cmp_count}",
          "D;#{arithmetic.operator}",
          "@SP",
          "A=M-1",
          "M=0",
          "@CMP_END_#{@cmp_count}",
          "0;JMP",
          "(CMP_TRUE_#{@cmp_count})",
          "@SP",
          "A=M-1",
          "M=-1",
          "(CMP_END_#{@cmp_count})"
        )
        @cmp_count += 1
      else
        @output.puts("M=M#{arithmetic.operator}D // M <- Stack top operator D")
      end
    end
  end

  # @param command_type [VmHackTranslator::CommandType]
  # @param segment [String]
  # @param value [String]
  def write_push_pop!(command_type, segment, value)
    case command_type
    when VmHackTranslator::CommandType::C_PUSH
      write_push!(segment, value)
    when VmHackTranslator::CommandType::C_POP
      write_pop!(segment, value)
    else
      raise "Invalid command type #{command_type}"
    end
 end

  def close!
    @output.puts("(END)", "@END", "0;JMP")
    @output.close
  end

  private

  def output_initialize!
    @output.puts(
      "@#{INITIAL_STACK_POINTER}", "D=A", "@SP", "M=D",
#      "@#{LOCAL_BASE}", "D=A", "@LCL", "M=D",
#      "@#{ARGUMENT_BASE}", "D=A", "@ARG", "M=D",
#      "@#{THIS_BASE}", "D=A", "@THIS", "M=D",
#      "@#{THAT_BASE}", "D=A", "@THAT", "M=D",
    )
  end

  def write_push!(segment, value)
    case segment.to_sym
    when :constant
      @output.puts("@#{value}", "D=A")
    when :pointer, :static
      @output.puts("@#{symbol_from(segment)}")
      @output.puts(["A=A+1"] * value.to_i) if value.to_i > 0
      @output.puts("D=M")
    else
      @output.puts("@#{symbol_from(segment)}", "A=M")
      @output.puts(["A=A+1"] * value.to_i) if value.to_i > 0
      @output.puts("D=M")
    end
    @output.puts(
      "@SP", "A=M", "M=D // StackTop <- D",
      "@SP", "M=M+1 // SP++"
    )
  end

  def write_pop!(segment, value)
    @output.puts(
      "@SP", "A=M-1", "D=M // D <- pop value",
      "@#{symbol_from(segment)}")
    @output.puts("A=M") unless [:pointer, :temp, :static].include?(segment.to_sym)
    @output.puts(["A=A+1"] * value.to_i) if value.to_i > 0
    @output.puts("M=D", "@SP", "M=M-1")
  end

  def symbol_from(segment)
    VmHackTranslator::MemoryAccessor.symbol_from(segment)
  end
end
