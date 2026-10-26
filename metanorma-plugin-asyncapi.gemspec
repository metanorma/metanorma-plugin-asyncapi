# frozen_string_literal: true

require_relative "lib/metanorma/plugin/asyncapi/version"

Gem::Specification.new do |spec|
  spec.name = "metanorma-plugin-asyncapi"
  spec.version = Metanorma::Plugin::Asyncapi::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "AsyncAPI as normative Metanorma sections"
  spec.description = "Render AsyncAPI documents as normative Metanorma " \
                     "sections: the [asyncapi,path=...] preprocessor and " \
                     "renderer over lutaml-asyncapi"
  spec.homepage = "https://github.com/metanorma/metanorma-plugin-asyncapi"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.license = "BSD-2-Clause"

  gemspec_file = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__,
                                             err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec_file) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/
                          .rubocop.yml])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "asciidoctor"
  # lutaml-model requires an XML adapter at require time
  spec.add_dependency "lutaml-asyncapi", "~> 0.1.0"
  spec.add_dependency "lutaml-model", "~> 0.8.122"
  spec.add_dependency "nokogiri"
  spec.add_dependency "yeptris", "~> 0.6.34"
end
