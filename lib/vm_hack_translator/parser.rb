require "vm_hack_translator/command_type"

class VmHackTranslator::Parser
  def initialize(input)
    File.open(input) do |f|
      @command_lines = remove_comment_and_space(f.readlines)
    end
    @current_command_line = nil
    @next_line_number = 0
  end

  def has_more_commands?
    !@command_lines[@next_line_number].nil?
  end

  def advance!
    raise "No new command_lines exists" unless has_more_commands?

    @current_command_line = @command_lines[@next_line_number].split
    @next_line_number += 1
  end

  def command_type
    VmHackTranslator::CommandType.command_type_from(current_command)
  end

  def arg1
    case command_type
    when VmHackTranslator::CommandType::C_ARITHMETIC
      current_command
    when VmHackTranslator::CommandType::C_RETURN
      raise "Invalid command type #{command_type}"
    else
      @current_command_line[1]
    end
  end

  def arg2
    raise "Invalid command type #{command_type}" unless arg2_enabeld?

    @current_command_line[2]
  end

  private

  def remove_comment_and_space(command_lines)
    command_lines.map do |c|
      c.sub!(/\s*\/\/.*/, "")
      c.empty? ? nil : c
      c.strip!
    end.compact
  end

  def current_command
    @current_command_line[0]
  end

  def arg2_enabeld?
    [
      VmHackTranslator::CommandType::C_PUSH,
      VmHackTranslator::CommandType::C_POP,
      VmHackTranslator::CommandType::C_FUNCTION,
      VmHackTranslator::CommandType::C_CALL,
    ].include?(command_type)
  end
end
