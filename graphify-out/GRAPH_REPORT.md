# Graph Report - .  (2026-06-26)

## Corpus Check
- Corpus is ~12,972 words - fits in a single context window. You may not need a graph.

## Summary
- 64 nodes · 71 edges · 13 communities (7 shown, 6 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Wholesale Real Estate Workflow|Wholesale Real Estate Workflow]]
- [[_COMMUNITY_Extraction Spec & Graph Rules|Extraction Spec & Graph Rules]]
- [[_COMMUNITY_Export Formats & Integrations|Export Formats & Integrations]]
- [[_COMMUNITY_Graphify Pipeline & Honesty|Graphify Pipeline & Honesty]]
- [[_COMMUNITY_Context-Mode Tool Selection|Context-Mode Tool Selection]]
- [[_COMMUNITY_Incremental Update & Hooks|Incremental Update & Hooks]]
- [[_COMMUNITY_GitHub Clone & Multi-Repo|GitHub Clone & Multi-Repo]]
- [[_COMMUNITY_CLAUDE.md Integration|CLAUDE.md Integration]]
- [[_COMMUNITY_AudioVideo Transcription|Audio/Video Transcription]]
- [[_COMMUNITY_Cross-Language Call Guard|Cross-Language Call Guard]]
- [[_COMMUNITY_File Type Enum|File Type Enum]]
- [[_COMMUNITY_Explain Traversal|Explain Traversal]]
- [[_COMMUNITY_Path Traversal|Path Traversal]]

