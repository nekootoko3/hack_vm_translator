require "vm_hack_translator/parser"
require "vm_hack_translator/command_type"

module VmHackTranslator::Cli
  def self.start(args)
    input_files = case File.ftype(args[0])
      when "file"
        raise "Invalid file type passed" unless args[0].match?(/.+\.vm/)

        [args[0]]
      when "directory"
        Dir.chdir(args[0])
        Dir.glob("*.vm")
      else
        raise "Invalid input specified"
      end
    output = args[1].nil? ? $stdout : File.open(args[1], "w+")

    input_files.each do |input_file|
      parser = VmHackTranslator::Parser.new(input_file)
    end
  end
end
