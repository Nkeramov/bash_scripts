if [ -z "$JAVA_HOME" ] ; then
    JAVACMD=`which java`
else
    JAVACMD="$JAVA_HOME/bin/java"
fi
 
if [ ! -x "$JAVACMD" ] ; then
    echo "The JAVA_HOME environment variable is not defined correctly" >&2
    echo "This environment variable is needed to run this program" >&2
    echo "NB: JAVA_HOME should point to a JDK not a JRE" >&2
    exit 1
else
    echo "JAVA HOME is OK" >&2
    echo "JAVA HOME path: $JAVACMD" >&2
fi
