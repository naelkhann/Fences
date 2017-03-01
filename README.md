# Fences
A light Ruby MVC framework utilizing Rack, similar to Rails. FencesController is similar to ActionController::Base, providing controller actions and template rendering. Router routes URL query params to controller actions.

## FencesController
### Key Features
- `#render`: Renders a template at the path - `app/views/<controller_name>` directory.
- `#redirect_to`: Redirects to specified URL with proper response header status 302
- `#session`: Cookies handling

## Router
The `Router` maps routes to controller actions. Example:

```ruby
router = Router.new
router.draw do
  get Regexp.new("^/heroes/new$"), HeroesController, :new
```

## TODOs
- Provide FencesModels ORM functionality.
- Add error handling.
- Add static asset handling.
- Create CLI to generate controllers, routes.
