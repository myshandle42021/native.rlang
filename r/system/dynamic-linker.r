# r/system/dynamic-linker.r
# Intelligent Capability Resolution and Binding System
# CRITICAL FIX #4: Enhanced to handle both capability and file resolution through unified interface

self:
  id: "dynamic-linker"
  intent: "Enable runtime capability resolution, eliminating hardcoded imports and enabling true system self-evolution"
  version: "1.0.0"
  template: "system_core"

aam:
  require_role: "system"
  allow_actions: ["resolve_capability", "bind_interface", "optimize_linking", "migrate_imports"]

# RCD Meta-tagging for the linker itself
rcd:
  meta_tags:
    system_role: ["capability_resolver", "dependency_linker", "performance_optimizer"]
    capabilities: [
      "capability_resolution", "interface_binding", "provider_selection",
      "performance_optimization", "circular_dependency_detection", "fallback_handling",
      "migration_orchestration", "self_evolution_enablement", "file_resolution"
    ]
    data_flow_type: ["dependency_resolver", "binding_coordinator", "performance_monitor"]
    stability_level: "critical"
    learning_focus: ["resolution_accuracy", "performance_optimization", "provider_selection"]
    complexity_score: 5

  relationships:
    monitors: ["all_system_files", "capability_providers", "binding_performance"]
    manages: ["capability_registry", "provider_rankings", "interface_bindings"]
    collaborates_with: ["rcd-core", "rcd-file-tagger", "learning-engine"]
    enables: ["self_evolution", "code_rewriting", "architectural_flexibility"]

