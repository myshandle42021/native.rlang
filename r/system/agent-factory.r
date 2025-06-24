# r/system/agent-factory.r
# Learning-based agent creation with continuous improvement

self:
  id: "agent-factory"
  intent: "Create optimized agents through learning and pattern analysis"
  version: "2.0.0"
  template: "intelligent_factory"

aam:
  require_role: "system"
  allow_actions: ["create_agent", "analyze_patterns", "optimize_templates", "evolve_factory"]

operations:
  create_intelligent_agent:
    - tamr.log: { event: "agent_creation_request", request: "${input}", timestamp: "${timestamp}" }

    # Phase 1: Intent Analysis & Context Understanding
    - analyze_creation_request:
        request: "${input}"
        context: "${creation_context}"
        historical_patterns: true

    # Phase 2: Pattern-Based Template Selection
    - query_historical_success_patterns:
        intent_type: "${analyzed_intent.type}"
        success_threshold: 0.8
        time_window: "-90d"

    # Phase 3: Intelligent Template Selection
    - select_optimal_template:
        intent: "${analyzed_intent}"
        success_patterns: "${historical_patterns}"
        performance_data: "${template_performance_history}"
        fallback_strategy: "best_match_or_enhance"

    # Phase 4: Template Enhancement & Customization
    - enhance_template_with_learning:
        base_template: "${selected_template}"
        intent_specifics: "${analyzed_intent.specifics}"
        optimization_insights: "${learning_insights}"
        customization_level: "${input.enhancement_level || 'standard'}"

    # Phase 5: Agent Generation & Validation
    - generate_agent_file:
        enhanced_template: "${enhanced_template}"
        agent_config: "${agent_configuration}"
        output_strategy: "${output_path_strategy}"

    # Phase 6: Performance Tracking Setup
    - initialize_agent_tracking:
        agent_id: "${generated_agent.id}"
        creation_metadata: "${creation_metadata}"
        performance_baseline: true

    - tamr.log: {
        event: "agent_created_successfully",
        agent_id: "${generated_agent.id}",
        template_used: "${selected_template.id}",
        enhancement_level: "${enhancement_level}",
        creation_time: "${creation_duration}"
      }

    - respond: "✅ Intelligent agent '${generated_agent.id}' created successfully using optimized template '${selected_template.id}'"

  analyze_creation_request:
    - infer.getIntent: "${input.request}"

    - extract_technical_requirements:
        request_text: "${input.request}"
        context: "${input.context}"
        implicit_requirements: true

    - classify_agent_type:
        intent: "${extracted_intent}"
        requirements: "${technical_requirements}"
        categories: [
          "automation_agent",
          "integration_agent",
          "monitoring_agent",
          "user_interface_agent",
          "data_processing_agent",
          "orchestration_agent"
        ]

    - determine_complexity_level:
        requirements: "${technical_requirements}"
        estimated_operations: "${technical_requirements.operations_count}"
        integration_complexity: "${technical_requirements.integrations}"

    - calculate_success_predictors:
        agent_type: "${classified_type}"
        complexity: "${complexity_level}"
        user_context: "${input.context}"
        historical_data: "${historical_patterns}"

    - return: {
        type: "${classified_type}",
        complexity: "${complexity_level}",
        requirements: "${technical_requirements}",
        success_predictors: "${success_predictors}",
        specifics: "${intent_specifics}"
      }

  query_historical_success_patterns:
    - tamr.query:
        event: "agent_created_successfully"
        since: "${input.time_window}"
        limit: 500

    - filter_by_intent_similarity:
        creation_logs: "${query_result}"
        target_intent: "${input.intent_type}"
        similarity_threshold: 0.7

    - analyze_performance_correlations:
        similar_agents: "${filtered_logs}"
        performance_metrics: ["uptime", "error_rate", "user_satisfaction", "task_completion"]
        time_horizon: "30d"

    - identify_success_patterns:
        performance_data: "${performance_correlations}"
        success_threshold: "${input.success_threshold}"
        pattern_types: ["template_choice", "configuration_params", "operation_structure"]

    - calculate_pattern_confidence:
        patterns: "${identified_patterns}"
        sample_size: "${similar_agents.length}"
        statistical_significance: true

    - return: {
        patterns: "${identified_patterns}",
        confidence_scores: "${pattern_confidence}",
        sample_size: "${similar_agents.length}",
        success_rate: "${overall_success_rate}"
      }

  select_optimal_template:
    - load_available_templates:
        sources: ["r/templates/", "r/system/templates/", "r/learned-templates/"]
        include_generated: true

    - score_template_compatibility:
        templates: "${available_templates}"
        intent: "${input.intent}"
        requirements: "${input.intent.requirements}"
        historical_success: "${input.success_patterns}"

    - apply_performance_weighting:
        compatibility_scores: "${template_scores}"
        performance_history: "${input.performance_data}"
        recency_bias: 0.3  # Favor recent performance data

    - select_top_candidates:
        weighted_scores: "${performance_weighted_scores}"
        candidate_count: 3
        minimum_score: 0.6

    - condition:
        if: "${top_candidates.length == 0}"
        then:
          - run: ["r/system/agent-factory.r", "handle_no_suitable_template"]
        else:
          - choose_best_template:
              candidates: "${top_candidates}"
              selection_strategy: "${input.fallback_strategy}"
              confidence_threshold: 0.8

    - return: {
        template: "${selected_template}",
        confidence: "${selection_confidence}",
        alternatives: "${alternative_templates}",
        selection_reason: "${selection_reasoning}"
      }

  enhance_template_with_learning:
    - load_optimization_insights:
        template_id: "${input.base_template.id}"
        time_window: "-60d"
        insight_types: ["performance_bottlenecks", "common_failures", "successful_patterns"]

    - apply_learning_enhancements:
        base_template: "${input.base_template}"
        insights: "${optimization_insights}"
        intent_specifics: "${input.intent_specifics}"
        enhancement_level: "${input.customization_level}"

    - condition:
        if: "${input.customization_level == 'advanced'}"
        then:
          - infer.enhanceAgent:
              template: "${enhanced_template}"
              intent: "${input.intent_specifics.detailed_description}"
              context: "${input.intent_specifics.context}"
              optimization_data: "${optimization_insights}"

          - validate_llm_enhancements:
              original: "${enhanced_template}"
              llm_enhanced: "${llm_enhancement_result}"
              safety_checks: ["syntax", "security", "performance"]

          - condition:
              if: "${llm_validation.safe && llm_validation.improvement_score > 0.2}"
              then:
                - merge_enhancements:
                    base: "${enhanced_template}"
                    llm_additions: "${llm_enhancement_result}"
                    merge_strategy: "conservative"

    - optimize_operation_structure:
        template: "${final_enhanced_template}"
        common_patterns: "${successful_operation_patterns}"
        performance_hints: "${operation_performance_data}"

    - add_monitoring_instrumentation:
        template: "${optimized_template}"
        tracking_level: "${input.customization_level}"
        metrics: ["execution_time", "error_rate", "resource_usage"]

    - return: {
        enhanced_template: "${instrumented_template}",
        enhancements_applied: "${applied_enhancements}",
        performance_predictions: "${predicted_performance}"
      }

  generate_agent_file:
    - run: ["r/system/agent-factory.r", "determine_agent_output_path", {
        agent_id: "${input.enhanced_template.self.id}",
        client_id: "${input.agent_config.client_id}",
        category: "${input.enhanced_template.category}",
        path_strategy: "${input.output_strategy}"
      }]

    - serialize_agent_to_yaml:
        template: "${input.enhanced_template}"
        format_style: "optimized_readability"
        include_metadata: true

    - add_generation_metadata:
        yaml_content: "${serialized_yaml}"
        metadata: {
          generated_by: "agent-factory",
          generation_time: "${timestamp}",
          template_source: "${input.enhanced_template.source}",
          enhancement_level: "${input.enhancement_level}",
          creation_request_hash: "${creation_request_hash}"
        }

    - run: ["r/system/agent-factory.r", "handle_file_operations", {
        operation: "write_with_backup",
        file_path: "${output_path_result.output_path}",
        content: "${final_yaml_content}",
        backup_existing: true
      }]

    - return: {
        agent_id: "${input.enhanced_template.self.id}",
        file_path: "${output_path_result.output_path}",
        size_bytes: "${file_operation_result.size}",
        operations_count: "${Object.keys(input.enhanced_template.operations).length}"
      }

  initialize_agent_tracking:
    - create_tracking_record:
        agent_id: "${input.agent_id}"
        creation_metadata: "${input.creation_metadata}"
        baseline_metrics: "${input.performance_baseline}"
        tracking_config: {
          monitor_uptime: true,
          track_performance: true,
          collect_user_feedback: true,
          analyze_error_patterns: true
        }

    - rcd.write:
        table: "agent_lifecycle"
        data: {
          agent_id: "${input.agent_id}",
          created_at: "${timestamp}",
          factory_version: "${self.version}",
          template_id: "${input.creation_metadata.template_id}",
          enhancement_level: "${input.creation_metadata.enhancement_level}",
          predicted_performance: "${input.creation_metadata.performance_predictions}",
          tracking_active: true
        }

    - schedule_performance_reviews:
        agent_id: "${input.agent_id}"
        review_schedule: ["1d", "7d", "30d", "90d"]
        auto_optimize: true

    - tamr.log: {
        event: "agent_tracking_initialized",
        agent_id: "${input.agent_id}",
        tracking_id: "${tracking_record.id}"
      }

  validate_agent_file_content:
    # All file validation logic moved from TypeScript agentio.ts
    - check_required_sections:
        content: "${input.content}"
        required_sections: ["self:", "operations:"]
        validation_errors: []
        loop:
          forEach: "${required_sections}"
          do:
            - condition:
                if: "!${input.content.includes(item)}"
                then:
                  - add_validation_error: { error: "Missing required section: ${item}" }

    - check_yaml_syntax:
        content: "${input.content}"
        lines: "${input.content.split('\n')}"
        loop:
          forEach: "${lines}"
          do:
            - condition:
                if: "${item.includes('\t')}"
                then:
                  - add_validation_error: { error: "YAML should use spaces, not tabs on line ${index + 1}" }

            - check_unterminated_strings:
                line: "${item}"
                line_number: "${index + 1}"
                condition:
                  if: "${item.includes('\"') && (item.split('\"').length - 1) % 2 !== 0}"
                  then:
                    - add_validation_error: { error: "Possible unterminated string on line ${line_number}" }

    - check_agent_structure:
        content: "${input.content}"
        validation_rules: {
          "self.id": "required",
          "self.intent": "required",
          "operations.initialize": "recommended",
          "operations.request_handler": "recommended"
        }
        loop:
          forEach: "${validation_rules}"
          do:
            - extract_field_value: { content: "${input.content}", field: "${item.key}" }
            - condition:
                if: "${item.value == 'required' && !extracted_value}"
                then:
                  - add_validation_error: { error: "Required field missing: ${item.key}" }
                else:
                  - condition:
                      if: "${item.value == 'recommended' && !extracted_value}"
                      then:
                        - add_validation_warning: { warning: "Recommended field missing: ${item.key}" }

    - return: {
        valid: "${validation_errors.length == 0}",
        errors: "${validation_errors}",
        warnings: "${validation_warnings}",
        line_count: "${lines.length}"
      }

  handle_file_operations:
    # File operation logic with backup handling moved from TypeScript
    - condition:
        if: "${input.operation == 'write_with_backup'}"
        then:
          - condition:
              if: "${input.backup_existing}"
              then:
                - check_file_exists: { path: "${input.file_path}" }
                - condition:
                    if: "${file_exists.exists}"
                    then:
                      - create_backup_path: {
                          original: "${input.file_path}",
                          timestamp: "${timestamp}"
                        }
                      - agentio.copyFile: {
                          source: "${input.file_path}",
                          destination: "${backup_path}"
                        }
                      - tamr.log: { event: "agent_file_backed_up", original: "${input.file_path}", backup: "${backup_path}" }

          - agentio.writeFile: {
              path: "${input.file_path}",
              content: "${input.content}"
            }

          - run: ["r/system/agent-factory.r", "validate_agent_file_content", { content: "${input.content}" }]

          - condition:
              if: "!${validation_result.valid}"
              then:
                - tamr.log: { event: "invalid_agent_file_created", errors: "${validation_result.errors}" }
                - condition:
                    if: "${backup_path}"
                    then:
                      - agentio.moveFile: { source: "${backup_path}", destination: "${input.file_path}" }
                      - tamr.log: { event: "agent_file_restored_from_backup" }
                - throw_error: { message: "Generated agent file is invalid: ${validation_result.errors}" }

  determine_agent_output_path:
    # Path determination logic moved from TypeScript
    - extract_agent_details:
        agent_id: "${input.agent_id}"
        client_id: "${input.client_id}"
        category: "${input.category}"

    - apply_path_strategy:
        strategy: "${input.path_strategy || 'default'}"
        condition:
          switch: "${strategy}"
          cases:
            - client_specific:
                - condition:
                    if: "${client_id}"
                    then:
                      - create_client_path: {
                          base: "r/clients/${client_id}/agents",
                          filename: "${agent_id}.r"
                        }
                    else:
                      - create_default_path: {
                          base: "r/agents",
                          filename: "${agent_id}.r"
                        }

            - categorized:
                - create_category_path: {
                    base: "r/agents/${category || 'general'}",
                    filename: "${agent_id}.r"
                  }

            - default:
                - create_default_path: {
                    base: "${client_id ? 'r/clients/' + client_id + '/agents' : 'r/agents'}",
                    filename: "${agent_id}.r"
                  }

    - ensure_directory_exists: { path: "${output_directory}" }

    - return: {
        output_path: "${final_output_path}",
        directory: "${output_directory}",
        filename: "${agent_id}.r"
      }
    - tamr.log: { event: "no_suitable_template_found", intent: "${input.intent}" }

    - condition:
        if: "${input.fallback_strategy == 'create_new'}"
        then:
          - generate_template_from_scratch:
              intent: "${input.intent}"
              requirements: "${input.requirements}"
              use_llm: true

          - validate_generated_template:
              template: "${generated_template}"
              safety_checks: true

          - condition:
              if: "${template_validation.safe}"
              then:
                - save_new_template:
                    template: "${generated_template}"
                    category: "generated"
                    experimental: true
                - return: { template: "${generated_template}", confidence: 0.6 }
              else:
                - run: ["r/system/agent-factory.r", "fallback_to_basic"]
        else:
          - run: ["r/system/agent-factory.r", "fallback_to_basic"]

  fallback_to_basic:
    - load_basic_template: { template_id: "basic_agent" }
    - customize_basic_template:
        intent: "${input.intent}"
        minimal_customization: true
    - return: {
        template: "${customized_basic}",
        confidence: 0.4,
        fallback_used: true
      }

  analyze_agent_performance:
    # Continuous learning operation - analyzes created agents and improves factory
    - query_agent_performance_data:
        since: "-30d"
        include_metrics: ["uptime", "error_rate", "user_satisfaction", "task_success"]

    - correlate_performance_with_creation:
        performance_data: "${agent_metrics}"
        creation_data: "${agent_creation_history}"
        correlation_types: ["template_choice", "enhancement_level", "customization_patterns"]

    - identify_improvement_opportunities:
        correlations: "${performance_correlations}"
        significance_threshold: 0.05
        improvement_potential: 0.15

    - condition:
        if: "${improvement_opportunities.length > 0}"
        then:
          - generate_factory_improvements:
              opportunities: "${improvement_opportunities}"
              current_algorithms: "${factory_algorithms}"

          - test_improvements:
              proposed_changes: "${factory_improvements}"
              test_method: "shadow_mode"
              duration: "7d"

          - condition:
              if: "${improvement_test.success_rate > current_success_rate + 0.1}"
              then:
                - apply_factory_improvements:
                    improvements: "${factory_improvements}"
                    rollback_plan: true
                - tamr.log: { event: "factory_self_improved", improvement: "${improvement_test.success_rate - current_success_rate}" }

  evolve_template_library:
    # Template evolution based on agent performance
    - analyze_template_success_rates:
        time_window: "-90d"
        minimum_usage: 5

    - identify_underperforming_templates:
        success_rates: "${template_analysis}"
        threshold: 0.7

    - identify_high_performing_patterns:
        success_rates: "${template_analysis}"
        threshold: 0.9
        extract_patterns: true

    - evolve_templates:
        underperforming: "${underperforming_templates}"
        successful_patterns: "${high_performing_patterns}"
        evolution_strategy: "pattern_injection"

    - condition:
        if: "${evolved_templates.length > 0}"
        then:
          - create_evolved_template_versions:
              templates: "${evolved_templates}"
              version_increment: "minor"
              experimental_flag: true

          - schedule_performance_comparison:
              original_vs_evolved: "${template_pairs}"
              comparison_duration: "30d"

  request_handler:
    - condition:
        if: "${request.type == 'natural_language'}"
        then:
          - infer.getIntent: "${request.text}"
          - condition:
              switch: "${intent.action}"
              cases:
                - create_agent:
                    - run: ["r/system/agent-factory.r", "create_intelligent_agent", {
                        request: "${request.text}",
                        context: "${request.context}",
                        enhancement_level: "${intent.complexity || 'standard'}"
                      }]

                - analyze_performance:
                    - run: ["r/system/agent-factory.r", "analyze_agent_performance"]

                - optimize_factory:
                    - run: ["r/system/agent-factory.r", "evolve_template_library"]

        else:
          - condition:
              if: "${request.operation == 'create_agent'}"
              then:
                - run: ["r/system/agent-factory.r", "create_intelligent_agent", "${request.params}"]

