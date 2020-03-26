module VmHackTranslator::CommandType
  C_UNDEFINED  = 0
  C_ARITHMETIC = 1
  C_PUSH       = 2
  C_POP        = 3
  C_LABEL      = 4
  C_GOTO       = 5
  C_IF         = 6
  C_FUNCTION   = 7
  C_RETURN     = 8
  C_CALL       = 9

  COMMAND_TYPE_MAPPING = {
    add:      C_ARITHMETIC,
    sub:      C_ARITHMETIC,
    neg:      C_ARITHMETIC,
    eq:       C_ARITHMETIC,
    gt:       C_ARITHMETIC,
    lt:       C_ARITHMETIC,
    and:      C_ARITHMETIC,
    or:       C_ARITHMETIC,
    not:      C_ARITHMETIC,
    push:     C_PUSH,
    pop:      C_POP,
    return:   C_RETURN,
    label:    C_LABEL,
    goto:     C_GOTO,
    if:       C_IF,
    call:     C_CALL,
    function: C_FUNCTION,
  }.freeze

  # @param instruction [String]
  # @return [Integer]
  def self.command_type_from(instruction)
    COMMAND_TYPE_MAPPING[instruction.to_sym]
  end
end
