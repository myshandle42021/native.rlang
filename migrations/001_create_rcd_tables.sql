-- RCD Database Schema Migration
-- Creates all tables needed for the Relational Contextual Database system

-- File metadata and capabilities tracking
CREATE TABLE IF NOT EXISTS rcd_files (
    id SERIAL PRIMARY KEY,
    file_path TEXT UNIQUE NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('typescript', 'rlang', 'javascript', 'json', 'template', 'config')),
    capabilities TEXT[] DEFAULT '{}',
    dependencies TEXT[] DEFAULT '{}',
    meta_tags JSONB DEFAULT '{}',
    content_hash TEXT NOT NULL,
    last_analyzed TIMESTAMP DEFAULT NOW(),
    performance_score FLOAT DEFAULT 1.0 CHECK (performance_score >= 0 AND performance_score <= 5.0),
    usage_frequency INTEGER DEFAULT 0,
    stability_rating FLOAT DEFAULT 1.0 CHECK (stability_rating >= 0 AND stability_rating <= 1.0),
    complexity_level INTEGER DEFAULT 1 CHECK (complexity_level >= 1 AND complexity_level <= 5),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_rcd_files_capabilities ON rcd_files USING GIN (capabilities);
CREATE INDEX IF NOT EXISTS idx_rcd_files_dependencies ON rcd_files USING GIN (dependencies);
CREATE INDEX IF NOT EXISTS idx_rcd_files_type ON rcd_files (file_type);
CREATE INDEX IF NOT EXISTS idx_rcd_files_meta_tags ON rcd_files USING GIN (meta_tags);
CREATE INDEX IF NOT EXISTS idx_rcd_files_hash ON rcd_files (content_hash);

