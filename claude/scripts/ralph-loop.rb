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
  STATUSES = %w[pending running completed failed].freeze

  def initialize
    @prd_file = nil
    @prompt_file_override = nil
    @max_parallel = nil
    @check_delay = nil
    @run_dir = "/tmp/ralph-loop-#{Process.pid}"
    @running_pids = {} # task_id => pid
    @process_groups = {} # task_id => pgid (for reliable group kills)
    @last_activity = {} # task_id => Time (last log file mtime change)
    @task_start_times = {} # task_id => Time (when task was spawned)
    @should_exit = false
    @cleaning_up = false
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
    @prd = read_prd_locked

    @max_parallel ||= @prd["maxParallel"] || 1
    @check_delay ||= @prd["checkInterval"] || 15
    @prompt_file = @prompt_file_override || @prd["promptFile"] || "ralph-prompt.md"
    @project_name = @prd["project"] || "Unknown"
    @stale_timeout = @prd["staleTimeout"] || 600  # seconds, default 10 minutes

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
        @should_exit = true
      end
    end

    # Safety net: if main_loop exits without explicit cleanup
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

  def render_progress_bar(completed, total, width: 30)
    return "[" + "░" * width + "] 0% (0/0 completed)" if total == 0

    percent = (completed.to_f / total * 100).round
    filled = (completed.to_f / total * width).round
    empty = width - filled

    bar = "█" * filled + "░" * empty
    "[#{bar}] #{percent}% (#{completed}/#{total} completed)"
  end

  def render_status_line(running, failed, pending)
    parts = []
    parts << colorize(:cyan, "#{running} running") if running > 0
    parts << colorize(:red, "#{failed} failed") if failed > 0
    parts << colorize(:gray, "#{pending} pending") if pending > 0
    parts.join(" | ")
  end

  def render_task_list(max_display: 3)
    # Collect tasks by status
    running = tasks_by_status("running")
    failed = tasks_by_status("failed")
    pending = tasks_by_status("pending")

    # Build display list: running first, then failed, then pending (up to max)
    display_tasks = []
    display_tasks.concat(running)
    display_tasks.concat(failed)
    display_tasks.concat(pending)
    display_tasks = display_tasks.first(max_display)

    puts "Tasks:"
    display_tasks.each do |task|
      id = task["id"]
      title = task["title"] || "Untitled"
      status = task["status"] || "pending"

      # Truncate title to fit
      max_title = 40
      title = title[0, max_title - 3] + "..." if title.length > max_title

      activity_str = ""
      case status
      when "completed"
        status_str = colorize(:green, "completed")
        pid_str = ""
      when "running"
        pid = @running_pids[id]
        activity = parse_task_activity(id)
        status_str = colorize(:cyan, "running")
        activity_str = colorize(:gray, " [#{activity}]")
        pid_str = pid ? "  (PID #{pid})" : ""
      when "failed"
        status_str = colorize(:red, "failed ")
        pid_str = ""
      else # pending
        status_str = colorize(:gray, "pending")
        pid_str = ""
      end

      log_path = File.join(@run_dir, "#{id}.log")
      id_display = hyperlink(log_path, id)
      puts "  #{id_display}  #{status_str}#{activity_str}  #{title}#{pid_str}"
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

      # Update activity timestamps from log file mtimes
      update_activity_timestamps

      # Get current counts
      passed_count = count_by_status("completed")
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
      puts

      render_task_list

      # Check if all done (completed or failed, none pending/running)
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

    # Explicit cleanup when loop exits normally via @should_exit
    cleanup
  end

  def reload_prd
    @prd = read_prd_locked

    # Reconcile: if a task is completed/failed on disk, stop tracking its PID
    @running_pids.each_key do |task_id|
      task = @prd["tasks"]&.find { |t| t["id"] == task_id }
      if task.nil? || task["status"] == "completed" || task["status"] == "failed"
        @running_pids.delete(task_id)
        @process_groups.delete(task_id)
        @last_activity.delete(task_id)
        @task_start_times.delete(task_id)
      end
    end

    true
  rescue JSON::ParserError => e
    error "Failed to parse prd.json: #{e.message} (skipping iteration)"
    false
  end

  def sync_running_status
    changed = false
    @prd["tasks"].each do |task|
      if @running_pids.key?(task["id"]) && process_alive?(@running_pids[task["id"]])
        unless task["status"] == "completed" || task["status"] == "failed" || task["status"] == "running"
          task["status"] = "running"
          changed = true
        end
      end
    end
    save_prd if changed
  end

  def save_prd
    write_prd_locked(@prd)
  end

  def read_prd_locked
    File.open(@prd_file, File::RDONLY | File::CREAT) do |f|
      f.flock(File::LOCK_SH)  # shared lock for reads
      JSON.parse(f.read)
    end
  end

  def write_prd_locked(data)
    File.open(@prd_file, File::RDWR | File::CREAT) do |f|
      f.flock(File::LOCK_EX)  # exclusive lock for writes
      f.truncate(0)
      f.rewind
      f.write(JSON.pretty_generate(data))
    end
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

    # Build prompt with task details injected inline
    prompt_content = File.read(@prompt_file)
    task = @prd["tasks"].find { |t| t["id"] == task_id }
    task_json = JSON.pretty_generate(task)
    task_prompt = "# YOUR ASSIGNED TASK\n\n```json\n#{task_json}\n```\n\n#{prompt_content}"
    File.write(prompt_file_path, task_prompt)

    # Spawn claude via bash, reading prompt from file via stdin
    # pgroup: true gives the child its own process group (PGID = child PID)
    cmd = "claude --print --verbose --output-format stream-json --dangerously-skip-permissions --model sonnet < #{prompt_file_path.shellescape}"
    pid = Process.spawn(
      "/bin/bash", "-c", cmd,
      out: log_file,
      err: log_file,
      pgroup: true
    )

    @running_pids[task_id] = pid
    @process_groups[task_id] = pid  # With pgroup: true, PGID == child PID
    @task_start_times[task_id] = Time.now
    @last_activity[task_id] = Time.now

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

        # Process still alive — check for staleness
        task = @prd["tasks"]&.find { |t| t["id"] == task_id }
        task_timeout = task&.dig("staleTimeout") || @stale_timeout
        last = @last_activity[task_id] || @task_start_times[task_id] || Time.now
        if Time.now - last > task_timeout
          kill_stale_process(task_id, pid, task_timeout)
          finished_tasks << [task_id, pid, 1]
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

  def kill_stale_process(task_id, _pid, timeout)
    pgid = @process_groups[task_id]
    return unless pgid

    # Append message to log before killing
    log_file = File.join(@run_dir, "#{task_id}.log")
    File.open(log_file, "a") do |f|
      f.puts "[ralph-loop] Killed: no activity for #{timeout} seconds"
    end

    # TERM the process group, wait up to 3s, then KILL
    begin
      Process.kill("-TERM", pgid)
    rescue Errno::ESRCH, Errno::EPERM
      return
    end

    poll_for_exit([pgid], timeout: 3)

    begin
      Process.kill("-KILL", pgid)
    rescue Errno::ESRCH, Errno::EPERM
      # Already dead
    end
  end

  def poll_for_exit(pgids, timeout: 3)
    deadline = Time.now + timeout
    remaining = pgids.dup

    while Time.now < deadline && remaining.any?
      remaining.reject! do |pgid|
        begin
          Process.kill(0, pgid)
          false  # still alive
        rescue Errno::ESRCH
          true   # dead
        rescue Errno::EPERM
          false  # can't check, assume alive
        end
      end
      sleep 0.1 if remaining.any?
    end

    remaining
  end

  def update_activity_timestamps
    @running_pids.each_key do |task_id|
      log_file = File.join(@run_dir, "#{task_id}.log")
      if File.exist?(log_file)
        mtime = File.mtime(log_file)
        @last_activity[task_id] = mtime if mtime > (@last_activity[task_id] || Time.at(0))
      end
    end
  end

  def parse_task_activity(task_id)
    log_file = File.join(@run_dir, "#{task_id}.log")
    return "Starting" unless File.exist?(log_file)

    # Read last 8KB (enough for the most recent JSONL events)
    last_line = nil
    File.open(log_file) do |f|
      size = f.size
      return "Starting" if size == 0

      read_size = [size, 8192].min
      f.seek(-read_size, IO::SEEK_END)
      chunk = f.read
      lines = chunk.split("\n").reject(&:empty?)
      last_line = lines.last
    end

    return "Working" unless last_line

    begin
      event = JSON.parse(last_line)
      case event["type"]
      when "assistant"
        # assistant turns contain content blocks — find the last tool_use or text
        content = event.dig("message", "content") || []
        last_tool = content.reverse.find { |b| b["type"] == "tool_use" }
        if last_tool
          "Tool: #{last_tool["name"]}"
        elsif content.any? { |b| b["type"] == "text" }
          "Writing"
        else
          "Working"
        end
      when "user"
        "Tool running"
      when "result"
        "Finishing"
      when "system"
        "Starting"
      else
        "Working"
      end
    rescue JSON::ParserError
      "Working"
    end
  end

  def process_finished_task(task_id, _pid, exit_code)
    task = @prd["tasks"].find { |t| t["id"] == task_id }

    if task
      if exit_code == 0
        task["status"] = "completed"
      else
        task["status"] = "failed"
      end
      save_prd
    end

    # Clean up tracking
    @running_pids.delete(task_id)
    @process_groups.delete(task_id)
    @last_activity.delete(task_id)
    @task_start_times.delete(task_id)
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def cleanup
    # Guard against re-entrancy (exit inside at_exit triggers at_exit again)
    return if @cleaning_up
    @cleaning_up = true

    # Collect all process groups we need to kill
    pgids_to_kill = @process_groups.values.uniq

    if pgids_to_kill.any?
      $stderr.puts "\nCleaning up #{pgids_to_kill.length} Claude process group(s)..."

      # TERM the entire process group (negative PID = kill group)
      pgids_to_kill.each do |pgid|
        begin
          Process.kill("-TERM", pgid)
        rescue Errno::ESRCH, Errno::EPERM
          # Already dead or no permission
        end
      end

      # Poll for exit instead of fixed sleep
      survivors = poll_for_exit(pgids_to_kill)

      # Force kill any survivors
      survivors.each do |pgid|
        begin
          Process.kill("-KILL", pgid)
        rescue Errno::ESRCH, Errno::EPERM
          # Already dead or no permission
        end
      end

      # Reap zombies
      @running_pids.each_value do |pid|
        begin
          Process.waitpid(pid, Process::WNOHANG)
        rescue Errno::ECHILD
          # Already reaped
        end
      end

      # Verify no tracked PIDs are still alive
      @running_pids.each do |task_id, pid|
        if process_alive?(pid)
          $stderr.puts "Warning: PID #{pid} (#{task_id}) still alive after cleanup"
        end
      end
    end

    # Reset any "running" tasks back to "pending" so they retry on next run
    reset_running_tasks_to_pending

    # Clean up master PID file
    FileUtils.rm_f(MASTER_PID_FILE)

  end

  def reset_running_tasks_to_pending
    return unless @prd_file && File.exist?(@prd_file)

    prd = read_prd_locked
    return unless prd["tasks"].is_a?(Array)

    changed = false
    prd["tasks"].each do |task|
      if task["status"] == "running"
        task["status"] = "pending"
        changed = true
      end
    end

    write_prd_locked(prd) if changed
  rescue StandardError
    # Best-effort — don't let JSON errors prevent the rest of cleanup
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
