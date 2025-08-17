#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'open3'
require 'rbconfig'

# Minimal, dependency-free perf runner for pretty-git
# Measures wall time per report across multiple iterations.
# Optionally captures RSS via `ps` on Unix-like systems.

opts = {
  repo: '.',
  reports: %w[summary files authors languages activity heatmap hotspots churn ownership],
  format: 'console',
  iters: 3,
  since: nil,
  until_at: nil,
  allocs: false
}

OptionParser.new do |o|
  o.on('--repo PATH', 'Path to repository') { |v| opts[:repo] = v }
  o.on('--reports LIST', 'Comma-separated reports list') { |v| opts[:reports] = v.split(',').map(&:strip) }
  o.on('--format FMT', 'Output format (console/json/csv/md/yaml/xml)') { |v| opts[:format] = v }
  o.on('--iters N', Integer, 'Iterations per report') { |v| opts[:iters] = v }
  o.on('--since T', 'Since datetime (optional)') { |v| opts[:since] = v }
  o.on('--until T', 'Until datetime (optional)') { |v| opts[:until_at] = v }
  o.on('--allocs', 'Capture allocated objects delta via GC.stat (best-effort)') { opts[:allocs] = true }
end.parse!(ARGV)

BIN = File.expand_path(File.join(__dir__, '..', 'bin', 'pretty-git'))
RUBY = RbConfig.ruby

abort "pretty-git binary not found or not executable: #{BIN}" unless File.executable?(BIN)

# Use ps to read RSS in kilobytes (macOS/Linux). Fallback: nil.
def rss_kb(pid)
  out, = Open3.capture2('ps', '-o', 'rss=', '-p', pid.to_s)
  out.strip.empty? ? nil : out.to_i
rescue StandardError
  nil
end

puts '== Perf baseline =='
puts "repo: #{opts[:repo]}"
puts "reports: #{opts[:reports].join(', ')}"
puts "format: #{opts[:format]}"
puts "iters: #{opts[:iters]}"
puts "since: #{opts[:since] || '-'} | until: #{opts[:until_at] || '-'}"
puts "allocs: #{opts[:allocs]}"
puts

# rubocop:disable Metrics/BlockLength
summary = []

opts[:reports].each do |report|
  times = []
  peak_rss = 0
  allocs_list = []

  opts[:iters].times do |i|
    args = [RUBY, BIN, report, opts[:repo], '--format', opts[:format]]
    args += ['--since', opts[:since]] if opts[:since]
    args += ['--until', opts[:until_at]] if opts[:until_at]

    start_alloc = nil
    if opts[:allocs]
      begin
        start_alloc = GC.stat[:total_allocated_objects]
      rescue StandardError
        start_alloc = nil
      end
    end
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Open3.popen3(*args) do |_stdin, _stdout, _stderr, thr|
      # Drain output to avoid blocking; we don't need to print it
      # but read non-blocking could complicate, so just let it flow to /dev/null by not reading.
      pid = thr.pid
      pr = rss_kb(pid)
      peak_rss = [peak_rss, pr.to_i].max if pr
      status = thr.value
      warn "Command failed (#{status.exitstatus}): #{args.join(' ')}" unless status.success?
    end
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    times << elapsed
    if start_alloc
      begin
        finish_alloc = GC.stat[:total_allocated_objects]
      rescue StandardError
        finish_alloc = nil
      end
      delta_alloc = finish_alloc && start_alloc ? (finish_alloc - start_alloc) : nil
      allocs_list << (delta_alloc || 0)
      printf(
        "%-12<report>s iter %-2<iter>d: %6.2<sec>fs allocs=%<allocs>d\n",
        { report: report, iter: i + 1, sec: elapsed, allocs: delta_alloc || 0 }
      )
    else
      printf("%-12<report>s iter %-2<iter>d: %6.2<sec>fs\n", { report: report, iter: i + 1, sec: elapsed })
    end
  end

  min = times.min || 0.0
  avg = times.sum / [times.size, 1].max
  max = times.max || 0.0
  allocs_min = allocs_list.min if allocs_list.any?
  allocs_avg = (allocs_list.sum.to_f / allocs_list.size) if allocs_list.any?
  allocs_max = allocs_list.max if allocs_list.any?
  summary << {
    report: report,
    min: min,
    avg: avg,
    max: max,
    rss_kb: peak_rss,
    allocs_min: allocs_min,
    allocs_avg: allocs_avg,
    allocs_max: allocs_max
  }
  if allocs_list.any?
    printf(
      "%-12<report>s summary: min=%5.2<min>f avg=%5.2<avg>f max=%5.2<max>f rss=%<rss>s KB\n",
      { report: report, min: min, avg: avg, max: max, rss: (peak_rss ? peak_rss.to_s : '-') }
    )
    printf(
      "%-12<prefix>s allocs(min/avg/max)=%<amin>d/%<aavg>.0f/%<amax>d\n\n",
      { prefix: '', amin: allocs_min || 0, aavg: allocs_avg || 0, amax: allocs_max || 0 }
    )
  else
    printf(
      "%-12<report>s summary: min=%5.2<min>f avg=%5.2<avg>f max=%5.2<max>f rss=%<rss>s KB\n\n",
      { report: report, min: min, avg: avg, max: max, rss: (peak_rss ? peak_rss.to_s : '-') }
    )
  end
end

puts '== Summary =='
summary.each do |row|
  rss = row[:rss_kb] ? row[:rss_kb].to_s : '-'
  if row[:allocs_avg]
    printf(
      "%-12<report>s min=%5.2<min>f avg=%5.2<avg>f max=%5.2<max>f rss=%<rss>s KB\n",
      { report: row[:report], min: row[:min], avg: row[:avg], max: row[:max], rss: rss }
    )
    printf(
      "%-12<prefix>s allocs(min/avg/max)=%<amin>d/%<aavg>.0f/%<amax>d\n",
      { prefix: '', amin: row[:allocs_min] || 0, aavg: row[:allocs_avg] || 0, amax: row[:allocs_max] || 0 }
    )
  else
    printf(
      "%-12<report>s min=%5.2<min>f avg=%5.2<avg>f max=%5.2<max>f rss=%<rss>s KB\n",
      { report: row[:report], min: row[:min], avg: row[:avg], max: row[:max], rss: rss }
    )
  end
end
# rubocop:enable Metrics/BlockLength
