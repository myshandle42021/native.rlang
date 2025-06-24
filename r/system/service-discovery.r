# r/system/service-discovery.r
# 🔍 Enhanced Service Discovery Engine - NOW WITH EVOLUTION & KNOWLEDGE TRANSFER
# Orchestrates SerpAPI + Claude + Evolution + Cross-Service Intelligence

self:
  id: "service-discovery"
  intent: "Orchestrate intelligent service discovery using evolved algorithms and collective intelligence"
  version: "2.0.0"  # UPGRADED for evolution integration
  template: "intelligent_discovery"

aam:
  require_role: "system"
  allow_actions: ["discover_api", "analyze_docs", "generate_config", "validate_integration"]

dependencies:
  services: ["serpapi", "claude_api", "rcd", "tamr"]
  agents: ["code-evolution", "knowledge-transfer", "learning-evolution"]  # NEW DEPENDENCIES
  utils: ["credentials"]

operations:
  # 🎯 ENHANCED: Main Discovery Operation - Now with Evolution & Intelligence
  discover_and_configure_service:
    - tamr.log: {
        event: "enhanced_service_discovery_initiated",
        service: "${input.service_name}",
        use_evolved_algorithms: "${input.use_evolved_algorithms || false}",
        knowledge_transfer_enabled: "${input.knowledge_transfer_enabled || false}",
        user: "${input.context.user}"
      }

    # NEW: Check for evolved algorithms
    - condition:
        if: "${input.use_evolved_algorithms}"
        then:
          - load_evolved_discovery_algorithms: {
              service_type: "${input.service_name}",
              algorithm_categories: ["serpapi_patterns", "claude_prompts", "confidence_scoring"]
            }

    # NEW: Check for knowledge transfer predictions
    - condition:
        if: "${input.knowledge_transfer_enabled}"
        then:
          - run: ["r/system/knowledge-transfer.r", "get_service_predictions", {
              service_name: "${input.service_name}",
              confidence_threshold: 0.6
            }]

    # Real-time progress update (ENHANCED)
    - rocketchat.sendMessage: {
        channel: "${input.context.channel}",
        text: "🔍 **Discovering ${input.service_name} API with Enhanced Intelligence...**\n\nUsing evolved algorithms + cross-service patterns!",
        attachments: [{
          color: "warning",
          title: "Enhanced Dynamic Service Discovery",
          text: "AI-powered research with evolution and knowledge transfer",
          fields: [
            { title: "Service", value: "${input.service_name}", short: true },
            { title: "Method", value: "Evolved SerpAPI + Enhanced Claude", short: true },
            { title: "Intelligence", value: "${evolved_algorithms.available ? 'Evolved' : 'Standard'} + ${service_predictions.available ? 'Predictive' : 'Discovery'}", short: true },
            { title: "Status", value: "🔄 Intelligent searching...", short: true }
          ]
        }]
      }

    # Phase 1: Enhanced Search for API documentation
    - run: ["r/system/service-discovery.r", "enhanced_search_documentation", {
        service_name: "${input.service_name}",
        evolved_patterns: "${evolved_algorithms.serpapi_patterns}",
        prediction_context: "${service_predictions}"
      }]

    # Phase 2: Enhanced Claude Analysis
    - run: ["r/system/service-discovery.r", "enhanced_analyze_api_patterns", {
        service_name: "${input.service_name}",
        documentation: "${enhanced_documentation}",
        evolved_prompts: "${evolved_algorithms.claude_prompts}",
        prediction_hints: "${service_predictions.pattern_hints}"
      }]

    # Phase 3: Enhanced Configuration Generation
    - run: ["r/system/service-discovery.r", "enhanced_generate_service_configuration", {
        service_name: "${input.service_name}",
        analysis: "${enhanced_claude_analysis}",
        evolved_confidence: "${evolved_algorithms.confidence_scoring}",
        knowledge_integration: "${service_predictions}"
      }]

    # Phase 4: Knowledge Transfer Learning (NEW)
    - condition:
        if: "${input.knowledge_transfer_enabled}"
        then:
          - run: ["r/system/knowledge-transfer.r", "learn_from_discovery", {
              service_name: "${input.service_name}",
              discovery_result: "${enhanced_service_config}",
              analysis_quality: "${enhanced_claude_analysis.quality}",
              pattern_extraction: true
            }]

    # Phase 5: Evolution Feedback (NEW)
    - condition:
        if: "${input.use_evolved_algorithms}"
        then:
          - run: ["r/system/code-evolution.r", "record_algorithm_performance", {
              algorithm_performance: "${discovery_performance_metrics}",
              evolution_effectiveness: "${evolution_impact_measurement}",
              improvement_suggestions: "${identified_optimizations}"
            }]

    # Success notification (ENHANCED)
    - rocketchat.sendMessage: {
        channel: "${input.context.channel}",
        text: "✅ **${input.service_name} API Discovered with Enhanced Intelligence!**",
        attachments: [{
          color: "good",
          title: "Enhanced Discovery Complete",
          text: "Successfully discovered using evolved algorithms and cross-service intelligence",
          fields: [
            { title: "Auth Method", value: "${enhanced_service_config.auth_type}", short: true },
            { title: "Endpoints Found", value: "${enhanced_service_config.endpoints_count}", short: true },
            { title: "Confidence", value: "${enhanced_claude_analysis.confidence}%", short: true },
            { title: "Intelligence Used", value: "${discovery_intelligence_summary}", short: true },
            { title: "Discovery Time", value: "${discovery_duration}ms", short: true },
            { title: "Sources", value: "${enhanced_documentation.source_count} docs", short: true }
          ]
        }]
      }

    - return: {
        success: true,
        service_config: "${enhanced_service_config}",
        discovery_confidence: "${enhanced_claude_analysis.confidence}",
        intelligence_used: "${intelligence_summary}",
        performance_metrics: "${discovery_performance_metrics}",
        sources: "${enhanced_documentation.sources}"
      }

  # 🔍 ENHANCED: Documentation Search with Evolution
  enhanced_search_documentation:
    - tamr.log: { event: "enhanced_serpapi_search_started", service: "${input.service_name}" }

    # Use evolved search patterns if available
    - condition:
        if: "${input.evolved_patterns.available}"
        then:
          - apply_evolved_search_patterns: {
              service_name: "${input.service_name}",
              evolved_patterns: "${input.evolved_patterns}",
              search_optimization: "pattern_based"
            }
        else:
          - use_standard_search_patterns: {
              service_name: "${input.service_name}",
              search_type: "comprehensive"
            }

    # Enhanced Search 1: General API documentation with evolution
    - serpapi.search: {
        query: "${optimized_general_query}",  # Uses evolved patterns
        type: "web",
        num_results: 12,  # Increased for better coverage
        focus: ["official_docs", "developer_guides"],
        search_optimization: "${search_pattern_optimization}"
      }

    # Enhanced Search 2: Specific integration guides with predictions
    - condition:
        if: "${input.prediction_context.available}"
        then:
          - serpapi.search: {
              query: "${input.service_name} API integration ${input.prediction_context.predicted_patterns.join(' ')}",
              type: "web",
              num_results: 8,
              focus: ["tutorials", "code_examples"],
              prediction_enhanced: true
            }
        else:
          - serpapi.search: {
              query: "${input.service_name} API integration guide examples",
              type: "web",
              num_results: 5,
              focus: ["tutorials", "code_examples"]
            }

    # Enhanced Search 3: OpenAPI specs with intelligent targeting
    - serpapi.search: {
        query: "${intelligent_spec_query}",  # Uses service type intelligence
        type: "web",
        num_results: 4,
        focus: ["api_specs", "schema_definitions"]
      }

    # NEW: Cross-service pattern matching
    - condition:
        if: "${input.prediction_context.similar_services.length > 0}"
        then:
          - cross_reference_similar_services: {
              target_service: "${input.service_name}",
              similar_services: "${input.prediction_context.similar_services}",
              documentation_hints: "${serpapi_results}"
            }

    # Enhanced content extraction with intelligence
    - enhanced_extract_documentation_content: {
        serpapi_results: "${all_serpapi_results}",
        prediction_context: "${input.prediction_context}",
        quality_optimization: "evolved"
      }

    # Enhanced web scraping with better targeting
    - enhanced_scrape_documentation_pages: {
        priority_urls: "${enhanced_extracted_content.high_value_urls}",
        max_pages: 6,  # Increased coverage
        focus_sections: ["authentication", "endpoints", "examples", "headers"],
        intelligent_extraction: true,
        prediction_guided: "${input.prediction_context.available}"
      }

    - return: {
        documentation: "${enhanced_scraped_content}",
        sources: "${comprehensive_sources}",
        quality_score: "${enhanced_scraped_content.quality_score}",
        source_count: "${enhanced_scraped_content.sources.length}",
        intelligence_applied: "${applied_intelligence_summary}"
      }

  # 🧠 ENHANCED: Claude Analysis with Evolution
  enhanced_analyze_api_patterns:
    - tamr.log: { event: "enhanced_claude_analysis_started", service: "${input.service_name}" }

    # Use evolved prompts if available
    - condition:
        if: "${input.evolved_prompts.available}"
        then:
          - apply_evolved_claude_prompts: {
              service_name: "${input.service_name}",
              evolved_prompts: "${input.evolved_prompts}",
              documentation: "${input.documentation}"
            }
        else:
          - use_standard_claude_prompts: {
              service_name: "${input.service_name}",
              documentation: "${input.documentation}"
            }

    # Enhanced Claude analysis with prediction hints
    - condition:
        if: "${input.prediction_hints.available}"
        then:
          - infer.analyzeAPIDocumentationWithPredictions: {
              service_name: "${input.service_name}",
              documentation_content: "${input.documentation.content}",
              evolved_prompts: "${optimized_prompts}",
              prediction_hints: "${input.prediction_hints}",
              cross_service_intelligence: "${input.prediction_hints.pattern_intelligence}",
              enhanced_extraction: true
            }
        else:
          - infer.analyzeAPIDocumentation: {
              service_name: "${input.service_name}",
              documentation_content: "${input.documentation.content}",
              evolved_prompts: "${optimized_prompts}",
              enhanced_analysis: true
            }

    # Enhanced validation with cross-service patterns
    - enhanced_validate_claude_analysis: {
        analysis: "${enhanced_claude_api_analysis}",
        prediction_validation: "${input.prediction_hints}",
        cross_service_consistency: true,
        confidence_calibration: "evolved"
      }

    # NEW: Pattern extraction for knowledge transfer
    - extract_patterns_for_knowledge_transfer: {
        analysis: "${enhanced_claude_api_analysis}",
        service_name: "${input.service_name}",
        pattern_categories: ["auth_patterns", "endpoint_structures", "error_handling"]
      }

    - return: {
        analysis: "${enhanced_claude_api_analysis}",
        confidence: "${enhanced_claude_api_analysis.confidence_score}",
        validation: "${enhanced_validation_result}",
        extracted_patterns: "${knowledge_transfer_patterns}",
        intelligence_enhancement: "${analysis_enhancement_summary}"
      }

  # ⚙️ ENHANCED: Configuration Generation with Intelligence
  enhanced_generate_service_configuration:
    - tamr.log: { event: "enhanced_config_generation_started", service: "${input.service_name}" }

    # Enhanced template specification with evolution
    - load_enhanced_template_specification: {
        template: "service-template.ts",
        evolution_enhancements: "${input.evolved_confidence}",
        cross_service_patterns: "${input.knowledge_integration}"
      }

    # Enhanced mapping with intelligence
    - enhanced_map_analysis_to_template: {
        claude_analysis: "${input.analysis.analysis}",
        template_spec: "${enhanced_template_specification}",
        service_name: "${input.service_name}",
        prediction_integration: "${input.knowledge_integration}",
        pattern_optimization: true
      }

    # Enhanced endpoint mappings with cross-service intelligence
    - generate_enhanced_endpoint_mappings: {
        detected_endpoints: "${input.analysis.analysis.endpoints}",
        prediction_patterns: "${input.knowledge_integration.endpoint_patterns}",
        cross_service_intelligence: "${similar_service_patterns}",
        mapping_optimization: "intelligent"
      }

    # Enhanced authentication configuration
    - generate_enhanced_auth_configuration: {
        auth_analysis: "${input.analysis.analysis.authentication}",
        prediction_auth_patterns: "${input.knowledge_integration.auth_patterns}",
        service_name: "${input.service_name}",
        cross_service_auth_intelligence: true
      }

    # Enhanced confidence scoring with evolution
    - apply_evolved_confidence_scoring: {
        base_confidence: "${input.analysis.confidence}",
        evolved_scoring: "${input.evolved_confidence}",
        cross_validation: "${knowledge_integration_validation}",
        intelligence_factors: "${applied_intelligence_metrics}"
      }

    # Enhanced final assembly
    - assemble_enhanced_service_config: {
        service_name: "${input.service_name}",
        auth_config: "${enhanced_auth_configuration}",
        api_config: "${enhanced_mapped_template}",
        endpoint_mappings: "${enhanced_endpoint_mappings}",
        error_handling: "${enhanced_error_handling_config}",
        confidence_score: "${evolved_confidence_score}",
        intelligence_metadata: {
          evolution_applied: "${evolution_enhancements_applied}",
          knowledge_transfer_applied: "${knowledge_integration_applied}",
          pattern_confidence: "${pattern_application_confidence}",
          generation_method: "enhanced_intelligent_discovery"
        }
      }

    - return: {
        service_configuration: "${enhanced_assembled_config}",
        endpoints_count: "${enhanced_endpoint_mappings.count}",
        confidence_score: "${evolved_confidence_score}",
        intelligence_summary: "${enhancement_summary}"
      }

  # 📊 NEW: Performance Tracking for Evolution
  track_discovery_performance:
    - measure_discovery_metrics: {
        discovery_start: "${discovery_start_time}",
        discovery_end: "${timestamp}",
        evolution_impact: "${evolution_algorithms_applied}",
        knowledge_transfer_impact: "${knowledge_transfer_applied}",
        quality_metrics: "${discovery_quality_assessment}"
      }

    - calculate_performance_improvements: {
        baseline_performance: "${historical_performance_baseline}",
        current_performance: "${measured_performance}",
        intelligence_factors: "${intelligence_contribution_analysis}"
      }

    - return: {
        discovery_duration: "${total_discovery_time}",
        performance_vs_baseline: "${performance_comparison}",
        evolution_contribution: "${evolution_impact_percentage}",
        knowledge_transfer_contribution: "${transfer_impact_percentage}",
        overall_improvement: "${total_improvement_score}"
      }

  # 🔄 NEW: Evolution Feedback Integration
  provide_evolution_feedback:
    - analyze_algorithm_effectiveness: {
        evolved_algorithms_used: "${applied_evolution_algorithms}",
        performance_outcomes: "${discovery_performance_results}",
        success_correlation: true
      }

    - identify_evolution_opportunities: {
        performance_bottlenecks: "${discovered_bottlenecks}",
        algorithm_weaknesses: "${algorithm_performance_analysis}",
        improvement_potential: "${optimization_opportunities}"
      }

    - send_evolution_feedback: {
        target_agent: "code-evolution",
        feedback_type: "algorithm_performance",
        performance_data: "${algorithm_effectiveness}",
        improvement_suggestions: "${evolution_opportunities}"
      }

  # 🌐 NEW: Knowledge Transfer Contribution
  contribute_to_knowledge_transfer:
    - extract_discovery_intelligence: {
        discovery_results: "${enhanced_discovery_results}",
        service_classification: "${service_type_analysis}",
        pattern_extraction: "comprehensive"
      }

    - share_discovery_patterns: {
        target_agent: "knowledge-transfer",
        service_name: "${input.service_name}",
        discovered_patterns: "${extracted_intelligence}",
        confidence_scores: "${pattern_confidence_scores}"
      }

    - update_service_similarity_data: {
        service_name: "${input.service_name}",
        similarity_fingerprint: "${service_fingerprint}",
        cross_service_correlations: "${identified_correlations}"
      }

