# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'pretty-git'
  version_file = File.expand_path('lib/pretty_git/version.rb', __dir__)
  version_content = File.read(version_file)
  spec.version = version_content[/VERSION\s*=\s*['\"](.*)['\"]/, 1]
  spec.authors       = ['Pretty Git Authors']
  spec.email         = ['']

  spec.summary       = 'Git repository analytics and reporting CLI'
  spec.description   = 'Generates structured analytics from local Git repositories with multiple export formats.'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(__dir__) do
    Dir['lib/**/*', 'README.md', 'LICENSE']
  end
  spec.bindir        = 'bin'
  spec.executables   = ['pretty-git']
  spec.require_paths = ['lib']

  spec.homepage = 'https://github.com/MikoMikocchi/pretty-git'
  spec.metadata['source_code_uri'] = 'https://github.com/MikoMikocchi/pretty-git'
  spec.metadata['changelog_uri'] = 'https://github.com/MikoMikocchi/pretty-git/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/MikoMikocchi/pretty-git/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.4'
end
