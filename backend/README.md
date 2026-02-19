# Solo Leveling Backend API

Production-ready Node.js/Express backend with Prisma ORM for the Solo Leveling Flutter app.

## Architecture

```
Flutter App → REST API (Express) → Prisma ORM → Supabase PostgreSQL
```

**Why This Architecture?**

- ✅ **Separation of Concerns**: Business logic in backend, not mobile app
- ✅ **Type-Safe Database**: Prisma provides autocomplete and type safety
- ✅ **Easy Migrations**: Never touch Supabase SQL editor again
- ✅ **Scalable**: Add auth, caching, rate limiting easily
- ✅ **Multi-Platform**: Same API for web, mobile, desktop

## Tech Stack

- **Runtime**: Node.js v18+
- **Language**: TypeScript
- **Framework**: Express.js
- **ORM**: Prisma
- **Database**: Supabase PostgreSQL
- **Validation**: Zod

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Set Up Environment

```bash
cp .env.example .env
```

Edit `.env` and add your Supabase connection string:

```env
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.ulixfhjwabfvfueatycz.supabase.co:5432/postgres"
PORT=3000
NODE_ENV=development
```

**Get your database password:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/ulixfhjwabfvfueatycz/settings/database)
2. Copy the connection string
3. Replace `[PASSWORD]` with your actual password

### 3. Run Prisma Migrations

```bash
npx prisma migrate dev --name init
```

This will:
- Create all tables in Supabase
- Generate Prisma Client with types

### 4. Seed Database

```bash
npm run prisma:seed
```

This creates:
- Initial player (id: 1)
- 14 predefined achievements

### 5. Start Development Server

```bash
npm run dev
```

Server runs on `http://localhost:3000`

## API Endpoints

### Player

- `GET /api/player` - Get player stats
- `PUT /api/player` - Update player
- `POST /api/player/add-xp` - Add XP to player
- `POST /api/player/toggle-shadow-mode` - Toggle Shadow Mode
- `POST /api/player/reset` - Reset player (dev only)

### Quests

- `GET /api/quests` - Get all quests (supports filters)
- `GET /api/quests/today` - Get today's quests
- `GET /api/quests/:id` - Get quest by ID
- `POST /api/quests` - Create new quest
- `PUT /api/quests/:id` - Update quest
- `POST /api/quests/:id/complete` - Complete quest (adds XP)
- `DELETE /api/quests/:id` - Delete quest

### Quest Templates

- `GET /api/templates` - Get all templates
- `GET /api/templates/:id` - Get template by ID
- `POST /api/templates` - Create template
- `PUT /api/templates/:id` - Update template
- `POST /api/templates/:id/toggle` - Activate/deactivate
- `DELETE /api/templates/:id` - Delete template

### Achievements

- `GET /api/achievements` - Get all achievements
- `GET /api/achievements/:id` - Get achievement by ID
- `POST /api/achievements/:id/unlock` - Unlock achievement

## Example API Calls

### Create a Quest

```bash
curl -X POST http://localhost:3000/api/quests \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Morning Workout",
    "description": "30 min gym session",
    "statType": "strength",
    "difficulty": 3,
    "timeMinutes": 30,
    "xpReward": 50
  }'
```

### Complete a Quest

```bash
curl -X POST http://localhost:3000/api/quests/1/complete
```

### Get Player Stats

```bash
curl http://localhost:3000/api/player
```

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma          # Database schema
│   ├── migrations/            # Migration history
│   └── seed.ts               # Seed data
├── src/
│   ├── controllers/          # Request handlers
│   ├── routes/               # API routes
│   ├── services/             # Business logic
│   ├── middleware/           # Express middleware
│   ├── utils/                # Utilities
│   ├── types/                # TypeScript types
│   └── index.ts              # App entry point
├── .env                      # Environment variables
├── package.json
└── tsconfig.json
```

## Adding New Features

### Example: Add a new field to Player

**1. Update Prisma Schema**

Edit `prisma/schema.prisma`:

```prisma
model Player {
  // ... existing fields
  energyLevel Int @default(100) @map("energy_level")
}
```

**2. Run Migration**

```bash
npx prisma migrate dev --name add_energy_level
```

Prisma will:
- ✅ Create migration SQL
- ✅ Update Supabase database
- ✅ Regenerate Prisma Client with new types
- ✅ Give you TypeScript autocomplete!

**3. Use in Code**

```typescript
// TypeScript now knows about energyLevel!
const player = await prisma.player.findFirst();
console.log(player.energyLevel); // ✅ Autocomplete works!
```

**That's it!** No SQL editor needed.

## Useful Commands

```bash
# Development
npm run dev                    # Start dev server with hot reload
npm run build                  # Build for production
npm start                      # Run production build

# Prisma
npx prisma studio              # Open database GUI
npx prisma generate            # Regenerate Prisma Client
npx prisma migrate dev         # Create and apply migration
npx prisma migrate reset       # Reset database (WARNING: deletes data)
npm run prisma:seed            # Seed database

# Database
npx prisma db push             # Push schema without migration (dev only)
npx prisma db pull             # Pull schema from database
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Supabase PostgreSQL connection string | `postgresql://postgres:...` |
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` or `production` |

## Deployment

### Option 1: Railway

1. Push code to GitHub
2. Connect Railway to your repo
3. Add `DATABASE_URL` environment variable
4. Railway auto-deploys!

### Option 2: Render

1. Create new Web Service
2. Connect GitHub repo
3. Build command: `npm install && npx prisma generate && npm run build`
4. Start command: `npm start`
5. Add environment variables

## Troubleshooting

**Prisma Client not found?**
```bash
npx prisma generate
```

**Migration failed?**
```bash
npx prisma migrate reset
npx prisma migrate dev
npm run prisma:seed
```

**Port already in use?**
```bash
# Change PORT in .env
PORT=3001
```

## Next Steps

1. ✅ Backend API is ready
2. 🔄 Update Flutter app to call these APIs
3. 🚀 Deploy backend to production
4. 🔐 Add authentication (optional)

## Support

For issues or questions, check:
- [Prisma Docs](https://www.prisma.io/docs)
- [Express Docs](https://expressjs.com/)
- [Supabase Docs](https://supabase.com/docs)
