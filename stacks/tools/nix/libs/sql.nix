{ pkgs }:

{
  packages = with pkgs; [
    # Relational databases
    postgresql
    postgresql_16
    mysql80
    mariadb
    sqlite

    # NoSQL / NewSQL / Analytics
    redis
    mongodb
    clickhouse
    duckdb
    cassandra
    neo4j

    # CLI clients and utilities
    psql
    pgcli
    pg_dump
    pgadmin4
    mycli
    mysql
    mariadb-client
    sqlite
    sqlitebrowser
    redis-cli
    mongosh
    clickhouse-client
    duckdb
    cqlsh
    cypher-shell

    # Migration/ORM tools
    flyway
    liquibase
    sqitchPg
    sqitchMysql
    sqlfluff

    # ODBC/JDBC and drivers
    unixODBC
    libiodbc
    openjdk
    jdk
    jre

    # Backup/restore/common utils
    gzip
    bzip2
    xz
    zstd
    curl
    wget
    jq
    bat
    ripgrep
    fd
  ];

  envVars = {
    # Default connection strings (override per project)
    POSTGRES_DB = "chain_rice";
    POSTGRES_USER = "postgres";
    POSTGRES_PASSWORD = "postgres";
    POSTGRES_HOST = "127.0.0.1";
    POSTGRES_PORT = "5432";

    MYSQL_DATABASE = "chain_rice";
    MYSQL_USER = "root";
    MYSQL_PASSWORD = "root";
    MYSQL_HOST = "127.0.0.1";
    MYSQL_PORT = "3306";

    MARIADB_DATABASE = "chain_rice";
    MARIADB_USER = "root";
    MARIADB_PASSWORD = "root";
    MARIADB_HOST = "127.0.0.1";
    MARIADB_PORT = "3307";

    SQLITE_DB = "./chain_rice.db";

    REDIS_HOST = "127.0.0.1";
    REDIS_PORT = "6379";

    MONGO_INITDB_DATABASE = "chain_rice";
    MONGO_HOST = "127.0.0.1";
    MONGO_PORT = "27017";

    CLICKHOUSE_HOST = "127.0.0.1";
    CLICKHOUSE_PORT = "9000";

    CASSANDRA_HOST = "127.0.0.1";
    CASSANDRA_PORT = "9042";

    NEO4J_URI = "bolt://127.0.0.1:7687";
    NEO4J_USER = "neo4j";
    NEO4J_PASSWORD = "neo4j";
  };

  shellHook = ''
    echo "🟦 SQL toolchain: Postgres/MySQL/MariaDB/SQLite + Redis/Mongo/ClickHouse/DuckDB/Cassandra/Neo4j"

    # Ensure data dirs
    mkdir -p .nix-data/postgres .nix-data/mysql .nix-data/mariadb .nix-data/redis .nix-data/mongo .nix-data/clickhouse .nix-data/cassandra .nix-data/neo4j

    # Aliases
    alias pg='psql -h ${POSTGRES_HOST:-127.0.0.1} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-chain_rice} -p ${POSTGRES_PORT:-5432}'
    alias pgui='pgadmin4'
    alias pgdump='pg_dump -h ${POSTGRES_HOST:-127.0.0.1} -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-chain_rice} -p ${POSTGRES_PORT:-5432}'

    alias my='mysql -h ${MYSQL_HOST:-127.0.0.1} -u ${MYSQL_USER:-root} -p${MYSQL_PASSWORD:-root} -P ${MYSQL_PORT:-3306} ${MYSQL_DATABASE:-chain_rice}'
    alias mydump='mysqldump -h ${MYSQL_HOST:-127.0.0.1} -u ${MYSQL_USER:-root} -p${MYSQL_PASSWORD:-root} -P ${MYSQL_PORT:-3306} ${MYSQL_DATABASE:-chain_rice}'

    alias maria='mysql -h ${MARIADB_HOST:-127.0.0.1} -u ${MARIADB_USER:-root} -p${MARIADB_PASSWORD:-root} -P ${MARIADB_PORT:-3307} ${MARIADB_DATABASE:-chain_rice}'

    alias sq='sqlite3 ${SQLITE_DB:-./chain_rice.db}'

    alias rcli='redis-cli -h ${REDIS_HOST:-127.0.0.1} -p ${REDIS_PORT:-6379}'

    alias mongo='mongosh --host ${MONGO_HOST:-127.0.0.1} --port ${MONGO_PORT:-27017} ${MONGO_INITDB_DATABASE:-chain_rice}'

    alias ch='clickhouse-client --host ${CLICKHOUSE_HOST:-127.0.0.1} --port ${CLICKHOUSE_PORT:-9000}'

    alias cql='cqlsh ${CASSANDRA_HOST:-127.0.0.1} ${CASSANDRA_PORT:-9042}'

    alias neo='cypher-shell -a ${NEO4J_URI:-bolt://127.0.0.1:7687} -u ${NEO4J_USER:-neo4j} -p ${NEO4J_PASSWORD:-neo4j}'

    # Flyway helpers (env-driven)
    alias fly='flyway'
    alias liq='liquibase'

    # SQLFluff helpers
    alias sqllint='sqlfluff lint .'
    alias sqlfix='sqlfluff fix . --force'

    # Quick start tips
    echo "💡 Postgres: initdb -D .nix-data/postgres && pg_ctl -D .nix-data/postgres -o \"-p ${POSTGRES_PORT:-5432}\" -l logfile start"
    echo "💡 MySQL: mysqld --datadir=.nix-data/mysql --port=${MYSQL_PORT:-3306} --skip-networking=0 &"
    echo "💡 MariaDB: mariadbd --datadir=.nix-data/mariadb --port=${MARIADB_PORT:-3307} &"
    echo "💡 SQLite: sq to open ${SQLITE_DB:-./chain_rice.db}"
    echo "💡 Redis: redis-server --port ${REDIS_PORT:-6379} --dir .nix-data/redis &"
    echo "💡 MongoDB: mongod --dbpath .nix-data/mongo --port ${MONGO_PORT:-27017} &"
    echo "💡 ClickHouse: clickhouse server -- --path .nix-data/clickhouse &"
    echo "💡 Cassandra: cassandra -R -Dcassandra.storagedir=.nix-data/cassandra &"
    echo "💡 Neo4j: neo4j console --home=.nix-data/neo4j &"
  '';
}
