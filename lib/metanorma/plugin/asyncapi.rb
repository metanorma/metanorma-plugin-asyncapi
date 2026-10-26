# frozen_string_literal: true

require "asciidoctor/extensions"

module Metanorma
  module Plugin
    module Asyncapi
      autoload :VERSION, "metanorma/plugin/asyncapi/version"
      autoload :Renderer, "metanorma/plugin/asyncapi/renderer"
      autoload :Preprocessor, "metanorma/plugin/asyncapi/preprocessor"
    end
  end
end
