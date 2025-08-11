#!/usr/bin/env python3
"""
PostgreSQL to MySQL Data Migration Script

This script migrates data from an existing PostgreSQL database to an existing MySQL database
for the API Itinéraire de vacances application. The MySQL database will be emptied if needed.
"""

import sys
import psycopg2
import mysql.connector

# Database connection parameters - EDIT THESE VALUES
PG_CONFIG = {
    'host': 'localhost',
    'port': '5432',
    'user': 'azeau_itineraire_vacances',
    'password': 'xxxx',
    'database': 'azeau_itineraire_vacances_RNCP38919'
}

MYSQL_CONFIG = {
    'host': 'localhost',
    'port': '3306',
    'user': 'azeau_itineraire_vacances',
    'password': 'itineraire_vacances_dtst',
    'database': 'azeau_itineraire_vacances_RNCP38919'
}


def connect_to_postgresql():
    """Connect to PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=PG_CONFIG['host'],
            port=PG_CONFIG['port'],
            user=PG_CONFIG['user'],
            password=PG_CONFIG['password'],
            database=PG_CONFIG['database']
        )
        print(f"Connected to PostgreSQL database: {PG_CONFIG['database']}")
        return conn
    except Exception as e:
        print(f"Error connecting to PostgreSQL: {e}")
        sys.exit(1)


def connect_to_mysql():
    """Connect to MySQL database."""
    try:
        conn = mysql.connector.connect(
            host=MYSQL_CONFIG['host'],
            port=MYSQL_CONFIG['port'],
            user=MYSQL_CONFIG['user'],
            password=MYSQL_CONFIG['password'],
            database=MYSQL_CONFIG['database']
        )
        print(f"Connected to MySQL database: {MYSQL_CONFIG['database']}")
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to MySQL: {err}")
        sys.exit(1)


def get_postgresql_tables(pg_conn):
    """Get a list of tables from PostgreSQL database."""
    cursor = pg_conn.cursor()
    cursor.execute("""
                   SELECT table_name
                   FROM information_schema.tables
                   WHERE table_schema = 'public'
                     AND table_type = 'BASE TABLE'
                   """)
    tables = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return tables


def empty_mysql_database(mysql_conn):
    """Empty all tables in the MySQL database."""
    cursor = mysql_conn.cursor()

    # Disable foreign key checks temporarily
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

    # Get all tables in the database
    cursor.execute("SHOW TABLES")
    tables = [row[0] for row in cursor.fetchall()]

    for table in tables:
        try:
            cursor.execute(f"TRUNCATE TABLE `{table}`")
            print(f"Emptied table {table}")
        except mysql.connector.Error as err:
            print(f"Error emptying table {table}: {err}")

    # Re-enable foreign key checks
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

    mysql_conn.commit()
    cursor.close()


def map_data_type(pg_type, max_length):
    """Map PostgreSQL data types to MySQL data types."""
    pg_type = pg_type.lower()

    type_mapping = {
        'integer': 'INT',
        'bigint': 'BIGINT',
        'smallint': 'SMALLINT',
        'text': 'TEXT',
        'boolean': 'BOOLEAN',
        'date': 'DATE',
        'timestamp without time zone': 'DATETIME',
        'timestamp with time zone': 'DATETIME',
        'time without time zone': 'TIME',
        'double precision': 'DOUBLE',
        'real': 'FLOAT',
        'numeric': 'DECIMAL(10,2)',
        'decimal': 'DECIMAL(10,2)',
        'uuid': 'VARCHAR(36)',
        'json': 'JSON',
        'jsonb': 'JSON'
    }

    if pg_type in type_mapping:
        return type_mapping[pg_type]
    elif pg_type == 'character varying':
        if max_length:
            return f'VARCHAR({max_length})'
        else:
            return 'VARCHAR(255)'
    elif pg_type == 'character':
        if max_length:
            return f'CHAR({max_length})'
        else:
            return 'CHAR(1)'
    elif pg_type.startswith('serial'):
        return 'INT AUTO_INCREMENT'
    else:
        print(f"Warning: Unknown PostgreSQL data type: {pg_type}, defaulting to TEXT")
        return 'TEXT'


def sync_tables(pg_conn, mysql_conn):
    """Ensure MySQL tables match PostgreSQL schema."""
    pg_cursor = pg_conn.cursor()
    mysql_cursor = mysql_conn.cursor()

    # Get PostgreSQL tables
    tables = get_postgresql_tables(pg_conn)
    print(f"Found {len(tables)} tables in PostgreSQL")

    # Check each table
    for table in tables:
        # Check if table exists in MySQL
        try:
            mysql_cursor.execute(f"DESCRIBE `{table}`")
            print(f"Table {table} exists in MySQL")
            continue
        except mysql.connector.Error:
            print(f"Table {table} does not exist in MySQL, creating it")

        # Get table schema from PostgreSQL
        pg_cursor.execute(f"""
            SELECT column_name, data_type, character_maximum_length, 
                   is_nullable, column_default
            FROM information_schema.columns
            WHERE table_name = '{table}'
            ORDER BY ordinal_position
        """)
        columns = pg_cursor.fetchall()

        # Get primary keys
        pg_cursor.execute(f"""
            SELECT a.attname
            FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
            WHERE i.indrelid = '{table}'::regclass AND i.indisprimary;
        """)
        primary_keys = [row[0] for row in pg_cursor.fetchall()]

        # Create table in MySQL
        create_table_sql = f"CREATE TABLE IF NOT EXISTS `{table}` (\n"

        column_defs = []
        for col_name, data_type, max_length, is_nullable, default in columns:
            # Map PostgreSQL data types to MySQL data types
            mysql_type = map_data_type(data_type, max_length)

            # Build column definition
            col_def = f"`{col_name}` {mysql_type}"

            # Add NOT NULL constraint if needed
            if is_nullable == 'NO':
                col_def += " NOT NULL"

            # Handle default values
            if default:
                # Extract default value from PostgreSQL format
                if "nextval" in default:
                    # This is an auto-increment column in PostgreSQL
                    col_def += " AUTO_INCREMENT"
                elif default.startswith("'") and default.endswith("'"):
                    # String default
                    col_def += f" DEFAULT {default}"
                else:
                    # Other default
                    col_def += f" DEFAULT {default}"

            column_defs.append(col_def)

        # Add primary key constraint
        if primary_keys:
            pk_constraint = f"PRIMARY KEY (`{'`, `'.join(primary_keys)}`)"
            column_defs.append(pk_constraint)

        create_table_sql += ",\n".join(column_defs)
        create_table_sql += "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

        # Create table in MySQL
        try:
            mysql_cursor.execute(create_table_sql)
            print(f"Created table {table} in MySQL")
        except mysql.connector.Error as err:
            print(f"Error creating table {table}: {err}")

    mysql_conn.commit()
    pg_cursor.close()
    mysql_cursor.close()


def migrate_data(pg_conn, mysql_conn):
    """Migrate data from PostgreSQL to MySQL."""
    pg_cursor = pg_conn.cursor()
    mysql_cursor = mysql_conn.cursor()

    # Get PostgreSQL tables
    tables = get_postgresql_tables(pg_conn)

    for table in tables:
        # Get column names
        pg_cursor.execute(f"""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = '{table}'
            ORDER BY ordinal_position
        """)
        columns = [row[0] for row in pg_cursor.fetchall()]

        # Fetch data from PostgreSQL
        pg_cursor.execute(f"SELECT * FROM {table}")
        rows = pg_cursor.fetchall()

        if not rows:
            print(f"Table {table} is empty, skipping")
            continue

        print(f"Migrating {len(rows)} rows from table {table}")

        # Insert data into MySQL
        placeholders = ', '.join(['%s'] * len(columns))
        insert_sql = f"INSERT INTO `{table}` (`{'`, `'.join(columns)}`) VALUES ({placeholders})"

        # Use batch insert for better performance
        batch_size = 1000
        for i in range(0, len(rows), batch_size):
            batch = rows[i:i + batch_size]
            try:
                mysql_cursor.executemany(insert_sql, batch)
                mysql_conn.commit()
                print(f"Inserted {len(batch)} rows into {table}")
            except mysql.connector.Error as err:
                print(f"Error inserting data into {table}: {err}")
                mysql_conn.rollback()

    pg_cursor.close()
    mysql_cursor.close()


def sync_foreign_keys(pg_conn, mysql_conn):
    """Sync foreign key constraints from PostgreSQL to MySQL."""
    pg_cursor = pg_conn.cursor()
    mysql_cursor = mysql_conn.cursor()

    # Get foreign key constraints from PostgreSQL
    pg_cursor.execute("""
                      SELECT tc.table_name,
                             kcu.column_name,
                             ccu.table_name  AS foreign_table_name,
                             ccu.column_name AS foreign_column_name,
                             tc.constraint_name
                      FROM information_schema.table_constraints AS tc
                               JOIN information_schema.key_column_usage AS kcu
                                    ON tc.constraint_name = kcu.constraint_name
                                        AND tc.table_schema = kcu.table_schema
                               JOIN information_schema.constraint_column_usage AS ccu
                                    ON ccu.constraint_name = tc.constraint_name
                                        AND ccu.table_schema = tc.table_schema
                      WHERE tc.constraint_type = 'FOREIGN KEY'
                        AND tc.table_schema = 'public'
                      """)

    foreign_keys = pg_cursor.fetchall()

    for table, column, ref_table, ref_column, constraint_name in foreign_keys:
        # Check if foreign key already exists
        mysql_cursor.execute(f"""
            SELECT COUNT(*)
            FROM information_schema.key_column_usage
            WHERE table_schema = '{MYSQL_CONFIG['database']}'
            AND table_name = '{table}'
            AND column_name = '{column}'
            AND referenced_table_name = '{ref_table}'
            AND referenced_column_name = '{ref_column}'
        """)

        fk_exists = mysql_cursor.fetchone()[0] > 0

        if fk_exists:
            print(f"Foreign key for {table}.{column} -> {ref_table}.{ref_column} already exists")
            continue

        # Create foreign key constraint in MySQL
        try:
            alter_sql = f"""
                ALTER TABLE `{table}`
                ADD CONSTRAINT `{constraint_name}`
                FOREIGN KEY (`{column}`)
                REFERENCES `{ref_table}`(`{ref_column}`)
                ON DELETE CASCADE
                ON UPDATE CASCADE
            """
            mysql_cursor.execute(alter_sql)
            mysql_conn.commit()
            print(f"Added foreign key constraint {constraint_name} to {table}.{column}")
        except mysql.connector.Error as err:
            print(f"Error adding foreign key constraint to {table}.{column}: {err}")

    pg_cursor.close()
    mysql_cursor.close()


def main():
    """Main function to execute the migration."""
    print("Starting PostgreSQL to MySQL migration...")

    # Connect to databases
    pg_conn = connect_to_postgresql()
    mysql_conn = connect_to_mysql()

    # Empty MySQL database
    empty_mysql_database(mysql_conn)

    # Ensure tables match PostgreSQL schema
    sync_tables(pg_conn, mysql_conn)

    # Migrate data
    migrate_data(pg_conn, mysql_conn)

    # Sync foreign keys
    sync_foreign_keys(pg_conn, mysql_conn)

    # Close connections
    pg_conn.close()
    mysql_conn.close()

    print("Migration completed successfully!")


if __name__ == "__main__":
    main()