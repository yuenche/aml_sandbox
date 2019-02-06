if [[ $# != 8 ]] ; then
  printf "YOU NEED TO INCLUDE THE FOLLOWING 7 PARAMETERS SEPARATED BY A SPACE IN ORDER
  \n CONTAINER REGISTRY NAME
  \n CONTAINER REGISTRY USER NAME
  \n CONTAINER REGISTRY PASSWORD
  \n IMAGE LOCATION URL
  \n DESIRED IOT DEPLOYMENT NAME
  \n IOT HUB NAME
  \n IOT DEVICE NAME TO TARGET \n"
 exit 0
fi

regname=$1
user=$2
password=$3
imagelocation=$4
iot_deployment_id=$5
iot_hub_name=$6
iot_device_id=$7
modulename=$8

echo WRITING YOUR CONFIGURATION FILE

echo "
{
    \"modulesContent\": {
        \"\$edgeAgent\": {
            \"properties.desired\": {
                \"schemaVersion\": \"1.0\",
                \"runtime\": {
                    \"type\": \"docker\",
                    \"settings\": {
                        \"loggingOptions\": \"\",
                        \"minDockerVersion\": \"v1.25\",
                        \"registryCredentials\": {
                            \"linomlwoacrqaxyxcyp\": {
                                \"address\": \"$regname.azurecr.io\",
                                \"password\": \"$password\",
                                \"username\": \"$user\"
                            }
                        }
                    }
                },
                \"systemModules\": {
                    \"edgeAgent\": {
                        \"type\": \"docker\",
                        \"settings\": {
                            \"image\": \"mcr.microsoft.com/azureiotedge-agent:1.0\",
                            \"createOptions\": \"\"
                        }
                    },
                    \"edgeHub\": {
                        \"type\": \"docker\",
                        \"settings\": {
                            \"image\": \"mcr.microsoft.com/azureiotedge-hub:1.0\",
                            \"createOptions\": \"{\\\"HostConfig\\\":{\\\"PortBindings\\\":{\\\"8883/tcp\\\":[{\\\"HostPort\\\":\\\"8883\\\"}],\\\"443/tcp\\\":[{\\\"HostPort\\\":\\\"443\\\"}],\\\"5671/tcp\\\":[{\\\"HostPort\\\":\\\"5671\\\"}]}}}\"
                        },
                        \"status\": \"running\",
                        \"restartPolicy\": \"always\"
                    }
                },
                \"modules\": {
                    \"$modulename\": {
                        \"type\": \"docker\",
                        \"settings\": {
                            \"image\": \"$imagelocation\",
                            \"createOptions\": \"\"
                        },
                        \"status\": \"running\",
                        \"restartPolicy\": \"always\",
                        \"version\": \"1.0\"
                    }
                }
            }
        },
        \"\$edgeHub\": {
            \"properties.desired\": {
                \"schemaVersion\": \"1.0\",
                \"routes\": {
                    \"route\": \"FROM /messages/* INTO \$upstream\"
                },
                \"storeAndForwardConfiguration\": {
                    \"timeToLiveSecs\": 7200
                }
            }
        }
    }
} 
" > deploy.json

echo DEPLOYING $iot_deployment_id ... 
az iot edge deployment create --deployment-id $iot_deployment_id --content ./deploy.json --hub-name $iot_hub_name --target-condition "deviceId='$iot_device_id'" --priority 1
echo DONE
