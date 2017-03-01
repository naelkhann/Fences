require 'json'

class Session

  def initialize(req)
    @cookie = req.cookies["_rails_lite_app"]
    if @cookie
      @cookie_json = JSON.parse(@cookie)
    else
      @cookie_json = {}
    end
  end

  def [](key)
    @cookie_json[key]
  end

  def []=(key, val)
    @cookie_json[key] = val
  end

  def store_session(res)
    cookie_attributes = {path: "/", value: @cookie_json.to_json}
    res.set_cookie("_rails_lite_app", cookie_attributes)
  end
end
