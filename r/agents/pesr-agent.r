# r/agents/pesr-agent.r
# Proactive External Signal Reasoner with RCD integration - Autonomous monitoring and pattern detection

self:
  id: "pesr-agent"
  intent: "Monitor external signals, detect patterns, and proactively trigger responses"
  version: "2.0.0"
  template: "signal_monitoring"

aam:
  require_role: "system"
  allow_actions: ["monitor", "detect", "analyze", "alert"]

dependencies:
  services: ["webhook_receiver", "api_poller", "file_watcher"]
  agents: ["ordr-agent", "system-doctor"]

# RCD Meta-tagging for signal intelligence
rcd:
  meta_tags:
    system_role: ["signal_monitor", "pattern_detector", "proactive_analyzer"]
    capabilities: [
      "signal_collection", "pattern_recognition", "anomaly_detection",
      "trend_analysis", "predictive_monitoring", "external_signal_processing",
      "cascade_detection", "signal_correlation", "threshold_optimization"
    ]
    data_flow_type: ["input_collector", "pattern_processor", "alert_generator"]
    stability_level: "critical"
    learning_focus: ["detection_accuracy", "false_positive_reduction", "pattern_discovery"]
    complexity_score: 5

  relationships:
    monitors: ["external_apis", "webhook_endpoints", "system_metrics", "database_events"]
    reports_to: ["system-doctor", "ordr-agent", "system_admin"]
    collaborates_with: ["system-doctor", "ordr-agent", "learning-engine"]
    manages: ["signal_sources", "detection_thresholds", "pattern_library"]
    feeds_data_to: ["ordr-agent", "system-doctor"]

  signal_schemas:
    system_health_signals:
      patterns: ["cpu_spike", "memory_leak", "disk_full", "connection_timeout"]
      thresholds: { "cpu_spike": 85, "memory_leak": 90, "disk_full": 95 }
      correlation_windows: "5m"

    external_service_signals:
      patterns: ["api_timeout", "rate_limit", "auth_failure", "service_down"]
      thresholds: { "timeout_ms": 5000, "error_rate": 0.1, "response_code": [400, 500] }
      correlation_windows: "10m"

    business_process_signals:
      patterns: ["payment_delay", "user_complaint", "workflow_stuck"]
      thresholds: { "delay_minutes": 30, "complaint_sentiment": -0.5 }
      correlation_windows: "30m"

  learning_patterns:
    detection_accuracy:
      track_metrics: ["true_positives", "false_positives", "missed_signals", "detection_latency"]
      optimization_target: "maximize_accuracy_minimize_noise"

    pattern_discovery:
      track_metrics: ["new_patterns_found", "pattern_validation_rate", "correlation_strength"]
      optimization_target: "improve_pattern_quality"

    threshold_optimization:
      track_metrics: ["optimal_threshold_drift", "threshold_effectiveness"]
      optimization_target: "dynamic_threshold_adjustment"

  performance_tracking:
    key_metrics: ["signal_processing_time", "detection_accuracy", "false_positive_rate", "pattern_discovery_rate"]
    baseline_performance: {
      "signal_processing_time_ms": 200,
      "detection_accuracy": 0.85,
      "false_positive_rate": 0.15,
      "pattern_discovery_rate": 0.1
    }
    improvement_targets: {
      "signal_processing_time_ms": 100,
      "detection_accuracy": 0.95,
      "false_positive_rate": 0.05,
      "pattern_discovery_rate": 0.2
    }