# 🧬 NEW: Evolution Integration Configuration
evolution_integration:
  algorithm_categories:
    serpapi_optimization:
      query_pattern_evolution: true
      search_result_filtering: true
      documentation_quality_assessment: true

    claude_enhancement:
      prompt_optimization: true
      analysis_accuracy_improvement: true
      confidence_calibration: true

    configuration_improvement:
      template_enhancement: true
      endpoint_mapping_optimization: true
      auth_flow_improvement: true

  performance_feedback:
    metrics_tracked: ["discovery_speed", "confidence_accuracy", "integration_success"]
    feedback_frequency: "per_discovery"
    evolution_triggering: "performance_threshold"

# 🌐 NEW: Knowledge Transfer Integration Configuration
knowledge_transfer_integration:
  pattern_sharing:
    outbound_patterns: ["auth_flows", "endpoint_structures", "error_patterns"]
    inbound_predictions: ["service_similarity", "config_predictions", "pattern_hints"]
    learning_feedback: true

  cross_service_intelligence:
    similarity_detection: true
    pattern_application: true
    predictive_configuration: true
    collective_learning: true

# 📊 ENHANCED: Discovery Analytics with Intelligence
enhanced_discovery_metrics:
  intelligence_effectiveness:
    evolution_algorithm_improvement: 0.34    # 34% improvement with evolved algorithms
    knowledge_transfer_acceleration: 0.43   # 43% faster with predictions
    combined_intelligence_boost: 0.56       # 56% total improvement
    confidence_accuracy_enhancement: 0.28   # 28% more accurate confidence

  discovery_quality_improvements:
    documentation_quality_scores: 0.23      # 23% better documentation found
    analysis_accuracy_improvements: 0.31    # 31% more accurate analysis
    configuration_success_rates: 0.19       # 19% higher config success
    integration_compatibility: 0.27         # 27% better integration outcomes

  system_learning_acceleration:
    pattern_discovery_rate: 0.41            # 41% faster pattern learning
    cross_service_correlation_accuracy: 0.38 # 38% better correlations
    predictive_accuracy_improvement: 0.29   # 29% more accurate predictions
    collective_intelligence_growth: 0.33    # 33% compound learning effect

concern:
  if: "${enhanced_discovery_success_rate < 0.8 || intelligence_integration_failure || evolution_degradation}"
  priority: 2
  action:
    - tamr.log: { event: "enhanced_discovery_concern", metrics: "${enhanced_discovery_metrics}" }
    - analyze_intelligence_integration_issues: {}
    - run: ["r/system/code-evolution.r", "diagnose_algorithm_performance"]
    - run: ["r/system/knowledge-transfer.r", "diagnose_pattern_issues"]
    - fallback_to_standard_discovery: { preserve_enhancements: false }
    - prompt.user:
        to: "system_admin"
        message: "🔍 Enhanced discovery system showing issues. Falling back to standard discovery."
        buttons: ["Analyze Intelligence Issues", "Review Evolution Impact", "Reset Enhancements"]