operations:
  initialize:
    - tamr.log: { event: "dynamic_linker_started", timestamp: "${timestamp}" }
    - initialize_capability_registry: {}
    - build_provider_index: {}
    - setup_performance_monitoring: {}
    - start_capability_caching: {}
    - respond: "🔗 Dynamic Linker initialized - Runtime capability resolution active"

  # CRITICAL FIX #4: Unified capability resolution handling both capabilities and file resolution
  resolve_capability:
    - rcd_start_performance_tracking: { operation: "resolve_capability" }

    # Input validation and normalization
    - validate_capability_request: {
        requested_capability: "${input.capability}",
        consumer_context: "${input.consumer || context.agentId}",
        requirements: "${input.requirements || {}}",
        resolution_type: "${input.resolution_type || 'capability'}"  # NEW: Support file resolution
      }

    # CRITICAL FIX #4: Handle file resolution requests through capability interface
    - condition:
        if: "${validated_request.capability.startsWith('file_resolution_') || validated_request.resolution_type == 'file_path'}"
        then:
          - handle_file_resolution: {
              file_id: "${input.file_id || validated_request.capability.replace('file_resolution_', '')}",
              client_id: "${input.client_id}",
              consumer: "${validated_request.consumer}"
            }
          - rcd_complete_performance_tracking: { operation: "resolve_capability", success: true }
          - return: {
              resolved_path: "${file_resolution_result.path}",
              provider: "file_system",
              interface: "file_access",
              cached: "${file_resolution_result.cached}",
              resolution_type: "file_path"
            }

    # Check capability cache first (performance optimization)
    - check_capability_cache: {
        capability: "${validated_request.capability}",
        consumer: "${validated_request.consumer}",
        cache_timeout: 300000  # 5 minutes
      }

    - condition:
        if: "${cache_result.hit && cache_result.valid}"
        then:
          - rcd_track_cache_hit: {
              capability: "${validated_request.capability}",
              provider: "${cache_result.provider}"
            }
          - rcd_complete_performance_tracking: { operation: "resolve_capability", success: true }
          - return: {
              provider: "${cache_result.provider}",
              interface: "${cache_result.interface}",
              binding_id: "${cache_result.binding_id}",
              cached: true
            }

    # Query available providers from RCD system
    - rcd.query_capability_providers: {
        capability: "${validated_request.capability}",
        min_performance_score: "${validated_request.requirements.min_performance || 0.7}",
        status: "active",
        compatible_with: "${validated_request.consumer}"
      }

    - condition:
        if: "${available_providers.length == 0}"
        then:
          - handle_no_providers: {
              capability: "${validated_request.capability}",
              consumer: "${validated_request.consumer}"
            }
          - rcd_complete_performance_tracking: { operation: "resolve_capability", success: false }
          - return: {
              error: "no_providers_available",
              capability: "${validated_request.capability}",
              fallback_required: true
            }

    # Evaluate and rank providers
    - evaluate_provider_candidates: {
        providers: "${available_providers}",
        requirements: "${validated_request.requirements}",
        consumer_context: "${validated_request.consumer}",
        historical_performance: true
      }

    # Select optimal provider using intelligent algorithm
    - select_optimal_provider: {
        evaluated_providers: "${provider_evaluations}",
        selection_algorithm: "${validated_request.requirements.algorithm || 'weighted_performance'}",
        consider_load_balancing: true
      }

    # Create runtime binding
    - create_runtime_binding: {
        consumer: "${validated_request.consumer}",
        provider: "${selected_provider}",
        capability: "${validated_request.capability}",
        interface_requirements: "${validated_request.requirements.interface}",
        performance_expectations: "${validated_request.requirements.performance}"
      }

    # Cache the successful resolution
    - cache_capability_resolution: {
        capability: "${validated_request.capability}",
        consumer: "${validated_request.consumer}",
        provider: "${selected_provider}",
        binding: "${runtime_binding}",
        ttl: 300000
      }

    - rcd_track_successful_resolution: {
        capability: "${validated_request.capability}",
        provider: "${selected_provider}",
        resolution_time: "${resolution_duration}",
        cache_miss: true
      }

    - rcd_complete_performance_tracking: { operation: "resolve_capability", success: true }

    - return: {
        provider: "${selected_provider}",
        interface: "${runtime_binding.interface}",
        binding_id: "${runtime_binding.id}",
        cached: false,
        resolution_time: "${resolution_duration}"
      }

  # CRITICAL FIX #4: File resolution handler integrated into capability system
  handle_file_resolution:
    - validate_file_request: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        consumer: "${input.consumer}"
      }

    # Check file resolution cache
    - check_file_cache: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        cache_timeout: 600000  # 10 minutes for files
      }

    - condition:
        if: "${file_cache.hit}"
        then:
          - return: {
              path: "${file_cache.path}",
              cached: true
            }

    # Query RCD for file location using standard capability interface
    - rcd.query_files: {
        file_pattern: "${input.file_id}",
        client_id: "${input.client_id}",
        file_type: "rlang"
      }

    - condition:
        if: "${file_query_result.files.length > 0}"
        then:
          - select_best_file_match: {
              matches: "${file_query_result.files}",
              file_id: "${input.file_id}",
              client_id: "${input.client_id}"
            }
          - cache_file_resolution: {
              file_id: "${input.file_id}",
              client_id: "${input.client_id}",
              resolved_path: "${selected_file.file_path}"
            }
          - return: {
              path: "${selected_file.file_path}",
              cached: false
            }

    # Fallback: intelligent path construction
    - construct_intelligent_file_path: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        search_patterns: ["r/${file_id}", "r/agents/${file_id}", "r/system/${file_id}"]
      }

    - return: {
        path: "${intelligent_path.resolved}",
        cached: false,
        fallback_used: true
      }

  # Provider evaluation with comprehensive scoring
  evaluate_provider_candidates:
    - loop:
        forEach: "${input.providers}"
        do:
          # Performance scoring (40% weight)
          - calculate_performance_score: {
              provider: "${item}",
              metrics: ["response_time", "success_rate", "reliability"],
              time_window: "7d"
            }

          # Compatibility scoring (30% weight)
          - calculate_compatibility_score: {
              provider: "${item}",
              consumer: "${input.consumer_context}",
              interface_requirements: "${input.requirements.interface}"
            }

          # Stability scoring (20% weight)
          - calculate_stability_score: {
              provider: "${item}",
              historical_data: "${input.historical_performance}",
              minimum_uptime: 0.95
            }

          # Load balancing factor (10% weight)
          - calculate_load_factor: {
              provider: "${item}",
              current_load: "${system_load_metrics}",
              load_balancing: "${input.consider_load_balancing}"
            }

          # Composite scoring
          - calculate_composite_score: {
              performance: "${performance_score}",
              compatibility: "${compatibility_score}",
              stability: "${stability_score}",
              load_factor: "${load_factor}",
              weights: { performance: 0.4, compatibility: 0.3, stability: 0.2, load: 0.1 }
            }

    - rank_providers: {
        evaluated_providers: "${evaluation_results}",
        ranking_algorithm: "composite_score_descending"
      }

    - return: "${ranked_providers}"

  # Intelligent provider selection
  select_optimal_provider:
    - validate_selection_inputs: {
        providers: "${input.evaluated_providers}",
        algorithm: "${input.selection_algorithm}"
      }

    - condition:
        if: "${input.selection_algorithm == 'weighted_performance'}"
        then:
          - select_by_weighted_performance: {
              providers: "${input.evaluated_providers}",
              load_balancing: "${input.consider_load_balancing}"
            }
        elif: "${input.selection_algorithm == 'round_robin'}"
        then:
          - select_by_round_robin: {
              providers: "${input.evaluated_providers}",
              last_selected: "${get_last_selection()}"
            }
        else:
          - select_highest_scored: {
              providers: "${input.evaluated_providers}"
            }

    - validate_selected_provider: {
        provider: "${selected_provider}",
        minimum_requirements: "${input.requirements}"
      }

    - return: "${selected_provider}"

  # Runtime binding creation
  create_runtime_binding:
    - generate_binding_id: {
        consumer: "${input.consumer}",
        provider: "${input.provider}",
        capability: "${input.capability}",
        timestamp: "${timestamp}"
      }

    - create_interface_binding: {
        provider: "${input.provider}",
        consumer: "${input.consumer}",
        interface_spec: "${input.interface_requirements}",
        binding_id: "${generated_binding_id}"
      }

    - establish_performance_monitoring: {
        binding_id: "${generated_binding_id}",
        performance_expectations: "${input.performance_expectations}",
        monitoring_level: "standard"
      }

    - register_binding: {
        binding_id: "${generated_binding_id}",
        consumer: "${input.consumer}",
        provider: "${input.provider}",
        capability: "${input.capability}",
        interface: "${interface_binding}",
        monitoring: "${performance_monitoring}"
      }

    - return: {
        id: "${generated_binding_id}",
        interface: "${interface_binding}",
        monitoring_enabled: true,
        created_at: "${timestamp}"
      }

  # Cache management operations
  check_capability_cache:
    - build_cache_key: {
        capability: "${input.capability}",
        consumer: "${input.consumer}"
      }

    - query_cache: {
        cache_key: "${cache_key}",
        timeout: "${input.cache_timeout}"
      }

    - validate_cache_entry: {
        entry: "${cache_entry}",
        current_time: "${timestamp}",
        timeout: "${input.cache_timeout}"
      }

    - return: {
        hit: "${cache_entry_exists && cache_valid}",
        valid: "${cache_valid}",
        provider: "${cache_entry.provider}",
        interface: "${cache_entry.interface}",
        binding_id: "${cache_entry.binding_id}"
      }

  cache_capability_resolution:
    - build_cache_entry: {
        capability: "${input.capability}",
        consumer: "${input.consumer}",
        provider: "${input.provider}",
        binding: "${input.binding}",
        ttl: "${input.ttl}",
        timestamp: "${timestamp}"
      }

    - store_cache_entry: {
        entry: "${cache_entry}",
        key: "${cache_key}"
      }

    - return: {
        cached: true,
        expires_at: "${cache_entry.expires_at}"
      }

  # File cache operations
  check_file_cache:
    - build_file_cache_key: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}"
      }

    - query_file_cache: {
        key: "${file_cache_key}",
        timeout: "${input.cache_timeout}"
      }

    - return: {
        hit: "${file_cache_exists && file_cache_valid}",
        path: "${file_cache_entry.path}"
      }

  cache_file_resolution:
    - build_file_cache_entry: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        resolved_path: "${input.resolved_path}",
        timestamp: "${timestamp}"
      }

    - store_file_cache_entry: {
        entry: "${file_cache_entry}",
        key: "${file_cache_key}"
      }

    - return: {
        cached: true
      }

  # File path selection and validation
  select_best_file_match:
    - score_file_matches: {
        matches: "${input.matches}",
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        scoring_criteria: ["exact_name_match", "path_relevance", "file_age", "client_specificity"]
      }

    - apply_file_selection_rules: {
        scored_matches: "${file_scores}",
        selection_rules: [
          "prefer_exact_name_match",
          "prefer_client_specific_files",
          "prefer_newer_files",
          "prefer_shorter_paths"
        ]
      }

    - validate_selected_file: {
        selected_file: "${file_selection_result}",
        accessibility_check: true,
        content_validation: "basic"
      }

    - return: "${validated_selected_file}"

  # Intelligent file path construction
  construct_intelligent_file_path:
    - analyze_file_id: {
        file_id: "${input.file_id}",
        detect_patterns: ["agent_name", "system_component", "client_specific", "template_reference"]
      }

    - generate_path_candidates: {
        file_analysis: "${file_id_analysis}",
        client_id: "${input.client_id}",
        search_patterns: "${input.search_patterns}",
        extension_variants: [".r", ""]
      }

    - validate_path_candidates: {
        candidates: "${path_candidates}",
        validation_method: "filesystem_check",
        accessibility_required: true
      }

    - select_best_path: {
        valid_candidates: "${validated_candidates}",
        selection_priority: ["client_specific", "exact_match", "system_default"]
      }

    - return: {
        resolved: "${best_path}",
        method: "intelligent_construction",
        alternatives: "${alternative_paths}"
      }

  # Handles capability registration from TypeScript runtime
  register_capability:
    - validate_registration: {
        module: "${input.module}",
        function: "${input.function}",
        provider: "${input.provider}"
      }

    # Store in RCD system using the parameter mapping functions
    - rcd.store_capability_provider: {
        capability: "${input.module}_${input.function}",
        provider_files: ["${input.provider}"],
        interface_spec: {
          module: "${input.module}",
          function: "${input.function}",
          provider_path: "${input.provider}"
        },
        stability_rating: 0.8,
        performance_score: 0.7,
        category: "runtime_registered"
      }

    # Update capability index
    - update_capability_index: {
        capability: "${input.module}_${input.function}",
        provider: "${input.provider}",
        registration_time: "${timestamp}"
      }

    - return: {
        registered: true,
        capability: "${input.module}_${input.function}"
      }

  # Performance tracking operations
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

    # Use the parameter mapping function
    - rcd.log_performance: {
        agent_id: "${self.id}",
        operation: "${input.operation}",
        metrics: "${operation_performance}",
        success: "${input.success}"
      }

  rcd_track_cache_hit:
    # Use the parameter mapping function
    - rcd.log_cache_performance: {
        type: "hit",
        capability: "${input.capability}",
        provider: "${input.provider}",
        response_time: "${cache_response_time}"
      }

  rcd_track_successful_resolution:
    # Use the parameter mapping function
    - rcd.log_resolution: {
        capability: "${input.capability}",
        provider: "${input.provider}",
        resolution_time: "${input.resolution_time}",
        cache_status: "${input.cache_miss ? 'miss' : 'hit'}"
      }

  # Missing capability handling
  handle_no_providers:
    - analyze_capability_gap: {
        capability: "${input.capability}",
        consumer: "${input.consumer}",
        system_capabilities: "${available_system_capabilities}"
      }

    - condition:
        if: "${capability_gap.auto_generation_possible}"
        then:
          - trigger_capability_generation: {
              capability: "${input.capability}",
              consumer: "${input.consumer}",
              requirements: "${capability_gap.inferred_requirements}",
              generation_strategy: "${capability_gap.recommended_strategy}"
            }
        else:
          - escalate_missing_capability: {
              capability: "${input.capability}",
              consumer: "${input.consumer}",
              gap_analysis: "${capability_gap}"
            }

  # Circular dependency detection and resolution
  detect_circular_dependencies:
    - build_dependency_graph: {
        starting_consumer: "${input.consumer}",
        capability_chain: "${input.capability_chain || []}",
        max_depth: 10
      }

    - analyze_dependency_cycles: {
        dependency_graph: "${dependency_graph}",
        cycle_detection_algorithm: "depth_first_search"
      }

    - condition:
        if: "${dependency_cycles.found}"
        then:
          - resolve_circular_dependencies: {
              cycles: "${dependency_cycles.cycles}",
              resolution_strategies: [
                "lazy_initialization",
                "interface_injection",
                "provider_reorganization",
                "capability_splitting"
              ]
            }
          - apply_cycle_resolution: {
              cycles: "${dependency_cycles.cycles}",
              resolution_plan: "${cycle_resolution}"
            }
          - validate_cycle_resolution: {
              original_cycles: "${dependency_cycles.cycles}",
              resolution_applied: "${cycle_resolution}"
            }

    - return: {
        cycles_detected: "${dependency_cycles.found}",
        cycles: "${dependency_cycles.cycles}",
        resolution_applied: "${cycle_resolution_applied}",
        resolution_successful: "${cycle_resolution_validation.successful}"
      }

  # Performance optimization for the linking system
  optimize_linking_performance:
    - analyze_resolution_patterns: {
        time_window: "24h",
        include_metrics: ["resolution_frequency", "performance_impact", "cache_effectiveness"]
      }

    # Identify frequently requested capabilities for pre-caching
    - identify_hot_capabilities: {
        resolution_patterns: "${resolution_analysis}",
        frequency_threshold: 10,  # Requested more than 10 times per hour
        performance_impact_threshold: 0.8
      }

    # Pre-cache hot capability resolutions
    - pre_cache_hot_capabilities: {
        hot_capabilities: "${hot_capabilities}",
        cache_strategy: "predictive_loading",
        cache_warmup_schedule: "continuous"
      }

    # Optimize provider selection algorithms based on success patterns
    - analyze_provider_selection_effectiveness: {
        selection_history: "${provider_selection_history}",
        success_metrics: ["binding_success_rate", "performance_satisfaction", "reliability"]
      }

    - condition:
        if: "${selection_effectiveness.improvement_opportunity > 0.1}"
        then:
          - optimize_selection_algorithms: {
              current_algorithms: "${current_selection_algorithms}",
              effectiveness_analysis: "${selection_effectiveness}",
              optimization_targets: ["accuracy", "speed", "reliability"]
            }
          - test_optimized_algorithms: {
              new_algorithms: "${optimized_algorithms}",
              test_duration: "1h",
              comparison_metrics: ["selection_accuracy", "resolution_time"]
            }
          - condition:
              if: "${algorithm_test.improvement > 0.05}"
              then:
                - deploy_optimized_algorithms: {
                    algorithms: "${optimized_algorithms}",
                    rollback_plan: "${current_algorithms}"
                  }
                - tamr.log: {
                    event: "linking_algorithms_optimized",
                    improvement: "${algorithm_test.improvement}"
                  }

    # Optimize cache strategies
    - optimize_cache_strategies: {
        cache_hit_rates: "${current_cache_performance}",
        memory_usage: "${cache_memory_usage}",
        optimization_goals: ["higher_hit_rate", "lower_memory_usage", "faster_lookup"]
      }

    - return: {
        optimizations_applied: "${applied_optimizations}",
        performance_improvement: "${overall_performance_improvement}",
        cache_improvements: "${cache_optimizations}"
      }

  # Fallback and error handling
  handle_resolution_failure:
    - log_resolution_failure: {
        capability: "${input.capability}",
        consumer: "${input.consumer}",
        failure_reason: "${input.reason}",
        attempted_providers: "${input.attempted_providers}"
      }

    # Attempt fallback strategies
    - attempt_fallback_resolution: {
        capability: "${input.capability}",
        consumer: "${input.consumer}",
        fallback_strategies: [
          "relaxed_requirements",
          "alternative_capabilities",
          "legacy_import_fallback",
          "degraded_functionality"
        ]
      }

    - condition:
        if: "${fallback_resolution.successful}"
        then:
          - return: {
              provider: "${fallback_resolution.provider}",
              interface: "${fallback_resolution.interface}",
              fallback_used: true,
              degraded_functionality: "${fallback_resolution.degraded}"
            }
        else:
          - escalate_resolution_failure: {
              capability: "${input.capability}",
              consumer: "${input.consumer}",
              all_attempts: "${resolution_attempts}"
            }
          - return: {
              error: "resolution_failed",
              capability: "${input.capability}",
              escalated: true
            }

