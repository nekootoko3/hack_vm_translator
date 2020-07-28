require "optparse"

require "vm_hack_translator/parser"
require "vm_hack_translator/command_type"
require "vm_hack_translator/code_writer"

module VmHackTranslator
  class Cli
    attr_reader :options, :vm_path
    attr_accessor :vm_files

    def self.start(options = nil)
      new(options).start
    end

    def initialize(options = nil)
      @vm_files = nil
      @vm_path = ARGV[0]

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
      load_vm_files!

      code_writer = CodeWriter.new(output)
      vm_files.each do |vm_file|
        parser = Parser.new(vm_file)
        code_writer.set_file_name(vm_file)
        while parser.has_more_commands?
          parser.advance!
          code_writer.write!(parser.command_type, parser.arg1, parser.arg2)
        end
      end

      code_writer.close!
    end

    private

    def load_vm_files!
      @vm_files = case File.ftype(vm_path)
        when "file"
          vm_path.match?(/.+\.vm/) ? [vm_path] : nil
        when "directory"
          Dir.glob("#{vm_path}/*.vm")
        else
          nil
        end

      raise ArgumentError, "vm file or directory which includes vm files should be paseed, but got #{vm_path}" unless @vm_files
    end

    def output
      return @output if defined?(@output)

      @output = options[:debug] ? $stdout : output_file
    end

    def output_file
      case File.ftype(vm_path)
      when "file"
        File.join(File.dirname(vm_path), File.basename(vm_path, ".*") + ".asm")
      when "directory"
        File.join(File.absolute_path(vm_path), vm_path + ".asm")
      else
        nil
      end
    end
  end
end
