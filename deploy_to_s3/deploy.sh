bucketName="$1"
liveFolder="live"
backupFolder="prev"


function exitWithError(){
  echo "Failed to deploy to ${bucketName}: $1"
  exit 1
}

function rollback(){
  echo "Deployment failed. Issuing rollback..."
  aws s3 sync --exact-timestamps s3://${bucketName}/${backupFolder} s3://${bucketName}/${liveFolder}  || exitWithError "Rollback failed"
  exitWithError "backup failed"
}

function backup(){
  echo "Backing up..."
  aws s3 sync --delete --exact-timestamps s3://${bucketName}/${liveFolder} s3://${bucketName}/${backupFolder}  || return 1
  echo "Backup successful."
}

function deploy(){
  echo "Deploying to s3 bucket: ${bucketName}"
  aws s3 sync ./dist s3://${bucketName}/${liveFolder} --exclude "*.html" --cache-control max-age=31536000
  aws s3 cp ./dist s3://${bucketName}/${liveFolder} --recursive --exclude "*" --include "*.html" --metadata-directive REPLACE --content-type text/html --cache-control max-age=120 || return 1
}

backup || exitWithError "backup failed"
deploy || rollback

