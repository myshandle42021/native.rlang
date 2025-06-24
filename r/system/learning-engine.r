# r/system/learning-engine.r
# Central Learning Orchestrator - Transforms ROL3 from reactive to proactive intelligence
# FIXED: Database schema consistency with rcd_ prefixes

self:
  id: "learning-engine"
  intent: "Continuously analyze, learn, and optimize agent performance across the entire system"
  version: "1.0.0"
  template: "system_intelligence"

aam:
  require_role: "system"
  allow_actions: ["analyze", "optimize", "transfer_knowledge", "predict", "evolve"]

dependencies:
  services: ["tamr", "rcd", "infer"]
  agents: ["system-doctor", "pesr-agent"]

operations:
  initialize:
    - tamr.log: { event: "learning_engine_started", timestamp: "${timestamp}" }
    - setup_learning_tables: {}
    - initialize_pattern_library: {}
    - start_continuous_learning: {}
    - respond: "🧠 Learning Engine initialized - Continuous intelligence active"

  setup_learning_tables:
    - rcd.query: "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'rcd_learning_events')"
    - condition:
        if: "!${table_exists}"
        then:
          - create_learning_schema: {}
          - tamr.log: { event: "learning_schema_created" }

  create_learning_schema:
    # FIXED: Create learning events table with rcd_ prefix
    - rcd.execute_sql: |
        CREATE TABLE IF NOT EXISTS rcd_learning_events (
          id SERIAL PRIMARY KEY,
          agent_id TEXT NOT NULL,
          operation_name TEXT NOT NULL,
          input_hash TEXT,
          success BOOLEAN NOT NULL,
          performance_metrics JSONB,
          context_data JSONB,
          learned_patterns JSONB,
          execution_duration_ms INTEGER,
          memory_usage_mb INTEGER,
          error_details TEXT,
          timestamp TIMESTAMP DEFAULT NOW(),
          learning_cycle INTEGER DEFAULT 0
        );

    # FIXED: Create agent patterns library with rcd_ prefix
    - rcd.execute_sql: |
        CREATE TABLE IF NOT EXISTS rcd_agent_patterns (
          id SERIAL PRIMARY KEY,
          pattern_type TEXT NOT NULL,
          pattern_data JSONB NOT NULL,
          discovered_by TEXT,
          applicable_to TEXT[],
          success_rate FLOAT DEFAULT 0.0,
          usage_count INTEGER DEFAULT 0,
          confidence_score FLOAT DEFAULT 0.0,
          last_validated TIMESTAMP DEFAULT NOW(),
          created_at TIMESTAMP DEFAULT NOW()
        );

    # FIXED: Create optimization history with rcd_ prefix
    - rcd.execute_sql: |
        CREATE TABLE IF NOT EXISTS rcd_optimization_history (
          id SERIAL PRIMARY KEY,
          agent_id TEXT NOT NULL,
          optimization_type TEXT NOT NULL,
          before_metrics JSONB,
          after_metrics JSONB,
          improvement_percentage FLOAT,
          applied_at TIMESTAMP DEFAULT NOW(),
          success BOOLEAN DEFAULT TRUE
        );

    # FIXED: Create knowledge transfers table with rcd_ prefix
    - rcd.execute_sql: |
        CREATE TABLE IF NOT EXISTS rcd_knowledge_transfers (
          id SERIAL PRIMARY KEY,
          source_agent TEXT NOT NULL,
          target_agent TEXT NOT NULL,
          knowledge_type TEXT NOT NULL,
          transfer_data JSONB,
          success_rate FLOAT DEFAULT 0.0,
          transferred_at TIMESTAMP DEFAULT NOW()
        );

  initialize_pattern_library:
    - rcd.query: "SELECT COUNT(*) as count FROM rcd_agent_patterns"
    - condition:
        if: "${pattern_count.count == 0}"
        then:
          - seed_initial_patterns: {}
          - tamr.log: { event: "pattern_library_seeded" }

  seed_initial_patterns:
    # Seed common performance patterns
    - rcd.execute_sql: |
        INSERT INTO rcd_agent_patterns (
          pattern_type, pattern_data, discovered_by, confidence_score
        ) VALUES
        ('response_time_optimization', '{"pattern": "cache_heavy_queries", "improvement": 0.4}', 'learning-engine', 0.9),
        ('error_reduction', '{"pattern": "input_validation", "effectiveness": 0.7}', 'learning-engine', 0.85),
        ('resource_optimization', '{"pattern": "lazy_loading", "memory_reduction": 0.3}', 'learning-engine', 0.8);

  start_continuous_learning:
    - schedule_learning_cycle: {
        interval_minutes: 15,
        initial_delay: 60000
      }
    - tamr.log: { event: "continuous_learning_started", interval: "15min" }

  # FIXED: Updated all table references to use rcd_ prefix
  analyze_learning_patterns:
    - rcd.query: |
        SELECT
          agent_id,
          operation_name,
          AVG(execution_duration_ms) as avg_duration,
          AVG(CASE WHEN success THEN 1.0 ELSE 0.0 END) as success_rate,
          COUNT(*) as execution_count
        FROM rcd_learning_events
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
        GROUP BY agent_id, operation_name
        ORDER BY execution_count DESC

    - identify_performance_bottlenecks: {
        learning_data: "${query_result}",
        threshold_duration: 5000,
        min_success_rate: 0.8
      }

    - detect_learning_opportunities: {
        patterns: "${performance_analysis}",
        min_execution_count: 10
      }

    - store_discovered_patterns: {
        patterns: "${learning_opportunities}",
        discovery_confidence: 0.85
      }

  store_discovered_patterns:
    - loop:
        forEach: "${input.patterns}"
        do:
          # FIXED: Insert into rcd_agent_patterns
          - rcd.execute_sql: |
              INSERT INTO rcd_agent_patterns (
                pattern_type, pattern_data, discovered_by,
                confidence_score, applicable_to
              ) VALUES (
                '${item.type}',
                '${JSON.stringify(item.data)}',
                '${self.id}',
                ${input.discovery_confidence},
                ARRAY[${item.applicable_agents.map(a => `'${a}'`).join(',')}]
              )

  # FIXED: Updated table name in query
  optimize_agent_performance:
    - rcd.query: |
        SELECT * FROM rcd_optimization_history
        WHERE agent_id = '${input.agent_id}'
        ORDER BY applied_at DESC LIMIT 10

    - analyze_optimization_history: {
        agent_id: "${input.agent_id}",
        history: "${optimization_history}",
        current_metrics: "${input.current_metrics}"
      }

    - generate_optimization_recommendations: {
        analysis: "${optimization_analysis}",
        target_improvements: ["response_time", "accuracy", "resource_usage"]
      }

    - apply_optimizations: {
        agent_id: "${input.agent_id}",
        recommendations: "${optimization_recommendations}",
        test_mode: false
      }

    # FIXED: Store in rcd_optimization_history
    - rcd.execute_sql: |
        INSERT INTO rcd_optimization_history (
          agent_id, optimization_type, before_metrics,
          after_metrics, improvement_percentage
        ) VALUES (
          '${input.agent_id}',
          '${applied_optimizations.type}',
          '${JSON.stringify(input.current_metrics)}',
          '${JSON.stringify(applied_optimizations.new_metrics)}',
          ${applied_optimizations.improvement_percentage}
        )

  # FIXED: All table references updated throughout the file
  transfer_knowledge:
    - identify_knowledge_transfer_opportunities: {
        source_agent: "${input.source_agent}",
        potential_targets: "${input.target_agents}"
      }

    - extract_transferable_knowledge: {
        agent_id: "${input.source_agent}",
        knowledge_types: ["successful_patterns", "error_resolutions", "optimization_techniques"]
      }

    - validate_knowledge_compatibility: {
        knowledge: "${extracted_knowledge}",
        target_agents: "${transfer_opportunities.targets}"
      }

    - execute_knowledge_transfer: {
        validated_transfers: "${compatibility_analysis.valid_transfers}"
      }

    # FIXED: Store transfers in rcd_knowledge_transfers
    - loop:
        forEach: "${executed_transfers}"
        do:
          - rcd.execute_sql: |
              INSERT INTO rcd_knowledge_transfers (
                source_agent, target_agent, knowledge_type,
                transfer_data, success_rate
              ) VALUES (
                '${item.source}',
                '${item.target}',
                '${item.knowledge_type}',
                '${JSON.stringify(item.data)}',
                ${item.success_rate}
              )

  # FIXED: Query from rcd_learning_events
  continuous_learning_cycle:
    - tamr.log: { event: "continuous_learning_cycle_started" }

    # Analyze recent learning events
    - rcd.query: |
        SELECT agent_id, operation_name, success, performance_metrics, learned_patterns
        FROM rcd_learning_events
        WHERE timestamp >= NOW() - INTERVAL '1 hour'
        AND learned_patterns IS NOT NULL

    - process_learning_events: {
        events: "${recent_events}",
        learning_focus: ["pattern_validation", "performance_optimization", "error_prevention"]
      }

    - update_system_intelligence: {
        processed_learnings: "${learning_processing_result}",
        confidence_threshold: 0.7
      }

    - schedule_next_cycle: {
        interval_minutes: 15,
        adaptive_scheduling: true
      }

  # Learning event logging with correct table name
  log_learning_event:
    # FIXED: Insert into rcd_learning_events
    - rcd.execute_sql: |
        INSERT INTO rcd_learning_events (
          agent_id, operation_name, success, performance_metrics,
          context_data, learned_patterns, execution_duration_ms, error_details
        ) VALUES (
          '${input.agent_id}',
          '${input.operation_name}',
          ${input.success},
          '${JSON.stringify(input.performance_metrics)}',
          '${JSON.stringify(input.context_data)}',
          '${JSON.stringify(input.learned_patterns)}',
          ${input.execution_duration_ms},
          '${input.error_details}'
        )

    - return: {
        logged: true,
        learning_event_id: "${insert_result.id}"
      }

  # Advanced pattern analysis operations
  extract_learning_patterns:
    - rcd.query: |
        SELECT
          pattern_type,
          pattern_data,
          success_rate,
          usage_count,
          confidence_score
        FROM rcd_agent_patterns
        WHERE last_validated >= NOW() - INTERVAL '${input.window || "7d"}'
        ORDER BY confidence_score DESC, usage_count DESC

    - analyze_pattern_effectiveness: {
        patterns: "${pattern_query_result}",
        effectiveness_threshold: 0.7
      }

    - identify_emerging_patterns: {
        recent_events: "${input.performance_data}",
        existing_patterns: "${pattern_query_result}"
      }

    - return: {
        validated_patterns: "${effective_patterns}",
        emerging_patterns: "${new_patterns}",
        pattern_evolution: "${pattern_changes}"
      }

  generate_optimizations:
    - loop:
        forEach: "${input.patterns}"
        do:
          - analyze_optimization_potential: {
              pattern: "${item}",
              target_metrics: ["response_time", "accuracy", "resource_usage"]
            }
          - generate_optimization_strategy: {
              pattern: "${item}",
              potential: "${optimization_potential}",
              safety_constraints: "${optimization_safety_rules}"
            }

    - filter_safe_optimizations: {
        optimizations: "${generated_optimizations}",
        safety_threshold: "${input.confidence_threshold || 0.7}"
      }

    - return: {
        optimizations: "${safe_optimizations}",
        high_impact: "${high_impact_optimizations}",
        experimental: "${experimental_optimizations}"
      }

  apply_safe_optimizations:
    - loop:
        forEach: "${input.optimizations}"
        do:
          - condition:
              if: "${item.confidence >= input.safety_threshold}"
              then:
                - test_optimization: {
                    optimization: "${item}",
                    test_mode: true,
                    rollback_enabled: true
                  }
                - condition:
                    if: "${optimization_test.success}"
                    then:
                      - apply_optimization: {
                          optimization: "${item}",
                          production_mode: true
                        }
                      - track_optimization_result: {
                          optimization: "${item}",
                          result: "${application_result}"
                        }

    - return: {
        applied_count: "${applied_optimizations.length}",
        success_rate: "${optimization_success_rate}",
        improvements: "${measured_improvements}"
      }

  perform_knowledge_transfer:
    # Identify knowledge transfer opportunities
    - rcd.query: |
        SELECT DISTINCT source_agent, target_agent, knowledge_type
        FROM rcd_knowledge_transfers
        WHERE transferred_at >= NOW() - INTERVAL '24h'

    - identify_new_transfer_opportunities: {
        recent_transfers: "${recent_transfers}",
        agent_capabilities: "${system_agent_capabilities}",
        success_patterns: "${high_performing_patterns}"
      }

    - execute_knowledge_transfers: {
        opportunities: "${transfer_opportunities}",
        transfer_method: "pattern_injection"
      }

    - return: {
        transfers_executed: "${transfer_results.length}",
        success_rate: "${transfer_success_rate}",
        knowledge_spread: "${knowledge_distribution_impact}"
      }

  predictive_analysis:
    # Analyze trends to predict future issues
    - rcd.query: |
        SELECT
          agent_id,
          operation_name,
          success,
          execution_duration_ms,
          timestamp
        FROM rcd_learning_events
        WHERE timestamp >= NOW() - INTERVAL '7d'
        ORDER BY timestamp DESC

    - analyze_performance_trends: {
        historical_data: "${trend_data}",
        trend_window: "${input.horizon || '24h'}",
        prediction_confidence: 0.8
      }

    - identify_failure_predictors: {
        trends: "${performance_trends}",
        failure_indicators: ["increasing_duration", "declining_success_rate", "error_spikes"]
      }

    - generate_preventive_recommendations: {
        predictors: "${failure_predictors}",
        prevention_strategies: ["preemptive_optimization", "resource_scaling", "pattern_application"]
      }

    - return: {
        predictions: "${performance_predictions}",
        risks: "${identified_risks}",
        recommendations: "${preventive_recommendations}"
      }

  self_evolution_check:
    # Analyze learning engine's own performance
    - analyze_learning_effectiveness: {
        time_window: "30d",
        metrics: ["pattern_discovery_rate", "optimization_success_rate", "prediction_accuracy"]
      }

    - identify_learning_improvements: {
        effectiveness_analysis: "${learning_analysis}",
        improvement_threshold: 0.1
      }

    - condition:
        if: "${learning_improvements.significant}"
        then:
          - generate_self_improvements: {
              current_algorithms: "${learning_algorithms}",
              improvement_areas: "${learning_improvements.areas}"
            }
          - test_self_improvements: {
              improvements: "${self_improvements}",
              test_environment: "sandbox"
            }
          - condition:
              if: "${self_improvement_tests.success}"
              then:
                - apply_self_improvements: {
                    improvements: "${tested_improvements}",
                    backup_current_state: true
                  }
                - tamr.log: {
                    event: "learning_engine_evolved",
                    improvements: "${applied_self_improvements}"
                  }

    - return: {
        evolution_applied: "${self_improvements_applied}",
        performance_gain: "${evolution_performance_impact}",
        next_evolution_cycle: "${next_evolution_timestamp}"
      }

  # Emergency learning for critical failures
  emergency_learning:
    - tamr.log: {
        event: "emergency_learning_triggered",
        agent: "${input.agent_id}",
        priority: "${input.priority}"
      }

    # Rapid failure analysis
    - rcd.query: |
        SELECT * FROM rcd_learning_events
        WHERE agent_id = '${input.agent_id}'
        AND success = false
        AND timestamp >= NOW() - INTERVAL '1h'
        ORDER BY timestamp DESC LIMIT 10

    - analyze_failure_patterns: {
        recent_failures: "${failure_events}",
        failure_context: "${input.failure_context}",
        urgency: "critical"
      }

    # Generate immediate solutions
    - generate_emergency_fixes: {
        failure_analysis: "${failure_patterns}",
        known_solutions: "${emergency_solution_library}",
        time_constraint: "immediate"
      }

    # Apply most promising fix
    - apply_emergency_fix: {
        solutions: "${emergency_solutions}",
        selection_criteria: "highest_confidence_fastest_application"
      }

    - return: {
        emergency_fix_applied: "${applied_emergency_fix}",
        fix_confidence: "${emergency_fix_confidence}",
        monitoring_required: true
      }

  # Get insights for specific agent
  get_learning_insights:
    - rcd.query: |
        SELECT
          p.pattern_type,
          p.pattern_data,
          p.confidence_score,
          p.success_rate
        FROM rcd_agent_patterns p
        WHERE '${input.agent_id}' = ANY(p.applicable_to)
        OR p.applicable_to IS NULL
        ORDER BY p.confidence_score DESC, p.success_rate DESC
        LIMIT 20

    - rcd.query: |
        SELECT
          optimization_type,
          improvement_percentage,
          applied_at
        FROM rcd_optimization_history
        WHERE agent_id = '${input.agent_id}'
        ORDER BY applied_at DESC LIMIT 10

    - compile_agent_insights: {
        patterns: "${applicable_patterns}",
        optimizations: "${optimization_history}",
        agent_id: "${input.agent_id}"
      }

    - return: {
        applicable_patterns: "${compiled_insights.patterns}",
        successful_optimizations: "${compiled_insights.optimizations}",
        recommendations: "${compiled_insights.recommendations}",
        confidence_score: "${compiled_insights.overall_confidence}"
      }

concern:
  if: "${learning_cycle_failures > 3 || pattern_discovery_rate < 0.1}"
  priority: 1
  action:
    - tamr.log: {
        event: "learning_engine_performance_concern",
        failures: "${learning_cycle_failures}",
        discovery_rate: "${pattern_discovery_rate}"
      }
    - run: ["learning-engine.r", "self_evolution_check"]
    - condition:
        if: "${learning_degradation_critical}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🧠 Learning Engine performance degraded. Discovery rate: ${pattern_discovery_rate}"
              buttons: ["Reset Learning", "Manual Optimization", "Emergency Recovery"]
