#!/bin/bash 

# Set variables
function usage()
{
  echo "ERROR: Incorrect arguments provided."
  echo "Usage: $0 {args}"
  echo "Where valid args are: "
  echo "  -p <profile> (REQUIRED) -- Profile to use for AWS commands"
  echo "  -r <release> (REQUIRED) -- prefix for the sync"
  echo "  -b <bucket> (REQUIRED) -- bucket name to sync to"
  echo "  -g <region> (REQUIRED) -- region name to sync to"
  echo "  -z <packaged zips> -- true or false. Default False"
  exit 1
}

# Parse args
if [[ "$#" -lt 2 ]] ; then
  echo 'parse error'
  usage
fi

ZIPS=false
while getopts "p:r:b:z:g:" opt; do
  case $opt in
    p)
      PROFILE=$OPTARG
    ;;
    r)
      RELEASE=$OPTARG
    ;;
    b)
      BUCKET=$OPTARG
    ;;
    g)
      REGION=$OPTARG
    ;;
    z)
      ZIPS=$OPTARG
    ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
    ;;
  esac
done
CWD=$(echo $PWD | rev | cut -d'/' -f1 | rev)
if [ $CWD != "jeremy_aws" ]
then
  echo "These tools are expecting to be ran from the base of the aws-tools repo."
  exit 1
fi

####
# Need to replace any / in release with . 
######
RELEASE=$(echo $RELEASE | sed 's/\//./')

aws s3 sync ./cloudformation/Network/ s3://$BUCKET/$RELEASE/cloudformation/Network/ --profile $PROFILE --exclude *.git/* --exclude *.swp --region $REGION
aws s3 sync ./cloudformation/Logging/ s3://$BUCKET/$RELEASE/cloudformation/Logging/ --profile $PROFILE --exclude *.git/* --exclude *.swp --region $REGION
aws s3 sync ./cloudformation/Common/ s3://$BUCKET/$RELEASE/cloudformation/Common/ --profile $PROFILE --exclude *.git/* --exclude *.swp --region $REGION
aws s3 sync ./cloudformation/jabber/ s3://$BUCKET/$RELEASE/cloudformation/ijabber/ --profile $PROFILE --exclude *.git/* --exclude *.swp --region $REGION
aws s3 sync ./bootstrap/ s3://$BUCKET/$RELEASE/bootstrap/ --profile $PROFILE --exclude *.git/* --exclude *.swp
if [ $ZIPS == true ]; then
  cd chef
  tar -zcf chef.tar.gz *
  cd ..
  # Send to S3
  aws s3 cp ./chef/chef.tar.gz s3://$BUCKET/$RELEASE/chef.tar.gz --profile $PROFILE
  # Clean up Clean up everybody to their share
  rm ./chef/chef.tar.gz

fi