operations:
  initialize:
    - tamr.log: { event: "pesr_agent_started", signals_monitored: "${config.signals}" }
    - setup_signal_sources: {}
    - start_monitoring_loops: {}
    # RCD Registration
    - rcd_register_signal_agent: {}
    - rcd_initialize_pattern_library: {}
    - rcd_load_learned_patterns: {}
    - respond: "🔍 PESR Agent initialized - Monitoring ${signal_sources.length} signal sources with RCD intelligence"

  monitor_continuously:
    - rcd_start_performance_tracking: { operation: "monitor_continuously" }

    - loop:
        while: "${monitoring_enabled}"
        do:
          - collect_signals: { sources: "${active_sources}" }
          - rcd_log_signal_collection: {
              collected_count: "${collected_signals.length}",
              sources: "${active_sources.length}"
            }

          - analyze_patterns: { signals: "${collected_signals}", window: "5m" }
          - rcd_validate_pattern_analysis: {
              patterns_found: "${signal_patterns}",
              analysis_quality: "${pattern_analysis_quality}"
            }

          - detect_anomalies: { patterns: "${signal_patterns}" }
          - rcd_score_anomaly_detection: {
              anomalies: "${detected_anomalies}",
              confidence_scores: "${anomaly_confidence}"
            }

          - condition:
              if: "${detected_anomalies.length > 0}"
              then:
                - loop:
                    forEach: "${detected_anomalies}"
                    do:
                      - classify_signal: { anomaly: "${item}" }
                      - rcd_store_signal_pattern: {
                          pattern_type: "${signal_classification.type}",
                          pattern_data: "${item}",
                          confidence: "${signal_classification.confidence}"
                        }
                      - route_to_ordr: {
                          signal: "${item}",
                          classification: "${signal_classification}",
                          priority: "${item.severity}"
                        }
          - wait: { seconds: 30 }

    - rcd_complete_performance_tracking: { operation: "monitor_continuously", success: true }

  setup_signal_sources:
    - rcd_start_performance_tracking: { operation: "setup_signal_sources" }

    - config.get: { key: "PESR_SIGNAL_SOURCES" }
    - condition:
        if: "!${config_value}"
        then:
          - config.set:
              key: "PESR_SIGNAL_SOURCES"
              value: [
                {
                  "type": "webhook",
                  "endpoint": "/signals/external",
                  "patterns": ["payment_delay", "api_timeout", "user_complaint"]
                },
                {
                  "type": "database_poll",
                  "table": "system_metrics",
                  "frequency": "1m",
                  "patterns": ["cpu_spike", "memory_leak", "disk_full"]
                },
                {
                  "type": "api_monitor",
                  "services": ["xero", "slack", "email"],
                  "patterns": ["rate_limit", "auth_failure", "service_down"]
                }
              ]
    - initialize_sources: { sources: "${config_value}" }
    - rcd_register_signal_sources: { sources: "${config_value}" }

    - rcd_complete_performance_tracking: { operation: "setup_signal_sources", success: true }

  collect_signals:
    - rcd_start_performance_tracking: { operation: "collect_signals" }

    - parallel.execute:
        tasks:
          - name: "webhook_signals"
            action: { rcd.query: { table: "webhook_events", since: "-5m" } }
          - name: "metric_signals"
            action: { rcd.query: { table: "system_metrics", since: "-5m" } }
          - name: "log_signals"
            action: { tamr.query: { event: "error", since: "-5m", limit: 100 } }
          - name: "external_api_signals"
            action: { check_external_apis: {} }

    - merge_signal_data: { parallel_results: "${parallel_results}" }
    - rcd_enrich_signals: {
        signals: "${merged_signals}",
        enrichment_type: "context_correlation"
      }

    - rcd_complete_performance_tracking: { operation: "collect_signals", success: true }
    - return: "${enriched_signals}"

  analyze_patterns:
    - rcd_start_performance_tracking: { operation: "analyze_patterns" }

    - rcd_apply_learned_patterns: {
        signals: "${input.signals}",
        pattern_library: "${cached_patterns}"
      }

    - infer.analyzeSignals:
        signals: "${input.signals}"
        context: "ROL3 system monitoring and anomaly detection"
        patterns_to_detect: [
          "cascading_failures",
          "performance_degradation",
          "external_service_issues",
          "user_behavior_anomalies",
          "security_incidents",
          "business_process_delays"
        ]

    - store_analysis: {
        analysis: "${signal_analysis}",
        timestamp: "${timestamp}"
      }

    - rcd_evaluate_pattern_quality: {
        analysis: "${signal_analysis}",
        applied_patterns: "${applied_patterns}",
        new_discoveries: "${novel_patterns}"
      }

    - rcd_complete_performance_tracking: { operation: "analyze_patterns", success: true }
    - return: "${signal_analysis}"

  detect_anomalies:
    - rcd_start_performance_tracking: { operation: "detect_anomalies" }

    - rcd_get_dynamic_thresholds: {
        signal_types: "${input.patterns.signal_types}",
        historical_context: "7d"
      }

    - condition:
        if: "${input.patterns.anomaly_score > dynamic_thresholds.anomaly_threshold}"
        then:
          - create_anomaly_record: {
              type: "high_confidence_anomaly",
              score: "${input.patterns.anomaly_score}",
              signals: "${input.patterns.contributing_signals}",
              predicted_impact: "${input.patterns.impact_analysis}",
              threshold_used: "${dynamic_thresholds.anomaly_threshold}"
            }

    - condition:
        if: "${input.patterns.trend_deviation > dynamic_thresholds.trend_threshold}"
        then:
          - create_anomaly_record: {
              type: "trend_deviation",
              deviation: "${input.patterns.trend_deviation}",
              baseline: "${input.patterns.baseline_trend}",
              current: "${input.patterns.current_trend}",
              threshold_used: "${dynamic_thresholds.trend_threshold}"
            }

    - condition:
        if: "${input.patterns.cascade_risk > dynamic_thresholds.cascade_threshold}"
        then:
          - create_anomaly_record: {
              type: "cascade_risk",
              risk_score: "${input.patterns.cascade_risk}",
              affected_systems: "${input.patterns.at_risk_systems}",
              threshold_used: "${dynamic_thresholds.cascade_threshold}"
            }

    - filter_critical_anomalies: { anomalies: "${detected_anomalies}" }
    - rcd_track_detection_accuracy: {
        detected: "${critical_anomalies}",
        thresholds_used: "${dynamic_thresholds}"
      }

    - rcd_complete_performance_tracking: { operation: "detect_anomalies", success: true }
    - return: "${critical_anomalies}"

  classify_signal:
    - rcd_start_performance_tracking: { operation: "classify_signal" }

    - rcd_check_known_classifications: {
        signal: "${input.anomaly}",
        pattern_library: "${classification_patterns}"
      }

    - condition:
        if: "${known_classification.found}"
        then:
          - apply_known_classification: {
              classification: "${known_classification}",
              confidence_boost: 0.2
            }
        else:
          - infer.classifySignal:
              signal: "${input.anomaly}"
              categories: [
                "technical_incident",
                "business_process_issue",
                "external_dependency_failure",
                "user_experience_degradation",
                "security_concern",
                "performance_issue"
              ]

    - determine_urgency: { classification: "${signal_classification}" }
    - assign_routing_target: {
        classification: "${signal_classification}",
        urgency: "${urgency_level}"
      }

    - rcd_store_classification_result: {
        signal: "${input.anomaly}",
        classification: "${signal_classification}",
        method: "${classification_method}",
        confidence: "${final_confidence}"
      }

    - rcd_complete_performance_tracking: { operation: "classify_signal", success: true }
    - return: {
        classification: "${signal_classification}",
        urgency: "${urgency_level}",
        routing_target: "${routing_target}",
        recommended_actions: "${classification.suggested_actions}",
        confidence: "${final_confidence}"
      }

  route_to_ordr:
    - rcd_start_performance_tracking: { operation: "route_to_ordr" }

    - tamr.log: {
        event: "pesr_signal_detected",
        signal: "${input.signal}",
        classification: "${input.classification}",
        routing_priority: "${input.priority}"
      }

    - rcd_track_signal_routing: {
        signal: "${input.signal}",
        target: "ordr-agent",
        priority: "${input.priority}"
      }

    - run: ["r/agents/ordr-agent.r", "route_signal", {
        signal: "${input.signal}",
        classification: "${input.classification}",
        priority: "${input.priority}",
        source: "pesr-agent",
        timestamp: "${timestamp}",
        confidence: "${input.classification.confidence}"
      }]

    - rcd_complete_performance_tracking: { operation: "route_to_ordr", success: true }

  handle_signal_request:
    - rcd_start_performance_tracking: { operation: "handle_signal_request" }

    # Called by other agents to request signal monitoring
    - validate_signal_request: { request: "${input}" }
    - add_signal_source: {
        agent_id: "${input.requesting_agent}",
        signal_type: "${input.signal_type}",
        patterns: "${input.patterns}",
        callback: "${input.callback_operation}"
      }
    - rcd_register_new_signal_source: {
        source: "${signal_source}",
        requesting_agent: "${input.requesting_agent}"
      }

    - tamr.log: {
        event: "signal_monitoring_added",
        for_agent: "${input.requesting_agent}",
        signal_type: "${input.signal_type}"
      }

    - rcd_complete_performance_tracking: { operation: "handle_signal_request", success: true }
    - respond: "✅ Signal monitoring active for ${input.signal_type}"

  self_optimize:
    - rcd_start_performance_tracking: { operation: "self_optimize" }

    - tamr.query: {
        agent_id: "pesr-agent",
        since: "-7d",
        event: "pesr_signal_detected"
      }
    - analyze_detection_accuracy: { recent_detections: "${query_result}" }
    - rcd_comprehensive_learning_analysis: {
        detection_history: "${query_result}",
        accuracy_analysis: "${detection_accuracy}",
        focus_areas: ["threshold_optimization", "pattern_refinement", "false_positive_reduction"]
      }

    - infer.optimizePatterns:
        current_patterns: "${signal_patterns}",
        performance_data: "${detection_accuracy}",
        feedback: "${false_positive_rate}",
        rcd_insights: "${learning_analysis}"

    - condition:
        if: "${optimized_patterns.improvement_score > 0.1}"
        then:
          - update_signal_patterns: { new_patterns: "${optimized_patterns}" }
          - rcd_update_pattern_library: {
              optimized_patterns: "${optimized_patterns}",
              improvement_score: "${optimized_patterns.improvement_score}"
            }
          - self.modify: {
              changes: {
                operations: {
                  analyze_patterns: "${optimized_patterns.enhanced_operations}"
                }
              }
            }
          - tamr.log: {
              event: "pesr_self_optimization",
              improvement_score: "${optimized_patterns.improvement_score}"
            }
          - rcd_store_evolution_event: {
              evolution_type: "pattern_optimization",
              improvement: "${optimized_patterns.improvement_score}"
            }

    - rcd_complete_performance_tracking: { operation: "self_optimize", success: true }

  get_signal_patterns:
    # API for other agents to query signal patterns
    - rcd_start_performance_tracking: { operation: "get_signal_patterns" }

    - rcd.query_patterns: {
        pattern_types: "${input.pattern_types}",
        time_window: "${input.time_window}",
        min_confidence: 0.7,
        discovered_by: "pesr-agent"
      }

    - filter_relevant_patterns: {
        patterns: "${query_result}",
        context: "${input.context}",
        requesting_agent: "${context.agentId}"
      }

    - rcd_complete_performance_tracking: { operation: "get_signal_patterns", success: true }
    - return: "${filtered_patterns}"

  # RCD Integration Operations
  rcd_register_signal_agent:
    - rcd.register_agent: {
        agent_id: "${self.id}",
        capabilities: "${rcd.meta_tags.capabilities}",
        relationships: "${rcd.relationships}",
        signal_schemas: "${rcd.signal_schemas}",
        performance_baseline: "${rcd.performance_tracking.baseline_performance}"
      }

  rcd_initialize_pattern_library:
    - rcd.initialize_pattern_library: {
        agent_id: "${self.id}",
        pattern_categories: ["signal_patterns", "anomaly_patterns", "classification_patterns"],
        learning_focus: "${rcd.learning_patterns}"
      }

  rcd_load_learned_patterns:
    - rcd.query_patterns: {
        discovered_by: "${self.id}",
        min_confidence: 0.6,
        active: true
      }
    - cache_patterns_for_runtime: { patterns: "${learned_patterns}" }

  rcd_start_performance_tracking:
    - tamr.remember: { key: "operation_start_time", value: "${timestamp}" }
    - tamr.remember: { key: "current_operation", value: "${input.operation}" }

  rcd_complete_performance_tracking:
    - calculate_operation_performance: {
        operation: "${input.operation}",
        start_time: "${memory.operation_start_time}",
        end_time: "${timestamp}",
        success: "${input.success}"
      }
    - rcd.log_performance: {
        agent_id: "${self.id}",
        operation: "${input.operation}",
        metrics: "${operation_performance}",
        success: "${input.success}"
      }
    - run: ["pesr-agent.r", "rcd_adaptive_learning"]

  rcd_adaptive_learning:
    - condition:
        if: "${operation_performance.below_baseline || !input.success}"
        then:
          - rcd.trigger_learning: {
              agent_id: "${self.id}",
              focus_area: "${memory.current_operation}",
              performance_data: "${operation_performance}",
              signal_context: "${current_signals}"
            }

  rcd_store_signal_pattern:
    - rcd.store_pattern: {
        pattern_type: "${input.pattern_type}",
        pattern_data: "${input.pattern_data}",
        discovered_by: "${self.id}",
        confidence: "${input.confidence}",
        context: "signal_monitoring",
        signal_metadata: "${signal_enrichment_data}"
      }

  rcd_validate_pattern_analysis:
    - evaluate_pattern_quality: {
        patterns: "${input.patterns_found}",
        analysis_metrics: "${input.analysis_quality}"
      }
    - rcd.log_analysis_quality: {
        agent_id: "${self.id}",
        patterns_count: "${input.patterns_found.length}",
        quality_score: "${pattern_quality.score}",
        timestamp: "${timestamp}"
      }

  rcd_get_dynamic_thresholds:
    - rcd.query_threshold_history: {
        signal_types: "${input.signal_types}",
        time_window: "${input.historical_context}"
      }
    - calculate_adaptive_thresholds: {
        historical_data: "${threshold_history}",
        current_baseline: "${baseline_metrics}",
        performance_target: "${rcd.performance_tracking.improvement_targets}"
      }
    - return: "${adaptive_thresholds}"

  rcd_track_detection_accuracy:
    - update_accuracy_metrics: {
        detected_anomalies: "${input.detected}",
        thresholds_used: "${input.thresholds_used}",
        timestamp: "${timestamp}"
      }
    - rcd.log_detection_metrics: {
        agent_id: "${self.id}",
        accuracy_metrics: "${updated_metrics}",
        threshold_effectiveness: "${threshold_performance}"
      }

  rcd_comprehensive_learning_analysis:
    - rcd.analyze_agent_learning: {
        agent_id: "${self.id}",
        focus_areas: "${input.focus_areas}",
        performance_data: "${input.accuracy_analysis}",
        detection_history: "${input.detection_history}"
      }
    - identify_learning_opportunities: {
        learning_analysis: "${learning_analysis}",
        performance_gaps: "${performance_gaps}"
      }

  rcd_update_pattern_library:
    - rcd.update_patterns: {
        agent_id: "${self.id}",
        new_patterns: "${input.optimized_patterns}",
        improvement_metrics: "${input.improvement_score}",
        update_type: "optimization"
      }
    - refresh_cached_patterns: { updated_patterns: "${pattern_updates}" }

  rcd_store_evolution_event:
    - rcd.store_evolution: {
        agent_id: "${self.id}",
        evolution_type: "${input.evolution_type}",
        improvement_data: "${input.improvement}",
        trigger: "self_optimization"
      }

  # Collaboration operations
  collaborate_with_system_doctor:
    - condition:
        if: "${critical_system_signals_detected}"
        then:
          - run: ["r/agents/system-doctor.r", "emergency_signal_alert", {
              signals: "${critical_signals}",
              urgency: "high",
              source: "pesr-agent"
            }]

  provide_signals_to_ordr:
    - rcd.query_recent_signals: {
        time_window: "1h",
        severity: ["medium", "high", "critical"]
      }
    - format_signals_for_routing: { signals: "${recent_signals}" }
    - return: "${formatted_signals}"

