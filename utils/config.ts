import { RLangContext } from "../schema/types";
import { db } from "./db";

export async function get(args: any, context: RLangContext) {
  const key = args.key;
  const clientId = context.clientId || "default";

  try {
    const { data, error } = await db
      .from("dynamic_configs")
      .select("config_value")
      .eq("config_key", key)
      .eq("client_id", clientId)
      .limit(1);

    if (error) {
      console.warn(`Config get error for ${key}:`, error);
      return { config_value: null };
    }

    return {
      config_value: data && data.length > 0 ? data[0].config_value : null,
    };
  } catch (error) {
    console.warn(`Config get exception for ${key}:`, error);
    return { config_value: null };
  }
}

export async function set(args: any, context: RLangContext) {
  const { key, value } = args;
  const clientId = context.clientId || "default";

  try {
    const { data, error } = await db
      .from("dynamic_configs")
      .insert({
        config_key: key,
        config_value: value,
        client_id: clientId,
        scope: "global",
        updated_at: new Date().toISOString(),
      })
      .select();

    if (error) {
      console.warn(`Config set error for ${key}:`, error);
      return { configured: false, error };
    }

    return { configured: true, data };
  } catch (error) {
    console.warn(`Config set exception for ${key}:`, error);
    return { configured: false, error };
  }
}
