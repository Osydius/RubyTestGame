class TestFile2
  @testVariable
  @testVariable2

  def initialize
    @testVariable = 2
    @testVariable2 = 6
  end

  def getTestVariable
    return @testVariable
  end

  def setTestVariable(newValue)
    @testVariable = newValue
  end

  def getTestVariable2
    return @testVariable2
  end

  def setTestVariable2(newValue)
    @testVariable2 = newValue
  end

  def addBothVariables()
    return @testVariable + @testVariable2
  end

  def multiplyBothVariables()
    return @testVariable * @testVariable2
  end

  def getArrayOfTestVariable(arrayLength)
    newArray = Array.new(arrayLength)
    newArray.each do |arrayIndex|
      newArray[arrayIndex] = @testVariable
    end
    return newArray
  end


end
