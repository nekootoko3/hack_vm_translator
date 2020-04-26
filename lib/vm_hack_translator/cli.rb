require "optparse"

require "vm_hack_translator/parser"
require "vm_hack_translator/command_type"
require "vm_hack_translator/code_writer"

module VmHackTranslator
  class Cli
    def self.start(options = nil)
      new(options).start
    end

    def initialize(options = nil)
      if options
        @options = options
        return
      end

      @options = {}
      OptionParser.new do |opts|
        opts.on("-d", "--debug") do |d|
          @options[:debug] = d
        end
      end.parse!
    end

    def start
      input = ARGV[0]
      if input.nil?
        raise "Neither input file specified nor debug option"
      end

      input_files = case File.ftype(input)
        when "file"
          raise ArgumentError, "Invalid file type passed" unless input.match?(/.+\.vm/)

          [input]
        when "directory"
          Dir.glob("#{input}/*.vm")
        else
          raise ArgumentError, "Invalid input specified"
        end
      raise ArgumentError, "Valid input files don't exist" if input_files.empty?

      output = @options[:debug] ? $stdout : output_file_from(input)
      code_writer = VmHackTranslator::CodeWriter.new(output)

      input_files.each do |input_file|
        parser = VmHackTranslator::Parser.new(input_file)
        code_writer.set_file_name(input_file)
        while parser.has_more_commands?
          parser.advance!

          case parser.command_type
          when VmHackTranslator::CommandType::C_PUSH, VmHackTranslator::CommandType::C_POP
            code_writer.write_push_pop!(parser.command_type, parser.arg1, parser.arg2.to_i)
          when VmHackTranslator::CommandType::C_ARITHMETIC
            code_writer.write_arithmetic!(parser.arg1)
          when VmHackTranslator::CommandType::C_LABEL
            code_writer.write_label!(parser.arg1)
          when VmHackTranslator::CommandType::C_IF_GOTO
            code_writer.write_if!(parser.arg1)
          when VmHackTranslator::CommandType::C_GOTO
            code_writer.write_goto!(parser.arg1)
          when VmHackTranslator::CommandType::C_FUNCTION
            code_writer.write_function!(parser.arg1, parser.arg2.to_i)
          when VmHackTranslator::CommandType::C_RETURN
            code_writer.write_return!
          when VmHackTranslator::CommandType::C_CALL
            code_writer.write_call!(parser.arg1, parser.arg2.to_i)
          else
          end
        end
      end

      code_writer.close!
    end

    private

    def output_file_from(input)
      case File.ftype(input)
      when "file"
        File.join(File.dirname(input), File.basename(input, ".*") + ".asm")
      when "directory"
        File.join(File.absolute_path(input), input + ".asm")
      end
    end
  end
end
