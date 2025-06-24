// utils/db.ts
// PostgreSQL database connection for VPS deployment

import { Pool, PoolClient } from "pg";
import dotenv from "dotenv";

dotenv.config();

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: parseInt(process.env.DB_POOL_SIZE || "20"),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: parseInt(process.env.DB_TIMEOUT || "30000"),
  ssl:
    process.env.NODE_ENV === "production"
      ? { rejectUnauthorized: false }
      : false,
});

// Connection health check
pool.on("connect", () => {
  console.log("🔗 Database connection established");
});

pool.on("error", (err) => {
  console.error("💥 Database connection error:", err);
});

// Supabase-compatible interface for existing ROL3 code
export const db = {
  from: (table: string) => new PostgreSQLQueryBuilder(table),

  // Direct SQL execution
  query: async (text: string, params?: any[]) => {
    const client = await pool.connect();
    try {
      const result = await client.query(text, params);
      return { data: result.rows, error: null };
    } catch (error) {
      return { data: null, error };
    } finally {
      client.release();
    }
  },

  // RPC method for stored procedures - FIXES .rpc() ERRORS
  rpc: async (functionName: string, params: any = {}) => {
    const client = await pool.connect();
    try {
      const paramKeys = Object.keys(params);
      const paramValues = paramKeys.map((key) => params[key]);
      const paramPlaceholders = paramValues.map((_, i) => `$${i + 1}`);

      const sql = `SELECT * FROM ${functionName}(${paramPlaceholders.join(", ")})`;

      const result = await client.query(sql, paramValues);
      return { data: result.rows, error: null };
    } catch (error) {
      return { data: null, error };
    } finally {
      client.release();
    }
  },

  // Raw method for raw SQL expressions - FIXES .raw() ERRORS
  raw: (expression: string) => {
    return {
      isRaw: true,
      expression: expression,
    };
  },

  // Health check
  health: async () => {
    try {
      const result = await pool.query("SELECT NOW()");
      return { healthy: true, timestamp: result.rows[0].now };
    } catch (error) {
      return {
        healthy: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  },
};

// Query builder to match Supabase API
class PostgreSQLQueryBuilder {
  private table: string;
  private selectFields: string = "*";
  private whereConditions: string[] = [];
  private orderByClause: string = "";
  private limitClause: string = "";
  private params: any[] = [];
  private paramCount: number = 0;

  // NEW: Add missing properties for conflict resolution
  private conflictClause: string = "";
  private conflictAction: string = "";
  private updateFields: Record<string, any> = {};

  constructor(table: string) {
    this.table = table;
  }

  select(fields: string = "*") {
    this.selectFields = fields;
    return this;
  }

  eq(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} = $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  neq(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} != $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  gte(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} >= $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  lte(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} <= $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  gt(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} > $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  lt(column: string, value: any) {
    this.paramCount++;
    this.whereConditions.push(`${column} < $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  ilike(column: string, pattern: string) {
    this.paramCount++;
    this.whereConditions.push(`${column} ILIKE $${this.paramCount}`);
    this.params.push(pattern);
    return this;
  }

  in(column: string, values: any[]) {
    this.paramCount++;
    this.whereConditions.push(`${column} = ANY($${this.paramCount})`);
    this.params.push(values);
    return this;
  }

  // NEW: contains method for array operations - FIXES .contains() ERRORS
  contains(column: string, values: any[]) {
    this.paramCount++;
    this.whereConditions.push(`${column} @> $${this.paramCount}`);
    this.params.push(JSON.stringify(values));
    return this;
  }

  // NEW: on method for upsert operations - FIXES .on() ERRORS
  on(conflict: string, action?: string) {
    this.conflictClause = `ON CONFLICT (${conflict})`;
    this.conflictAction = action || "DO NOTHING";
    return this;
  }

  order(column: string, options: { ascending?: boolean } = {}) {
    const direction = options.ascending === false ? "DESC" : "ASC";
    this.orderByClause = `ORDER BY ${column} ${direction}`;
    return this;
  }

  limit(count: number) {
    this.limitClause = `LIMIT ${count}`;
    return this;
  }

  // Execute SELECT query
  async execute(): Promise<{ data: any[] | null; error: any }> {
    try {
      const whereClause =
        this.whereConditions.length > 0
          ? `WHERE ${this.whereConditions.join(" AND ")}`
          : "";

      const sql = `
        SELECT ${this.selectFields}
        FROM ${this.table}
        ${whereClause}
        ${this.orderByClause}
        ${this.limitClause}
      `.trim();

      const client = await pool.connect();
      try {
        const result = await client.query(sql, this.params);
        return { data: result.rows, error: null };
      } finally {
        client.release();
      }
    } catch (error) {
      return { data: null, error };
    }
  }

  // Promise-like interface for compatibility
  then(onResolve: (result: { data: any[] | null; error: any }) => any) {
    return this.execute().then(onResolve);
  }

  catch(onReject: (error: any) => any) {
    return this.execute().catch(onReject);
  }

  // ENHANCED: INSERT operation with conflict resolution
  async insert(data: any | any[]): Promise<{ data: any[] | null; error: any }> {
    try {
      const isArray = Array.isArray(data);
      const records = isArray ? data : [data];

      if (records.length === 0) {
        return { data: [], error: null };
      }

      // Get column names from first record
      const columns = Object.keys(records[0]);
      const columnList = columns.join(", ");

      // Build parameterized values
      const valueRows: string[] = [];
      const allParams: any[] = [];
      let paramIndex = 1;

      for (const record of records) {
        const rowParams: string[] = [];
        for (const column of columns) {
          rowParams.push(`$${paramIndex++}`);
          allParams.push(record[column]);
        }
        valueRows.push(`(${rowParams.join(", ")})`);
      }

      let sql = `
        INSERT INTO ${this.table} (${columnList})
        VALUES ${valueRows.join(", ")}
      `;

      // NEW: Add conflict resolution if specified
      if (this.conflictClause) {
        sql += ` ${this.conflictClause}`;

        if (this.conflictAction === "DO NOTHING") {
          sql += " DO NOTHING";
        } else if (Object.keys(this.updateFields).length > 0) {
          // Handle DO UPDATE SET
          const updateList = Object.keys(this.updateFields).map((key) => {
            if (
              this.updateFields[key] &&
              typeof this.updateFields[key] === "object" &&
              this.updateFields[key].isRaw
            ) {
              return `${key} = ${this.updateFields[key].expression}`;
            }
            return `${key} = EXCLUDED.${key}`;
          });
          sql += ` DO UPDATE SET ${updateList.join(", ")}`;
        }
      }

      sql += " RETURNING *";

      const client = await pool.connect();
      try {
        const result = await client.query(sql, allParams);
        return { data: result.rows, error: null };
      } finally {
        client.release();
      }
    } catch (error) {
      return { data: null, error };
    }
  }

  // ENHANCED: UPDATE operation - now supports chaining with .on()
  async update(data: any): Promise<{ data: any[] | null; error: any }> {
    try {
      // Store update fields for potential use in conflict resolution
      this.updateFields = { ...data };

      if (this.whereConditions.length === 0) {
        throw new Error("UPDATE requires WHERE conditions for safety");
      }

      const columns = Object.keys(data);
      const setClause = columns
        .map((col, index) => {
          // Handle raw SQL expressions
          if (data[col] && typeof data[col] === "object" && data[col].isRaw) {
            return `${col} = ${data[col].expression}`;
          }
          return `${col} = $${this.params.length + index + 1}`;
        })
        .join(", ");

      // Only add non-raw values to params
      const updateParams = [
        ...this.params,
        ...columns
          .filter(
            (col) =>
              !(data[col] && typeof data[col] === "object" && data[col].isRaw),
          )
          .map((col) => data[col]),
      ];

      const whereClause = `WHERE ${this.whereConditions.join(" AND ")}`;

      const sql = `
        UPDATE ${this.table}
        SET ${setClause}
        ${whereClause}
        RETURNING *
      `;

      const client = await pool.connect();
      try {
        const result = await client.query(sql, updateParams);
        return { data: result.rows, error: null };
      } finally {
        client.release();
      }
    } catch (error) {
      return { data: null, error };
    }
  }

  // DELETE operation
  async delete(): Promise<{ data: any[] | null; error: any }> {
    try {
      if (this.whereConditions.length === 0) {
        throw new Error("DELETE requires WHERE conditions for safety");
      }

      const whereClause = `WHERE ${this.whereConditions.join(" AND ")}`;

      const sql = `
        DELETE FROM ${this.table}
        ${whereClause}
        RETURNING *
      `;

      const client = await pool.connect();
      try {
        const result = await client.query(sql, this.params);
        return { data: result.rows, error: null };
      } finally {
        client.release();
      }
    } catch (error) {
      return { data: null, error };
    }
  }
}

// Database utilities
export const dbUtils = {
  // Run migrations
  migrate: async () => {
    const client = await pool.connect();
    try {
      // Check if migrations table exists
      const migrationCheck = await client.query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables
          WHERE table_name = 'migrations'
        );
      `);

      if (!migrationCheck.rows[0].exists) {
        await client.query(`
          CREATE TABLE migrations (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            executed_at TIMESTAMPTZ DEFAULT NOW()
          );
        `);
      }

      console.log("✅ Database migrations ready");
    } finally {
      client.release();
    }
  },

  // Clean old logs
  cleanup: async (retentionDays: number = 30) => {
    const client = await pool.connect();
    try {
      const result = await client.query(`
        DELETE FROM agent_logs
        WHERE timestamp < NOW() - INTERVAL '${retentionDays} days'
        RETURNING count(*);
      `);

      console.log(`🧹 Cleaned ${result.rowCount} old log entries`);
    } finally {
      client.release();
    }
  },

  // Get database stats
  getStats: async () => {
    const client = await pool.connect();
    try {
      const stats = await client.query(`
        SELECT
          schemaname,
          tablename,
          n_tup_ins as inserts,
          n_tup_upd as updates,
          n_tup_del as deletes,
          n_live_tup as live_rows,
          n_dead_tup as dead_rows
        FROM pg_stat_user_tables
        ORDER BY n_live_tup DESC;
      `);

      return stats.rows;
    } finally {
      client.release();
    }
  },
};

// Graceful shutdown
process.on("SIGINT", async () => {
  console.log("🔌 Closing database connections...");
  await pool.end();
});

process.on("SIGTERM", async () => {
  console.log("🔌 Closing database connections...");
  await pool.end();
});
