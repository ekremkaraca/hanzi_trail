module Shared
  class FooterComponent < ViewComponent::Base
    # DRY: single muted line with copyright + repo link, kept minimal on purpose.
    def source_link
      helpers.link_to("Source", "https://github.com/ekremkaraca/hanzi_trail")
    end
  end
end
