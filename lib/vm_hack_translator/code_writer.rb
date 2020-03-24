require "vm_hack_translator/command_type"
require "vm_hack_translator/arithmetic_command"

class VmHackTranslator::CodeWriter
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

  def close
    @output.close
  end

  private

  def output_initialize!
    @output.puts("@256", "D=A", "@SP", "M=D")
  end

  def write_push!(segment, value)
    case segment.to_sym
    when :constant
      @output.puts(
        "@#{value}",
        "D=A",
        "@SP",
        "A=M",
        "M=D   // StackTop <- D",
        "@SP",
        "M=M+1 // SP++"
      )
    else
    end
  end

  def write_pop!(value)
  end
end