-- Learning patterns storage
CREATE TABLE IF NOT EXISTS rcd_patterns (
    id SERIAL PRIMARY KEY,
    pattern_type TEXT NOT NULL CHECK (pattern_type IN (
        'success_condition', 'failure_pattern', 'optimization_opportunity',
        'architectural_pattern', 'capability_cluster', 'dependency_pattern',
        'evolution_opportunity', 'performance_pattern', 'stability_pattern'
    )),
    pattern_data JSONB NOT NULL,
    confidence_score FLOAT DEFAULT 0.5 CHECK (confidence_score >= 0 AND confidence_score <= 1.0),
    usage_count INTEGER DEFAULT 0,
    success_rate FLOAT DEFAULT 0.0 CHECK (success_rate >= 0 AND success_rate <= 1.0),
    last_used TIMESTAMP,
    discovered_by TEXT NOT NULL, -- agent_id
    validated_by TEXT[] DEFAULT '{}', -- agent_ids that confirmed pattern
    domain TEXT, -- 'execution', 'architecture', 'performance', etc.
    context_hash TEXT, -- For finding similar contexts
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for pattern queries
CREATE INDEX IF NOT EXISTS idx_rcd_patterns_type ON rcd_patterns (pattern_type);
CREATE INDEX IF NOT EXISTS idx_rcd_patterns_confidence ON rcd_patterns (confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_rcd_patterns_success_rate ON rcd_patterns (success_rate DESC);
CREATE INDEX IF NOT EXISTS idx_rcd_patterns_domain ON rcd_patterns (domain);
CREATE INDEX IF NOT EXISTS idx_rcd_patterns_data ON rcd_patterns USING GIN (pattern_data);

-- Capability registry for dynamic linking
CREATE TABLE IF NOT EXISTS rcd_capabilities (
    id SERIAL PRIMARY KEY,
    capability_name TEXT UNIQUE NOT NULL,
    provider_files TEXT[] DEFAULT '{}',
    consumer_files TEXT[] DEFAULT '{}',
    interface_spec JSONB DEFAULT '{}', -- Function signatures, expected parameters
    complexity_level INTEGER DEFAULT 1 CHECK (complexity_level >= 1 AND complexity_level <= 5),
    stability_rating FLOAT DEFAULT 1.0 CHECK (stability_rating >= 0 AND stability_rating <= 1.0),
    usage_frequency INTEGER DEFAULT 0,
    last_accessed TIMESTAMP,
    description TEXT,
    category TEXT, -- 'core', 'utility', 'integration', 'ai', etc.
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for capability lookups
CREATE INDEX IF NOT EXISTS idx_rcd_capabilities_name ON rcd_capabilities (capability_name);
CREATE INDEX IF NOT EXISTS idx_rcd_capabilities_providers ON rcd_capabilities USING GIN (provider_files);
CREATE INDEX IF NOT EXISTS idx_rcd_capabilities_consumers ON rcd_capabilities USING GIN (consumer_files);
CREATE INDEX IF NOT EXISTS idx_rcd_capabilities_category ON rcd_capabilities (category);

-- Learning events for tracking system evolution
CREATE TABLE IF NOT EXISTS rcd_learning_events (
    id SERIAL PRIMARY KEY,
    agent_id TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'pattern_discovered', 'capability_linked', 'evolution_success', 'evolution_failure',
        'dependency_resolved', 'capability_added', 'performance_improvement',
        'stability_issue', 'complexity_reduction', 'pattern_validated'
    )),
    context_data JSONB NOT NULL,
    outcome TEXT CHECK (outcome IN ('success', 'failure', 'partial', 'unknown')),
    patterns_involved INTEGER[] DEFAULT '{}', -- References to rcd_patterns.id
    files_involved TEXT[] DEFAULT '{}',
    impact_score FLOAT DEFAULT 0.0 CHECK (impact_score >= -1.0 AND impact_score <= 1.0),
    confidence FLOAT DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1.0),
    duration_ms INTEGER,
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Indexes for learning event queries
CREATE INDEX IF NOT EXISTS idx_rcd_learning_events_agent ON rcd_learning_events (agent_id);
CREATE INDEX IF NOT EXISTS idx_rcd_learning_events_type ON rcd_learning_events (event_type);
CREATE INDEX IF NOT EXISTS idx_rcd_learning_events_outcome ON rcd_learning_events (outcome);
CREATE INDEX IF NOT EXISTS idx_rcd_learning_events_timestamp ON rcd_learning_events (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_rcd_learning_events_impact ON rcd_learning_events (impact_score DESC);

-- Evolution history for tracking autonomous changes
CREATE TABLE IF NOT EXISTS rcd_evolution_history (
    id SERIAL PRIMARY KEY,
    file_path TEXT NOT NULL,
    change_type TEXT NOT NULL CHECK (change_type IN (
        'capability_added', 'dependency_resolved', 'pattern_applied',
        'structure_optimized', 'complexity_reduced', 'stability_improved',
        'performance_optimized', 'code_generated', 'refactored', 'migrated'
    )),
    before_state JSONB,
    after_state JSONB,
    triggered_by TEXT, -- agent_id or event_id
    success BOOLEAN DEFAULT TRUE,
    rollback_data JSONB, -- For autonomous rollback if needed
    validation_score FLOAT DEFAULT 0.0,
    performance_impact FLOAT DEFAULT 0.0,
    stability_impact FLOAT DEFAULT 0.0,
    approval_required BOOLEAN DEFAULT FALSE,
    approved_by TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Indexes for evolution tracking
CREATE INDEX IF NOT EXISTS idx_rcd_evolution_file ON rcd_evolution_history (file_path);
CREATE INDEX IF NOT EXISTS idx_rcd_evolution_type ON rcd_evolution_history (change_type);
CREATE INDEX IF NOT EXISTS idx_rcd_evolution_success ON rcd_evolution_history (success);
CREATE INDEX IF NOT EXISTS idx_rcd_evolution_timestamp ON rcd_evolution_history (timestamp DESC);

-- Dependency graph for real-time capability resolution
CREATE TABLE IF NOT EXISTS rcd_dependency_graph (
    id SERIAL PRIMARY KEY,
    consumer_file TEXT NOT NULL,
    provider_file TEXT NOT NULL,
    capability TEXT NOT NULL,
    interface_used TEXT,
    dependency_strength FLOAT DEFAULT 1.0 CHECK (dependency_strength >= 0 AND dependency_strength <= 1.0),
    last_accessed TIMESTAMP DEFAULT NOW(),
    access_count INTEGER DEFAULT 1,
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(consumer_file, provider_file, capability)
);

-- Indexes for dependency resolution
CREATE INDEX IF NOT EXISTS idx_rcd_dep_graph_consumer ON rcd_dependency_graph (consumer_file);
CREATE INDEX IF NOT EXISTS idx_rcd_dep_graph_provider ON rcd_dependency_graph (provider_file);
CREATE INDEX IF NOT EXISTS idx_rcd_dep_graph_capability ON rcd_dependency_graph (capability);
CREATE INDEX IF NOT EXISTS idx_rcd_dep_graph_critical ON rcd_dependency_graph (is_critical);

-- Performance metrics for RCD system itself
CREATE TABLE IF NOT EXISTS rcd_system_metrics (
    id SERIAL PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value FLOAT NOT NULL,
    metric_unit TEXT,
    context JSONB DEFAULT '{}',
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rcd_metrics_name ON rcd_system_metrics (metric_name);
CREATE INDEX IF NOT EXISTS idx_rcd_metrics_time ON rcd_system_metrics (recorded_at DESC);

-- Views for common queries
CREATE OR REPLACE VIEW rcd_capability_providers AS
SELECT
    c.capability_name,
    c.provider_files,
    c.stability_rating,
    c.usage_frequency,
    array_length(c.provider_files, 1) as provider_count,
    array_length(c.consumer_files, 1) as consumer_count
FROM rcd_capabilities c
WHERE array_length(c.provider_files, 1) > 0;

CREATE OR REPLACE VIEW rcd_file_health AS
SELECT
    f.file_path,
    f.file_type,
    f.performance_score,
    f.stability_rating,
    f.complexity_level,
    array_length(f.capabilities, 1) as capability_count,
    array_length(f.dependencies, 1) as dependency_count,
    CASE
        WHEN f.performance_score >= 0.8 AND f.stability_rating >= 0.8 THEN 'healthy'
        WHEN f.performance_score >= 0.6 AND f.stability_rating >= 0.6 THEN 'moderate'
        ELSE 'needs_attention'
    END as health_status
FROM rcd_files f;

CREATE OR REPLACE VIEW rcd_unresolved_dependencies AS
SELECT DISTINCT
    unnest(f.dependencies) as dependency,
    f.file_path as requesting_file,
    f.file_type
FROM rcd_files f
WHERE NOT EXISTS (
    SELECT 1 FROM rcd_capabilities c
    WHERE c.capability_name = ANY(f.dependencies)
    AND array_length(c.provider_files, 1) > 0
);

-- Functions for common operations
CREATE OR REPLACE FUNCTION rcd_update_capability_usage(cap_name TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE rcd_capabilities
    SET usage_frequency = usage_frequency + 1,
        last_accessed = NOW(),
        updated_at = NOW()
    WHERE capability_name = cap_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rcd_record_pattern_usage(pattern_id INTEGER, success BOOLEAN)
RETURNS VOID AS $$
BEGIN
    UPDATE rcd_patterns
    SET usage_count = usage_count + 1,
        success_rate = CASE
            WHEN usage_count = 0 THEN CASE WHEN success THEN 1.0 ELSE 0.0 END
            ELSE (success_rate * usage_count + CASE WHEN success THEN 1.0 ELSE 0.0 END) / (usage_count + 1)
        END,
        last_used = NOW(),
        updated_at = NOW()
    WHERE id = pattern_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rcd_calculate_system_health()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    total_files INTEGER;
    healthy_files INTEGER;
    capability_coverage FLOAT;
    dependency_resolution FLOAT;
BEGIN
    -- Count total and healthy files
    SELECT COUNT(*) INTO total_files FROM rcd_files;
    SELECT COUNT(*) INTO healthy_files FROM rcd_file_health WHERE health_status = 'healthy';

    -- Calculate capability coverage
    SELECT
        CASE WHEN COUNT(*) = 0 THEN 0.0
        ELSE COUNT(CASE WHEN array_length(provider_files, 1) > 0 THEN 1 END)::FLOAT / COUNT(*)::FLOAT
        END INTO capability_coverage
    FROM rcd_capabilities;

    -- Calculate dependency resolution rate
    SELECT
        CASE WHEN total_deps = 0 THEN 1.0
        ELSE 1.0 - (unresolved_deps::FLOAT / total_deps::FLOAT)
        END INTO dependency_resolution
    FROM (
        SELECT
            (SELECT COUNT(*) FROM (SELECT unnest(dependencies) FROM rcd_files) AS all_deps) as total_deps,
            (SELECT COUNT(*) FROM rcd_unresolved_dependencies) as unresolved_deps
    ) AS dep_calc;

    result := jsonb_build_object(
        'total_files', total_files,
        'healthy_files', healthy_files,
        'file_health_ratio', CASE WHEN total_files = 0 THEN 0.0 ELSE healthy_files::FLOAT / total_files::FLOAT END,
        'capability_coverage', capability_coverage,
        'dependency_resolution_rate', dependency_resolution,
        'overall_score', (
            CASE WHEN total_files = 0 THEN 0.0 ELSE healthy_files::FLOAT / total_files::FLOAT END +
            capability_coverage +
            dependency_resolution
        ) / 3.0,
        'calculated_at', NOW()
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic maintenance
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to tables with updated_at columns
CREATE TRIGGER update_rcd_files_updated_at
    BEFORE UPDATE ON rcd_files
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rcd_patterns_updated_at
    BEFORE UPDATE ON rcd_patterns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rcd_capabilities_updated_at
    BEFORE UPDATE ON rcd_capabilities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample data for testing
INSERT INTO rcd_capabilities (capability_name, description, category) VALUES
('database_operations', 'CRUD operations on PostgreSQL database', 'core'),
('step_execution', 'Execute RLang steps and operations', 'core'),
('error_handling', 'Handle and recover from errors', 'utility'),
('api_operations', 'HTTP requests and API integrations', 'integration'),
('filesystem_operations', 'Read and write files', 'utility'),
('code_generation', 'Generate code from templates', 'ai'),
('ai_inference', 'LLM and AI model operations', 'ai'),
('logging_monitoring', 'System logging and monitoring', 'utility'),
('user_interaction', 'Chat and user interface operations', 'interface'),
('agent_orchestration', 'Coordinate multiple agents', 'core')
ON CONFLICT (capability_name) DO NOTHING;

-- Create initial system health record
INSERT INTO rcd_system_metrics (metric_name, metric_value, metric_unit)
VALUES ('initialization_complete', 1.0, 'boolean');

COMMENT ON TABLE rcd_files IS 'Tracks all files in the system with their capabilities and dependencies';
COMMENT ON TABLE rcd_patterns IS 'Stores learned patterns for decision making and evolution';
COMMENT ON TABLE rcd_capabilities IS 'Registry of all system capabilities and their providers';
COMMENT ON TABLE rcd_learning_events IS 'Log of all learning and evolution events';
COMMENT ON TABLE rcd_evolution_history IS 'History of autonomous system changes';
COMMENT ON TABLE rcd_dependency_graph IS 'Real-time dependency relationships between files';

-- Grant permissions (adjust as needed for your security model)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol3_system;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol3_system;
