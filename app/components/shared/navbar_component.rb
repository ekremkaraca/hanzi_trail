module Shared
  class NavbarComponent < ViewComponent::Base
    def nav_link(label, path)
      helpers.link_to(label, path, "@click": "close()")
    end
  end
end
