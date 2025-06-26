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

  // RPC method for stored procedures
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

  // Raw method for raw SQL expressions
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

// FIXED: Query builder that separates building from executing
class PostgreSQLQueryBuilder {
  private table: string;
  private selectFields: string = "*";
  private whereConditions: string[] = [];
  private orderByClause: string = "";
  private limitClause: string = "";
  private params: any[] = [];
  private paramCount: number = 0;

  // Conflict resolution properties
  private conflictClause: string = "";
  private conflictAction: string = "";
  private updateFields: Record<string, any> = {};
  private insertData: any = null;
  private updateData: any = null;
  private isDeleteQuery: boolean = false;

  constructor(table: string) {
    this.table = table;
  }

  // CHAINABLE METHODS - These build the query
  select(fields: string = "*"): PostgreSQLQueryBuilder {
    this.selectFields = fields;
    return this;
  }

  eq(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} = $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  neq(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} != $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  gte(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} >= $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  lte(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} <= $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  gt(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} > $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  lt(column: string, value: any): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} < $${this.paramCount}`);
    this.params.push(value);
    return this;
  }

  ilike(column: string, pattern: string): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} ILIKE $${this.paramCount}`);
    this.params.push(pattern);
    return this;
  }

  in(column: string, values: any[]): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} = ANY($${this.paramCount})`);
    this.params.push(values);
    return this;
  }

  contains(column: string, values: any[]): PostgreSQLQueryBuilder {
    this.paramCount++;
    this.whereConditions.push(`${column} @> $${this.paramCount}`);
    this.params.push(JSON.stringify(values));
    return this;
  }

  // FIXED: on() method for conflict resolution - CHAINABLE
  on(conflict: string, action?: string): PostgreSQLQueryBuilder {
    this.conflictClause = `ON CONFLICT (${conflict})`;
    this.conflictAction = action || "DO NOTHING";
    return this;
  }

  order(
    column: string,
    options: { ascending?: boolean } = {},
  ): PostgreSQLQueryBuilder {
    const direction = options.ascending === false ? "DESC" : "ASC";
    this.orderByClause = `ORDER BY ${column} ${direction}`;
    return this;
  }

  limit(count: number): PostgreSQLQueryBuilder {
    this.limitClause = `LIMIT ${count}`;
    return this;
  }

  // FIXED: insert() method - CHAINABLE, not async
  insert(data: any | any[]): PostgreSQLQueryBuilder {
    this.insertData = data;
    return this;
  }

  // FIXED: update() method - CHAINABLE, not async
  update(data: any): PostgreSQLQueryBuilder {
    this.updateData = data;
    this.updateFields = { ...data };
    return this;
  }

  // FIXED: delete() method - CHAINABLE, not async
  delete(): PostgreSQLQueryBuilder {
    this.isDeleteQuery = true;
    return this;
  }

  // EXECUTION METHODS - These actually run the query
  async execute(): Promise<{ data: any[] | null; error: any }> {
    try {
      let sql = "";
      let queryParams = [...this.params];

      if (this.insertData) {
        // INSERT query
        const records = Array.isArray(this.insertData)
          ? this.insertData
          : [this.insertData];
        if (records.length === 0) return { data: [], error: null };

        const columns = Object.keys(records[0]);
        const columnList = columns.join(", ");
        const valueRows: string[] = [];
        let paramIndex = this.paramCount + 1;

        for (const record of records) {
          const rowParams: string[] = [];
          for (const column of columns) {
            rowParams.push(`$${paramIndex++}`);
            queryParams.push(record[column]);
          }
          valueRows.push(`(${rowParams.join(", ")})`);
        }

        sql = `INSERT INTO ${this.table} (${columnList}) VALUES ${valueRows.join(", ")}`;

        // Handle conflict resolution
        if (this.conflictClause) {
          sql += ` ${this.conflictClause}`;
          if (this.conflictAction === "DO NOTHING") {
            sql += " DO NOTHING";
          } else if (Object.keys(this.updateFields).length > 0) {
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
      } else if (this.updateData) {
        // UPDATE query
        if (this.whereConditions.length === 0) {
          throw new Error("UPDATE requires WHERE conditions for safety");
        }

        const columns = Object.keys(this.updateData);
        const setClause = columns
          .map((col, index) => {
            if (
              this.updateData[col] &&
              typeof this.updateData[col] === "object" &&
              this.updateData[col].isRaw
            ) {
              return `${col} = ${this.updateData[col].expression}`;
            }
            queryParams.push(this.updateData[col]);
            return `${col} = $${queryParams.length}`;
          })
          .join(", ");

        sql = `UPDATE ${this.table} SET ${setClause} WHERE ${this.whereConditions.join(" AND ")} RETURNING *`;
      } else if (this.isDeleteQuery) {
        // DELETE query
        if (this.whereConditions.length === 0) {
          throw new Error("DELETE requires WHERE conditions for safety");
        }

        sql = `DELETE FROM ${this.table} WHERE ${this.whereConditions.join(" AND ")} RETURNING *`;
      } else {
        // SELECT query
        const whereClause =
          this.whereConditions.length > 0
            ? `WHERE ${this.whereConditions.join(" AND ")}`
            : "";
        sql =
          `SELECT ${this.selectFields} FROM ${this.table} ${whereClause} ${this.orderByClause} ${this.limitClause}`.trim();
      }

      const client = await pool.connect();
      try {
        const result = await client.query(sql, queryParams);
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
}

// Database utilities
export const dbUtils = {
  // Run migrations
  migrate: async () => {
    const client = await pool.connect();
    try {
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
};

// Standalone exports for R-lang step executor
export async function health(args: any, context: any) {
  return db.health();
}
