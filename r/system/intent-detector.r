# r/system/intent-detector.r
self:
  id: "intent-detector"
  intent: "Parse natural language into structured agent requirements"
  template: "ai_intelligence"

aam:
  require_role: "system"
  allow_actions: ["analyze_intent", "extract_requirements", "prompt_clarification"]

operations:
  analyze_user_request:
    - build_intent_template: {
        user_prompt: "${input.text}",
        context: "${input.context}"
      }

    - llm.complete: {
        system_prompt: "You are an intent extraction specialist. Fill in this template based on the user's request:",
        template: "${intent_template}",
        user_input: "${input.text}",
        output_format: "yaml"
      }

    - validate_extracted_intent: {
        extracted: "${llm_response}",
        completeness_check: true
      }

    - condition:
        if: "${validation.incomplete_fields.length > 0}"
        then:
          - request_clarification: {
              missing_fields: "${validation.incomplete_fields}",
              context: "${input.context}"
            }
        else:
          - return: "${validated_intent}"

  build_intent_template:
    - return: |
        # INTENT EXTRACTION TEMPLATE
        # Fill in based on user request: "${input.user_prompt}"

        agent_requirements:
          agent_type: "[customer_service|email_assistant|data_analysis|finance_processor|custom]"
          primary_purpose: "[one sentence description]"
          key_capabilities: "[list 3-5 main functions]"

        system_integrations:
          required_services: "[xero|quickbooks|email|slack|etc]"
          data_sources: "[what data will it access]"
          output_destinations: "[where results go]"

        business_context:
          department: "[finance|hr|sales|operations]"
          complexity_level: "[simple|standard|advanced]"
          urgency: "[low|medium|high]"

        approval_requirements:
          human_oversight_needed: "[always|exceptions_only|never]"
          approval_thresholds: "[dollar amounts, risk levels, etc]"
          escalation_paths: "[who gets notified when]"

        missing_information:
          clarification_needed: "[list any unclear aspects]"
          suggested_questions: "[questions to ask user]"

  request_clarification:
    - generate_clarification_prompt: {
        missing_fields: "${input.missing_fields}",
        user_context: "${input.context}"
      }

    - prompt.user: {
        to: "${input.context.user_id}",
        message: "I need a bit more detail to create the perfect agent for you:",
        attachments: [{
          title: "Quick Questions",
          text: "${clarification_questions}",
          color: "warning"
        }]
      }
