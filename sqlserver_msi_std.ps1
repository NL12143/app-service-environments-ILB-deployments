$RGNAME=$args[0]
$USER=$args[1]

az login
$SQL_SERVER=$(az deployment group show -g $RGNAME -n services --query properties.outputs.sqlServerName.value -o tsv)
$SQL_DATABASE=$(az deployment group show -g $RGNAME -n services --query properties.outputs.sqlDatabaseName.value -o tsv)

$VOTING_COUNTER_FUNCTION_NAME=$(az deployment group show -g $RGNAME -n sites --query properties.outputs.votingFunctionName.value -o tsv)
$VOTING_API_NAME=$(az deployment group show -g $RGNAME -n sites --query properties.outputs.votingApiName.value -o tsv)

$SQL="CREATE USER [$VOTING_COUNTER_FUNCTION_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];CREATE USER [$VOTING_API_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API_NAME];"

sqlcmd -S tcp:$SQL_SERVER.database.windows.net,1433 -d $SQL_DATABASE -N -l 30 -U $USER -G -Q $SQL

$SQL_TABLE_OBJECT="IF OBJECT_ID('dbo.Counts', 'U') IS NULL CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT);"

sqlcmd -S tcp:$SQL_SERVER.database.windows.net,1433 -d $SQL_DATABASE -N -l 30 -U $USER -G -Q $SQL_TABLE_OBJECT
