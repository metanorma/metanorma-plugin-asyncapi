# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Plugin::Asyncapi do
  it "reports its version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end

RSpec.describe Metanorma::Plugin::Asyncapi::Preprocessor do
  fixtures = File.expand_path("fixtures", __dir__)

  it "splices real sections past the plugin-lutaml namespace" do
    stub_const("Metanorma::Plugin::Lutaml", Module.new)
    docfile = File.join(fixtures, "simple-asyncapi.yml")
    registry = Asciidoctor::Extensions.create do
      preprocessor Metanorma::Plugin::Asyncapi::Preprocessor
    end

    doc = Asciidoctor.load(
      "[asyncapi,path=simple-asyncapi.yml]\n--\n--\n",
      extension_registry: registry,
      attributes: { "docfile" => docfile },
    )

    sections = doc.find_by(context: :section) { |s| s.title == "Channels" }
    expect(sections).not_to be_empty
  end

  it "raises on a missing -- -- envelope" do
    docfile = File.join(fixtures, "simple-asyncapi.yml")
    registry = Asciidoctor::Extensions.create do
      preprocessor Metanorma::Plugin::Asyncapi::Preprocessor
    end

    expect do
      Asciidoctor.load("[asyncapi,path=simple-asyncapi.yml]\n",
                       extension_registry: registry,
                       attributes: { "docfile" => docfile })
    end.to raise_error(ArgumentError, /envelope/)
  end
end
