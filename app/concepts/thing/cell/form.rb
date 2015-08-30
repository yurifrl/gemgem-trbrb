class Thing::Cell::Form < ::Cell::Concept
  inherit_views Thing::Cell

  include ActionView::RecordIdentifier
  include SimpleForm::ActionViewExtensions::FormHelper


  def show
    @form = model

    render :form
  end

private
  def css_class
    return "admin" if admin?
    ""
  end

  # this will be ::property :signed_in?, boolean: true
  def signed_in?
    @options[:signed_in]
  end

  def admin?
    @options[:admin]
  end
end