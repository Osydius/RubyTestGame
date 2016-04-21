require 'simplecov'
require 'simplecov-json'
require 'rspec'
require 'rspec/core/formatters/json_formatter'
require 'json'
require 'yaml'

testFile = ARGV

#------------------------------#
# ADD RSPEC STUFF! #
@rspecConfig = RSpec.configuration
@rpsecFormatter = RSpec::Core::Formatters::JsonFormatter.new(@rspecConfig.output_stream)

# create reporter with json formatter
reporter =  RSpec::Core::Reporter.new(@rspecConfig)
@rspecConfig.instance_variable_set(:@reporter, reporter)

# internal hack
# api may not be stable, make sure lock down Rspec version
loader = @rspecConfig.send(:formatter_loader)
notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)

reporter.register_listener(@rpsecFormatter, *notifications)

#------------------------------#
# Formatting simplecov
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter

SimpleCov.start
SimpleCov.at_exit do
  SimpleCov.result.format!
end

RSpec::Core::Runner.run([testFile])

# here's your json hash
rspecResult = @rpsecFormatter.output_hash

File.open('coverage/rspecResult.yml', 'w+') {|f| f.write(YAML.dump(rspecResult)) }
