#!/usr/bin/env bun
/**
 * Split a monolithic plan.md into an index.md + per-phase files.
 *
 * Usage:
 *   bun split_plan.ts path/to/plan.md [--output path/to/plan/] [--dry-run]
 *
 * Creates:
 *   plan/index.md              - everything except detailed phase content
 *   plan/phases/phase-1.md     - phase 1 content
 *   plan/phases/phase-2.md     - phase 2 content
 *   ...
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { basename, dirname, join, resolve } from "path";
import { parseArgs } from "util";

const INDEX_SECTIONS = [
  "Overview",
  "Current State Analysis",
  "Desired End State",
  "What We're NOT Doing",
  "Implementation Approach",
  "Testing Strategy",
  "Performance Considerations",
  "Migration Notes",
  "Alternative Approaches Considered",
  "Risk Analysis",
  "Rollback Strategy",
  "References",
  "Next Steps",
];

const PHASE_RE = /^##\s+Phase\s+(\d+)\s*[:\-–—]\s*(.+)$/;

type Section = [heading: string, headingLine: string, contentLines: string[]];
type PhaseSection = [num: number, name: string, headingLine: string, contentLines: string[]];
type IndexSections = Map<string, [headingLine: string, contentLines: string[]]>;

function parseSections(lines: string[]): { titleBlock: string; sections: Section[] } {
  const titleBlockLines: string[] = [];
  const sections: Section[] = [];
  let currentHeading: string | null = null;
  let currentHeadingLine: string | null = null;
  let currentLines: string[] = [];
  let inTitleBlock = true;

  for (const line of lines) {
    if (line.startsWith("## ")) {
      if (inTitleBlock) {
        inTitleBlock = false;
        titleBlockLines.push(...currentLines);
        currentLines = [];
      } else {
        sections.push([currentHeading!, currentHeadingLine!, currentLines]);
        currentLines = [];
      }
      currentHeadingLine = line;
      currentHeading = line.slice(3).trim();
      continue;
    }
    currentLines.push(line);
  }

  if (currentHeading !== null) {
    sections.push([currentHeading, currentHeadingLine!, currentLines]);
  } else if (currentLines.length > 0) {
    titleBlockLines.push(...currentLines);
  }

  return { titleBlock: titleBlockLines.join(""), sections };
}

function classifySections(sections: Section[]): { indexSections: IndexSections; phaseSections: PhaseSection[] } {
  const indexSections: IndexSections = new Map();
  const phaseSections: PhaseSection[] = [];

  for (const [heading, headingLine, contentLines] of sections) {
    const m = headingLine.trimEnd().match(PHASE_RE);
    if (m) {
      phaseSections.push([parseInt(m[1]), m[2].trim(), headingLine, contentLines]);
    } else {
      indexSections.set(heading, [headingLine, contentLines]);
    }
  }

  return { indexSections, phaseSections };
}

function determinePhaseStatus(contentLines: string[]): "complete" | "in_progress" | "not_started" {
  let checked = 0;
  let unchecked = 0;

  for (const line of contentLines) {
    const stripped = line.trim();
    if (stripped.startsWith("- [x]") || stripped.startsWith("- [X]")) checked++;
    else if (stripped.startsWith("- [ ]")) unchecked++;
  }

  if (checked === 0 && unchecked === 0) return "not_started";
  if (unchecked === 0) return "complete";
  if (checked > 0) return "in_progress";
  return "not_started";
}

function stripTrailingHr(contentLines: string[]): string[] {
  const lines = [...contentLines];
  while (lines.length > 0 && lines[lines.length - 1].trim() === "") lines.pop();
  if (lines.length > 0 && lines[lines.length - 1].trim() === "---") lines.pop();
  while (lines.length > 0 && lines[lines.length - 1].trim() === "") lines.pop();
  if (lines.length > 0 && !lines[lines.length - 1].endsWith("\n")) {
    lines[lines.length - 1] += "\n";
  }
  return lines;
}

function buildPhaseFile(headingLine: string, contentLines: string[]): string {
  return headingLine + stripTrailingHr(contentLines).join("");
}

function buildPhaseIndexTable(phaseSections: PhaseSection[]): string {
  const rows = [
    "## Phase Index",
    "",
    "| # | Phase | Status | File |",
    "|---|-------|--------|------|",
  ];
  for (const [num, name, , contentLines] of phaseSections) {
    const status = determinePhaseStatus(contentLines);
    rows.push(`| ${num} | ${name} | ${status} | phases/phase-${num}.md |`);
  }
  rows.push("");
  return rows.join("\n") + "\n";
}

function buildIndexFile(titleBlock: string, indexSections: IndexSections, phaseSections: PhaseSection[]): string {
  const parts = [titleBlock.trimEnd() + "\n"];

  for (const sectionName of INDEX_SECTIONS) {
    const entry = indexSections.get(sectionName);
    if (entry) {
      const [headingLine, contentLines] = entry;
      const cleaned = stripTrailingHr(contentLines);
      parts.push("", headingLine.trimEnd(), cleaned.join("").trimEnd());
    }

    if (sectionName === "Implementation Approach") {
      parts.push("", buildPhaseIndexTable(phaseSections).trimEnd());
    }
  }

  // Any sections not in the canonical list
  const known = new Set(INDEX_SECTIONS);
  for (const [heading, [headingLine, contentLines]] of indexSections) {
    if (!known.has(heading)) {
      const cleaned = stripTrailingHr(contentLines);
      parts.push("", headingLine.trimEnd(), cleaned.join("").trimEnd());
    }
  }

  return parts.join("\n") + "\n";
}

function splitPlan(planPath: string, outputDir: string | null, dryRun: boolean): number {
  const resolved = resolve(planPath);
  if (!existsSync(resolved)) {
    console.error(`Error: ${resolved} does not exist`);
    return 1;
  }

  const lines = readFileSync(resolved, "utf-8").split(/(?<=\n)/);
  const { titleBlock, sections } = parseSections(lines);
  const { indexSections, phaseSections } = classifySections(sections);

  if (phaseSections.length === 0) {
    console.warn("Warning: No phases found in the plan.");
  }

  const indexContent = buildIndexFile(titleBlock, indexSections, phaseSections);
  const phaseFiles: [filename: string, content: string][] = [];
  for (const [num, , headingLine, contentLines] of phaseSections) {
    phaseFiles.push([`phase-${num}.md`, buildPhaseFile(headingLine, contentLines)]);
  }

  const output = outputDir ? resolve(outputDir) : join(dirname(resolved), "plan");

  if (dryRun) {
    console.log(`Would create directory: ${output}`);
    console.log(`Would create directory: ${join(output, "phases")}`);
    console.log(`\nWould create: ${join(output, "index.md")} (${indexContent.length} bytes)`);
    for (const [filename, content] of phaseFiles) {
      console.log(`Would create: ${join(output, "phases", filename)} (${content.length} bytes)`);
    }

    console.log("\nPhase Index:");
    console.log(`  ${"#".padEnd(4)} ${"Phase".padEnd(50)} ${"Status".padEnd(15)}`);
    console.log(`  ${"─".repeat(4)} ${"─".repeat(50)} ${"─".repeat(15)}`);
    for (const [num, name, , contentLines] of phaseSections) {
      const status = determinePhaseStatus(contentLines);
      console.log(`  ${String(num).padEnd(4)} ${name.padEnd(50)} ${status.padEnd(15)}`);
    }
    return 0;
  }

  mkdirSync(join(output, "phases"), { recursive: true });

  const indexPath = join(output, "index.md");
  writeFileSync(indexPath, indexContent);
  console.log(`Created: ${indexPath}`);

  for (const [filename, content] of phaseFiles) {
    const phasePath = join(output, "phases", filename);
    writeFileSync(phasePath, content);
    console.log(`Created: ${phasePath}`);
  }

  console.log(`\nSplit into ${phaseFiles.length} phases + index.md`);
  return 0;
}

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    output: { type: "string", short: "o" },
    "dry-run": { type: "boolean", default: false },
  },
  allowPositionals: true,
});

if (positionals.length === 0) {
  console.error("Usage: bun split_plan.ts path/to/plan.md [--output path/to/plan/] [--dry-run]");
  process.exit(1);
}

process.exit(splitPlan(positionals[0], values.output ?? null, values["dry-run"] ?? false));
