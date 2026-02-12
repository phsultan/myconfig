#! /bin/bash
# Sources :
# - https://willhaley.com/blog/generate-jwt-with-bash/
# 

SCRIPT_NAME=$(basename $0)

# Get the last argument, will contain the Opentok command to execute
for LAST_ARG in $@; do :; done

NOW=$(date +"%s")

# HTTP headers
HTTP_CONTENT_TYPE_HEADER="application/json"
HTTP_ACCEPT_HEADER="application/json"

################################################################################
# Help                                                                         #
################################################################################
function example() {
	echo "examples:"
	echo "# List archives (recordings) in Opentok"
	echo " ${SCRIPT_NAME} listArchives"
	echo ""
	echo "# Start a broadcast for a given (API_KEY, API_SECRET, SESSION_ID) tuple"
	echo " API_KEY=XXX API_SECRET=XXX SESSION_ID=XXX ${SCRIPT_NAME} broadcastStart"
}	

function usage() {
   # Display Help
   echo
	 echo "Syntax: $(basename $0) [-h] <command>"
	 echo "command"
	 echo "  createSession                      Create a session"
	 echo "  listArchives                       List archives"
	 echo "  archiveDetail                      Get information for a given archive (needs ARCHIVE_ID variable)"
	 echo "  experienceComposerList             List Experience Composers"
	 echo "  experienceComposerDetails          Get details for a given Experience Composer"
	 echo "  experienceComposerStart            Start Experience Composer"
	 echo "  experienceComposerStop             Stop Experience Composer"
	 echo "  broadcastList                      List active broadcasts"
	 echo "  broadcastStart                     Broadcast a session"
	 echo "  broadcastStop                      Stop a broadcast (needs BROADCAST_ID variable)"
	 echo "  broadcastDetail                    Get information for a given broadcast (needs BROADCAST_ID variable)"
	 echo "  broadcastSetLayoutPip              Set PiP layout for a given broadcast (needs BROADCAST_ID variable)"
	 echo "  broadcastSetLayoutHorizontal       Set verticalPresention layout for a given broadcast (needs BROADCAST_ID variable)"
	 echo "  broadcastSetLayoutCustom           Set custom layout for a given broadcast (needs BROADCAST_ID variable)"
	 echo "  streamList                         Get stream details (including layout classes)"
	 echo "  streamSetLayoutClassEmpty          Set \"\" layout class for a given stream (needs STREAM_ID variable)"
	 echo "  streamSetLayoutClassFocus          Set \"focus\" layout class for a given stream (needs STREAM_ID variable)"
	 echo "  streamSetLayoutClassFull           Set \"full\" layout class for a given stream (needs STREAM_ID variable)"
	 echo "  streamRemoveLayoutClass            Remove layout classes for a given stream (needs STREAM_ID variable)"
   echo "  getInsights                        Ask for Opentok Insights data (needs a GRAPHQL_QUERY variable)"
   echo "options:"
   echo "  -h                                 Print this Help."
   echo "environment variables:"
   echo "  API_KEY                            Opentok API key"
   echo "  API_SECRET                         Opentok API secret"
   echo "  SESSION_ID                         Opentok session identifier"
	 echo "  BROADCAST_ID                       A UUID that identifies an HLS/RTMP session (broadcast)"
	 echo "  STREAM_ID                          A UUID that identifies an Opentok stream"
	 echo "  EXPERIENCE_COMPOSER_ID             A UUID that identifies an Experience Composer instance"
	 echo "  TOKEN                              An Opentok token valid for the session, needed to start an Experience Composer"
	 echo "  URL                                A URL to record by an Experience Composer"
   echo
	 example
}

function print_message_and_exit() {
	echo $1
	exit 1;
}

JQ_CMD=$(which jq)
[ $? = 1 ] && print_message_and_exit "jq is not installed"

BASE64_CMD=$(which base64)
[ $? = 1 ] && print_message_and_exit "base64 is not installed"

OPENSSL_CMD=$(which openssl)
[ $? = 1 ] && print_message_and_exit "openssl is not installed"

while getopts ":h:k:" option; do
	case $option in
		h) # display usage
			echo "Send REST requests to Opentok"
			usage
			exit
			;;
	esac
done

