function handler() {
  export LAMBDA_INTEGRATION_EVENT=$1
  COMMAND="./$SWIFT_EXECUTABLE execute"
  RESPONSE=`$COMMAND`
  echo $RESPONSE
}
