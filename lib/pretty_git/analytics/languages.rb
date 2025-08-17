# frozen_string_literal: true

require 'time'
require 'json'
require 'find'

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
      '.json' => 'JSON',
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

    # Language → HEX color (without leading #) for exports (CSV/JSON/YAML/XML)
    LANG_HEX_COLORS = {
      'Ruby' => 'cc342d',
      'JavaScript' => 'f1e05a', 'TypeScript' => '3178c6',
      'JSX' => 'f1e05a', 'TSX' => '3178c6',
      'Python' => '3572a5', 'Go' => '00add8', 'Rust' => 'dea584', 'Java' => 'b07219',
      'C' => '555555', 'C++' => 'f34b7d', 'C#' => '178600', 'Objective-C' => '438eff', 'Swift' => 'ffac45',
      'Kotlin' => 'a97bff', 'Scala' => 'c22d40', 'Groovy' => 'e69f56', 'Dart' => '00b4ab',
      'PHP' => '4f5d95', 'Perl' => '0298c3', 'R' => '198ce7', 'Lua' => '000080', 'Haskell' => '5e5086',
      'Elixir' => '6e4a7e', 'Erlang' => 'b83998',
      'Shell' => '89e051', 'PowerShell' => '012456', 'Batchfile' => 'c1f12e',
      'HTML' => 'e34c26', 'CSS' => '563d7c', 'SCSS' => 'c6538c',
      'JSON' => 'eeeeee',
      'YAML' => 'cb171e', 'TOML' => '9c4221', 'INI' => '6b7280', 'XML' => '0060ac',
      'Markdown' => '083fa1', 'Makefile' => '427819', 'Dockerfile' => '384d54',
      'SQL' => 'e38c00', 'GraphQL' => 'e10098', 'Proto' => '3b5998',
      'Svelte' => 'ff3e00', 'Vue' => '41b883'
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
    # Computes language distribution by bytes, files, and LOC per language.
    # Default metric: bytes (similar to GitHub Linguist approach).
    # rubocop:disable Metrics/ClassLength
    class Languages
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def self.call(_enum, filters)
        repo = filters.repo_path
        prof = ENV['PG_PROF'] == '1'
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) if prof
        metric = (filters.metric || 'bytes').to_s
        items = calculate(repo, include_globs: filters.paths, exclude_globs: filters.exclude_paths, metric: metric)
        totals = compute_totals(items)
        items = add_percents(items, totals, metric)
        items = add_colors(items)
        items = sort_and_limit(items, filters.limit, metric)

        res = build_result(repo, items, totals, metric)
        if prof
          t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          elapsed = (t1 - t0)
          files = totals[:files]
          warn format(
            '[pg_prof] languages: time=%<sec>.3fs files=%<files>d metric=%<metric>s',
            { sec: elapsed, files: files, metric: metric }
          )
          summary = { component: 'languages', time_sec: elapsed, files: files, metric: metric }
          warn("[pg_prof_json] #{summary.to_json}")
        end
        res
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize
      def self.calculate(repo_path, include_globs:, exclude_globs:, metric: 'bytes')
        by_lang = Hash.new { |h, k| h[k] = { bytes: 0, files: 0, loc: 0 } }
        Dir.chdir(repo_path) do
          each_source_file(include_globs, exclude_globs) do |path|
            basename = File.basename(path)
            ext = File.extname(path).downcase
            lang = FILENAME_TO_LANG[basename] || EXT_TO_LANG[ext]
            next unless lang

            size = safe_file_size(path)
            lines = metric == 'loc' ? safe_count_lines(path) : 0
            agg = by_lang[lang]
            agg[:bytes] += size
            agg[:files] += 1
            agg[:loc] += lines
          end
        end
        by_lang.map { |lang, h| { language: lang, bytes: h[:bytes], files: h[:files], loc: h[:loc] } }
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.each_source_file(include_globs, exclude_globs, &block)
        # Traverse tree with early prune for vendor/binary paths, then apply include/exclude
        files = []
        Find.find('.') do |path|
          rel = path.sub(%r{^\./}, '')
          # Prune vendor dirs early
          if File.directory?(path)
            dir = File.basename(path)
            if VENDOR_DIRS.include?(dir)
              Find.prune
              next
            end
            next
          end
          next unless File.file?(path)
          next if rel.empty?
          next if vendor_path?(rel) || binary_ext?(rel)

          files << rel
        end

        files = filter_includes(files, include_globs)
        files = filter_excludes(files, exclude_globs)
        files.each { |rel| block.call(rel) }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def self.safe_file_size(path)
        File.size(path)
      rescue StandardError
        0
      end

      def self.safe_count_lines(path)
        count = 0
        File.foreach(path) { |_l| count += 1 }
        count
      rescue StandardError
        0
      end

      def self.filter_includes(files, globs)
        globs = Array(globs).compact
        return files if globs.empty?

        allowed = globs.flat_map { |g| Dir.glob(g) }
        allowed_map = allowed.each_with_object({}) { |f, h| h[f] = true }
        files.select { |f| allowed_map[f] }
      end

      def self.filter_excludes(files, globs)
        globs = Array(globs).compact
        return files if globs.empty?

        blocked = globs.flat_map { |g| Dir.glob(g) }
        blocked_map = blocked.each_with_object({}) { |f, h| h[f] = true }
        files.reject { |f| blocked_map[f] }
      end

      def self.vendor_path?(path)
        parts = path.split(File::SEPARATOR)
        parts.any? { |seg| VENDOR_DIRS.include?(seg) }
      end

      def self.binary_ext?(path)
        BINARY_EXTS.include?(File.extname(path).downcase)
      end

      def self.compute_totals(items)
        {
          bytes: items.sum { |i| i[:bytes] },
          files: items.sum { |i| i[:files] },
          loc: items.sum { |i| i[:loc] }
        }
      end

      def self.add_percents(items, totals, metric)
        total = totals[metric.to_sym].to_f
        return items.map { |item| item.merge(percent: 0.0) } unless total.positive?

        items.map do |item|
          val = item[metric.to_sym].to_f
          pct = (val * 100.0 / total).round(2)
          item.merge(percent: pct)
        end
      end

      def self.add_colors(items)
        items.map do |item|
          color = LANG_HEX_COLORS[item[:language]]
          item.merge(color: color)
        end
      end

      def self.sort_and_limit(items, limit, metric)
        key = metric.to_sym
        sorted = items.sort_by { |item| [-item[key], item[:language]] }
        lim = limit.to_i
        return sorted if lim <= 0

        sorted.first(lim)
      end

      def self.build_result(repo, items, totals, metric)
        {
          report: 'languages',
          repo_path: repo,
          metric: metric,
          generated_at: Time.now.utc.iso8601,
          totals: totals.merge(languages: items.size),
          items: items
        }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
