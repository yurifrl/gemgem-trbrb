require "test_helper"
require "session/operations.rb"

class SessionSignInTest < MiniTest::Spec
  # successful.
  it do
    sign_in_op = Session::SignUp.(user: {
      email: "selectport@trb.org", password: "123123", confirm_password: "123123",
    })

    res, op = Session::SignIn.run(session: {
      email: "selectport@trb.org",
      password: "123123"
    })

    op.model.must_equal sign_in_op.model
  end

  # wrong password.
  it do
    sign_in_op = Session::SignUp.(user: {
      email: "selectport@trb.org", password: "123123", confirm_password: "123123",
    })

    res, op = Session::SignIn.run(session: {
      email: "selectport@trb.org",
      password: "wrong"
    })

    res.must_equal false
    op.model.must_equal nil
  end

  # 3x wrong password in 10 mins
end