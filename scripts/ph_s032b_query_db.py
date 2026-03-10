#!/usr/bin/env python3
"""PH-S03.2B: Read-only DB queries (no secrets in output)."""
import os
import asyncio
import asyncpg

async def main():
    c = await asyncpg.connect(
        host=os.environ.get("PGHOST", "10.0.0.10"),
        port=int(os.environ.get("PGPORT", "5432")),
        user=os.environ.get("PGUSER"),
        password=os.environ.get("PGPASSWORD"),
        database=os.environ.get("PGDATABASE"),
    )
    # Columns of catalog_source_connections (no password column)
    r = await c.fetch(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_schema = 'seller' AND table_name = 'catalog_source_connections' "
        "ORDER BY ordinal_position"
    )
    cols = [x["column_name"] for x in r]
    print("COLUMNS:", cols)
    print("HAS_PASSWORD_COLUMN:", "password" in [c.lower() for c in cols])
    # Sample row (masked) - only columns that exist
    r2 = await c.fetch(
        "SELECT id, source_id, protocol, host, port, username, secret_ref_id "
        "FROM seller.catalog_source_connections LIMIT 1"
    )
    if r2:
        row = r2[0]
        print("SAMPLE_ROW: protocol=%s has_secret_ref=%s" % (
            row.get("protocol"), row.get("secret_ref_id") is not None
        ))
    else:
        print("SAMPLE_ROW: (none)")
    # secret_ref FTP_CREDENTIALS
    r3 = await c.fetch(
        """SELECT id, "tenantId", name, "refType",
           CASE WHEN "vaultPath" IS NOT NULL AND length("vaultPath") > 0 THEN '(set)' ELSE '(empty)' END AS vault_path_status
           FROM seller.secret_refs WHERE "refType" = 'FTP_CREDENTIALS' LIMIT 1"""
    )
    if r3:
        print("FTP_CREDENTIALS_EXISTS: vault_path_status=%s" % r3[0].get("vault_path_status"))
    else:
        print("FTP_CREDENTIALS_EXISTS: (no row)")
    await c.close()

if __name__ == "__main__":
    asyncio.run(main())
