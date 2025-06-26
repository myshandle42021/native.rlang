# r/system/rcd-core.r
# RCD (Relational Contextual Database) - The meta-memory system
# Enables self-awareness, learning, and autonomous code evolution

self:
  id: "rcd-core"
  intent: "Provide foundational RCD operations for file metadata, capabilities, and learning patterns"
  version: "1.0.0"
  template: "system-core"

aam:
  require_role: "system"
  allow_actions: ["schema_init", "file_track", "capability_query", "pattern_store"]

operations:
  # Initialize RCD database schema
  schema_init:
    - tamr.log: { event: "rcd_schema_init", timestamp: "${timestamp}" }
    - rcd.createTables:
        tables:
          - name: "rcd_files"
            schema:
              id: "SERIAL PRIMARY KEY"
              file_path: "TEXT UNIQUE NOT NULL"
              file_type: "TEXT NOT NULL" # typescript, rlang, template, config
              capabilities: "TEXT[]" # step_execution, error_handling, db_ops
              dependencies: "TEXT[]" # function_resolver, context_manager
              meta_tags: "JSONB" # {layer: runtime, stability: critical, complexity: high}
              content_hash: "TEXT" # For change detection
              last_analyzed: "TIMESTAMP DEFAULT NOW()"
              performance_score: "FLOAT DEFAULT 1.0"
              usage_frequency: "INTEGER DEFAULT 0"

          - name: "rcd_patterns"
            schema:
              id: "SERIAL PRIMARY KEY"
              pattern_type: "TEXT NOT NULL" # success_condition, failure_pattern, optimization_opportunity
              pattern_data: "JSONB NOT NULL"
              confidence_score: "FLOAT DEFAULT 0.5"
              usage_count: "INTEGER DEFAULT 0"
              success_rate: "FLOAT DEFAULT 0.0"
              last_used: "TIMESTAMP"
              discovered_by: "TEXT" # agent_id
              validated_by: "TEXT[]" # agent_ids that confirmed pattern

          - name: "rcd_capabilities"
            schema:
              id: "SERIAL PRIMARY KEY"
              capability_name: "TEXT UNIQUE NOT NULL"
              provider_files: "TEXT[]" # Files that provide this capability
              consumer_files: "TEXT[]" # Files that need this capability
              interface_spec: "JSONB" # Expected function signatures, parameters
              complexity_level: "INTEGER DEFAULT 1" # 1-5 scale
              stability_rating: "FLOAT DEFAULT 1.0"

          - name: "rcd_learning_events"
            schema:
              id: "SERIAL PRIMARY KEY"
              agent_id: "TEXT NOT NULL"
              event_type: "TEXT NOT NULL" # pattern_discovered, capability_linked, evolution_success
              context_data: "JSONB NOT NULL"
              outcome: "TEXT" # success, failure, partial
              patterns_involved: "INTEGER[]" # Reference to rcd_patterns.id
              timestamp: "TIMESTAMP DEFAULT NOW()"
              impact_score: "FLOAT DEFAULT 0.0"

          - name: "rcd_evolution_history"
            schema:
              id: "SERIAL PRIMARY KEY"
              file_path: "TEXT NOT NULL"
              change_type: "TEXT NOT NULL" # capability_added, dependency_resolved, pattern_applied
              before_state: "JSONB"
              after_state: "JSONB"
              triggered_by: "TEXT" # agent_id or event_id
              success: "BOOLEAN DEFAULT TRUE"
              rollback_data: "JSONB" # For autonomous rollback if needed
              timestamp: "TIMESTAMP DEFAULT NOW()"

    - respond: "🗄️ RCD database schema initialized successfully"

  # Track a file in RCD system
  file_track:
    - condition:
        if: "${input.file_path}"
        then:
          - rcd.analyze_file:
              file_path: "${input.file_path}"
              force_reanalyze: "${input.force || false}"
        else:
          - respond: "❌ file_path required for tracking"

    - tamr.log:
        event: "rcd_file_tracked"
        file_path: "${input.file_path}"
        capabilities: "${analyzed_file.capabilities}"
        dependencies: "${analyzed_file.dependencies}"

  # Query capabilities across the system
  capability_query:
    - condition:
        switch: "${input.query_type}"
        cases:
          - by_capability:
              - rcd.find_providers:
                  capability: "${input.capability}"
                  minimum_stability: "${input.min_stability || 0.7}"
              - respond: "${provider_files}"

          - by_file:
              - rcd.get_file_capabilities:
                  file_path: "${input.file_path}"
              - respond: "${file_capabilities}"

          - missing_capabilities:
              - rcd.find_unresolved_dependencies:
                  scope: "${input.scope || 'all'}"
              - respond: "${unresolved_dependencies}"

          - capability_gaps:
              - rcd.analyze_capability_gaps:
                  target_capabilities: "${input.target_capabilities}"
              - respond: "${capability_analysis}"

  # Store and retrieve learning patterns
  pattern_store:
    - condition:
        if: "${input.pattern_data && input.pattern_type}"
        then:
          - rcd.store_pattern:
              pattern_type: "${input.pattern_type}"
              pattern_data: "${input.pattern_data}"
              discovered_by: "${context.agentId}"
              confidence: "${input.confidence || 0.5}"
          - tamr.log:
              event: "rcd_pattern_stored"
              pattern_type: "${input.pattern_type}"
              agent_id: "${context.agentId}"
        else:
          - respond: "❌ pattern_data and pattern_type required"

  # Query patterns for decision making
  pattern_query:
    - condition:
        switch: "${input.query_type}"
        cases:
          - by_type:
              - rcd.get_patterns:
                  pattern_type: "${input.pattern_type}"
                  min_confidence: "${input.min_confidence || 0.7}"
                  limit: "${input.limit || 10}"
              - respond: "${matching_patterns}"

          - for_context:
              - rcd.find_relevant_patterns:
                  context: "${input.context}"
                  similarity_threshold: "${input.threshold || 0.8}"
              - respond: "${relevant_patterns}"

          - success_patterns:
              - rcd.get_successful_patterns:
                  domain: "${input.domain}"
                  min_success_rate: "${input.min_success_rate || 0.8}"
              - respond: "${success_patterns}"

  # Link capabilities between files (dynamic dependency resolution)
  capability_link:
    - rcd.create_capability_link:
        consumer_file: "${input.consumer_file}"
        provider_file: "${input.provider_file}"
        capability: "${input.capability}"
        interface_used: "${input.interface}"

    - rcd.update_capability_registry:
        capability: "${input.capability}"
        new_consumer: "${input.consumer_file}"

    - tamr.log:
        event: "rcd_capability_linked"
        consumer: "${input.consumer_file}"
        provider: "${input.provider_file}"
        capability: "${input.capability}"

  # Autonomous evolution operations
  suggest_evolution:
    - rcd.analyze_evolution_opportunities:
        scope: "${input.scope || 'system'}"
        focus_areas: "${input.focus_areas || ['performance', 'stability', 'capabilities']}"

    - loop:
        forEach: "${evolution_opportunities}"
        do:
          - condition:
              if: "${item.confidence_score > 0.8}"
              then:
                - rcd.generate_evolution_plan:
                    opportunity: "${item}"
                    safety_checks: true
                - rcd.simulate_evolution:
                    plan: "${evolution_plan}"
                - condition:
                    if: "${simulation_result.safe && simulation_result.beneficial}"
                    then:
                      - rcd.store_pattern:
                          pattern_type: "evolution_opportunity"
                          pattern_data: "${evolution_plan}"
                          confidence: "${item.confidence_score}"
                      - prompt.user:
                          to: "system_admin"
                          message: "🧬 Evolution opportunity detected: ${item.description}"
                          buttons: ["Apply", "Simulate More", "Reject"]
                          metadata: "${evolution_plan}"

  # System health through RCD lens
  health_check:
    - rcd.analyze_system_health:
        metrics:
          - "capability_coverage"
          - "dependency_resolution_rate"
          - "pattern_utilization"
          - "evolution_velocity"
          - "learning_rate"

    - condition:
        if: "${system_health.overall_score < 0.7}"
        then:
          - run: ["r/system/rcd-core.r", "suggest_evolution"]
          - tamr.log:
              event: "rcd_health_degradation"
              score: "${system_health.overall_score}"
              issues: "${system_health.issues}"
        else:
          - respond: "✅ RCD system health: ${system_health.overall_score}/1.0"

  # Learn from execution patterns
  learn_from_execution:
    - condition:
        if: "${input.execution_trace}"
        then:
          - rcd.extract_patterns_from_trace:
              trace: "${input.execution_trace}"
              context: "${input.context}"
              outcome: "${input.outcome}"

          - loop:
              forEach: "${extracted_patterns}"
              do:
                - rcd.validate_pattern:
                    pattern: "${item}"
                    historical_data: true

                - condition:
                    if: "${pattern_validation.confidence > 0.8}"
                    then:
                      - run: ["r/system/rcd-core.r", "pattern_store"]
                        input:
                          pattern_type: "${item.type}"
                          pattern_data: "${item.data}"
                          confidence: "${pattern_validation.confidence}"

concern:
  # Monitor RCD system integrity
  if: "${rcd_files_count == 0 || capability_resolution_rate < 0.8}"
  priority: 1
  action:
    - tamr.log: { event: "rcd_integrity_concern", details: "${concern_details}" }
    - run: ["r/system/rcd-core.r", "health_check"]
    - condition:
        if: "${rcd_files_count == 0}"
        then:
          - run: ["r/system/rcd-file-tagger.r", "full_system_scan"]
