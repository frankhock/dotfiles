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
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "pending" }]
      )
      pid = Process.spawn("sleep 60")
      tasks = [{ "id" => "t1", "status" => "pending" }]
      r = build_ralph(
        prd_file: prd_path,
        prd: { "tasks" => tasks },
        running_pids: { "t1" => pid }
      )

      r.send(:sync_running_status)
      expect(tasks[0]["status"]).to eq("running")
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
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
      expect(File.read(written_prompt)).to include("YOUR ASSIGNED TASK")
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

  # ─── Activity tracking ──────────────────────────────────────────

  describe "#start_task activity tracking" do
    it "populates @last_activity and @task_start_times" do
      dir, prd_path, prompt_path = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "pending" }],
        prompt_content: "test prompt"
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      r = build_ralph(prd_file: prd_path, run_dir: run_dir, prompt_file_override: prompt_path)
      Dir.chdir(dir) { r.send(:load_config) }
      allow(Process).to receive(:spawn).and_return(99999)

      r.send(:start_task, "t1")

      expect(r.instance_variable_get(:@last_activity)["t1"]).to be_a(Time)
      expect(r.instance_variable_get(:@task_start_times)["t1"]).to be_a(Time)
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  describe "#update_activity_timestamps" do
    it "updates time when log file mtime changes" do
      run_dir = Dir.mktmpdir("ralph-run-")
      log_file = File.join(run_dir, "t1.log")
      File.write(log_file, "initial")

      old_time = Time.now - 60
      r = build_ralph(
        run_dir: run_dir,
        running_pids: { "t1" => 99999 },
        last_activity: { "t1" => old_time }
      )

      r.send(:update_activity_timestamps)

      new_time = r.instance_variable_get(:@last_activity)["t1"]
      expect(new_time).to be > old_time
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "does not regress time when log file is older" do
      run_dir = Dir.mktmpdir("ralph-run-")
      log_file = File.join(run_dir, "t1.log")
      File.write(log_file, "initial")

      future_time = Time.now + 60
      r = build_ralph(
        run_dir: run_dir,
        running_pids: { "t1" => 99999 },
        last_activity: { "t1" => future_time }
      )

      r.send(:update_activity_timestamps)

      expect(r.instance_variable_get(:@last_activity)["t1"]).to eq(future_time)
    ensure
      FileUtils.rm_rf(run_dir)
    end
  end

  describe "#process_finished_task activity cleanup" do
    it "cleans up @last_activity and @task_start_times" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      r = build_ralph(
        prd_file: prd_path,
        run_dir: run_dir,
        running_pids: { "t1" => 999 },
        last_activity: { "t1" => Time.now },
        task_start_times: { "t1" => Time.now }
      )
      Dir.chdir(dir) { r.send(:load_config) }
      r.send(:process_finished_task, "t1", 999, 0)

      expect(r.instance_variable_get(:@last_activity)).not_to have_key("t1")
      expect(r.instance_variable_get(:@task_start_times)).not_to have_key("t1")
    ensure
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  # ─── Stale detection ────────────────────────────────────────────

  describe "#check_running_tasks stale detection" do
    it "kills process when @last_activity is older than @stale_timeout" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")
      # Create log file so kill_stale_process can append to it
      File.write(File.join(run_dir, "t1.log"), "")

      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(
        prd_file: prd_path,
        run_dir: run_dir,
        running_pids: { "t1" => pid },
        process_groups: { "t1" => pid },
        last_activity: { "t1" => Time.now - 700 },
        task_start_times: { "t1" => Time.now - 700 },
        stale_timeout: 600
      )
      Dir.chdir(dir) { r.send(:load_config) }

      r.send(:check_running_tasks)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("failed")
      expect(r.instance_variable_get(:@running_pids)).to be_empty
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end

    it "does NOT kill process when activity is recent" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")

      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(
        prd_file: prd_path,
        run_dir: run_dir,
        running_pids: { "t1" => pid },
        process_groups: { "t1" => pid },
        last_activity: { "t1" => Time.now },
        task_start_times: { "t1" => Time.now },
        stale_timeout: 600
      )
      Dir.chdir(dir) { r.send(:load_config) }

      r.send(:check_running_tasks)

      # Task should still be running (not reaped since sleep 60 is alive)
      expect(r.instance_variable_get(:@running_pids)).to have_key("t1")
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end

    it "uses per-task staleTimeout override" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running", "staleTimeout" => 10 }]
      )
      run_dir = Dir.mktmpdir("ralph-run-")
      File.write(File.join(run_dir, "t1.log"), "")

      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(
        prd_file: prd_path,
        run_dir: run_dir,
        running_pids: { "t1" => pid },
        process_groups: { "t1" => pid },
        last_activity: { "t1" => Time.now - 15 },
        task_start_times: { "t1" => Time.now - 15 },
        stale_timeout: 600  # global is 600, but task overrides to 10
      )
      Dir.chdir(dir) { r.send(:load_config) }

      r.send(:check_running_tasks)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("failed")
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(run_dir)
    end
  end

  # ─── Cleanup improvements ─────────────────────────────────────────

  describe "#cleanup improvements" do
    it "does not call pkill" do
      run_dir = Dir.mktmpdir("ralph-run-")
      r = build_ralph(run_dir: run_dir, running_pids: {}, process_groups: {})

      expect(r).not_to receive(:system)
      r.send(:cleanup)
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "logs warning when tracked PID is still alive after cleanup" do
      run_dir = Dir.mktmpdir("ralph-run-")
      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(run_dir: run_dir, running_pids: { "t1" => pid }, process_groups: { "t1" => pid })

      # Allow all Process.kill calls but make process_alive? always return true
      allow(Process).to receive(:kill).and_call_original
      allow(r).to receive(:process_alive?).with(pid).and_return(true)
      allow(Process).to receive(:waitpid).with(pid, anything)

      output = capture_stderr { r.send(:cleanup) }
      expect(output).to include("Warning: PID #{pid}")
    ensure
      begin
        Process.kill("KILL", pid)
        Process.wait(pid)
      rescue StandardError
        nil
      end
      FileUtils.rm_rf(run_dir)
    end
  end

  describe "#poll_for_exit" do
    it "returns empty when processes exit quickly" do
      pid = Process.spawn("true", pgroup: true)
      Process.wait(pid)  # reap it so kill(0) raises ESRCH

      result = ralph.send(:poll_for_exit, [pid], timeout: 3)
      expect(result).to be_empty
    end

    it "returns remaining PIDs after timeout" do
      pid = Process.spawn("sleep 60", pgroup: true)

      result = ralph.send(:poll_for_exit, [pid], timeout: 0.3)
      expect(result).to eq([pid])
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  # ─── JSON file locking ──────────────────────────────────────────

  describe "#read_prd_locked" do
    it "acquires shared lock and parses JSON" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "pending" }]
      )
      r = build_ralph(prd_file: prd_path)

      result = r.send(:read_prd_locked)
      expect(result["tasks"].length).to eq(1)
      expect(result["tasks"][0]["id"]).to eq("t1")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe "#write_prd_locked" do
    it "acquires exclusive lock and writes JSON" do
      dir, prd_path, _ = create_fixtures(tasks: [])
      r = build_ralph(prd_file: prd_path)

      new_data = { "project" => "test", "tasks" => [{ "id" => "t1", "status" => "completed" }] }
      r.send(:write_prd_locked, new_data)

      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("completed")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  # ─── State consistency ─────────────────────────────────────────

  describe "#sync_running_status persistence" do
    it "calls save_prd when it changes status from pending to running" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "pending" }]
      )
      pid = Process.spawn("sleep 60")

      r = build_ralph(
        prd_file: prd_path,
        prd: { "tasks" => [{ "id" => "t1", "status" => "pending" }] },
        running_pids: { "t1" => pid }
      )

      r.send(:sync_running_status)

      # Verify persisted to disk
      saved = JSON.parse(File.read(prd_path))
      expect(saved["tasks"][0]["status"]).to eq("running")
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
    end

    it "does NOT call save_prd when status is already running" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )
      pid = Process.spawn("sleep 60")

      r = build_ralph(
        prd_file: prd_path,
        prd: { "tasks" => [{ "id" => "t1", "status" => "running" }] },
        running_pids: { "t1" => pid }
      )

      expect(r).not_to receive(:save_prd)
      r.send(:sync_running_status)
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(dir)
    end
  end

  describe "#reload_prd reconciliation" do
    it "removes task from @running_pids when on-disk status is completed" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "completed" }]
      )

      r = build_ralph(
        prd_file: prd_path,
        running_pids: { "t1" => 99999 },
        process_groups: { "t1" => 99999 },
        last_activity: { "t1" => Time.now },
        task_start_times: { "t1" => Time.now }
      )

      r.send(:reload_prd)

      expect(r.instance_variable_get(:@running_pids)).not_to have_key("t1")
      expect(r.instance_variable_get(:@process_groups)).not_to have_key("t1")
      expect(r.instance_variable_get(:@last_activity)).not_to have_key("t1")
      expect(r.instance_variable_get(:@task_start_times)).not_to have_key("t1")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "removes task from @running_pids when task is deleted from disk" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t2", "status" => "pending" }]
      )

      r = build_ralph(
        prd_file: prd_path,
        running_pids: { "t1" => 99999 },
        process_groups: { "t1" => 99999 },
        last_activity: { "t1" => Time.now },
        task_start_times: { "t1" => Time.now }
      )

      r.send(:reload_prd)

      expect(r.instance_variable_get(:@running_pids)).not_to have_key("t1")
      expect(r.instance_variable_get(:@process_groups)).not_to have_key("t1")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "keeps task in @running_pids when on-disk status is running" do
      dir, prd_path, _ = create_fixtures(
        tasks: [{ "id" => "t1", "status" => "running" }]
      )

      r = build_ralph(
        prd_file: prd_path,
        running_pids: { "t1" => 99999 },
        process_groups: { "t1" => 99999 }
      )

      r.send(:reload_prd)

      expect(r.instance_variable_get(:@running_pids)).to have_key("t1")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  # ─── Signal handling ────────────────────────────────────────────

  describe "#setup_signal_handlers" do
    it "signal handler only sets @should_exit (does not call exit)" do
      r = build_ralph
      r.send(:setup_signal_handlers)

      # Simulate what the signal handler does by sending ourselves SIGTERM
      # If exit were called, this test process would die. Instead, only the flag is set.
      r.instance_variable_set(:@should_exit, false)
      Process.kill("TERM", Process.pid)
      sleep 0.1  # give signal time to be delivered

      expect(r.instance_variable_get(:@should_exit)).to be true
    end
  end

  describe "#cleanup guard" do
    it "prevents double execution when called twice" do
      run_dir = Dir.mktmpdir("ralph-run-")
      pid = Process.spawn("sleep 60", pgroup: true)

      r = build_ralph(run_dir: run_dir, running_pids: { "t1" => pid }, process_groups: { "t1" => pid })

      # First call should output cleanup message
      output1 = capture_stderr { r.send(:cleanup) }
      expect(output1).to include("Cleaning up")

      # Second call should be a no-op (guard prevents re-entry)
      output2 = capture_stderr { r.send(:cleanup) }
      expect(output2).to eq("")
    ensure
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      FileUtils.rm_rf(run_dir)
    end
  end

  # ─── Activity parsing ─────────────────────────────────────────────

  describe "#parse_task_activity" do
    it "returns 'Starting' when log file doesn't exist" do
      run_dir = Dir.mktmpdir("ralph-run-")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Starting")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Starting' when log file is empty" do
      run_dir = Dir.mktmpdir("ralph-run-")
      File.write(File.join(run_dir, "t1.log"), "")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Starting")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Tool: Edit' for assistant turn with tool_use content" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = {
        "type" => "assistant",
        "message" => {
          "content" => [
            { "type" => "text", "text" => "Let me edit that file" },
            { "type" => "tool_use", "name" => "Edit", "id" => "toolu_123" }
          ]
        }
      }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Tool: Edit")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Writing' for assistant turn with only text content" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = {
        "type" => "assistant",
        "message" => {
          "content" => [{ "type" => "text", "text" => "Here is the result..." }]
        }
      }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Writing")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Tool running' for user turn (tool result)" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = {
        "type" => "user",
        "message" => {
          "content" => [{ "type" => "tool_result", "tool_use_id" => "toolu_123" }]
        }
      }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Tool running")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Starting' for system init event" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = { "type" => "system", "subtype" => "init", "session_id" => "abc" }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Starting")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Finishing' for result event" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = { "type" => "result", "subtype" => "success", "duration_ms" => 5000 }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Finishing")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "returns 'Working' for unparseable last line" do
      run_dir = Dir.mktmpdir("ralph-run-")
      File.write(File.join(run_dir, "t1.log"), "not valid json\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Working")
    ensure
      FileUtils.rm_rf(run_dir)
    end

    it "reads only the last line from multi-line logs" do
      run_dir = Dir.mktmpdir("ralph-run-")
      early = { "type" => "assistant", "message" => { "content" => [{ "type" => "tool_use", "name" => "Read" }] } }
      late = { "type" => "assistant", "message" => { "content" => [{ "type" => "tool_use", "name" => "Bash" }] } }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(early) + "\n" + JSON.generate(late) + "\n")
      r = build_ralph(run_dir: run_dir)

      expect(r.send(:parse_task_activity, "t1")).to eq("Tool: Bash")
    ensure
      FileUtils.rm_rf(run_dir)
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

    it "includes activity string for running tasks" do
      run_dir = Dir.mktmpdir("ralph-run-")
      event = { "type" => "assistant", "message" => { "content" => [{ "type" => "tool_use", "name" => "Edit" }] } }
      File.write(File.join(run_dir, "t1.log"), JSON.generate(event) + "\n")

      tasks = [{ "id" => "t1", "status" => "running", "title" => "Test task" }]
      r = build_ralph(
        prd: { "tasks" => tasks },
        run_dir: run_dir,
        running_pids: { "t1" => 123 }
      )

      output = capture_stdout { r.send(:render_task_list) }
      expect(output).to include("Tool: Edit")
    ensure
      FileUtils.rm_rf(run_dir)
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

# Helper to capture stderr
def capture_stderr
  original = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = original
end
