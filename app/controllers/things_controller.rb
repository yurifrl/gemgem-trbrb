class ThingsController  < ApplicationController
  respond_to :html

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

    # @form.prepopulate! # TODO: must be @form.render
    @form.prepopulate!
    render action: :new
  end

  def show
    present Thing::Update
    form Comment::Create # overrides @model and @form!
    @form.prepopulate!
  end

  def create_comment
    present Thing::Update
    run Comment::Create do |op| # overrides @model and @form!
      flash[:notice] = "Created comment for \"#{op.thing.name}\""
      return redirect_to thing_path(op.thing)
    end

    render :show
  end

  def edit
    form Thing::Update

    @form.prepopulate!

    render action: :new
  end

  def update
    # require "pp"
    # pp Thing::Update.contract_class.object_representer_class.representable_attrs
    run Thing::Update do |op|
      return redirect_to op.model
    end


    # @form.prepopulate!
    render action: :new
  end


  protect_from_forgery except: :next_comments # FIXME: this is only required in the test, things_controller_test.
  def next_comments
    present Thing::Update

    render js: concept("comment/cell/grid", @thing, page: params[:page]).(:append)
  end
end