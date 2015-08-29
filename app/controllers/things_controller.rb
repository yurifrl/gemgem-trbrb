class ThingsController  < ApplicationController
  respond_to :html

  require_dependency "session/impersonate"
  before_filter { Session::Impersonate.(params.merge!(tyrant: tyrant)) } # TODO: allow Op.(params, session)
  module BeforeFilter
    def process_params!(params)
      # super # from ApplicationController
      # #params.merge!(current_user: tyrant.current_user)
      # Session::Impersonate.(params)
      params
    end
  end
  include BeforeFilter

  def new
    # return render text: "yoo"
    # Thing::Create
    # return render text: "yoooo"

    form Thing::Create
    @form.prepopulate!
  end

  def create
    run Thing::Create do |op|
      return redirect_to op.model
    end

    @form.prepopulate!
    render action: :new
  end

  def show
    present Thing::Show
    @op = @operation # FIXME.


    form Comment::Create # overrides @model and @form!
    @form.prepopulate!
  end

  def create_comment
    present Thing::Show
    @op = @operation # FIXME.

    run Comment::Create do |op| # overrides @model and @form!
      flash[:notice] = "Created comment for \"#{op.thing.name}\""
      return redirect_to thing_path(op.thing)
    end

    render :show
  end

  def edit
    puts "edit: @@@@??@ #{params.inspect}"

    form Thing::Update::SignedIn

    @form.prepopulate!

    render action: :new
  end

  def update
    # require "pp"
    # pp Thing::Update.contract_class.object_representer_class.representable_attrs
    run Thing::Update::SignedIn do |op|
      return redirect_to op.model
    end


    # @form.prepopulate!
    render action: :new
  end

  # TODO: test me.
  def destroy
    run Thing::Delete::SignedIn do |op|
      flash[:notice] = "#{op.model.name} deleted."
      return redirect_to root_path
    end
  end


  protect_from_forgery except: :next_comments # FIXME: this is only required in the test, things_controller_test.
  def next_comments
    present Thing::Show

    render js: concept("comment/cell/grid", @thing, page: params[:page]).(:append)
  end
end