# r/system/rcd-file-tagger.r
# Auto-tags existing TypeScript/R-lang files with capabilities and dependencies
# Enables the system to understand its own architecture

self:
  id: "rcd-file-tagger"
  intent: "Automatically analyze and tag files with capabilities, dependencies, and metadata for RCD system"
  version: "1.0.0"
  template: "system-analyzer"

aam:
  require_role: "system"
  allow_actions: ["scan_files", "analyze_content", "tag_files", "detect_patterns"]

operations:
  # Scan entire system and tag all files
  full_system_scan:
    - tamr.log: { event: "rcd_full_scan_start", timestamp: "${timestamp}" }

    - rcd.scan_directory:
        path: "./"
        file_patterns: ["*.ts", "*.r", "*.js", "*.json"]
        exclude_patterns: ["node_modules", ".git", "dist", "build"]

    - respond: "🔍 Found ${scanned_files.length} files for analysis"

    - loop:
        forEach: "${scanned_files}"
        do:
          - run: ["r/system/rcd-file-tagger.r", "analyze_single_file"]
            input:
              file_path: "${item.path}"
              file_type: "${item.type}"

    - rcd.build_dependency_graph:
        files: "${scanned_files}"

    - rcd.identify_capability_clusters:
        dependency_graph: "${dependency_graph}"

    - tamr.log:
        event: "rcd_full_scan_complete"
        files_analyzed: "${scanned_files.length}"
        capabilities_discovered: "${discovered_capabilities.length}"
        dependency_links: "${dependency_graph.edges.length}"

    - respond: "✅ System scan complete: ${scanned_files.length} files tagged with ${discovered_capabilities.length} capabilities"

  # Analyze a single file and extract metadata
  analyze_single_file:
    - condition:
        if: "${input.file_path}"
        then:
          - rcd.read_file_content:
              file_path: "${input.file_path}"
        else:
          - respond: "❌ file_path required"

    - rcd.detect_file_type:
        file_path: "${input.file_path}"
        content: "${file_content}"

    - condition:
        switch: "${detected_file_type}"
        cases:
          - typescript:
              - run: ["r/system/rcd-file-tagger.r", "analyze_typescript"]
                input:
                  file_path: "${input.file_path}"
                  content: "${file_content}"

          - rlang:
              - run: ["r/system/rcd-file-tagger.r", "analyze_rlang"]
                input:
                  file_path: "${input.file_path}"
                  content: "${file_content}"

          - json_config:
              - run: ["r/system/rcd-file-tagger.r", "analyze_config"]
                input:
                  file_path: "${input.file_path}"
                  content: "${file_content}"

  # Store analyzed file metadata
  store_file_analysis:
    - rcd.storeFileMetadata:
        file_path: "${input.file_path}"
        file_type: "${detected_file_type}"
        capabilities: "${analyzed_capabilities}"
        dependencies: "${analyzed_dependencies}"
        meta_tags: "${analyzed_meta_tags}"
        content_hash: "${file_content_hash}"
        performance_score: "${calculated_metrics.performance}"
        stability_rating: "${calculated_metrics.stability}"
        complexity_level: "${calculated_metrics.complexity}"
        last_analyzed: "${timestamp}"

    - respond: "📝 Tagged ${input.file_path}: ${analyzed_capabilities.length} capabilities, ${analyzed_dependencies.length} dependencies"

  # TypeScript file analysis - ALL LOGIC IN .r
  analyze_typescript:
    # Extract file structure by analyzing content
    - analyze_typescript_structure:
        content: "${input.content}"
        patterns:
          exports: "export\\s+(function|class|const|interface)\\s+(\\w+)"
          imports: "import.*from\\s+['\"]([^'\"]+)['\"]"
          functions: "(function|const)\\s+(\\w+)\\s*[\\(=]"
          classes: "class\\s+(\\w+)"
          interfaces: "interface\\s+(\\w+)"
          error_handling: "(try|catch|throw|Error)"
          async_ops: "(async|await|Promise)"

    # Map detected patterns to capabilities using declarative rules
    - map_capabilities_from_content:
        content: "${input.content}"
        file_path: "${input.file_path}"
        capability_rules:
          database_operations:
            patterns: ["insert", "update", "delete", "query", "select", "db\\.", "from\\("]
            weight: 2
          step_execution:
            patterns: ["execute", "run", "step", "invoke", "operation"]
            weight: 3
          error_handling:
            patterns: ["try", "catch", "error", "exception", "validate", "throw"]
            weight: 2
          api_operations:
            patterns: ["fetch", "request", "api", "http", "webhook", "axios"]
            weight: 2
          filesystem_operations:
            patterns: ["readFile", "writeFile", "fs\\.", "path\\.", "import.*fs"]
            weight: 2
          code_generation:
            patterns: ["generate", "template", "create.*File", "build", "compile"]
            weight: 4
          ai_inference:
            patterns: ["infer", "predict", "analyze", "llm", "ai", "openai", "anthropic"]
            weight: 3
          logging_monitoring:
            patterns: ["log", "monitor", "trace", "track", "console\\.", "debug"]
            weight: 1

    # Extract dependencies using pattern matching
    - extract_typescript_dependencies:
        content: "${input.content}"
        dependency_rules:
          internal_modules:
            pattern: "import.*from\\s+['\"]\\.\\.?/"
            extract: "from\\s+['\"]([^'\"]+)['\"]"
          external_packages:
            pattern: "import.*from\\s+['\"][^\\.]"
            extract: "from\\s+['\"]([^'\"]+)['\"]"
          dynamic_imports:
            pattern: "import\\s*\\("
            extract: "import\\s*\\(['\"]([^'\"]+)['\"]"
          module_calls:
            pattern: "\\w+\\.(\\w+)\\s*\\("
            extract: "(\\w+)\\."

    # Calculate metrics based on content analysis
    - calculate_file_metrics:
        content: "${input.content}"
        capabilities: "${mapped_capabilities}"
        dependencies: "${extracted_dependencies}"
        metric_rules:
          complexity:
            base_score: 1
            function_weight: 0.3
            class_weight: 0.5
            conditional_weight: 0.2
            loop_weight: 0.4
          stability:
            base_score: 1.0
            dependency_penalty: 0.05
            error_handling_bonus: 0.1
            type_definition_bonus: 0.1
          performance:
            base_score: 1.0
            async_bonus: 0.2
            database_penalty: 0.1
            ai_penalty: 0.3
            file_io_penalty: 0.1

    # Determine architectural layer
    - classify_architectural_layer:
        file_path: "${input.file_path}"
        layer_patterns:
          utility: "utils/"
          execution: "runtime/"
          data: "schema/"
          generation: "templates/"
          system: "r/system/"
          agent: "r/agents/"
          client: "r/clients/"

    # Generate comprehensive metadata
    - generate_typescript_metadata:
        file_path: "${input.file_path}"
        capabilities: "${mapped_capabilities}"
        dependencies: "${extracted_dependencies}"
        metrics: "${calculated_metrics}"
        layer: "${architectural_layer}"
        content_analysis: "${typescript_structure}"

  # R-lang file analysis - ALL LOGIC IN .r
  analyze_rlang:
    # Parse R-lang YAML structure
    - parse_rlang_yaml:
        content: "${input.content}"
        file_path: "${input.file_path}"
        yaml_sections:
          - "self:"
          - "aam:"
          - "operations:"
          - "concern:"
          - "incoming:"

    # Map R-lang operations to capabilities
    - map_rlang_capabilities:
        operations: "${rlang_structure.operations}"
        capability_mapping:
          user_interaction:
            patterns: ["respond:", "prompt\\.user:"]
            complexity: 2
            description: "User communication and interaction"
          agent_orchestration:
            patterns: ["run:", "execute:"]
            complexity: 3
            description: "Agent coordination and execution"
          flow_control:
            patterns: ["condition:", "loop:", "switch:"]
            complexity: 2
            description: "Logic flow and control structures"
          system_integration:
            patterns: ["tamr\\.", "rcd\\.", "config\\."]
            complexity: 2
            description: "System service integration"
          self_evolution:
            patterns: ["self\\.modify:", "self\\.reflect:"]
            complexity: 5
            description: "Self-modification capabilities"
          ai_generation:
            patterns: ["infer\\.", "generateAgent:", "generate"]
            complexity: 4
            description: "AI-powered generation and inference"
          data_operations:
            patterns: ["query:", "store:", "update:"]
            complexity: 2
            description: "Data manipulation operations"
          monitoring:
            patterns: ["monitor:", "health:", "diagnose:"]
            complexity: 2
            description: "System monitoring and diagnostics"

    # Extract R-lang dependencies
    - extract_rlang_dependencies:
        operations: "${rlang_structure.operations}"
        dependency_patterns:
          agent_files:
            pattern: "run:\\s*\\[?[\"']([^\"']+\\.r)[\"']"
            extract: "([^/]+\\.r)"
            type: "agent_dependency"
          module_calls:
            pattern: "(\\w+)\\."
            extract: "(\\w+)\\."
            type: "module_dependency"
          template_refs:
            pattern: "template:\\s*[\"']([^\"']+)[\"']"
            extract: "([^\"']+)"
            type: "template_dependency"

    # Analyze agent structure and intent
    - analyze_agent_structure:
        self_section: "${rlang_structure.self}"
        aam_section: "${rlang_structure.aam}"
        operations: "${rlang_structure.operations}"
        concern: "${rlang_structure.concern}"
        analysis_rules:
          intent_extraction:
            field: "intent"
            required: true
            description: "Primary purpose of the agent"
          role_requirements:
            field: "require_role"
            security_impact: true
            description: "Required security role"
          action_permissions:
            field: "allow_actions"
            security_impact: true
            description: "Permitted operations"
          operation_complexity:
            count_operations: true
            complexity_threshold: 5
            description: "Number of defined operations"

    # Calculate R-lang specific metrics
    - calculate_rlang_metrics:
        operations: "${rlang_structure.operations}"
        capabilities: "${rlang_capabilities}"
        dependencies: "${rlang_dependencies}"
        structure: "${agent_structure_analysis}"
        metric_calculations:
          complexity:
            base: 1
            operations_factor: 0.3
            self_evolution_penalty: 1.0
            nested_conditions_factor: 0.2
          stability:
            base: 1.0
            self_evolution_penalty: 0.2
            dependency_penalty: 0.1
            error_handling_bonus: 0.1
          performance:
            base: 1.0
            operation_count_factor: -0.05
            async_bonus: 0.1

    # Generate R-lang metadata
    - generate_rlang_metadata:
        file_path: "${input.file_path}"
        capabilities: "${rlang_capabilities}"
        dependencies: "${rlang_dependencies}"
        metrics: "${rlang_metrics}"
        structure_analysis: "${agent_structure_analysis}"
        meta_tag_rules:
          is_agent: "file_path contains '/agents/'"
          is_system: "file_path contains '/system/'"
          has_self_evolution: "capabilities contains 'self_evolution'"
          security_level: "aam_section.require_role"
          agent_category: "self_section.template"

  # Configuration file analysis
  analyze_config:
    - rcd.parse_config_structure:
        content: "${input.content}"
        file_path: "${input.file_path}"

    - condition:
        switch: "${config_structure.type}"
        cases:
          - package_json:
              - rcd.analyze_package_dependencies:
                  dependencies: "${config_structure.dependencies}"
                  dev_dependencies: "${config_structure.devDependencies}"
              - rcd.tag_package_capabilities:
                  scripts: "${config_structure.scripts}"
                  dependencies: "${config_structure.dependencies}"

          - tsconfig:
              - rcd.analyze_typescript_config:
                  compiler_options: "${config_structure.compilerOptions}"
                  includes: "${config_structure.include}"
                  excludes: "${config_structure.exclude}"

          - env_config:
              - rcd.analyze_environment_config:
                  variables: "${config_structure.variables}"

    - rcd.tag_config_file:
        file_path: "${input.file_path}"
        config_type: "${config_structure.type}"
        capabilities: ["configuration", "environment_setup"]
        dependencies: "${config_dependencies}"

  # Detect missing capabilities and suggest files to create
  capability_gap_analysis:
    - rcd.get_all_dependencies:
        scope: "system"

    - rcd.find_unresolved_dependencies:
        all_dependencies: "${system_dependencies}"
        available_capabilities: "${system_capabilities}"

    - loop:
        forEach: "${unresolved_dependencies}"
        do:
          - rcd.suggest_implementation:
              missing_capability: "${item.capability}"
              requesting_files: "${item.consumers}"
              suggested_location: "${item.suggested_path}"
              template_recommendation: "${item.template}"

          - tamr.log:
              event: "rcd_capability_gap_detected"
              capability: "${item.capability}"
              consumers: "${item.consumers}"
              suggestion: "${implementation_suggestion}"

    - condition:
        if: "${unresolved_dependencies.length > 0}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🔍 Found ${unresolved_dependencies.length} capability gaps"
              buttons: ["Auto-Generate", "Review Suggestions", "Ignore"]
              metadata: "${capability_gap_suggestions}"

  # Real-time file change monitoring
  monitor_file_changes:
    - rcd.setup_file_watcher:
        directories: ["./utils", "./runtime", "./r", "./schema"]
        file_patterns: ["*.ts", "*.r", "*.js"]

    - tamr.log: { event: "rcd_file_monitoring_started" }

    # This would be triggered by file system events
    - on_file_changed:
        - rcd.check_content_hash:
            file_path: "${changed_file.path}"

        - condition:
            if: "${content_hash_changed}"
            then:
              - run: ["r/system/rcd-file-tagger.r", "analyze_single_file"]
                input:
                  file_path: "${changed_file.path}"
                  force_reanalyze: true

              - rcd.update_dependency_links:
                  file_path: "${changed_file.path}"
                  old_capabilities: "${old_file_metadata.capabilities}"
                  new_capabilities: "${new_file_metadata.capabilities}"

              - tamr.log:
                  event: "rcd_file_auto_retagged"
                  file_path: "${changed_file.path}"
                  capability_changes: "${capability_changes}"

  # Pattern recognition from file analysis
  discover_architectural_patterns:
    - rcd.analyze_file_relationships:
        all_files: "${system_files}"
        dependency_graph: "${system_dependency_graph}"

    - rcd.identify_patterns:
        pattern_types:
          - "module_dependency_patterns"
          - "capability_clustering_patterns"
          - "architectural_layer_patterns"
          - "naming_convention_patterns"
          - "complexity_distribution_patterns"

    - loop:
        forEach: "${identified_patterns}"
        do:
          - run: ["r/system/rcd-core.r", "pattern_store"]
            input:
              pattern_type: "architectural_pattern"
              pattern_data: "${item}"
              confidence: "${item.confidence_score}"

    - respond: "🧠 Discovered ${identified_patterns.length} architectural patterns"

concern:
  # Auto-retag files if dependency resolution drops below threshold
  if: "${dependency_resolution_rate < 0.8 || outdated_file_count > 5}"
  priority: 2
  action:
    - tamr.log:
        event: "rcd_file_tagging_concern"
        resolution_rate: "${dependency_resolution_rate}"
        outdated_files: "${outdated_file_count}"
    - run: ["r/system/rcd-file-tagger.r", "full_system_scan"]
