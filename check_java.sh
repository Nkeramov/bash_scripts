if type -p java > /dev/null; then
    echo "Found java executable in PATH" >&2
    JAVA_CMD=`which java`
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo "Found java executable in JAVA_HOME" >&2   
    JAVA_CMD="$JAVA_HOME/bin/java"
else
    echo "The JAVA_HOME environment variable is not defined correctly" >&2
    echo "JAVA_HOME should point to a JDK not a JRE" >&2
    exit 1
fi

if [[ "$JAVA_CMD" ]]; then
    JAVA_VERSION=$("$JAVA_CMD" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "JAVA_HOME=$JAVA_CMD, version $JAVA_VERSION" >&2
fi
