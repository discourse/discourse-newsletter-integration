# frozen_string_literal: true

module ::NewsletterIntegration
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace NewsletterIntegration
    config.autoload_paths << File.join(config.root, "lib")
  end
end
