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

    @max_parallel ||= @prd["maxParallel"] || 5
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
    puts "#{colorize(:yellow, 'Project:')}       #{@project_name}"
    puts "#{colorize(:yellow, 'Working Dir:')}   #{Dir.pwd}"
    puts "#{colorize(:yellow, 'PRD File:')}      #{@prd_file}"
    puts "#{colorize(:yellow, 'Prompt File:')}   #{@prompt_file}"
    puts "#{colorize(:yellow, 'Max Parallel:')}  #{@max_parallel}"
    puts "#{colorize(:yellow, 'Check Delay:')}   #{@check_delay}s"
    puts "#{colorize(:yellow, 'Run Dir:')}       #{@run_dir}"
    puts
    puts "#{colorize(:cyan, 'Master PID:')}    #{Process.pid} (use 'ralph-loop --kill' to stop)"
    puts
  end

  def main_loop
    iteration = 0

    until @should_exit
      iteration += 1

      puts
      puts colorize(:blue, "━" * 64)
      puts colorize(:yellow, "Iteration #{iteration}")
      puts colorize(:blue, "━" * 64)

      # Reload PRD to get latest status
      unless reload_prd
        puts colorize(:cyan, "Next check in #{@check_delay}s... (Ctrl+C to stop)")
        interruptible_sleep(@check_delay)
        next
      end

      # Validate tasks array exists
      unless @prd["tasks"].is_a?(Array)
        error "prd.json missing 'tasks' array (skipping iteration)"
        puts colorize(:cyan, "Next check in #{@check_delay}s... (Ctrl+C to stop)")
        interruptible_sleep(@check_delay)
        next
      end

      # Check on running tasks
      check_running_tasks

      # Get current counts
      done_count = count_by_passes(true)
      total = @prd["tasks"].length  # Safe: validated as Array above

      # Check if all done
      if done_count >= total && total > 0
        show_status
        puts
        success "🎉 All tasks completed!"
        success "   \"I'm a helper!\" - Ralph Wiggum"

        # Update completion timestamp
        @prd["completedAt"] = Time.now.utc.iso8601
        save_prd

        exit 0
      end

      # Start new tasks if we have capacity
      running_count = @running_pids.count { |_, pid| process_alive?(pid) }
      available = @max_parallel - running_count

      if available > 0
        pending_tasks = tasks_by_passes(false).reject { |t| @running_pids.key?(t["id"]) }

        pending_tasks.each do |task|
          break if available <= 0

          start_task(task["id"])
          available -= 1
          sleep 1 # Small delay between spawns
        end
      end

      show_status

      # Check if stuck
      running_count = @running_pids.count { |_, pid| process_alive?(pid) }
      pending = count_pending

      if running_count == 0 && pending == 0 && done_count < total
        warn_msg "No tasks running and none pending. Check ralph-tasks.json."
        exit 1
      end

      puts colorize(:cyan, "Next check in #{@check_delay}s... (Ctrl+C to stop)")
      interruptible_sleep(@check_delay)
    end
  end

  def reload_prd
    @prd = JSON.parse(File.read(@prd_file))
    true
  rescue JSON::ParserError => e
    error "Failed to parse prd.json: #{e.message} (skipping iteration)"
    false
  end

  def save_prd
    File.write(@prd_file, JSON.pretty_generate(@prd))
  end

  def tasks_by_passes(passes_value)
    return [] unless @prd["tasks"].is_a?(Array)

    @prd["tasks"].select { |t| t["passes"] == passes_value }
  end

  def count_by_passes(passes_value)
    tasks_by_passes(passes_value).length
  end

  def count_pending
    return 0 unless @prd["tasks"].is_a?(Array)

    # Pending = passes:false AND not currently running
    @prd["tasks"].count { |t| !t["passes"] && !@running_pids.key?(t["id"]) }
  end

  def start_task(task_id)
    log_file = File.join(@run_dir, "#{task_id}.log")
    prompt_file_path = File.join(@run_dir, "#{task_id}-prompt.txt")

    # Build prompt with task ID and write to temp file
    prompt_content = File.read(@prompt_file)
    task_prompt = "# YOUR ASSIGNED TASK ID: #{task_id}\n\n#{prompt_content}"
    File.write(prompt_file_path, task_prompt)

    success "▶ Starting Claude for task #{task_id}"

    # Spawn claude via bash, reading prompt from file via stdin
    cmd = "claude --print --dangerously-skip-permissions < #{prompt_file_path.shellescape}"
    pid = Process.spawn(
      "/bin/bash", "-c", cmd,
      out: log_file,
      err: log_file,
      pgroup: true
    )

    @running_pids[task_id] = pid

    puts colorize(:cyan, "  PID: #{pid}")
    puts colorize(:cyan, "  Log: #{log_file}")
  end

  def check_running_tasks
    puts colorize(:cyan, "Checking #{@running_pids.length} running tasks...")

    # Collect finished tasks (can't modify hash while iterating)
    finished_tasks = []

    @running_pids.each do |task_id, pid|
      # Try to reap the process first (catches zombies)
      begin
        result = Process.waitpid2(pid, Process::WNOHANG)
        if result
          # Process has exited
          _, status = result
          exit_code = status&.exitstatus || 0
          puts colorize(:cyan, "  Task #{task_id} (PID #{pid}): FINISHED (exit #{exit_code})")
          finished_tasks << [task_id, pid, exit_code]
          next
        end
      rescue Errno::ECHILD
        # No child process - already reaped or not our child
        puts colorize(:cyan, "  Task #{task_id} (PID #{pid}): FINISHED (no child)")
        finished_tasks << [task_id, pid, 0]
        next
      end

      # Process still running
      puts colorize(:cyan, "  Task #{task_id} (PID #{pid}): still running")
    end

    # Process finished tasks
    finished_tasks.each do |task_id, pid, exit_code|
      process_finished_task(task_id, pid, exit_code)
    end
  end

  def process_finished_task(task_id, pid, exit_code)
    log_file = File.join(@run_dir, "#{task_id}.log")
    task_completed = exit_code == 0

    if task_completed
      success "✓ Task #{task_id} completed (exit 0)"
    else
      error "✗ Task #{task_id} failed (exit #{exit_code})"
    end

    # Mark task as passed if completed successfully
    if task_completed
      task = @prd["tasks"].find { |t| t["id"] == task_id }
      if task
        task["passes"] = true
        save_prd
        success "  Updated #{task_id} passes=true in #{@prd_file}"
      else
        error "  Could not find task #{task_id} in tasks array!"
        error "  Available IDs: #{@prd["tasks"].map { |t| t["id"] }.join(", ")}"
      end
    end

    # Show last output
    if File.exist?(log_file)
      lines = File.readlines(log_file)
      if lines.any?
        puts colorize(:cyan, "  Last output:")
        lines.last(5).each { |line| puts "    #{line}" }
      else
        warn_msg "  (No output in log)"
      end
    end

    # Clean up
    @running_pids.delete(task_id)
    FileUtils.rm_f(log_file)
  end

  def show_status
    reload_prd

    running = @running_pids.count { |_, pid| process_alive?(pid) }
    done_count = count_by_passes(true)
    pending = count_pending
    tasks = @prd["tasks"]
    total = tasks.is_a?(Array) ? tasks.length : 0

    puts
    puts colorize(:blue, "═" * 64)

    status_parts = [
      "Progress: #{done_count}/#{total} passed",
      "#{running} running",
      "#{pending} pending"
    ]

    puts colorize(:yellow, status_parts.join(" | "))
    puts colorize(:blue, "═" * 64)

    # Show running processes
    if running > 0
      puts colorize(:cyan, "Running:")
      @running_pids.each do |task_id, pid|
        next unless process_alive?(pid)

        log_file = File.join(@run_dir, "#{task_id}.log")
        if File.exist?(log_file)
          lines = File.readlines(log_file).length
          puts "  Task #{task_id}: PID #{pid} (#{lines} lines of output)"
        else
          puts "  Task #{task_id}: PID #{pid}"
        end
      end
    end
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def cleanup
    warn_msg "Cleaning up Claude processes..."

    # Kill all tracked process groups (negative PID kills entire group)
    @running_pids.each do |task_id, pid|
      next unless process_alive?(pid)

      warn_msg "  Stopping task #{task_id} (PGID: #{pid})"
      begin
        Process.kill("-TERM", pid)  # Kill entire process group
      rescue Errno::ESRCH, Errno::EPERM
        # Already dead or no permission
      end
    end

    sleep 1

    # Force kill remaining process groups
    @running_pids.each do |_, pid|
      begin
        Process.kill("-KILL", pid) if process_alive?(pid)
      rescue Errno::ESRCH, Errno::EPERM
        # Already dead or no permission
      end
    end

    # Clean up run directory
    FileUtils.rm_rf(@run_dir) if @run_dir && Dir.exist?(@run_dir)

    warn_msg "Check prd.json for progress"
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