case ${LAST_ARG} in
	experienceComposerList)
		OT_COMMAND="render"
		HTTP_REQUEST_METHOD="GET"
		;;
	experienceComposerDetails)
		if [[ -z "${EXPERIENCE_COMPOSER_ID}" ]] || ! [[ "${EXPERIENCE_COMPOSER_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "EXPERIENCE_COMPOSER_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="render/${EXPERIENCE_COMPOSER_ID}"
		HTTP_REQUEST_METHOD="GET"
		;;
	experienceComposerStart)
		if [[ -z "${SESSION_ID}" ]]; then 
			echo "SESSION_ID variable is empty"
			usage
			exit 1
		fi

		if [[ -z "${TOKEN}" ]]; then 
			echo "TOKEN variable is empty"
			usage
			exit 1
		fi

		if [[ -z "${URL}" ]]; then 
			echo "URL variable is empty"
			usage
			exit 1
		fi

		OT_COMMAND="render"
		HTTP_REQUEST_METHOD="POST"
    JSON_DATA="
{
  \"sessionId\": \"${SESSION_ID}\",
  \"token\": \"${TOKEN}\",
  \"url\": \"${URL}\",
  \"maxDuration\": 1800,
  \"resolution\": \"1280x720\",
  \"properties\": {
    \"name\": \"Composed stream for Live event #1\"
  }
}"
		;;
	experienceComposerStop)
		if [[ -z "${EXPERIENCE_COMPOSER_ID}" ]] || ! [[ "${EXPERIENCE_COMPOSER_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "EXPERIENCE_COMPOSER_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="render/${EXPERIENCE_COMPOSER_ID}"
		HTTP_REQUEST_METHOD="DELETE"
		;;

	listArchives)
		OT_COMMAND="archive"
		HTTP_REQUEST_METHOD="GET"
		;;
	archiveDetail)
		if [[ -z "${ARCHIVE_ID}" ]] || ! [[ "${ARCHIVE_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "ARCHIVE_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="archive/${ARCHIVE_ID}"
		HTTP_REQUEST_METHOD="GET"
		;;
	createSession)
		OT_COMMAND="session/create"
		HTTP_REQUEST_METHOD="POST"
		;;
	broadcastList)
		OT_COMMAND="broadcast"
		HTTP_REQUEST_METHOD="GET"
		;;
	broadcastStart)
		OT_COMMAND="broadcast"
		HTTP_REQUEST_METHOD="POST"
		JSON_DATA="{
  \"sessionId\": \"${SESSION_ID}\",
  \"resolution\": \"1280x720\",
  \"outputs\": {
    \"hls\": {}
  }
}
"
		;;
	broadcastStop)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}/stop"
		HTTP_REQUEST_METHOD="POST"
		;;
	broadcastDetail)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}"
		HTTP_REQUEST_METHOD="GET"
		;;
	broadcastSetLayoutCustom)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}/layout"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"type\": \"custom\",
	\"stylesheet\": \"stream {float:left; margin-top: 672px; width: 85px; height: 48px;}stream.focus {position: absolute; top: 0; left: 0; margin-top: 0px; width: 100%; height: 672px;}\"
}
"
		;;
	broadcastSetLayoutPip)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}/layout"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"type\": \"pip\"
}
"
		;;
	broadcastSetLayoutHorizontal)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}/layout"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"type\": \"horizontalPresentation\"
}
"
		;;
	broadcastSetLayoutBestFit)
		if [[ -z "${BROADCAST_ID}" ]] || ! [[ "${BROADCAST_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "BROADCAST_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="broadcast/${BROADCAST_ID}/layout"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"type\": \"bestFit\"
}
"
		;;
	streamList)
		OT_COMMAND="session/${SESSION_ID}/stream"
		HTTP_REQUEST_METHOD="GET"
	;;
	streamSetLayoutClassEmpty)
		if [[ -z "${STREAM_ID}" ]] || ! [[ "${STREAM_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "STREAM_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="session/${SESSION_ID}/stream"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"items\": [
    {
      \"id\": \"${STREAM_ID}\",
      \"layoutClassList\": [\"\"]
    }
  ]
}"
	;;
	streamSetLayoutClassFocus)
		if [[ -z "${STREAM_ID}" ]] || ! [[ "${STREAM_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "STREAM_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="session/${SESSION_ID}/stream"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"items\": [
    {
      \"id\": \"${STREAM_ID}\",
      \"layoutClassList\": [\"focus\"]
    }
  ]
}"
	;;
	streamSetLayoutClassFull)
		if [[ -z "${STREAM_ID}" ]] || ! [[ "${STREAM_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "STREAM_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="session/${SESSION_ID}/stream"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"items\": [
    {
      \"id\": \"${STREAM_ID}\",
      \"layoutClassList\": [\"full\"]
    }
  ]
}"
	;;
	streamRemoveLayoutClass)
		if [[ -z "${STREAM_ID}" ]] || ! [[ "${STREAM_ID}" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]]; then 
			echo "STREAM_ID variable is empty or invalid"
			usage
			exit 1
		fi

		OT_COMMAND="session/${SESSION_ID}/stream"
		HTTP_REQUEST_METHOD="PUT"
		JSON_DATA="{
  \"items\": [
    {
      \"id\": \"${STREAM_ID}\",
      \"layoutClassList\": []
    }
  ]
}"
	;;
  getInsights)
		if [[ -z "${GRAPHQL_QUERY}" ]]; then 
			echo "GRAPHQL_QUERY is empty"
			usage
			exit 1
		fi