concern:
  if: "${resolution_failure_rate > 0.05 || average_resolution_time > 100}"
  priority: 1
  action:
    - tamr.log: {
        event: "dynamic_linker_performance_concern",
        failure_rate: "${resolution_failure_rate}",
        avg_resolution_time: "${average_resolution_time}"
      }
    - run: ["dynamic-linker.r", "optimize_linking_performance"]
    - condition:
        if: "${performance_degradation_critical}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🔗 Dynamic Linker performance degraded. Resolution failure rate: ${resolution_failure_rate}"
              buttons: ["Optimize System", "Fallback to Imports", "Emergency Reset"]

# Configuration for capability resolution
resolution_config:
  default_algorithms:
    provider_selection: "weighted_performance"
    load_balancing: "least_connections"
    fallback_strategy: "graceful_degradation"

  performance_targets:
    max_resolution_time: 50  # milliseconds
    min_cache_hit_rate: 0.8
    max_failure_rate: 0.01

  cache_settings:
    default_ttl: 300000  # 5 minutes
    max_cache_size: 1000  # entries
    eviction_policy: "lru"

  migration_settings:
    default_strategy: "gradual_fallback"
    testing_period: 604800000  # 7 days
    rollback_threshold: 0.05  # 5% failure rate triggers rollback
