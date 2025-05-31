# Scar Desktop Assistant - Development Roadmap

## Project Overview
A desktop AI assistant that uses SuperWhisper for voice input, processes through AI models, and responds with Scar's voice from The Lion King. Built on Hammerspoon, leveraging existing solutions from Convex Agent and a16z's companion-app for context management and real-time sync.

## Architecture Overview
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  SuperWhisper   │────▶│   Hammerspoon    │────▶│  Convex Agent   │
│  (Voice Input)  │     │   (Controller)    │     │ (Context + AI)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │                           │
                               ▼                           ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │ Menubar (White    │     │   TTS Engine    │
                        │  SVG Icon)       │     │   (Play HT)     │
                        └──────────────────┘     └─────────────────┘
```

## Key Discovery: We Don't Need to Build Most of This!

The repos you provided already have:

### Convex Agent (get-convex/agent)
- ✅ Automatic chat history storage (per-user or per-thread)
- ✅ RAG with hybrid text & vector search
- ✅ Context management with configurable options
- ✅ Tool calls support
- ✅ Real-time updates
- ✅ Usage tracking
- ✅ Workflow integration

### Companion App (a16z-infra/companion-app)  
- ✅ AI companions with personality/backstory
- ✅ Vector database with similarity search
- ✅ Conversational memory queue
- ✅ LangChain.js orchestration
- ✅ Multiple LLM support (OpenAI, Vicuna)
- ✅ Embeddings generation from character files

### AI Town (a16z-infra/ai-town)
- ✅ Convex-based real-time sync
- ✅ Shared global state
- ✅ Built-in simulation engine
- ✅ Character management system

## Development Phases (Simplified!)

### Phase 1: Basic Integration (3-5 days)
**Goal**: Connect SuperWhisper → Convex Agent → TTS

- [x] SuperWhisper Spoon (COMPLETE)
- [ ] Replace menubar emoji with white SVG icon
- [ ] Set up Convex project with Agent component
- [ ] Create Scar character file (backstory, personality)
- [ ] Basic TTS integration (Edge TTS for testing)
- [ ] Connect Hammerspoon to Convex via HTTP/WebSocket

**Implementation**:
```javascript
// Use Convex Agent directly!
const scarAgent = new Agent(components.agent, {
  chat: openai.chat("gpt-4o"),
  textEmbedding: openai.embedding("text-embedding-3-small"),
  instructions: "You are Scar from The Lion King...",
  contextOptions: {
    recentMessages: 10,
    searchOptions: { vectorSearch: true }
  }
});
```

### Phase 2: Character Polish (2-3 days)
**Goal**: Make it truly feel like Scar

- [ ] Play HT integration for Scar voice
- [ ] Fine-tune character prompt using companion-app format
- [ ] Add character-specific responses and catchphrases
- [ ] Test personality consistency

**Character File** (scar.txt):
```
You are Scar from The Lion King. You are intelligent, theatrical, and sardonic.
You speak with eloquence and often use metaphors. You have a dry sense of humor.
###ENDPREAMBLE###
Human: Hello Scar
Scar: *Languidly* Oh, what a surprise. Another interruption to my contemplation...
###ENDSEEDCHAT###
[Extended backstory and personality traits...]
```

### Phase 3: Desktop Experience (3-4 days)
**Goal**: Seamless desktop integration

- [ ] HTTP server in Hammerspoon for Convex communication
- [ ] Audio playback queue for TTS responses
- [ ] Visual feedback states (listening, thinking, speaking)
- [ ] Hotkey improvements
- [ ] Auto-paste with context awareness

### Phase 4: Advanced Features (Optional, 1-2 weeks)
**Goal**: Full agent capabilities

- [ ] Enable Convex Agent tools (file ops, web search)
- [ ] Workflow automation using Convex Workflows
- [ ] GUI using companion-app's React interface
- [ ] Cross-device sync (already built into Convex!)

## Technical Stack (Updated)

### Core Components
- **Voice Input**: SuperWhisper Spoon ✅
- **Controller**: Hammerspoon ✅
- **AI Backend**: Convex Agent (no need to build!)
- **Context/Memory**: Built into Convex Agent
- **Vector Search**: Built into Convex Agent
- **TTS**: Play HT / Edge TTS
- **Real-time Sync**: Convex (automatic!)

### What We Actually Need to Build
1. **Hammerspoon → Convex Bridge**: Simple HTTP client
2. **TTS Integration**: API calls to Play HT
3. **Character Configuration**: Scar personality file
4. **Audio Playback**: Queue management in Hammerspoon

That's it! Most of the heavy lifting is already done.

## Simple Implementation Plan

### Step 1: Set up Convex Backend (30 minutes)
```bash
# In a new directory for the backend
npm create convex
npm install @convex-dev/agent @ai-sdk/openai
```

### Step 2: Create Scar Agent (convex/scar.ts)
```typescript
import { Agent } from "@convex-dev/agent";
import { openai } from "@ai-sdk/openai";

