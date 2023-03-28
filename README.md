## What this tool is good for

This tool allows querying Cosmos DB using AAD sign on. You must set up RBAC for querying data before as described here:
[Configure role-based access control with Azure Active Directory for your Azure Cosmos DB account](https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac)

## Requirements

- Powershell 7
- Az.Acounts module

## Usage

```
Connect-AzAccount -TenantId <your tenant id here>
Import-Module <path>\CosmosDBClient\CosmosDBClient.psm1
Get-CosmosQueryResults -CosmosDBAccount 'mycosmosaccount' -DBName 'mydb' -ContainerName 'customers' -Query 'select * from customers c where c.accountnumber = '123'
```
