const { db } = require('./utils/db');

async function debugConfig() {
  const { data, error } = await db
    .from("api_connections")
    .select("*")
    .eq("service", "rocketchat")
    .eq("client_id", "default")
    .limit(1);
    
  console.log("Raw database config:", JSON.stringify(data[0], null, 2));
  
  if (data[0]) {
    console.log("Base URL:", data[0].base_url);
    console.log("Endpoints object:", data[0].endpoints);
    console.log("Credentials endpoints:", data[0].credentials?.endpoints);
    console.log("Endpoint lookup test:", data[0].endpoints?.send_message || data[0].credentials?.endpoints?.send_message);
  }
}

debugConfig().catch(console.error);
