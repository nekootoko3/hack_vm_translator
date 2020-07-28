module VmHackTranslator
  class ArithmeticCommand
    UNDEFINED = 0
    ADD       = 1
    SUB       = 2
    NEG       = 3
    EQ        = 4
    GT        = 5
    LT        = 6
    AND       = 7
    OR        = 8
    NOT       = 9

    ARITHMETIC_COMMAND_MAPPING = {
      add: ADD,
      sub: SUB,
      neg: NEG,
      eq:  EQ,
      gt:  GT,
      lt:  LT,
      and: AND,
      or:  OR,
      not: NOT,
    }

    BINARY_FUNCTIONS = [
      ADD,
      SUB,
      EQ,
      GT,
      LT,
      AND,
      OR,
    ].freeze
    UNARY_FUNCTIONS = [
      NEG,
      NOT,
    ].freeze

    COMMAND_OPERATOR_MAPPING = {
      ADD => "+",
      SUB => "-",
      NEG => "-",
      EQ  => "JEQ",
      GT  => "JGT",
      LT  => "JLT",
      AND => "&",
      OR  => "|",
      NOT => "!",
    }

    # @param command [String]
    def initialize(command)
      @command = ARITHMETIC_COMMAND_MAPPING[command.to_sym]

      raise VmHackTranslator::Error, "Invalid command #{@command}" unless @command
    end

    def unary_function?
      UNARY_FUNCTIONS.include?(@command)
    end

    def binary_function?
      BINARY_FUNCTIONS.include?(@command)
    end

    def comparison?
      [EQ, GT, LT].include?(@command)
    end

    def operator
      COMMAND_OPERATOR_MAPPING[@command]
    end
  end
end
