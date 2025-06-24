-- ROL3 Database Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Agent execution logs (TAMR system)
CREATE TABLE IF NOT EXISTS agent_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL,
    client_id TEXT,
    execution_id TEXT NOT NULL,
    event TEXT NOT NULL,
    data JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    success BOOLEAN DEFAULT true,
    error TEXT,
    step_name TEXT,
    duration_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_agent_logs_agent_timestamp ON agent_logs(agent_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_agent_logs_event ON agent_logs(event);

-- System health tracking
CREATE TABLE IF NOT EXISTS system_health (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    status TEXT NOT NULL CHECK (status IN ('healthy', 'degraded', 'critical')),
    last_check TIMESTAMPTZ DEFAULT NOW(),
    issues JSONB DEFAULT '[]',
    metrics JSONB DEFAULT '{}',
    doctor_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dynamic configuration
CREATE TABLE IF NOT EXISTS dynamic_configs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    config_key TEXT NOT NULL,
    config_value JSONB NOT NULL,
    client_id TEXT,
    scope TEXT DEFAULT 'global',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(config_key, client_id, scope)
);

CREATE INDEX IF NOT EXISTS idx_dynamic_configs_key_client ON dynamic_configs(config_key, client_id);

-- API connections (auto-discovered integrations)
CREATE TABLE IF NOT EXISTS api_connections (
    id TEXT PRIMARY KEY,
    service TEXT NOT NULL,
    auth_type TEXT NOT NULL,
    base_url TEXT,
    endpoints TEXT[] DEFAULT '{}',
    client_id TEXT,
    credentials JSONB DEFAULT '{}',
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_connections_service_client ON api_connections(service, client_id);

-- Agent states
CREATE TABLE IF NOT EXISTS agent_states (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL UNIQUE,
    client_id TEXT,
    status TEXT DEFAULT 'active',
    config JSONB DEFAULT '{}',
    memory JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial system health
INSERT INTO system_health (status, issues, metrics)
VALUES ('healthy', '[]', '{"initialized": true}')
ON CONFLICT DO NOTHING;

-- Insert basic system configs
INSERT INTO dynamic_configs (config_key, config_value, scope) VALUES
('SYSTEM_INITIALIZED', '"true"', 'global'),
('AUTO_DISCOVERY_ENABLED', 'true', 'global')
ON CONFLICT (config_key, client_id, scope) DO NOTHING;
