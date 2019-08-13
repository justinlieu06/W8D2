require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req, @res = req, res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    prepare_render_or_redirect
    @res.status = 302
    @res["Location"] = url
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    prepare_render_or_redirect
    @res.write(content)
    @res['Content-Type'] = content_type
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    dir_path = File.dirname(__FILE__)
    file = File.join(
      dir_path, "..",
      "views", self.class.name.underscore, "#{template_name}.html.erb"
    )
    temp = File.read(file)
    render_content(
      ERB.new(temp).result(binding),
      "text/html"
    )
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    if protect_from_forgery? && req.request_method != "GET"
      check_authenticity_token
    else
      form_authenticity_token
    end

    self.send(name)
    render(name) unless already_built_response?
  end

  private
  def prepare_render_or_redirect
    raise "double render error" if already_built_response?
    @already_built_response = true
    session.store_session(@res)
    
  end
end