## God Nodes (most connected - your core abstractions)
1. `Graphify Pipeline Skill` - 20 edges
2. `Wholesale Real Estate Full Workflow Skill` - 9 edges
3. `Step 6 Generate Obsidian Vault and HTML` - 6 edges
4. `Part B Semantic Extraction via Subagents` - 5 edges
5. `BFS and DFS Graph Traversal` - 5 edges
6. `Stage 2 Analyze the Deal MAO Calculation` - 5 edges
7. `Step 0 GitHub Clone and Multi-Path Merge` - 4 edges
8. `Step 3 Extract Entities and Relationships` - 4 edges
9. `Part C Merge AST and Semantic Extraction` - 4 edges
10. `Step 4 Build Graph Cluster Analyze Outputs` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Graphify Always-On CLAUDE.md Section` --references--> `Graphify Pipeline Skill`  [EXTRACTED]
  CLAUDE.md → .claude/skills/graphify/SKILL.md
- `MCP Server Export` --semantically_similar_to--> `BFS and DFS Graph Traversal`  [INFERRED] [semantically similar]
  .claude/skills/graphify/references/exports.md → .claude/skills/graphify/references/query.md
- `Native CLAUDE.md Graphify Integration` --references--> `Graphify Always-On CLAUDE.md Section`  [INFERRED]
  .claude/skills/graphify/references/hooks.md → CLAUDE.md
- `Wholesale Real Estate Skill Overview` --references--> `Wholesale Real Estate Full Workflow Skill`  [EXTRACTED]
  README.md → SKILL.md
- `Graphify Pipeline Skill` --references--> `Graphify Watch Folder Auto Rebuild`  [EXTRACTED]
  .claude/skills/graphify/SKILL.md → .claude/skills/graphify/references/add-watch.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Graphify Three-Phase Extraction Pipeline** — graphify_skill_md_step3a_ast, graphify_skill_md_step3b_semantic, graphify_skill_md_step3c_merge_ast_semantic [EXTRACTED 1.00]
- **Wholesale Deal End-to-End Workflow Stages** — skill_md_stage0_deal_finder, skill_md_stage1_qualify_lead, skill_md_stage2_deal_analysis, skill_md_stage3_comps_arv, skill_md_stage4_make_offer, skill_md_stage5_end_buyer_assign, skill_md_stage6_close_deal [EXTRACTED 1.00]
- **Context Mode Tool Selection Hierarchy** — claude_md_ctx_batch_execute, claude_md_ctx_search, claude_md_ctx_execute, claude_md_ctx_fetch_and_index [EXTRACTED 1.00]

## Communities (13 total, 6 thin omitted)

### Community 0 - "Wholesale Real Estate Workflow"
Cohesion: 0.23
Nodes (13): Wholesale Real Estate Skill Overview, Assignment Fee Formula, Key Formulas Reference, Maximum Allowable Offer MAO Formula, Motivated Seller Score MSS Rubric, Stage 0 Deal Finder Search by City, Stage 1 Qualify Existing Lead, Stage 2 Analyze the Deal MAO Calculation (+5 more)

### Community 1 - "Extraction Spec & Graph Rules"
Cohesion: 0.22
Nodes (11): Edge Confidence Score Rubric, Node ID Format Rules, Extraction Subagent Prompt Template, Semantic Extraction Cache, Graph Shrink Guard, Step 3 Extract Entities and Relationships, Part A Structural AST Extraction, Part B Semantic Extraction via Subagents (+3 more)

### Community 2 - "Export Formats & Integrations"
Cohesion: 0.20
Nodes (10): FalkorDB Export, MCP Server Export, Neo4j Export, Token Reduction Benchmark, Wiki Export, Fast Path Existing Graph Query, Step 6 Generate Obsidian Vault and HTML, BFS and DFS Graph Traversal (+2 more)

### Community 3 - "Graphify Pipeline & Honesty"
Cohesion: 0.22
Nodes (9): Graphify Add URL Ingest, Graphify Skill Registration, Graphify Pipeline Skill, Graphify Honesty Rules, Step 1 Install Graphify, Step 2 Detect Files, Step 4.5 Graph Health Check, Step 9 Save Manifest Update Cost Tracker Cleanup (+1 more)

### Community 4 - "Context-Mode Tool Selection"
Cohesion: 0.40
Nodes (5): Context Mode MANDATORY Routing Rules, ctx_batch_execute Primary Tool, ctx_execute Sandbox Execution Tool, ctx_fetch_and_index Web Fetch Tool, ctx_search Follow-Up Query Tool

### Community 5 - "Incremental Update & Hooks"
Cohesion: 0.50
Nodes (4): Graphify Watch Folder Auto Rebuild, Git Post-Commit Auto-Rebuild Hook, Build Merge Incremental Graph Merge, Incremental Update Re-Extraction

### Community 6 - "GitHub Clone & Multi-Repo"
Cohesion: 0.50
Nodes (4): Single Repo GitHub Clone, Cross-Repo Graph Merge, Monorepo Multi-Subfolder Merge, Step 0 GitHub Clone and Multi-Path Merge

## Knowledge Gaps
- **30 isolated node(s):** `Graphify Skill Registration`, `Step 1 Install Graphify`, `Step 2 Detect Files`, `Step 4.5 Graph Health Check`, `Step 9 Save Manifest Update Cost Tracker Cleanup` (+25 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Graphify Pipeline Skill` connect `Graphify Pipeline & Honesty` to `Extraction Spec & Graph Rules`, `Export Formats & Integrations`, `Incremental Update & Hooks`, `GitHub Clone & Multi-Repo`, `CLAUDE.md Integration`, `Audio/Video Transcription`?**
  _High betweenness centrality (0.369) - this node is a cross-community bridge._
- **Why does `Step 3 Extract Entities and Relationships` connect `Extraction Spec & Graph Rules` to `Graphify Pipeline & Honesty`?**
  _High betweenness centrality (0.106) - this node is a cross-community bridge._
- **Why does `Step 6 Generate Obsidian Vault and HTML` connect `Export Formats & Integrations` to `Graphify Pipeline & Honesty`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `BFS and DFS Graph Traversal` (e.g. with `MCP Server Export` and `Fast Path Existing Graph Query`) actually correct?**
  _`BFS and DFS Graph Traversal` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Graphify Skill Registration`, `Step 1 Install Graphify`, `Step 2 Detect Files` to the rest of the system?**
  _36 weakly-connected nodes found - possible documentation gaps or missing edges._