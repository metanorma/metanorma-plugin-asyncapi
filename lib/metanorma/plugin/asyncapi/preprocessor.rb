# frozen_string_literal: true

require "asciidoctor"

module Metanorma
  module Plugin
    module Asyncapi
      # Splices rendered AsciiDoc in place of an
      #
      #   [asyncapi,path=/to/document.yaml]
      #   --
      #   --
      #
      # envelope before the document parses. A preprocessor, not a
      # block processor: Parser.parse_blocks (the only parse path a
      # block processor gets) cannot create sections.
      class Preprocessor < ::Asciidoctor::Extensions::Preprocessor
        ASYNCAPI_ATTRS = /\A\[asyncapi([,\]].*)?\]\s*\z/

        def process(document, reader)
          ::Asciidoctor::Reader.new(splice(document, reader.readlines),
                                    reader.cursor)
        end

        private

        def splice(document, lines)
          out = []
          until lines.empty?
            line = lines.shift
            if line.match?(ASYNCAPI_ATTRS)
              out.concat(consume_and_render(document, line, lines))
            else
              out << line
            end
          end
          out
        end

        def dashed?(line)
          line&.strip == "--"
        end

        # The closing -- is optional; a missing opening envelope raises
        # from consume_and_render
        def envelope(lines)
          lines.shift while lines.first && lines.first.strip.empty?
          return nil unless dashed?(lines.shift)

          body = []
          while (line = lines.shift) && !dashed?(line)
            body << line
          end
          body
        end

        def consume_and_render(document, attr_line, lines)
          envelope(lines) or
            raise ::ArgumentError,
                  "asyncapi block needs a -- -- envelope: #{attr_line}"
          base = ::File.dirname(document.attributes["docfile"] || ".")
          source = envelope_path(attr_line)
          renderer = Renderer.new(load_document(document, source, base))
          content = renderer.render
          content.split("\n")
        end

        def envelope_path(attr_line)
          path = attr_line[/path=("([^"]+)"|(\S+?))\]/, 2] ||
            attr_line[/path=("([^"]+)"|(\S+?))\]/, 3] ||
            attr_line[/path=([^\]\s]+)/, 1]
          raise ::ArgumentError, "asyncapi block needs a path" unless path

          path
        end

        def load_document(_document, source, base)
          # ::Lutaml — metanorma-plugin-lutaml defines
          # Metanorma::Plugin::Lutaml, which would capture a lexically
          # scoped Lutaml::Asyncapi lookup
          ::Lutaml::Asyncapi.parse(
            ::File.read(::File.expand_path(source, base)),
          )
        end
      end
    end
  end
end
