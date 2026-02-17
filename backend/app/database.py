"""
FraudX Analyst - Database
===========================
Connects to Supabase PostgreSQL.
Creates all tables on startup if they don't exist.
"""

import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy import text
from dotenv import load_dotenv

load_dotenv()

# ── Connection ─────────────────────────────────────────────────────────────────
# Convert standard postgresql:// URL to async asyncpg:// URL
DATABASE_URL = os.getenv("SUPABASE_DATABASE_URL", "")
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

engine = create_async_engine(
    DATABASE_URL,
    echo=False,          # set True to see SQL queries in console (debug only)
    pool_size=5,
    max_overflow=10,
    connect_args={
        "ssl": "require",
        "statement_cache_size": 0,   # required for Supabase connection pooler
    },
)

AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()


# ── Dependency — used in API routes to get a DB session ───────────────────────
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


# ── Create all tables ──────────────────────────────────────────────────────────
async def create_tables():
    """
    Creates all tables in Supabase if they don't already exist.
    Safe to run on every startup — won't overwrite existing data.
    """
    async with engine.begin() as conn:
        # Import here to avoid circular imports
        from app.models import MLModel, Dataset, SimulationHistory, KnowledgeBase
        await conn.run_sync(Base.metadata.create_all)