export const scarAgent = new Agent(components.agent, {
  chat: openai.chat("gpt-4o"),
  textEmbedding: openai.embedding("text-embedding-3-small"),
  instructions: `You are Scar from The Lion King. You are intelligent, 
    theatrical, sardonic, and speak with eloquence. You often use 
    Shakespeare-like metaphors and have a dry, witty sense of humor.
    Never break character.`,
  contextOptions: {
    recentMessages: 20,
    searchOptions: { 
      vectorSearch: true,
      textSearch: true,
      limit: 10
    }
  }
});

// Expose as actions for Hammerspoon to call
export const chat = action({
  args: { prompt: v.string(), threadId: v.optional(v.string()) },
  handler: async (ctx, { prompt, threadId }) => {
    const { thread, threadId: newThreadId } = threadId 
      ? await scarAgent.continueThread(ctx, { threadId })
      : await scarAgent.createThread(ctx);
    
    const result = await thread.generateText({ prompt });
    return { text: result.text, threadId: newThreadId };
  }
});
```

### Step 3: Update Hammerspoon Bridge
```lua
-- In SuperWhisper.spoon/init.lua
function obj:sendToScar(text)
    local url = "https://your-app.convex.site/chat"
    hs.http.asyncPost(url, 
        hs.json.encode({prompt = text, threadId = self.currentThreadId}),
        {["Content-Type"] = "application/json"},
        function(status, body)
            local response = hs.json.decode(body)
            self.currentThreadId = response.threadId
            self:speakResponse(response.text)
        end
    )
end
```

### Step 4: Add TTS
```lua
function obj:speakResponse(text)
    -- Option 1: Edge TTS (free)
    hs.execute("edge-tts --text '" .. text .. "' --voice en-GB-RyanNeural | afplay -")
    
    -- Option 2: Play HT (Scar voice)
    -- Make API call to Play HT, get audio URL, play it
end
```

## Why This Approach is Better

1. **Convex Agent gives us**:
   - Automatic conversation history
   - Vector search for context
   - Thread management
   - Usage tracking
   - Real-time updates

2. **Companion App patterns give us**:
   - Character file format
   - Personality management
   - Embedding generation

3. **We only build**:
   - Hammerspoon ↔ Convex bridge (50 lines)
   - TTS integration (20 lines)
   - Audio playback (30 lines)

## Menubar Icon Update

For the white SVG icon to match system icons:

```lua
-- In init.lua, update the menubar creation
self.menubar = hs.menubar.new()
-- Use hs.image to load SVG and set as template (makes it white)
local icon = hs.image.imageFromPath(obj.spoonPath .. "/mic-icon.svg")
icon:template(true)  -- This makes it adapt to system color
self.menubar:setIcon(icon)
```

Place a `mic-icon.svg` in the Spoon directory - it should be a simple microphone shape.

## File Structure
```
scar-assistant/
├── hammerspoon/
│   └── Spoons/
│       └── SuperWhisper.spoon/
│           ├── init.lua          # Updated with Convex bridge
│           └── mic-icon.svg      # White microphone icon
├── convex-backend/
│   ├── convex/
│   │   ├── scar.ts             # Scar agent definition
│   │   └── convex.config.ts    # Agent component setup
│   ├── package.json
│   └── .env.local              # API keys
└── docs/
    └── scar-character.txt      # Full character backstory
```

## Configuration Toggles

Since Convex Agent handles most features, our config is simple:

```lua
-- In SuperWhisper.spoon/init.lua
obj.config = {
    -- Essential
    convexUrl = "https://your-app.convex.site",
    
    -- Features
    useTTS = true,              -- Enable voice responses
    ttsEngine = "edge-tts",     -- or "playht"
    
    -- Behavior  
    autoSendTranscription = true,
    showNotifications = true,
    
    -- Advanced (when ready)
    enableTools = false,        -- Agent capabilities
    requireConfirmation = true  -- For dangerous actions
}
```

## Next Steps

1. **Today**: 
   - Set up Convex project
   - Create basic Scar agent
   - Test with curl/Postman

2. **Tomorrow**: 
   - Update Hammerspoon spoon to call Convex
   - Add white SVG icon
   - Test voice → text → response flow

3. **Day 3**: 
   - Add Edge TTS
   - Test full voice → AI → voice flow
   
4. **Day 4-5**: 
   - Polish character personality
   - Add Play HT for authentic Scar voice
   - Fine-tune context settings

## Publishing as a Spoon

Once working, we can publish to Peacockery Studio:

1. Clean up code and add documentation
2. Create `SuperWhisperAssistant.spoon` with all features
3. Add setup instructions for Convex backend
4. Submit to Hammerspoon Spoons registry

The beauty is that users can:
- Use the basic spoon without AI (just SuperWhisper integration)
- Add their own Convex backend for AI features
- Customize with their own character/personality

---

*"Be prepared... for the simplest implementation!" - Scar*