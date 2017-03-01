require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params
  attr_accessor :already_built_response

  def initialize(req, res)
    @req = req
    @res = res
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    unless already_built_response?
      res.location = url
      res.status = 302
      @already_built_response = true
      @session.store_session(res)
    else
      raise "Cannot render, you are double rendering"
    end
  end


  def render_content(content, content_type)
    unless already_built_response?
      res['Content-Type'] = content_type
      res.write(content)
      @already_built_response = true
      @session.store_session(res)
    else
      raise "Cannot render, you are double rendering, check your renders"
    end
  end


  def render(template_name)
    controller_name = ActiveSupport::Inflector::underscore(self.class.to_s)
    path = "views/#{controller_name}/#{template_name}.html.erb"
    template = File.read(path)
    template = ERB.new(template).result(binding)
    render_content(template, 'text/html')
  end


  def session
    @session ||= Session.new(@req)
  end

  def invoke_action(name)
  end
end
