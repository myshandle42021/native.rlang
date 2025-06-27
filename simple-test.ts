// simple-test.js - Quick LLM test without TypeScript
require("dotenv").config();

async function testLLMConnection() {
  console.log("🧪 Testing LLM Connection...");

  // Check environment
  console.log("📋 Environment Check:");
  console.log(
    "  OPENAI_API_KEY:",
    process.env.OPENAI_API_KEY
      ? `✅ Set (${process.env.OPENAI_API_KEY.substring(0, 20)}...)`
      : "❌ Missing",
  );
  console.log(
    "  ANTHROPIC_API_KEY:",
    process.env.ANTHROPIC_API_KEY ? "✅ Set" : "❌ Missing",
  );

  // Test OpenAI API call
  if (process.env.OPENAI_API_KEY) {
    try {
      console.log("\n🔄 Testing OpenAI API...");
      const response = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [
              { role: "user", content: 'Just reply with "API_TEST_OK"' },
            ],
            max_tokens: 10,
          }),
        },
      );

      if (response.ok) {
        const data = await response.json();
        console.log("✅ OpenAI Response:", data.choices[0].message.content);
      } else {
        const error = await response.text();
        console.log("❌ OpenAI Error:", response.status, error);

        if (response.status === 401) {
          console.log("💡 This looks like an invalid API key!");
        }
      }
    } catch (error) {
      console.log("❌ OpenAI Request Failed:", error.message);
    }
  }

  // Also test a simplified intent extraction
  if (process.env.OPENAI_API_KEY) {
    try {
      console.log("\n🧠 Testing Intent Extraction...");
      const response = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [
              {
                role: "user",
                content: `Extract intent from: "Create an agent that connects to Xero to analyze revenue"

            Respond with YAML:
            agent_requirements:
              agent_type: "[type]"
              primary_purpose: "[purpose]"
            system_integrations:
              required_services: ["[service]"]`,
              },
            ],
            max_tokens: 200,
          }),
        },
      );

      if (response.ok) {
        const data = await response.json();
        console.log("🎯 Intent Extraction Result:");
        console.log("─".repeat(50));
        console.log(data.choices[0].message.content);
        console.log("─".repeat(50));
      } else {
        const error = await response.text();
        console.log("❌ Intent Extraction Failed:", response.status, error);
      }
    } catch (error) {
      console.log("❌ Intent Extraction Error:", error.message);
    }
  }
}

testLLMConnection().catch(console.error);
