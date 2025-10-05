# Quick Start: OpenAI Integration

This is a quick reference guide to get OpenAI working with Supabase. For full details, see [OPENAI_SETUP.md](OPENAI_SETUP.md).

## 🚀 For Supabase Studio AI Features (5 minutes)

Want AI-powered SQL generation and query assistance in the Supabase Studio? Follow these steps:

1. **Get an OpenAI API key**
   ```
   Visit: https://platform.openai.com/api-keys
   Create a new key (starts with sk-...)
   ```

2. **Create `.env` file**
   ```bash
   cp .env.example .env
   ```

3. **Add your key to `.env`**
   ```bash
   SUPABASE_OPENAI_API_KEY=sk-your-actual-key-here
   ```

4. **Start Supabase**
   ```bash
   npm run db:start
   ```

5. **Done!** Open http://localhost:8000 and use AI features

## 🔧 For Custom Edge Functions (10 minutes)

Want to call OpenAI from your own Edge Functions? Follow these steps:

1. **Check the example function**
   ```bash
   cat supabase/functions/openai-chat/index.ts
   ```

2. **Set the secret**
   ```bash
   # For local development, add to .env
   echo "OPENAI_API_KEY=sk-your-key" >> .env
   
   # For production
   supabase secrets set OPENAI_API_KEY=sk-your-key
   ```

3. **Test locally**
   ```bash
   # Start Supabase
   supabase start
   
   # Serve the function
   supabase functions serve openai-chat
   
   # In another terminal, test it
   curl http://localhost:54321/functions/v1/openai-chat \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello!"}'
   ```

4. **Deploy**
   ```bash
   supabase functions deploy openai-chat
   ```

## ❓ Troubleshooting

**"OPENAI_API_KEY is not set"**
- Check your `.env` file exists
- Verify the key name matches exactly
- Restart Supabase

**"Invalid API key"**
- Get a new key from https://platform.openai.com/api-keys
- Ensure you copied the full key (starts with sk-)
- Check your OpenAI account has billing set up

**Studio AI features not working**
- Use `SUPABASE_OPENAI_API_KEY` (not `OPENAI_API_KEY`)
- Restart Supabase after adding the key
- Check the key in `.env` has no quotes

## 📝 Key Differences

| Use Case | Variable Name | Where to Set |
|----------|--------------|--------------|
| Studio AI | `SUPABASE_OPENAI_API_KEY` | `.env` file |
| Edge Functions | `OPENAI_API_KEY` | Supabase secrets |

## 🔗 More Information

- **Full Guide**: [OPENAI_SETUP.md](OPENAI_SETUP.md)
- **Example Function**: [supabase/functions/openai-chat/](supabase/functions/openai-chat/)
- **OpenAI Docs**: https://platform.openai.com/docs
- **Supabase Docs**: https://supabase.com/docs/guides/functions
