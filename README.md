---
name: Cosmos DB SDK-Type Bindings with Azure Functions (Python)
description: Bind to rich SDK types when using Cosmos input.
languages:
- python
products:
- azure
- azure-functions
- azure-cosmos
- sdk-bindings
page_type: sample
urlFragment: cosmosdb-sdk-type-bindings-with-azure-functions

---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->

# Cosmos DB SDK-Type Bindings with Azure Functions (Python)

This sample demonstrates how to use the Azure Functions Cosmos DB SDK-type bindings in Python. The supported SDK types includes CosmosClient, DatabaseProxy, and ContainerProxy.

You can learn more about SDK-type bindings for Cosmos DB in the [SDK-type Bindings for Python Reference](https://learn.microsoft.com/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators#sdk-type-bindings).

## Prerequisites

Before running the sample, you need the following:

1. **Azure Subscription**: An [Azure account](https://azure.com/free) is required.
   
2. **Azure Functions Core Tools**: Install [Azure Functions Core Tools](https://learn.microsoft.com/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-python) to run and test functions locally.

3. **A Supported Version of Python**: Visit the [Supported Python versions page](https://learn.microsoft.com/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators#supported-python-versions) to learn more. The Azure deployments use Python 3.14, which is currently a preview runtime in Azure Functions.

4. **Azure Developer CLI**: Install the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) to provision and deploy all three samples.

5. **Azure Storage Account**: For local testing, create a [storage account](https://learn.microsoft.com/azure/storage/common/storage-account-overview) and get the connection string. The Azure Developer CLI deployment provisions its own storage account.

## Using SDK-type Bindings for Cosmos DB in an Azure Function App
The code in the sample folder has already been updated to support use of SDK-type bindings for Cosmos DB. Let's walk through the changed files.

The `requirements.txt` file has an additional dependency of the `azurefunctions-extensions-bindings-cosmosdb` module:

```
azure-functions
azurefunctions-extensions-bindings-cosmosdb
```

Each cosmosdb_samples_* folder contains `function_app.py` which imports the `azurefunctions-extensions-bindings-cosmosdb` module.
```python
import azure.functions as func
import azurefunctions.extensions.bindings.cosmosdb as cosmosdb
```

In each `function_app.py` file, there is a function that is an HTTP trigger and Cosmos DB input. This function specifies an arg named `client` and defines the type as an SDK-type.

The cosmosdb_samples_cosmosclient directory shows the type defined as `CosmosClient`.
```python
@app.cosmos_db_input(arg_name="client",
                     connection="CosmosDBConnection",
                     database_name=None,
                     container_name=None)
def get_docs(req: func.HttpRequest, client: cosmos.CosmosClient):
```
The cosmosdb_samples_databaseproxy directory shows the type defined as DatabaseProxy, and the cosmosdb_samples_containerproxy directory shows the type defined as ContainerProxy.

## Running the sample
### Testing Locally
1. **Clone the repository**: 
    ```
        git clone https://github.com/Azure-Samples/azure-functions-cosmosdb-sdk-bindings-python.git
    ```
2. **Navigate to the project directory**:
    ```
        cd cosmosdb_samples_cosmosclient
    ```
3. Create a [Python virtual environment](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments) and activate it.
4. **Install the required dependencies**:
    ```
        pip install -r requirements.txt
    ```
5. **Update `local.settings.json`**: replace `CosmosDBConnection` with your Cosmos DB connection string.
6. **Update the database and/or container name (if needed)**: in `function_app.py`, some Cosmos SDK types require a database name and/or a container name. Replace depending on the SDK type used that reflects that is in your Cosmos DB instance. For example, using `ContainerProxy` will require a valid database name and container name.
7. **Start the function**: If you are using VS Code for development, click the "Run and Debug" button or follow [the instructions for running a function locally](https://docs.microsoft.com/azure/azure-functions/create-first-function-vs-code-python#run-the-function-locally). Outside of VS Code, follow [these instructions for using Core Tools commands directly to run the function locally](https://docs.microsoft.com/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Cpython%2Cportal%2Cbash#start).
   ```
       Functions:
               get_docs:  http://localhost:7071/api/cosmos
   ```
8. **Execute the function**: 
   - HTTP trigger: execute the httpTrigger by pinging the endpoint. You should see the log below printed in the terminal, where the database IDs are printed.
   ```
      Found database with ID: ...
   ```

### Deploying to Azure

The repository contains one Azure Developer CLI project with three independently deployable services:

| Service | Project directory |
| --- | --- |
| `cosmosclient` | `cosmosdb_samples_cosmosclient` |
| `databaseproxy` | `cosmosdb_samples_databaseproxy` |
| `containerproxy` | `cosmosdb_samples_containerproxy` |

Sign in and deploy from the repository root:

```shell
azd auth login
azd up
```

`azd up` provisions and deploys all three samples. Each sample runs in a separate Linux Flex Consumption Function App using the Python 3.14 preview runtime. The environment shares a resource group, serverless Azure Cosmos DB account, database, container, storage account, and Log Analytics workspace. Each Function App has its own FC1 plan, user-assigned managed identity, deployment package container, and Application Insights resource.

The deployment uses managed identities for Azure Functions host storage, package storage, and Cosmos DB. Storage shared-key access and Cosmos DB local authentication are disabled.

After the environment has been provisioned, deploy one sample without changing the others:

```shell
azd deploy cosmosclient
azd deploy databaseproxy
azd deploy containerproxy
```

Remove the environment and its resources when finished:

```shell
azd down
```

You can also deploy manually using either of these approaches:

* [Deploy with the VS Code Azure Functions extension](https://docs.microsoft.com/azure/azure-functions/create-first-function-vs-code-python#publish-the-project-to-azure).
* [Deploy with the Azure CLI](https://docs.microsoft.com/azure/azure-functions/create-first-function-cli-python?tabs=azure-cli%2Cbash%2Cbrowser#create-supporting-azure-resources-for-your-function).

## Next Steps
Visit the [SDK-type bindings in Python reference documentation](https://learn.microsoft.com/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators#sdk-type-bindings) to learn more about how to use SDK-type bindings in a Python Function App and the [API reference documentation](https://learn.microsoft.com/python/api/azure-cosmos/azure.cosmos?view=azure-python) to learn more about what you can do with the Azure Cosmos DB library.
