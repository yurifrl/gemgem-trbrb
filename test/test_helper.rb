ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "pp"

Rails.backtrace_cleaner.remove_silencers!

MiniTest::Spec.class_eval do
  after :each do
    # DatabaseCleaner.clean
    Thing.delete_all
    Comment.delete_all
    User.delete_all
  end
end

# this is otherwise done in Cell::TestCase, which is derived from ActiveSupport::TestCase, and sucks.
Cell::Testing.capybara = true

#NoMethodError: undefined method `assert_selector' for #<ThingCellTest:0xc32a5a8>
# require "minitest/rails/capybara"
# class IntegrationTest < Capybara::Rails::TestCase
#   def sign_in!(*)
#     sign_up! #=> Session::SignUp

#     visit "/sessions/sign_in_form"

#     submit!(email="fred@trb.org", password="123456")
#   end

#   def sign_up!(email="fred@trb.org", password="123456")
#     Session::SignUp::Admin.(user: {email: email, password: password})
#   end

#   def submit!(email, password)
#     within("//form[@id='new_session']") do
#       fill_in 'Email',    with: email
#       fill_in 'Password', with: password
#     end
#     click_button "Sign in!"
#   end
# end