MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex

/etc/eks/bootstrap.sh ${CLUSTER_NAME} --b64-cluster-ca ${B64_CLUSTER_CA} --apiserver-endpoint ${API_SERVER_URL} --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup-image=${AMI_ID},eks.amazonaws.com/capacityType=ON_DEMAND,eks.amazonaws.com/nodegroup=demo' 

--//--
