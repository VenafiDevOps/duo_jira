#!/bin/sh

# default JIRA install directory
JIRA=/opt/atlassian/jira
AKEY=`python -c "import hashlib, os;  print hashlib.sha1(os.urandom(32)).hexdigest()"`

usage () {
    printf >&2 "Usage: $0 [-d JIRA directory] -i ikey -s skey -h host\n"
    printf >&2 "ikey, skey, and host can be found in Duo account's administration panel at admin.duosecurity.com\n"
}

while getopts d:i:s:h: o
do  
    case "$o" in
        d)  JIRA="$OPTARG";;
        i)  IKEY="$OPTARG";;
        s)  SKEY="$OPTARG";;
        h)  HOST="$OPTARG";;
        [?]) usage
            exit 1;;
    esac
done

if [ -z $IKEY ]; then echo "Missing -i (Duo integration key)"; usage; exit 1; fi
if [ -z $SKEY ]; then echo "Missing -s (Duo secret key)"; usage; exit 1; fi
if [ -z $HOST ]; then echo "Missing -h (Duo API hostname)"; usage; exit 1; fi

echo "Installing Duo integration to $JIRA..."

CONFLUENCE_ERROR="The directory ($JIRA) does not look like a JIRA installation. Use the -d option to specify where JIRA is installed."

if [ ! -d $JIRA ]; then
    echo "$JIRA_ERROR"
    exit 1
fi
if [ ! -e $JIRA/atlassian-jira/WEB-INF/lib ]; then
    echo "$JIRA_ERROR"
    exit 1
fi

# make sure we haven't already installed
if [ -e $JIRA/atlassian-jira/WEB-INF/lib/duo_java-1.0.jar ]; then
    echo "duo_java-1.0.jar already exists in $JIRA/atlassian-jira/WEB-INF/lib.  Move or remove this jar to continue."
    echo 'exiting'
    exit 1
fi

# make sure we haven't already installed
if [ -e $JIRA/atlassian-jira/WEB-INF/lib/duo-filter-1.3.2-SNAPSHOT.jar ]; then
    echo "duo-filter-1.3.2-SNAPSHOT.jar already exists in $JIRA/atlassian-jira/WEB-INF/lib.  Move or remove this jar to continue."
    echo 'exiting'
    exit 1
fi

# we don't actually write to web.xml, so just warn if it's already there
grep '<filter-name>duoauth</filter-name>' $JIRA/atlassian-jira/WEB-INF/web.xml >/dev/null
if [ $? -eq 0 ]; then
    echo "Warning: It looks like the Duo authenticator has already been added to JIRA's web.xml."
fi

echo "Copying in Duo integration files..."

# install the duo_java jar
cp etc/duo_java-1.0.jar $JIRA/atlassian-jira/WEB-INF/lib
if [ $? -ne 0 ]; then
    echo 'Could not copy duo_java-1.0.jar, please contact support@duosecurity.com'
    echo 'exiting'
    exit 1
fi

# install the seraph filter jar
cp etc/duo-filter-1.3.2-SNAPSHOT.jar $JIRA/atlassian-jira/WEB-INF/lib
if [ $? -ne 0 ]; then
    echo 'Could not copy duo-filter-1.3.2-SNAPSHOT.jar, please contact support@duosecurity.com'
    echo 'exiting'
    exit 1
fi

echo "duo_jira jars have been installed. Next steps, in order:"
echo "- Upload and install the plugin in etc/duo-twofactor-1.3.1-SNAPSHOT.jar "
echo "  using the JIRA web UI."
echo "- Edit web.xml, located at $JIRA/atlassian-jira/WEB-INF/web.xml,"
echo "  adding the following after the security filter and before any "
echo "  post-seraph filters:"
echo
echo "    <filter>"
echo "        <filter-name>duoauth</filter-name>"
echo "        <filter-class>com.duosecurity.seraph.filter.DuoAuthFilter</filter-class>"
echo "        <init-param>"
echo "            <param-name>ikey</param-name>"
echo "            <param-value>$IKEY</param-value>"
echo "        </init-param>"
echo "        <init-param>"
echo "            <param-name>skey</param-name>"
echo "            <param-value>$SKEY</param-value>"
echo "        </init-param>"
echo "        <init-param>"
echo "            <param-name>akey</param-name>"
echo "            <param-value>$AKEY</param-value>"
echo "        </init-param>"
echo "        <init-param>"
echo "            <param-name>host</param-name>"
echo "            <param-value>$HOST</param-value>"
echo "        </init-param>"
echo "    </filter>"
echo "    <filter-mapping>"
echo "        <filter-name>duoauth</filter-name>"
echo "        <url-pattern>/*</url-pattern>"
echo "        <dispatcher>FORWARD</dispatcher>"
echo "        <dispatcher>REQUEST</dispatcher>"
echo "    </filter-mapping>"
echo
echo "- Restart JIRA."
