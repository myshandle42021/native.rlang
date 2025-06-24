// utils/tamr.ts - Internal logging and memory system
import { db } from './db';
import { RLangContext } from '../schema/types';

export async function log(args: any, context: RLangContext) {
  const logEntry = {
    agent_id: context.agentId,
    client_id: context.clientId,
    event: args.event || 'unknown',
    data: args,
    timestamp: new Date().toISOString(),
    execution_id: context.memory.execution_id,
    success: true
  };

  const { error } = await db.from('agent_logs').insert(logEntry);
  if (error) throw new Error(`TAMR log failed: ${error.message}`);

  return { logged: true, entry: logEntry };
}

export async function query(args: any, context: RLangContext) {
  let query = db.from('agent_logs');

  if (args.agent_id) {
    query = query.eq('agent_id', args.agent_id);
  } else if (context.agentId) {
    query = query.eq('agent_id', context.agentId);
  }

  if (args.event) query = query.eq('event', args.event);
  if (args.since) query = query.gte('timestamp', args.since);
  if (args.limit) query = query.limit(args.limit);

  query = query.order('timestamp', { ascending: false });

  const { data, error } = await query;
  if (error) throw new Error(`TAMR query failed: ${error.message}`);

  return data || [];
}

export async function remember(args: any, context: RLangContext) {
  context.memory[args.key] = args.value;

  if (args.persist) {
    await log({ event: 'memory_update', key: args.key, value: args.value }, context);
  }

  return { remembered: true, key: args.key };
}