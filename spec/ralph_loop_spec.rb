# frozen_string_literal: true

RSpec.describe RalphLoop do
  subject(:ralph) { build_ralph }

  # ─── Pure rendering ───────────────────────────────────────────────

  describe "#render_progress_bar" do
    it "shows empty bar when total is 0" do
      result = ralph.send(:render_progress_bar, 0, 0)
      expect(result).to include("0%").and include("0/0 completed")
    end

    it "shows 50% when half completed" do
      result = ralph.send(:render_progress_bar, 3, 6)
      expect(result).to include("50%").and include("3/6 completed")
    end

    it "shows 100% when all completed" do
      result = ralph.send(:render_progress_bar, 4, 4)
      expect(result).to include("100%").and include("4/4 completed")
    end

    it "respects custom width" do
      result = ralph.send(:render_progress_bar, 5, 10, width: 10)
      # 50% of 10 = 5 filled blocks
      expect(result).to include("█" * 5 + "░" * 5)
    end
  end

  describe "#render_status_line" do
    it "shows running, failed, and pending counts" do
      result = ralph.send(:render_status_line, 2, 1, 3)
      expect(result).to include("2 running")
      expect(result).to include("1 failed")
      expect(result).to include("3 pending")
    end

    it "omits zero-count statuses" do
      result = ralph.send(:render_status_line, 0, 1, 0)
      expect(result).not_to include("running")
      expect(result).to include("1 failed")
      expect(result).not_to include("pending")
    end

    it "returns empty string when all counts are zero" do
      result = ralph.send(:render_status_line, 0, 0, 0)
      expect(result).to eq("")
    end
  end

  describe "#colorize" do
    it "wraps text in ANSI escape codes" do
      result = ralph.send(:colorize, :red, "hello")
      expect(result).to eq("\e[0;31mhello\e[0m")
    end

    it "handles different colors" do
      result = ralph.send(:colorize, :green, "ok")
      expect(result).to eq("\e[0;32mok\e[0m")
    end
  end

  describe "#hyperlink" do
    it "produces OSC 8 terminal hyperlink" do
      result = ralph.send(:hyperlink, "/tmp/foo.json", "my file")
      expect(result).to eq("\e]8;;file:///tmp/foo.json\e\\my file\e]8;;\e\\")
    end
  end

  # ─── State queries ────────────────────────────────────────────────

  describe "#tasks_by_status" do
    let(:tasks) do
      [
        { "id" => "1", "status" => "pending" },
        { "id" => "2", "status" => "running" },
        { "id" => "3", "status" => "pending" },
        { "id" => "4", "status" => "completed" }
      ]
    end

    subject(:ralph) { build_ralph(prd: { "tasks" => tasks }) }

    it "returns tasks matching the given status" do
      result = ralph.send(:tasks_by_status, "pending")
      expect(result.map { |t| t["id"] }).to eq(%w[1 3])
    end

    it "returns empty array for unmatched status" do
      result = ralph.send(:tasks_by_status, "failed")
      expect(result).to eq([])
    end

    it "returns empty array when tasks is not an array" do
      bad = build_ralph(prd: { "tasks" => nil })
      expect(bad.send(:tasks_by_status, "pending")).to eq([])
    end
  end

  describe "#count_by_status" do
    let(:tasks) do
      [
        { "id" => "1", "status" => "pending" },
        { "id" => "2", "status" => "pending" },
        { "id" => "3", "status" => "completed" }
      ]
    end

    subject(:ralph) { build_ralph(prd: { "tasks" => tasks }) }

    it "returns correct count" do
      expect(ralph.send(:count_by_status, "pending")).to eq(2)
      expect(ralph.send(:count_by_status, "completed")).to eq(1)
      expect(ralph.send(:count_by_status, "failed")).to eq(0)
    end
  end

  # ─── Config loading ───────────────────────────────────────────────

  describe "#load_config" do
    it "reads JSON and applies defaults" do
      dir, prd_path, _prompt_path = create_fixtures(
        tasks: [{ "id" => "1", "status" => "pending" }]
      )

      r = build_ralph(prd_file: prd_path)
      Dir.chdir(dir) { r.send(:load_config) }

      expect(r.instance_variable_get(:@max_parallel)).to eq(1)
      expect(r.instance_variable_get(:@check_delay)).to eq(15)
      expect(r.instance_variable_get(:@project_name)).to eq("test-project")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "uses values from JSON when present" do
      dir, prd_path, _prompt_path = create_fixtures(
        tasks: [],
        "maxParallel" => 3,
        "checkInterval" => 5
      )

      r = build_ralph(prd_file: prd_path)
      Dir.chdir(dir) { r.send(:load_config) }

      expect(r.instance_variable_get(:@max_parallel)).to eq(3)
      expect(r.instance_variable_get(:@check_delay)).to eq(5)
    ensure
      FileUtils.rm_rf(dir)
    end

    it "CLI overrides take precedence" do
      dir, prd_path, _prompt_path = create_fixtures(
        tasks: [],
        "maxParallel" => 3,
        "checkInterval" => 5
      )

      r = build_ralph(prd_file: prd_path, max_parallel: 10, check_delay: 2)
      Dir.chdir(dir) { r.send(:load_config) }

      expect(r.instance_variable_get(:@max_parallel)).to eq(10)
      expect(r.instance_variable_get(:@check_delay)).to eq(2)
    ensure
      FileUtils.rm_rf(dir)
    end

    it "uses prompt_file_override when set" do
      dir, prd_path, _prompt_path = create_fixtures(tasks: [])
      custom_prompt = File.join(dir, "custom.md")
      File.write(custom_prompt, "custom prompt")

      r = build_ralph(prd_file: prd_path, prompt_file_override: custom_prompt)
      Dir.chdir(dir) { r.send(:load_config) }

      expect(r.instance_variable_get(:@prompt_file)).to eq(custom_prompt)
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe "#reload_prd" do
    it "returns true and loads valid JSON" do
      dir, prd_path, _ = create_fixtures(tasks: [{ "id" => "x", "status" => "pending" }])
      r = build_ralph(prd_file: prd_path)

      expect(r.send(:reload_prd)).to be true
      expect(r.instance_variable_get(:@prd)["tasks"].length).to eq(1)
    ensure
      FileUtils.rm_rf(dir)
    end

    it "returns false on invalid JSON" do
      dir = Dir.mktmpdir("ralph-spec-")
      bad_path = File.join(dir, "bad.json")
      File.write(bad_path, "not json {{{")

      r = build_ralph(prd_file: bad_path)
      expect { r.send(:reload_prd) }.to output(/Failed to parse/).to_stdout
      # Second call also prints to stdout — capture it so it doesn't leak into test output
      result = capture_stdout { r.send(:reload_prd) }
      expect(result).to include("Failed to parse")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  # ─── State mutation ───────────────────────────────────────────────

  describe "#sync_running_status" do
    it "marks pending tasks as running when their PID is alive" do
      pid = Process.spawn("sleep 60")
      tasks = [{ "id" => "t1", "status" => "pending" }]
      r = build_ralph(
        prd: { "tasks" => tasks },
        running_pids: { "t1" => pid }
      )

      r.send(:sync_running_status)
      expect(tasks[0]["status"]).to eq("running")
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end

    it "does not overwrite completed status" do
      pid = Process.spawn("sleep 60")
      tasks = [{ "id" => "t1", "status" => "completed" }]
      r = build_ralph(
        prd: { "tasks" => tasks },
        running_pids: { "t1" => pid }
      )

      r.send(:sync_running_status)
      expect(tasks[0]["status"]).to eq("completed")
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end

    it "does not overwrite failed status" do
      pid = Process.spawn("sleep 60")
      tasks = [{ "id" => "t1", "status" => "failed" }]
      r = build_ralph(
        prd: { "tasks" => tasks },
        running_pids: { "t1" => pid }
      )

      r.send(:sync_running_status)
      expect(tasks[0]["status"]).to eq("failed")
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  describe "#process_finished_task" do
    it "marks task as completed on exit code 0" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")
      log_file = File.join(run_dir, "t1.log")
      File.write(log_file, "some output")

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, running_pids: { "t1" => 999 })
      Dir.chdir(dir) { r.send(:load_config) }
      r.send(:process_finished_task, "t1", 999, 0)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("completed")
      expect(r.instance_variable_get(:@running_pids)).not_to have_key("t1")
      expect(File.exist?(log_file)).to be true
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end

    it "marks task as failed on non-zero exit code" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, running_pids: { "t1" => 999 })
      Dir.chdir(dir) { r.send(:load_config) }
      r.send(:process_finished_task, "t1", 999, 1)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("failed")
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  # ─── Process management ──────────────────────────────────────────

  describe "#process_alive?" do
    it "returns true for a living process" do
      pid = Process.spawn("sleep 60")
      expect(ralph.send(:process_alive?, pid)).to be true
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end

    it "returns false for a dead PID" do
      # Use a PID that almost certainly doesn't exist
      expect(ralph.send(:process_alive?, 2_000_000_000)).to be false
    end
  end

  describe "#check_running_tasks" do
    it "reaps finished child processes and calls process_finished_task" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      pid = Process.spawn("true") # exits immediately with 0
      sleep 0.2 # give it a moment to finish

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, running_pids: { "t1" => pid })
      Dir.chdir(dir) { r.send(:load_config) }
      r.send(:check_running_tasks)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("completed")
      expect(r.instance_variable_get(:@running_pids)).to be_empty
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end

    it "marks failed for non-zero exit" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      pid = Process.spawn("false") # exits with 1
      sleep 0.2

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, running_pids: { "t1" => pid })
      Dir.chdir(dir) { r.send(:load_config) }
      r.send(:check_running_tasks)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("failed")
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  describe "#start_task" do
    it "spawns a process and updates task status to running" do
      dir, prd_path, prompt_path = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "pending" }],
        prompt_content: "test prompt content"
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, prompt_file_override: prompt_path)
      Dir.chdir(dir) { r.send(:load_config) }

      # Stub Process.spawn to avoid launching claude
      allow(Process).to receive(:spawn).and_return(99999)

      r.send(:start_task, "t1")

      # Verify prompt file was written
      written_prompt = File.join(run_dir, "t1-prompt.txt")
      expect(File.exist?(written_prompt)).to be true
      expect(File.read(written_prompt)).to include("YOUR ASSIGNED TASK ID: t1")
      expect(File.read(written_prompt)).to include("test prompt content")

      # Verify PID tracked
      expect(r.instance_variable_get(:@running_pids)["t1"]).to eq(99999)

      # Verify status saved
      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("running")
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  describe "#cleanup" do
    it "kills tracked processes and removes run dir" do
      run_dir = Dir.mktmpdir("ralph-run-")
      # Spawn with pgroup: true to match how start_task spawns (cleanup uses -TERM on pgid)
      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(run_dir: run_dir, running_pids: { "t1" => pid }, process_groups: { "t1" => pid })

      expect { r.send(:cleanup) }.to output(/Cleaning up/).to_stderr

      # Reap the child so process_alive? returns false
      Process.wait(pid) rescue nil
      expect(r.send(:process_alive?, pid)).to be false
      expect(Dir.exist?(run_dir)).to be true
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(run_dir) if Dir.exist?(run_dir)
    end

    it "does nothing when no processes are running" do
      run_dir = Dir.mktmpdir("ralph-run-")
      r = build_ralph(run_dir: run_dir, running_pids: {}, process_groups: {})

      expect { r.send(:cleanup) }.not_to output(/Cleaning up/).to_stderr
      expect(Dir.exist?(run_dir)).to be true
    ensure
      FileUtils.rm_rf(run_dir) if Dir.exist?(run_dir)
    end

    it "resets running tasks to pending in the JSON file" do
      dir, prd_path, _ = create_fixtures(
        tasks: [
          { "id" => "t1", "status" => "running" },
          { "id" => "t2", "status" => "completed" },
          { "id" => "t3", "status" => "running" }
        ]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, running_pids: {}, process_groups: {})

      r.send(:cleanup)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("pending")
      expect(saved["tasks"][1]["status"]).to eq("completed")
      expect(saved["tasks"][2]["status"]).to eq("pending")
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir) if Dir.exist?(run_dir)
    end
  end

  # ─── Option parsing ──────────────────────────────────────────────

  describe "#parse_options" do
    around do |example|
      # Save and restore ARGV
      original_argv = ARGV.dup
      example.run
      ARGV.replace(original_argv)
    end

    it "finds ralph-tasks.json in current directory" do
      dir = Dir.mktmpdir("ralph-spec-")
      File.write(File.join(dir, "ralph-tasks.json"), "{}")

      r = build_ralph
      ARGV.replace([])
      Dir.chdir(dir) { r.send(:parse_options) }

      expect(r.instance_variable_get(:@prd_file)).to eq("ralph-tasks.json")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "falls back to .claude/tasks/prd.json" do
      dir = Dir.mktmpdir("ralph-spec-")
      FileUtils.mkdir_p(File.join(dir, ".claude", "tasks"))
      File.write(File.join(dir, ".claude", "tasks", "prd.json"), "{}")

      r = build_ralph
      ARGV.replace([])
      Dir.chdir(dir) { r.send(:parse_options) }

      expect(r.instance_variable_get(:@prd_file)).to eq(".claude/tasks/prd.json")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "sets explicit flags" do
      r = build_ralph
      ARGV.replace(["-p", "/tmp/my.json", "-m", "/tmp/prompt.md", "-j", "8", "-d", "30"])
      r.send(:parse_options)

      expect(r.instance_variable_get(:@prd_file)).to eq("/tmp/my.json")
      expect(r.instance_variable_get(:@prompt_file_override)).to eq("/tmp/prompt.md")
      expect(r.instance_variable_get(:@max_parallel)).to eq(8)
      expect(r.instance_variable_get(:@check_delay)).to eq(30)
    end

    it "exits when no task file found" do
      dir = Dir.mktmpdir("ralph-spec-")

      r = build_ralph
      ARGV.replace([])
      expect {
        Dir.chdir(dir) { r.send(:parse_options) }
      }.to raise_error(SystemExit).and output(/No task file found/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  # ─── Rendering: task list ─────────────────────────────────────────

  describe "#render_task_list" do
    it "displays tasks in priority order: running, failed, pending" do
      tasks = [
        { "id" => "t1", "status" => "pending", "title" => "Pending task" },
        { "id" => "t2", "status" => "failed", "title" => "Failed task" },
        { "id" => "t3", "status" => "running", "title" => "Running task" },
        { "id" => "t4", "status" => "completed", "title" => "Completed task" }
      ]
      r = build_ralph(prd: { "tasks" => tasks })

      output = capture_stdout { r.send(:render_task_list) }

      # Running should appear before failed, failed before pending
      running_pos = output.index("Running task")
      failed_pos = output.index("Failed task")
      pending_pos = output.index("Pending task")

      expect(running_pos).to be < failed_pos
      expect(failed_pos).to be < pending_pos
      # Completed tasks should not appear
      expect(output).not_to include("Completed task")
    end

    it "truncates long titles" do
      tasks = [{ "id" => "t1", "status" => "pending", "title" => "A" * 50 }]
      r = build_ralph(prd: { "tasks" => tasks })

      output = capture_stdout { r.send(:render_task_list) }
      expect(output).to include("...")
    end

    it "renders task IDs as OSC 8 hyperlinks to log files" do
      tasks = [{ "id" => "T-001", "status" => "running", "title" => "Test task" }]
      run_dir = "/tmp/ralph-loop-test"
      r = build_ralph(prd: { "tasks" => tasks }, run_dir: run_dir, running_pids: { "T-001" => 123 })

      output = capture_stdout { r.send(:render_task_list) }
      expect(output).to include("\e]8;;file://#{run_dir}/T-001.log\e\\T-001\e]8;;\e\\")
    end

    it "respects max_display limit" do
      tasks = (1..10).map { |i| { "id" => "t#{i}", "status" => "pending", "title" => "Task #{i}" } }
      r = build_ralph(prd: { "tasks" => tasks })

      output = capture_stdout { r.send(:render_task_list, max_display: 2) }
      expect(output.scan(/pending/).count).to eq(2)
    end
  end
end

# Helper to capture stdout
def capture_stdout
  original = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original
end
