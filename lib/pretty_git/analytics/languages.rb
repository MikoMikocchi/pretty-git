# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Extension → Language mapping (common set; heuristic only)
    EXT_TO_LANG = {
      # Web / Script
      '.rb' => 'Ruby',
      '.js' => 'JavaScript', '.mjs' => 'JavaScript', '.cjs' => 'JavaScript',
      '.jsx' => 'JSX', '.tsx' => 'TSX',
      '.ts' => 'TypeScript',
      '.py' => 'Python', '.php' => 'PHP', '.phtml' => 'PHP',
      '.sh' => 'Shell', '.bash' => 'Shell', '.zsh' => 'Shell',
      '.ps1' => 'PowerShell', '.psm1' => 'PowerShell',
      '.bat' => 'Batchfile', '.cmd' => 'Batchfile',
      # Intentionally excluding JSON (usually data, not source code)
      '.yml' => 'YAML', '.yaml' => 'YAML', '.toml' => 'TOML', '.ini' => 'INI', '.xml' => 'XML',
      '.html' => 'HTML', '.htm' => 'HTML', '.css' => 'CSS', '.scss' => 'SCSS', '.sass' => 'SCSS',
      '.md' => 'Markdown', '.markdown' => 'Markdown',
      '.vue' => 'Vue', '.svelte' => 'Svelte',

      # Systems / Compiled
      '.go' => 'Go', '.rs' => 'Rust', '.java' => 'Java',
      '.c' => 'C', '.h' => 'C',
      '.cpp' => 'C++', '.cc' => 'C++', '.cxx' => 'C++', '.hpp' => 'C++', '.hh' => 'C++',
      '.m' => 'Objective-C', '.mm' => 'Objective-C', '.swift' => 'Swift',
      '.kt' => 'Kotlin', '.kts' => 'Kotlin', '.scala' => 'Scala', '.groovy' => 'Groovy',
      '.dart' => 'Dart', '.cs' => 'C#',

      # Data / Query / Spec
      '.sql' => 'SQL', '.graphql' => 'GraphQL', '.gql' => 'GraphQL', '.proto' => 'Proto',

      # Misc / Scripting
      '.pl' => 'Perl', '.pm' => 'Perl', '.r' => 'R', '.R' => 'R', '.lua' => 'Lua', '.hs' => 'Haskell',
      '.ex' => 'Elixir', '.exs' => 'Elixir', '.erl' => 'Erlang'
    }.freeze

    # Filename → Language (no/varied extension)
    FILENAME_TO_LANG = {
      'Makefile' => 'Makefile',
      'Dockerfile' => 'Dockerfile'
    }.freeze

    VENDOR_DIRS = %w[
      vendor node_modules .git .bundle dist build out target coverage
      .venv venv env __pycache__ .mypy_cache .pytest_cache .tox .eggs .ruff_cache
      .ipynb_checkpoints
    ].freeze
    BINARY_EXTS = %w[
      .png .jpg .jpeg .gif .svg .webp .ico .bmp
      .pdf .zip .tar .gz .tgz .bz2 .7z .rar
      .mp3 .ogg .wav .mp4 .mov .avi .mkv
      .woff .woff2 .ttf .otf .eot
      .jar .class .dll .so .dylib
      .exe .bin .dat
    ].freeze
    # Computes language distribution by summing file sizes per language.
    # Similar to GitHub Linguist approach (bytes per language).
    class Languages
      def self.call(_enum, filters)
        repo = filters.repo_path
        items = calculate(repo, include_globs: filters.paths, exclude_globs: filters.exclude_paths)
        total = total_bytes(items)
        items = add_percents(items, total)
        items = sort_and_limit(items, filters.limit)

        build_result(repo, items, total)
      end

      def self.calculate(repo_path, include_globs:, exclude_globs:)
        by_lang = Hash.new(0)
        Dir.chdir(repo_path) do
          each_source_file(include_globs, exclude_globs) do |abs_path|
            basename = File.basename(abs_path)
            ext = File.extname(abs_path).downcase
            lang = FILENAME_TO_LANG[basename] || EXT_TO_LANG[ext]
            next unless lang

            size = begin
              File.size(abs_path)
            rescue StandardError
              0
            end
            by_lang[lang] += size
          end
        end
        by_lang.map { |lang, bytes| { language: lang, bytes: bytes } }
      end

      def self.each_source_file(include_globs, exclude_globs)
        # Build list of files under repo respecting includes/excludes
        all = Dir.glob('**/*', File::FNM_DOTMATCH).select { |p| File.file?(p) }
        files = all.reject { |p| vendor_path?(p) || binary_ext?(p) }
        files = filter_includes(files, include_globs)
        files = filter_excludes(files, exclude_globs)
        files.each { |rel| yield File.expand_path(rel) }
      end

      def self.filter_includes(files, globs)
        globs = Array(globs).compact
        return files if globs.empty?

        allowed = globs.flat_map { |g| Dir.glob(g) }
        files.select { |f| allowed.include?(f) }
      end

      def self.filter_excludes(files, globs)
        globs = Array(globs).compact
        return files if globs.empty?

        blocked = globs.flat_map { |g| Dir.glob(g) }
        files.reject { |f| blocked.include?(f) }
      end

      def self.vendor_path?(path)
        parts = path.split(File::SEPARATOR)
        parts.any? { |seg| VENDOR_DIRS.include?(seg) }
      end

      def self.binary_ext?(path)
        BINARY_EXTS.include?(File.extname(path).downcase)
      end

      def self.total_bytes(items)
        items.sum { |item| item[:bytes] }
      end

      def self.add_percents(items, total)
        return items.map { |item| item.merge(percent: 0.0) } unless total.positive?

        items.map { |item| item.merge(percent: (item[:bytes] * 100.0 / total)) }
      end

      def self.sort_and_limit(items, limit)
        sorted = items.sort_by { |item| [-item[:percent], item[:language]] }
        lim = limit.to_i
        return sorted if lim <= 0

        sorted.first(lim)
      end

      def self.build_result(repo, items, total)
        {
          report: 'languages',
          repo_path: repo,
          generated_at: Time.now.utc.iso8601,
          totals: { bytes: total, languages: items.size },
          items: items
        }
      end
    end
  end
end