concern:
  if: "${agent_creation_failure_rate > 0.15 || average_creation_time > 30000}"
  priority: 2
  action:
    - tamr.log: { event: "factory_performance_concern", failure_rate: "${agent_creation_failure_rate}", avg_time: "${average_creation_time}" }
    - run: ["r/system/agent-factory.r", "analyze_agent_performance"]
    - condition:
        if: "${analysis_suggests_degradation}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🏭 Agent Factory performance degraded. Failure rate: ${agent_creation_failure_rate}%"
              buttons: ["Analyze Patterns", "Reset Templates", "Manual Review"]

# Factory learning configuration
learning_config:
  performance_tracking:
    review_intervals: ["1d", "7d", "30d", "90d"]
    metrics: ["uptime", "error_rate", "user_satisfaction", "resource_efficiency"]
    success_threshold: 0.8

  template_evolution:
    evolution_frequency: "monthly"
    minimum_usage_for_analysis: 5
    pattern_extraction_confidence: 0.7
    experimental_template_lifetime: "60d"

  enhancement_levels:
    basic:
      llm_enhancement: false
      pattern_application: "simple"
      monitoring_instrumentation: "minimal"

    standard:
      llm_enhancement: true
      pattern_application: "moderate"
      monitoring_instrumentation: "standard"

    advanced:
      llm_enhancement: true
      pattern_application: "comprehensive"
      monitoring_instrumentation: "detailed"
      custom_optimization: true

# Template scoring weights (can be learned and adjusted)
template_scoring:
  compatibility_weight: 0.4
  historical_performance_weight: 0.3
  recency_weight: 0.2
  complexity_match_weight: 0.1
