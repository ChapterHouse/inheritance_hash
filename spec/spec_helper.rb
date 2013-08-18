require 'bundler/setup'
require 'rspec/autorun'
require 'inheritance_hash'

# Support the errors_on check without rails loaded
#module ::ActiveModel::Validations
#  def errors_on(attribute)
#    self.valid?
#    [self.errors[attribute]].flatten.compact
#  end
#  alias :error_on :errors_on
#end

RSpec.configure do |config|
  config.order = "random"
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end



