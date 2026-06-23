# ---- Run Liquibase ----
echo "Running Liquibase migrations..."

"$LIQUIBASE_DIR/liquibase" \
    --classpath="$DRIVER_JAR" \
    --driver=org.postgresql.Driver \
    --url="jdbc:postgresql://localhost:${PG_PORT}/${DB_NAME}" \
    --username=postgres \
    --searchPath="$PROJECT_ROOT,$PROJECT_ROOT/liquibase/postgresql" \
    --changeLogFile="liquibase/postgresql/master.xml" \
    update

echo "Liquibase migrations completed successfully"