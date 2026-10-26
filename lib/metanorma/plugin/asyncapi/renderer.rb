# frozen_string_literal: true

require "lutaml/asyncapi"

module Metanorma
  module Plugin
    module Asyncapi
      # metanorma-plugin-lutaml pins coradoc ~> 1.1.8, which excludes the
      # 2.0 hub in every metanorma-cli bundle; descriptions pass through
      # with only the link bridge when the monorepo is absent.
      begin
        require "coradoc"
        require "coradoc/markdown"
        require "coradoc/asciidoc"
        MONOREPO = true
      rescue LoadError
        MONOREPO = false
      end

      # Renders an AsyncAPI document as normative AsciiDoc sections.
      class Renderer
        def initialize(document)
          @document = document
        end

        def render
          [preface, servers_section, channels_section,
           operations_section, messages_section].compact.join("\n\n")
        end

        TEXT_KEYS = %w[summary description].freeze

        private

        def raw
          @raw ||= @document.to_hash
        end

        def preface
          info = raw["info"] || {}
          lines = ["== #{info['title'] || 'AsyncAPI document'}", ""]
          if @document.asyncapi
            lines << "AsyncAPI version: #{@document.asyncapi}"
          end
          if (desc = info["description"])
            lines << to_asciidoc(desc) << ""
          end
          lines.join("\n")
        end

        def servers_section
          servers = raw["servers"]
          return nil if servers.nil? || servers.empty?

          lines = ["== Servers", ""]
          servers.sort.each do |name, server|
            lines << "=== #{name}" << ""
            lines.concat(server_lines(server)) if server.is_a?(Hash)
            lines << ""
          end
          lines.join("\n")
        end

        def server_lines(server)
          out = []
          out << "URL: `#{server['url']}`" if server["url"]
          if server["protocol"]
            out << "Protocol: `#{server['protocol']}`"
          end
          if server["description"]
            out << to_asciidoc(server["description"]) << ""
          end
          out
        end

        def channels_section
          channels = raw["channels"]
          return nil if channels.nil? || channels.empty?

          lines = ["== Channels", ""]
          channels.sort.each do |id, channel|
            lines << "=== #{id}" << ""
            lines.concat(channel_lines(channel)) if channel.is_a?(Hash)
            lines << ""
          end
          lines.join("\n")
        end

        def channel_lines(channel)
          out = []
          if channel["address"]
            out << "Address: `#{channel['address']}`"
          end
          if channel["description"]
            out << to_asciidoc(channel["description"]) << ""
          end
          out
        end

        def operations_section
          ops = operations
          return nil if ops.empty?

          lines = ["== Operations", ""]
          ops.each do |name, op|
            lines << "=== #{name}" << ""
            lines << "Action: `#{op['action']}`" if op["action"]
            lines.concat(text_lines(op))
            lines << ""
          end
          lines.join("\n")
        end

        # 3.x: top-level operations. 2.x: publish/subscribe embedded in
        # channels, keyed "<channel> <action>".
        def operations
          root_ops = (raw["operations"] || {}).select do |_name, op|
            op.is_a?(Hash)
          end
          root_ops.merge(embedded_operations)
        end

        def embedded_operations
          ops = {}
          (raw["channels"] || {}).each do |id, channel|
            next unless channel.is_a?(Hash)

            append_embedded(ops, id, channel)
          end
          ops
        end

        def append_embedded(ops, id, channel)
          %w[publish subscribe].each do |action|
            if (op = channel[action]).is_a?(Hash)
              ops["#{id} #{action}"] = op.merge("action" => action)
            end
          end
        end

        def messages_section
          messages = collect_messages
          return nil if messages.empty?

          lines = ["== Messages", ""]
          messages.each do |name, message|
            lines << "=== #{name}" << ""
            lines.concat(message_lines(message)) if message.is_a?(Hash)
            lines << ""
          end
          lines.join("\n")
        end

        def message_lines(message)
          out = []
          if message["contentType"]
            out << "Payload content type: `#{message['contentType']}`"
          end
          out.concat(text_lines(message))
          out
        end

        def text_lines(node)
          TEXT_KEYS.filter_map do |key|
            to_asciidoc(node[key]) << "" if node[key]
          end
        end

        def collect_messages
          found = {}
          walk(raw) do |node|
            next unless node.is_a?(Hash) && node["payload"]

            name = node["name"] || node["title"] || "message"
            found[name] = node unless found.key?(name)
          end
          found
        end

        def walk(node, &)
          case node
          when Hash
            yield node
            node.each_value { |v| walk(v, &) }
          when Array
            node.each { |v| walk(v, &) }
          end
        end

        def to_asciidoc(markdown)
          adoc = convert_markdown(markdown)
          adoc.gsub(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/) do
            "#{Regexp.last_match(2)}[#{Regexp.last_match(1)}]"
          end
        end

        def convert_markdown(markdown)
          return markdown unless MONOREPO

          Coradoc.convert(markdown, from: :markdown, to: :asciidoc)
        end
      end
    end
  end
end
