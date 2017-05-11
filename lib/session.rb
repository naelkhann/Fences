require 'json'

class Session

  def initialize(req)
    @cookie = req.cookies["fences"]
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
    res.set_cookie("fences", cookie_attributes)
  end
end
