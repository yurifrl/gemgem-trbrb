module Session
  class SignIn < Trailblazer::Operation
    contract do
      undef :persisted? # TODO: allow with trailblazer/reform.
      attr_reader :user

      property :email,    virtual: true
      property :password, virtual: true

      validates :email, :password, presence: true
      validate :password_ok?

    private
      def password_ok?
        return if email.blank?
        return if password.blank? # TODO: test me.

        @user = User.find_by_email(email)
        return errors.add(:password, "Wrong password.") unless @user # TODO: test me.

        # DISCUSS: move validation of PW to Op#process?
        errors.add(:password, "Wrong password.") unless Tyrant::Authenticatable.new(@user).digest?(password)#
      end
    end

    def process(params)
      # model = User.find_by_email(email) 00000> pass user into form?
      validate(params[:session], nil) do |contract|
         # Monban.config.sign_in_service.new(contract.user).perform
        @model = contract.user
      end
    end
  end

  class Signout < Trailblazer::Operation
    def process(params)
      # empty for now, this could e.g. log signout, etc.
    end
  end


  require "reform/form/validation/unique_validator.rb"
  require "tyrant/sign_up"
  class SignUp < Tyrant::SignUp::Confirmed
    contract do
      validates :email, email: true, unique: true
    end


    class Admin < self # TODO: test. this is kinda "Admin" as it allows instant creation and sign up.
      self.contract_class = Class.new(Reform::Form)
      contract do # inherit: false would be cool here.
        property :email
        property :password, virtual: true
        property :password_digest

        def password_ok?(*) # TODO: allow removing validations.
        end
      end
    end


    class UnconfirmedNoPassword < Trailblazer::Operation
      contract do
        property :email
        validates :email, email: true#, unique: true, presence: true
      end

      def process(params)
        auth = Tyrant::Authenticatable.new(params[:user])
        auth.confirmable!
        auth.sync # DISCUSS: sync here?
      end
    end
  end

  class ChangePassword < Trailblazer::Operation
    include CRUD
    model User, :find

    # TODO: copy from SignUp and remove email.
    contract do
      property :password, virtual: true
      property :confirm_password, virtual: true

      validates :password, :confirm_password, presence: true
      validate :password_ok?


      # TODO: separate form class:
      property :confirmation_token, virtual: true

    private
      # TODO: more, like minimum 6 chars, etc.
      def password_ok?
        return unless password and confirm_password
        errors.add(:password, "Passwords don't match") if password != confirm_password
      end
    end

    attr_reader :confirmation_token
    def setup_params!(params)
      @confirmation_token = params[:confirmation_token] # FIXME: separate class!
      # contract.confirmation_token = @confirmation_token
    end
    # TODO: inherit from SignUp/share with module.
    def process(params)
      @requires_old = params[:requires_old]

      validate(params[:user]) do
        auth = Tyrant::Authenticatable.new(contract.model)
        auth.digest!(contract.password)
        auth.confirmed!
        auth.sync

        contract.save# do |hash|
      end
    end
  end


  # DISCUSS: maybe call ConfirmationTokenIsValid
  class IsConfirmable < Trailblazer::Operation
    include CRUD # TODO: implement with twin.
    model User, :find

    def process(params)
      return if Tyrant::Authenticatable.new(model).confirmable?(params[:confirmation_token])
      invalid!
    end

    def self.reject(*args) # TODO: Implement in Trb.
      run(*args).tap do |res, op|
        yield op if res == false
      end
    end
  end
end