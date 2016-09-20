# Provide path to your oc command which can work with 3.3 openshift (can do oc cluster up)
oc='oc_rc'
$oc version
$oc cluster up
# hotfix for a alpha3 which was broken
#$oc cluster up --version=v1.3.0-alpha.2
# create CICD namesapce and setup service accounts
$oc new-project cicd --display-name="CI/CD"
$oc policy add-role-to-user edit system:serviceaccount:cicd:default -n cicd
# create CI/CD infrastructure
$oc process -f complete_template.yaml | oca create -f -


# create dev and stage projects and switch back to cicd
$oc new-project dev --display-name="Tasks - Dev" > /dev/null
$oc new-project stage --display-name="Tasks - Stage" > /dev/null
$oc policy add-role-to-user edit system:serviceaccount:cicd:default -n dev
$oc policy add-role-to-user edit system:serviceaccount:cicd:default -n stage
$oc project cicd
echo "Waiting for a gogs to come online"
x=1
RETURN=$(curl -o /dev/null -sL -w "%{http_code}" http://gogs-cicd.10.40.3.141.xip.io/user/login)
while [ ! $RETURN -eq 200 ]
    do
      sleep 5
      printf %s .
      x=$(( $x + 1 ))
       if [ $x -gt 100 ]
      then
        echo ""
        echo "Gogs did not start correctly."
        exit 255
      fi
       RETURN=$(curl -o /dev/null -sL -w "%{http_code}" http://gogs-cicd.10.40.3.141.xip.io/user/login)
    done
echo ""
echo "Gogs is online: http://gogs-cicd.10.40.3.141.xip.io/user/login"
$oc get dc gogs -o yaml | grep GOGS -A 1
# proof that jobs is started when jenkins is online
$oc start-build playground-pipeline
echo "Waiting for a jenkins to come online"
x=1
RETURN=$(curl -o /dev/null -sL -w "%{http_code}" http://jenkins-cicd.10.40.3.141.xip.io/login)
while [ ! $RETURN -eq 200 ]
    do
      sleep 5
      printf %s .
      x=$(( $x + 1 ))
       if [ $x -gt 100 ]
      then
        echo ""
        echo "Jenkins did not start correctly."
        exit 255
      fi
       RETURN=$(curl -o /dev/null -sL -w "%{http_code}" http://jenkins-cicd.10.40.3.141.xip.io/login)
    done
echo ""
echo "Jenkins is online: http://jenkins-cicd.10.40.3.141.xip.io/login"
$oc get dc jenkins -o yaml | grep JENKINS -A 1
# get logs from started build
# $oc logs builds/playground-pipeline-1
# Logs are not available via oc command