# GRAPHQL_QUERY must have double quotes escaped. A valid example:
#
# export GRAPHQL_QUERY='{
#   project(projectId: 12385612) {
#     sessionData {
#       sessions(sessionIds: [\"1_MX40NTY4NTYxMn5-MTY0NDgzNzA4NDE5Nn40Z3pHbXRmRnZpcy9qMi9EQmhoU3hRR3p-fg\"]) {
#         resources {
#           publisherMinutes
#           subscriberMinutes
#           participantMinutes {
#             from1To2Publishers
#             from1To4Publishers
#             from1To8Publishers
#             from1To10Publishers
#             from1To25Publishers
#             from3To6Publishers
#             from3To25Publishers
#             from5To8Publishers
#             from7To8Publishers
#             from9To10Publishers
#             from11To20Publishers
#             from11To35Publishers
#             from21To35Publishers
#             from26To35Publishers
#             from36PlusPublishers
#             from36To40Publishers
#             from41PlusPublishers
#           }
#         }
#       }
#     }
#   }
# }'

		OT_COMMAND="getInsights"
		HTTP_REQUEST_METHOD="POST"
    JSON_DATA="{
  \"query\": \"$(echo $GRAPHQL_QUERY)\"
}"
    ;;
	*)
		echo "Unkown command $1"
		usage
		exit;;
esac

################################################################################
# Build JWT authentication header                                              #
################################################################################
header='
{
  "alg": "HS256",
  "typ": "JWT"
}'

# Static header fields.
payload="{
  \"iss\": \"${API_KEY}\",
  \"ist\": \"project\",
  \"jti\": \"jwt_nonce\"
}"

# Use jq to set the dynamic `iat` and `exp`
# fields on the header using the current time.
# `iat` is set to now, and `exp` is now + 1 second.
payload=$(
echo "${payload}" | jq --arg time_str "$(date +%s)" \
	'
	($time_str | tonumber) as $time_num
	| .iat=$time_num
	| .exp=($time_num + 1)
	'
)

base64_encode()
{
	declare input=${1:-$(</dev/stdin)}
	# Use `tr` to URL encode the output from base64.
	printf '%s' "${input}" | ${BASE64_CMD} | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

json() {
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | ${JQ_CMD} -c .
}

hmacsha256_sign()
{
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | ${OPENSSL_CMD} dgst -binary -sha256 -hmac "${API_SECRET}"
}

header_base64=$(echo "${header}" | json | base64_encode)
payload_base64=$(echo "${payload}" | json | base64_encode)

header_payload=$(echo "${header_base64}.${payload_base64}")
signature=$(echo "${header_payload}" | hmacsha256_sign | base64_encode)

################################################################################
# End of Build JWT authentication header                                       #
################################################################################

if [ "${OT_COMMAND}" = "getInsights" ]; then
	curl -vvv -d "${JSON_DATA}" \
		-H "Content-Type: application/json" \
		-H "Accept: ${HTTP_ACCEPT_HEADER}" \
		-H "X-OPENTOK-AUTH: ${header_payload}.${signature}" \
		https://insights.opentok.com/graphql
	
	[ $? = 0 ] && exit 0
	exit 1;
fi

if [ "${OT_COMMAND}" = "session/create" ]; then
	curl -d "${JSON_DATA}" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-H "Accept: ${HTTP_ACCEPT_HEADER}" \
		-H "X-OPENTOK-AUTH: ${header_payload}.${signature}" \
		https://api.opentok.com/${OT_COMMAND} | ${JQ_CMD}
	
	[ $? = 0 ] && exit 0
	exit 1;
fi

if [ -z "${JSON_DATA}" ]; then
	# HTTP GET resquests
	curl -X ${HTTP_REQUEST_METHOD} \
		-H "Accept: ${HTTP_ACCEPT_HEADER}" \
		-H "X-OPENTOK-AUTH: ${header_payload}.${signature}" \
		https://api.opentok.com/v2/project/${API_KEY}/${OT_COMMAND} | ${JQ_CMD}
else
	# HTTP POST/PUT requests
	curl -v -X ${HTTP_REQUEST_METHOD} \
	  -d "${JSON_DATA}" \
		-H "Content-Type: ${HTTP_CONTENT_TYPE_HEADER}" \
		-H "Accept: ${HTTP_ACCEPT_HEADER}" \
		-H "X-OPENTOK-AUTH: ${header_payload}.${signature}" \
		https://api.opentok.com/v2/project/${API_KEY}/${OT_COMMAND} | ${JQ_CMD}
fi
