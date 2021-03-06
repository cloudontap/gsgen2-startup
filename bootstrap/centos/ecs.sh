#!/bin/bash -ex
# Assumes ECS cluster is passed as an environment variable
exec > >(tee /var/log/gosource/ecs.log|logger -t gosource-ecs -s 2>/dev/console) 2>&1
REGION=$(/etc/gosource/facts.sh | grep gs:accountRegion= | cut -d '=' -f 2)
CREDENTIALS=$(/etc/gosource/facts.sh | grep gs:credentials= | cut -d '=' -f 2)
ACCOUNT=$(/etc/gosource/facts.sh | grep gs:account= | cut -d '=' -f 2)
aws --region ${REGION} s3 cp s3://${CREDENTIALS}/${ACCOUNT}/alm/docker/ecs.config /etc/ecs/ecs.config
echo ECS_CLUSTER=$ECS_CLUSTER >> /etc/ecs/ecs.config
#
# Add log driver to docker startup options if provided
if [[ "${ECS_LOGLEVEL}" != "" ]]; then
	echo ECS_LOGLEVEL=$ECS_LOGLEVEL >> /etc/ecs/ecs.config
fi

#
# Add log driver to docker startup options if provided
if [[ "${ECS_LOG_DRIVER}" != "" ]]; then
	. /etc/sysconfig/docker
	if [[ "$(echo $OPTIONS | grep -- --log-driver )" == "" ]]; then
		echo OPTIONS="\"${OPTIONS} --log-driver=${ECS_LOG_DRIVER}\"" >> /etc/sysconfig/docker
	fi
fi
#
# Restart docker to ensure it picks up any EBS volume mounts and updated configuration settings
# - see https://github.com/aws/amazon-ecs-agent/issues/62
/sbin/service docker restart 
/sbin/start ecs
