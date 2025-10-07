// openrouter-chat edge function
// Example demonstrating OpenRouter integration with Supabase Edge Functions
// OpenRouter provides access to 100+ AI models through a single API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for browser requests
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Types for our request/response
interface RequestBody {
  message: string;
  model?: string;
}

interface ResponseBody {
  reply: string;
  model: string;
  provider?: string;
  timestamp: string;
  user?: {
    id: string;
    email?: string;
  };
}

// Main request handler
serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get OpenRouter API key from environment
    const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");

    if (!openrouterApiKey) {
      console.error("OPENROUTER_API_KEY is not set in environment variables");
      return new Response(
        JSON.stringify({
          error:
            "OpenRouter API key is not configured. Please set OPENROUTER_API_KEY in your Supabase secrets.",
          hint: "Run: supabase secrets set OPENROUTER_API_KEY=sk-or-your_key_here",
          documentation: "See OPENROUTER_SETUP.md for OpenRouter setup instructions",
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
          status: 500,
        },
      );
    }

    // Parse request body
    const { message, model = "openai/gpt-3.5-turbo" }: RequestBody = await req.json();

    if (!message) {
      return new Response(
        JSON.stringify({
          error: "Message is required",
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
          status: 400,
        },
      );
    }

    // Get authorization header to check if user is authenticated
    const authHeader = req.headers.get("Authorization");
    let user = null;

    if (authHeader) {
      // Create Supabase client with the user's JWT
      const supabaseClient = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        {
          global: {
            headers: { Authorization: authHeader },
          },
        },
      );

      // Get the authenticated user
      const { data: { user: authUser } } = await supabaseClient.auth.getUser();
      if (authUser) {
        user = {
          id: authUser.id,
          email: authUser.email,
        };
      }
    }

    // Call OpenRouter API
    console.log(`Calling OpenRouter API with model: ${model}`);
    const openrouterResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openrouterApiKey}`,
        "Content-Type": "application/json",
        // Optional: These headers help your app appear on OpenRouter leaderboards
        "HTTP-Referer": Deno.env.get("SUPABASE_URL") || "",
        "X-Title": "Supabase AI App",
      },
      body: JSON.stringify({
        model: model,
        messages: [
          {
            role: "user",
            content: message,
          },
        ],
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!openrouterResponse.ok) {
      const errorData = await openrouterResponse.json();
      console.error("OpenRouter API error:", errorData);

      return new Response(
        JSON.stringify({
          error: "OpenRouter API request failed",
          details: errorData,
          hint:
            "Check your API key and model name. Model format should be 'provider/model-name' (e.g., 'openai/gpt-3.5-turbo')",
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
          status: openrouterResponse.status,
        },
      );
    }

    const data = await openrouterResponse.json();
    const reply = data.choices[0]?.message?.content || "No response generated";

    // Extract provider from model name
    const provider = model.split("/")[0];

    // Prepare response
    const response: ResponseBody = {
      reply,
      model,
      provider,
      timestamp: new Date().toISOString(),
      ...(user && { user }),
    };

    // Return successful response
    return new Response(
      JSON.stringify(response),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
        status: 200,
      },
    );
  } catch (error) {
    // Error handling
    console.error("Function error:", error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
        status: 500,
      },
    );
  }
});

/*
 * Testing this function:
 *
 * 1. Set up OpenRouter API key:
 *    Get your key from https://openrouter.ai
 *    supabase secrets set OPENROUTER_API_KEY=sk-or-your_openrouter_key
 *
 * 2. Local development:
 *    supabase functions serve openrouter-chat
 *
 * 3. Basic test with OpenAI model:
 *    curl -i http://localhost:54321/functions/v1/openrouter-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Hello, how are you?"}'
 *
 * 4. Test with Anthropic Claude:
 *    curl -i http://localhost:54321/functions/v1/openrouter-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Explain quantum computing", "model": "anthropic/claude-3-sonnet"}'
 *
 * 5. Test with Google Gemini:
 *    curl -i http://localhost:54321/functions/v1/openrouter-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "What is machine learning?", "model": "google/gemini-pro"}'
 *
 * 6. Test with Meta Llama:
 *    curl -i http://localhost:54321/functions/v1/openrouter-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Write a haiku", "model": "meta-llama/llama-3-70b"}'
 *
 * 7. With authentication:
 *    curl -i http://localhost:54321/functions/v1/openrouter-chat \
 *      -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Hello!"}'
 *
 * 8. Deploy:
 *    supabase functions deploy openrouter-chat
 *
 * See https://openrouter.ai/models for all available models
 */
