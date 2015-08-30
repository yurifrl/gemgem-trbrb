class Thing::Cell::Form < ::Cell::Concept
  inherit_views Thing::Cell

  include ActionView::RecordIdentifier
  include SimpleForm::ActionViewExtensions::FormHelper


  def show
    @operation = options[:op]
    @form = model

    render :form
  end

  def signed_in?
    @options[:signed_in]
  end
end