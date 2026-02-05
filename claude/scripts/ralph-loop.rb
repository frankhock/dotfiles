#!/usr/bin/env ruby
# frozen_string_literal: true

# Ralph Wiggum Loop - Parallel Claude runner using JSON state
# Based on snarktank/ralph pattern
#
# Usage: ralph-loop [options]
#   -p, --prd FILE          Path to ralph-tasks.json (or uses ./ralph-tasks.json if present)
#   -m, --prompt FILE       Path to prompt.md (overrides promptFile in prd.json)
#   -j, --jobs N            Max parallel jobs (default: from prd.json or 5)
#   -d, --delay N           Delay between checks in seconds (default: from prd.json or 15)
#   -k, --kill              Kill all ralph-loop and claude processes
#   -h, --help              Show this help message

require "json"
require "optparse"
require "fileutils"
require "time"
require "shellwords"

class RalphLoop
  MASTER_PID_FILE = "/tmp/ralph-loop-master.pid"

  # ANSI colors
  COLORS = {
    red: "\e[0;31m",
    green: "\e[0;32m",
    yellow: "\e[1;33m",
    blue: "\e[0;34m",
    cyan: "\e[0;36m",
    bright_cyan: "\e[1;96m",
    gray: "\e[0;90m",
    reset: "\e[0m"
  }.freeze

  # Status values
  STATUSES = %w[pending running passed failed].freeze

  def initialize
    @prd_file = nil
    @prompt_file_override = nil
    @max_parallel = nil
    @check_delay = nil
    @run_dir = "/tmp/ralph-loop-#{Process.pid}"
    @running_pids = {} # task_id => pid
    @should_exit = false
  end

  def run
    parse_options
    validate_environment
    load_config
    setup_run_dir
    setup_signal_handlers
    write_master_pid
    display_banner
    main_loop
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Ralph Wiggum Loop - Parallel Claude runner"
      opts.separator ""
      opts.separator "Usage: ralph-loop [options]"
      opts.separator ""
      opts.separator "Options:"

      opts.on("-p", "--prd FILE", "Path to ralph-tasks.json (or uses ./ralph-tasks.json if present)") do |file|
        @prd_file = file
      end

      opts.on("-m", "--prompt FILE", "Path to prompt.md (overrides promptFile in prd.json)") do |file|
        @prompt_file_override = file
      end

      opts.on("-j", "--jobs N", Integer, "Max parallel jobs") do |n|
        @max_parallel = n
      end

      opts.on("-d", "--delay N", Integer, "Check interval in seconds") do |n|
        @check_delay = n
      end

      opts.on("-k", "--kill", "Kill all ralph-loop and claude processes") do
        kill_all_processes
        exit 0
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit 0
      end
    end.parse!

    # Try default prd file if not specified
    if @prd_file.nil?
      # Look for ralph-tasks.json in current directory first
      if File.exist?("ralph-tasks.json")
        @prd_file = "ralph-tasks.json"
      elsif File.exist?(".claude/tasks/prd.json")
        @prd_file = ".claude/tasks/prd.json"
      else
        error "No task file found. Looked for:"
        error "  - ralph-tasks.json (current directory)"
        error "  - .claude/tasks/prd.json"
        error "Use: ralph-loop -p /path/to/tasks.json"
        exit 1
      end
    end
  end

  def validate_environment
    unless File.exist?("CLAUDE.md")
      error "Must run from project root (CLAUDE.md not found)"
      error "cd to your project directory first"
      exit 1
    end

    unless system("which claude > /dev/null 2>&1")
      error "claude CLI not found"
      exit 1
    end

    unless File.exist?(@prd_file)
      error "PRD file not found: #{@prd_file}"
      exit 1
    end
  end

  def load_config
    @prd = JSON.parse(File.read(@prd_file))

    @max_parallel ||= @prd["maxParallel"] || 1
    @check_delay ||= @prd["checkInterval"] || 15
    @prompt_file = @prompt_file_override || @prd["promptFile"] || "ralph-prompt.md"
    @project_name = @prd["project"] || "Unknown"

    unless File.exist?(@prompt_file)
      error "Prompt file not found: #{@prompt_file}"
      error "Set 'promptFile' in prd.json, use --prompt, or create the file"
      exit 1
    end
  end

  def setup_run_dir
    FileUtils.mkdir_p(@run_dir)
  end

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        puts "\n"
        warn_msg "Interrupted!"
        @should_exit = true
      end
    end

    at_exit { cleanup }
  end

  def write_master_pid
    File.write(MASTER_PID_FILE, Process.pid.to_s)
  end

  def display_banner
    y = COLORS[:yellow]
    bc = COLORS[:bright_cyan]
    x = COLORS[:reset]

    # Head (yellow)
    puts "#{y} ⠀⠀⠀⠀⠀⠀⣀⣤⣶⡶⢛⠟⡿⠻⢻⢿⢶⢦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⠀⢀⣠⡾⡫⢊⠌⡐⢡⠊⢰⠁⡎⠘⡄⢢⠙⡛⡷⢤⡀⠀⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⢠⢪⢋⡞⢠⠃⡜⠀⠎⠀⠉⠀⠃⠀⠃⠀⠃⠙⠘⠊⢻⠦⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⢇⡇⡜⠀⠜⠀⠁⠀⢀⠔⠉⠉⠑⠄⠀⠀⡰⠊⠉⠑⡄⡇⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⡸⠧⠄⠀⠀⠀⠀⠀⠘⡀⠾⠀⠀⣸⠀⠀⢧⠀⠛⠀⠌⡇⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠙⠒⠒⠚⠁⠈⠉⠲⡍⠒⠈⠀⡇⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⠈⠲⣆⠀⠀⠀⠀⠀⠀⠀⠀⣠⠖⠉⡹⠤⠶⠁⠀⠀⠀⠈⢦⠀⠀⠀⠀⠀#{x}"
    puts "#{y} ⠀⠀⠀⠀⠈⣦⡀⠀⠀⠀⠀⠧⣴⠁⠀⠘⠓⢲⣄⣀⣀⣀⡤⠔⠃⠀⠀⠀⠀⠀#{x}"
    # Body/shirt (bright cyan)
    puts "#{bc} ⠀⠀⠀⠀⣜⠀⠈⠓⠦⢄⣀⣀⣸⠀⠀⠀⠀⠁⢈⢇⣼⡁⠀⠀⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{bc} ⠀⠀⢠⠒⠛⠲⣄⠀⠀⠀⣠⠏⠀⠉⠲⣤⠀⢸⠋⢻⣤⡛⣄⠀⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{bc} ⠀⠀⢡⠀⠀⠀⠀⠉⢲⠾⠁⠀⠀⠀⠀⠈⢳⡾⣤⠟⠁⠹⣿⢆⠀⠀⠀⠀⠀⠀#{x}"
    puts "#{bc} ⠀⢀⠼⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠈⣧⠀⠀⠀⠀⠀#{x}"
    puts "#{bc} ⠀⡏⠀⠘⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀#{x}"
    puts
    puts colorize(:yellow, "Ralph Loop") + " | " + @project_name
  end

  def hyperlink(path, text)
    "\e]8;;file://#{path}\e\\#{text}\e]8;;\e\\"
  end

  def clear_screen
    print "\e[2J\e[H"  # Clear screen and move cursor to top-left
  end

  def render_progress_bar(passed, total, width: 30)
    return "[" + "░" * width + "] 0% (0/0 passed)" if total == 0

    percent = (passed.to_f / total * 100).round
    filled = (passed.to_f / total * width).round
    empty = width - filled

    bar = "█" * filled + "░" * empty
    "[#{bar}] #{percent}% (#{passed}/#{total} passed)"
  end

  def render_status_line(running, failed, pending)
    parts = []
    parts << colorize(:cyan, "#{running} running") if running > 0
    parts << colorize(:red, "#{failed} failed") if failed > 0
    parts << colorize(:gray, "#{pending} pending") if pending > 0
    parts.join(" | ")
  end

  def render_task_list
    puts "Tasks:"
    @prd["tasks"].each do |task|
      id = task["id"]
      title = task["title"] || "Untitled"
      status = task["status"] || "pending"

      # Truncate title to fit
      max_title = 40
      title = title[0, max_title - 3] + "..." if title.length > max_title

      case status
      when "passed"
        status_str = colorize(:green, "passed ")
        pid_str = ""
      when "running"
        pid = @running_pids[id]
        status_str = colorize(:cyan, "running")
        pid_str = pid ? "  (PID #{pid})" : ""
      when "failed"
        status_str = colorize(:red, "failed ")
        pid_str = ""
      else # pending
        status_str = colorize(:gray, "pending")
        pid_str = ""
      end

      puts "  #{id}  #{status_str}  #{title}#{pid_str}"
    end
  end

  def render_footer(seconds_remaining)
    puts
    puts colorize(:blue, "━" * 64)
    puts "PID: #{Process.pid} | Next check in #{seconds_remaining}s... (Ctrl+C to stop)"
  end

  def main_loop
    until @should_exit
      # Reload PRD to get latest status
      unless reload_prd
        sleep 1
        next
      end

      # Validate tasks array exists
      unless @prd["tasks"].is_a?(Array)
        error "ralph-tasks.json missing 'tasks' array"
        sleep 1
        next
      end

      # Update running task statuses in JSON
      sync_running_status

      # Check on running tasks (reap finished processes)
      check_running_tasks

      # Get current counts
      passed_count = count_by_status("passed")
      running_count = count_by_status("running")
      failed_count = count_by_status("failed")
      pending_count = count_by_status("pending")
      total = @prd["tasks"].length

      # Render full TUI
      clear_screen
      puts
      display_banner

      puts colorize(:blue, "━" * 64)
      prd_link = hyperlink(File.expand_path(@prd_file), "PRD: #{File.basename(@prd_file)}")
      prompt_link = hyperlink(File.expand_path(@prompt_file), "Prompt: #{File.basename(@prompt_file)}")
      puts colorize(:gray, "#{prd_link} | #{prompt_link}")
      puts
      puts render_progress_bar(passed_count, total)
      puts
      puts render_status_line(running_count, failed_count, pending_count)

      render_task_list

      # Check if all done (passed or failed, none pending/running)
      if pending_count == 0 && running_count == 0 && total > 0
        puts

        if failed_count == 0
          success "All tasks completed!"
          puts
          success "🚌 \"I'm a helper!\" - Ralph Wiggum"
        else
          warn_msg "Finished with #{failed_count} failed task(s)"
        end

        @prd["completedAt"] = Time.now.utc.iso8601
        save_prd
        exit(failed_count > 0 ? 1 : 0)
      end

      # Start new tasks if we have capacity
      actual_running = @running_pids.count { |_, pid| process_alive?(pid) }
      available = @max_parallel - actual_running

      if available > 0
        pending_tasks = tasks_by_status("pending")

        pending_tasks.each do |task|
          break if available <= 0
          start_task(task["id"])
          available -= 1
          sleep 0.5  # Small delay between spawns
        end
      end

      # Countdown with TUI refresh each second
      puts
      @check_delay.times do |i|
        break if @should_exit

        remaining = @check_delay - i

        print "\r" + " " * 80 + "\r"  # Clear line
        print "Next check in #{remaining}s... (Ctrl+C to stop)"

        sleep 1
      end
    end
  end

  def reload_prd
    @prd = JSON.parse(File.read(@prd_file))
    true
  rescue JSON::ParserError => e
    error "Failed to parse prd.json: #{e.message} (skipping iteration)"
    false
  end

  def sync_running_status
    # Mark tasks as "running" if we have their PID
    @prd["tasks"].each do |task|
      if @running_pids.key?(task["id"]) && process_alive?(@running_pids[task["id"]])
        task["status"] = "running" unless task["status"] == "passed" || task["status"] == "failed"
      end
    end
  end

  def save_prd
    File.write(@prd_file, JSON.pretty_generate(@prd))
  end

  def tasks_by_status(status_value)
    return [] unless @prd["tasks"].is_a?(Array)
    @prd["tasks"].select { |t| t["status"] == status_value }
  end

  def count_by_status(status_value)
    tasks_by_status(status_value).length
  end

  def start_task(task_id)
    log_file = File.join(@run_dir, "#{task_id}.log")
    prompt_file_path = File.join(@run_dir, "#{task_id}-prompt.txt")

    # Build prompt with task ID and write to temp file
    prompt_content = File.read(@prompt_file)
    task_prompt = "# YOUR ASSIGNED TASK ID: #{task_id}\n\n#{prompt_content}"
    File.write(prompt_file_path, task_prompt)

    # Spawn claude via bash, reading prompt from file via stdin
    cmd = "claude --print --dangerously-skip-permissions < #{prompt_file_path.shellescape}"
    pid = Process.spawn(
      "/bin/bash", "-c", cmd,
      out: log_file,
      err: log_file,
      pgroup: true
    )

    @running_pids[task_id] = pid

    # Update status in JSON
    task = @prd["tasks"].find { |t| t["id"] == task_id }
    if task
      task["status"] = "running"
      save_prd
    end
  end

  def check_running_tasks
    finished_tasks = []

    @running_pids.each do |task_id, pid|
      begin
        result = Process.waitpid2(pid, Process::WNOHANG)
        if result
          _, status = result
          exit_code = status&.exitstatus || 0
          finished_tasks << [task_id, pid, exit_code]
          next
        end
      rescue Errno::ECHILD
        finished_tasks << [task_id, pid, 0]
        next
      end
    end

    finished_tasks.each do |task_id, pid, exit_code|
      process_finished_task(task_id, pid, exit_code)
    end
  end

  def process_finished_task(task_id, _pid, exit_code)
    task = @prd["tasks"].find { |t| t["id"] == task_id }

    if task
      if exit_code == 0
        task["status"] = "passed"
      else
        task["status"] = "failed"
      end
      save_prd
    end

    # Clean up
    @running_pids.delete(task_id)

    # Remove log file
    log_file = File.join(@run_dir, "#{task_id}.log")
    FileUtils.rm_f(log_file)
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def cleanup
    # Only show cleanup messages if there are processes to clean up
    running = @running_pids.select { |_, pid| process_alive?(pid) }

    if running.any?
      puts
      warn_msg "Cleaning up #{running.length} Claude process(es)..."

      # Kill all tracked process groups (negative PID kills entire group)
      running.each do |task_id, pid|
        warn_msg "  Stopping task #{task_id} (PGID: #{pid})"
        begin
          Process.kill("-TERM", pid)
        rescue Errno::ESRCH, Errno::EPERM
          # Already dead or no permission
        end
      end

      sleep 1

      # Force kill remaining process groups
      running.each do |_, pid|
        begin
          Process.kill("-KILL", pid) if process_alive?(pid)
        rescue Errno::ESRCH, Errno::EPERM
          # Already dead or no permission
        end
      end
    end

    # Clean up run directory
    FileUtils.rm_rf(@run_dir) if @run_dir && Dir.exist?(@run_dir)
  end

  def kill_all_processes
    puts "Killing all ralph-loop and claude processes..."

    # Kill master if running
    if File.exist?(MASTER_PID_FILE)
      master_pid = File.read(MASTER_PID_FILE).to_i
      if process_alive?(master_pid)
        puts "  Killing master loop (PID: #{master_pid})"
        begin
          Process.kill("TERM", master_pid)
          sleep 1
          Process.kill(9, master_pid) if process_alive?(master_pid)
        rescue Errno::ESRCH, Errno::EPERM
          # Already dead or no permission
        end
      end
      FileUtils.rm_f(MASTER_PID_FILE)
    end

    # Kill all claude --print processes
    puts "  Killing all claude --print processes..."
    system("pkill -TERM -f 'claude --print' 2>/dev/null")
    sleep 1
    system("pkill -9 -f 'claude --print' 2>/dev/null")

    # Clean up leftover run dirs
    Dir.glob("/tmp/ralph-loop-*").each { |d| FileUtils.rm_rf(d) }

    puts "Done."
  end

  # Sleep that can be interrupted by signal handlers
  def interruptible_sleep(seconds)
    seconds.times do
      break if @should_exit
      sleep 1
    end
  end

  # Color helpers
  def colorize(color, text)
    "#{COLORS[color]}#{text}#{COLORS[:reset]}"
  end

  def error(msg)
    puts colorize(:red, "Error: #{msg}")
  end

  def warn_msg(msg)
    puts colorize(:yellow, msg)
  end

  def success(msg)
    puts colorize(:green, msg)
  end
end

# Run if executed directly
RalphLoop.new.run if __FILE__ == $PROGRAM_NAME
