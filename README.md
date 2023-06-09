## What this tool is good for

This tool allows querying Cosmos DB using AAD sign on. You must set up RBAC for querying data before as described here:
[Configure role-based access control with Azure Active Directory for your Azure Cosmos DB account](https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac)

## Requirements

- Powershell 7
- Az.Acounts module

## Usage

Sign on first and import module:

```
Connect-AzAccount -TenantId <your tenant id here>
Import-Module <path>\CosmosDBClient\CosmosDBClient.psm1
```

Run query:

```
Get-CosmosQueryResults -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb' -ContainerName 'customers' -Query "select * from customers c where c.accountnumber = '123'"
```

Execute stored procedure:

```
Invoke-CosmosStoredProcedure -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb' -ContainerName 'customers' -PartitionKey 'mypartition' -StoredProcedureId 'bulkDelete' -StoredProcedureParameters "select * from customers"
```

Update a document:

```
Set-CosmosDocument -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb' -ContainerName 'customers' -PartitionKey 'mypartition' -DocumentId '123' -Content @{ id = '123'; firstName = 'Joe'; lastName = 'Normal' }
```

Get specific collection metadata info:

```
Get-CosmosCollectionMetadata -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb' -ContainerName 'customers'
```

Get all containers metadata:

```
Get-CosmosCollectionMetadata -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb'
```
