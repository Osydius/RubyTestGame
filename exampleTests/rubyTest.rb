class RubyTest
  @testVariable

  def initialize()
    @testVariable = "testingTesting"
    @testAnotherVariable = 100
  end

  def getTestVariable()
    return @testVariable
  end

  def getTestAnotherVariable()
    return @testAnotherVariable
  end

  def setTestVariable(input)
    @testVariable = input
  end

 def setTestAnotherVariable(input)
    @testAnotherVariable = input
  end

end
