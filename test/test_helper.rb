ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

MiniTest::Spec.class_eval do
  after :each do
    # DatabaseCleaner.clean
    Thing.delete_all
  end
end

ActionController::TestCase.class_eval do
  def get(*)
    super
    @page = Capybara.string response.body
  end

  def post(*)
    super
    @page = Capybara.string response.body
  end

  def put(*)
    super
    @page = Capybara.string response.body
  end

  def delete(*)
    super
    @page = Capybara.string response.body
  end

  def patch(*)
    super
    @page = Capybara.string response.body
  end

  attr_reader :page
end