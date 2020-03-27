require "vm_hack_translator/command_type"

class VmHackTranslator::CodeWriter
  INITIAL_STACK_POINTER = 256
  POINTER_BASE_ADDRESS = 3
  TEMP_BASE_ADDRESS = 5
  LOCAL_BASE = 300
  ARGUMENT_BASE = 400
  THIS_BASE = 3000
  THAT_BASE = 3010

  COMMAND_OPERATOR_MAPPING = {
    add: "+",
    sub: "-",
    neg: "-",
    eq:  "JEQ",
    gt:  "JGT",
    lt:  "JLT",
    and: "&",
    or:  "|",
    not: "!",
  }

  SEGMENT_SYMBOL_MAPPING = {
    local: "LCL",
    argument: "ARG",
    this: "THIS",
    that: "THAT",
  }

  # @param output [String]
  def initialize(output)
    @output = output.nil? ?
      $stdout : File.open(output, "w+")
    @cmp_count = 0

    output_initialize!
  end

  # @param file_name [String]
  def set_file_name(file_name)
    @file_name = File.basename(file_name, ".vm")
  end

  # @param command [String]
  def write_arithmetic!(command)
    case command.to_sym
    when :neg, :not
      write_stack_top_address_on_a_register!
      @output.puts("M=#{assembly_from(command)}M")
    when :add, :sub, :and, :or
      write_stack_top_value_on_d_register!
      decrement_sp!
      write_stack_top_address_on_a_register!
      @output.puts("M=M#{assembly_from(command)}D")
    when :eq, :gt, :lt
      write_stack_top_value_on_d_register!
      decrement_sp!
      write_stack_top_address_on_a_register!
      exec_comparison!(command)
    else
      raise "Invalid arithmetic command"
    end
  end

  # @param command_type [VmHackTranslator::CommandType]
  # @param segment [String]
  # @param index [Integer]
  def write_push_pop!(command_type, segment, index)
    case command_type
    when VmHackTranslator::CommandType::C_PUSH
      write_push!(segment, index)
    when VmHackTranslator::CommandType::C_POP
      write_pop!(segment, index)
    else
      raise "Invalid command type #{command_type}"
    end
  end

  # @param label [String]
  def write_label!(label)
    @output.puts("(#{label})")
  end

  # @param label [String]
  def write_if_goto!(label)
    write_stack_top_value_on_d_register!
    decrement_sp!
    @output.puts("@#{label}", "D;JGT")
  end

  # @param label [String]
  def write_goto!(label)
    @output.puts("@#{label}", "0;JMP")
  end

  # @param label [String]
  # @param num_locals [Integer]
  def write_function!(label, num_locals)
    @output.puts("(#{label})")
    write_local_initialization!(num_locals)
  end

  def write_return!
    write_local_base_address_on_r13!
    write_return_address_on_r14!
    write_return_value!
    write_caller_frame!
    write_goto_return_address!
  end

  # @param label [String]
  # @param num_locals [Integer]
  def write_call!(label, num_locals)
  end

  def close!
    write_inifinite_loop!
    @output.close
  end

  private

  def output_initialize!
    @output.puts(
#      "@#{INITIAL_STACK_POINTER}", "D=A", "@SP", "M=D",
#      "@#{LOCAL_BASE}", "D=A", "@LCL", "M=D",
#      "@#{ARGUMENT_BASE}", "D=A", "@ARG", "M=D",
#      "@#{THIS_BASE}", "D=A", "@THIS", "M=D",
#      "@#{THAT_BASE}", "D=A", "@THAT", "M=D",
    )
  end

  # @param segment [String]
  # @param index [Integer]
  def write_push!(segment, index)
    write_segment_value_on_d_register!(segment, index)
    write_d_register_value_on_stack_top!
    increment_sp!
  end

  def write_pop!(segment, index)
    write_stack_top_value_on_d_register!
    write_d_register_value_on_segment!(segment, index)
    decrement_sp!
  end

  def symbol_from(segment)
    SEGMENT_SYMBOL_MAPPING[segment.to_sym]
  end

  # -------------------------------------------------------------------------
  # write assebly methods
  # -------------------------------------------------------------------------

  def assembly_from(vm_command)
    COMMAND_OPERATOR_MAPPING[vm_command.to_sym]
  end

  def write_stack_top_address_on_a_register!
    @output.puts("@SP", "A=M-1")
  end

  def write_stack_top_value_on_d_register!
    @output.puts("@SP", "A=M-1", "D=M")
  end

  def decrement_sp!
    @output.puts("@SP", "M=M-1")
  end

  def increment_sp!
    @output.puts("@SP", "M=M+1")
  end

  def write_d_register_value_on_stack_top!
    @output.puts("@SP", "A=M", "M=D")
  end

  def write_segment_value_on_d_register!(segment, index)
    case segment.to_sym
    when :constant
      write_constant_on_d_register!(index)
    when :pointer
      write_pointer_value_on_d_register!(index)
    when :static
      write_static_value_on_d_register!(index)
    when :temp
      write_temp_value_on_d_register!(index)
    else
      write_symbol_value_on_d_register!(segment, index)
    end
  end

  def write_constant_on_d_register!(index)
    @output.puts("@#{index}", "D=A")
  end

  def write_pointer_value_on_d_register!(index)
    @output.puts("@#{POINTER_BASE_ADDRESS + index}", "D=M")
  end

  def write_static_value_on_d_register!(index)
    @output.puts("@#{@file_name}.#{index}", "D=M")
  end

  def write_temp_value_on_d_register!(index)
    @output.puts("@#{TEMP_BASE_ADDRESS + index}", "D=M")
  end

  def write_symbol_value_on_d_register!(segment, index)
    @output.puts("@#{symbol_from(segment)}", "A=M")
    @output.puts(["A=A+1"] * index) if index > 0
    @output.puts("D=M")
  end

  def write_d_register_value_on_segment!(segment, index)
    case segment.to_sym
    when :pointer
      write_pointer_address_on_a_register!(index)
    when :static
      write_static_address_on_a_register!(index)
    when :temp
      write_temp_address_on_a_register!(index)
    else
      write_symbol_address_on_a_register!(segment, index)
    end
    @output.puts("M=D")
  end

  def write_pointer_address_on_a_register!(index)
    @output.puts("@#{POINTER_BASE_ADDRESS + index}")
  end

  def write_static_address_on_a_register!(index)
    @output.puts("@#{@file_name}.#{index}")
  end

  def write_temp_address_on_a_register!(index)
    @output.puts("@#{TEMP_BASE_ADDRESS + index}")
  end

  def write_symbol_address_on_a_register!(segment, index)
    @output.puts("@#{symbol_from(segment)}", "A=M")
    @output.puts(["A=A+1"] * index) if index > 0
  end

  # before exec_comparison, d register must be right and stack top value must be nn
  def exec_comparison!(vm_command)
    @cmp_count = 0 unless defined?(@cmp_count)

    @output.puts(
      "D=M-D", "@CMP_TRUE_#{@cmp_count}", "D;#{assembly_from(vm_command)}",
      "@SP // false case", "A=M-1", "M=0", "@CMP_END_#{@cmp_count}", "0;JMP",
      "(CMP_TRUE_#{@cmp_count})  // true case", "@SP", "A=M-1", "M=-1",
      "(CMP_END_#{@cmp_count})"
    )

    @cmp_count += 1
  end

  # @param num_locals [Integer]
  def write_local_initialization!(num_locals)
    return unless num_locals > 0

    write_local_base_address_on_a_register!
    @output.puts(["M=0", "A=A+1"] * num_locals)
  end

  def write_local_base_address_on_a_register!
    @output.puts("@LCL", "A=M")
  end

  def write_local_base_address_on_r13!
    @output.puts("@LCL", "D=M", "@R13", "M=D")
  end

  def write_return_address_on_r14!
    @output.puts("@R13", "D=M", ["D=D-1"] * 5, "A=D", "D=M", "@R14", "M=D")
  end

  def write_return_value!
    write_pop!("argument", 0)
  end

  def write_caller_frame!
    @output.puts("@ARG", "D=M", "@SP", "M=D+1")
    @output.puts("@R13", "M=M-1", "A=M", "D=M", "@THAT", "M=D")
    @output.puts("@R13", "M=M-1", "A=M", "D=M", "@THIS", "M=D")
    @output.puts("@R13", "M=M-1", "A=M", "D=M", "@ARG", "M=D")
    @output.puts("@R13", "M=M-1", "A=M", "D=M", "@LCL", "M=D")
  end

  def write_goto_return_address!
    @output.puts("@R14", "A=M", "0;JMP")
  end

  def write_inifinite_loop!
    @output.puts("(END)", "@END", "0;JMP")
  end
end