concern:
  if: "${false_positive_rate > 0.3 || missed_signals > 5}"
  priority: 2
  action:
    - tamr.log: { event: "pesr_accuracy_concern", stats: "${detection_stats}" }
    - run: ["pesr-agent.r", "self_optimize"]
    - condition:
        if: "${optimization_failed}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🔍 PESR Agent accuracy degraded. Manual tuning may be needed."
              buttons: ["Review Patterns", "Reset to Defaults", "Disable PESR"]

incoming:
  webhook:
    path: "/signals/external"
    method: "POST"
    operation: "process_external_signal"

# Enhanced signal pattern definitions with RCD metadata
signal_patterns:
  cascading_failures:
    window: "10m"
    threshold: 3
    correlation: "service_dependency_chain"
    rcd_metadata:
      pattern_type: "system_critical"
      learning_priority: "high"
      confidence_threshold: 0.8

  performance_degradation:
    window: "15m"
    metrics: ["response_time", "error_rate", "throughput"]
    baseline_deviation: 2.0
    rcd_metadata:
      pattern_type: "performance_trend"
      learning_priority: "medium"
      adaptive_thresholds: true

  external_service_issues:
    window: "5m"
    services: ["xero", "slack", "stripe", "github"]
    failure_threshold: 0.5
    rcd_metadata:
      pattern_type: "external_dependency"
      learning_priority: "medium"
      correlation_analysis: true
