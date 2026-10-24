module Shared
  class NavbarComponent < ViewComponent::Base
    def nav_link(label, path)
      helpers.link_to(label, path, data: { action: "click->navbar#close" })
    end
  end
end
