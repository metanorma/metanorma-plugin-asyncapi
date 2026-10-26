# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Plugin::Asyncapi::Renderer do
  fixtures = File.expand_path("fixtures", __dir__)

  def render_from(path)
    described_class.new(Lutaml::Asyncapi.parse(File.read(path))).render
  end

  it "renders info, servers, channels and operations for a 3.x document" do
    adoc = render_from(File.join(fixtures, "simple-asyncapi.yml"))
    expect(adoc).to start_with("== ")
    expect(adoc).to include("== Channels")
    expect(adoc).to include("== Operations")
  end

  it "renders 2.x embedded publish/subscribe as operations" do
    adoc = render_from(File.join(fixtures, "asyncapi-corpus-2x.yaml"))
    expect(adoc).to include("== Operations")
  end

  it "exposes the Asciidoctor preprocessor class for metanorma activation" do
    expect(Metanorma::Plugin::Asyncapi::Preprocessor.superclass)
      .to be(Asciidoctor::Extensions::Preprocessor)
  end
end
