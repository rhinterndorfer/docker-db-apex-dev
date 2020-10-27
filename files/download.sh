alias open="powershell.exe /c start"

if ! [ -f apache-tomcat-8.5.59.tar.gz ]; then
    curl -L https://www-eu.apache.org/dist/tomcat/tomcat-8/v8.5.59/bin/apache-tomcat-8.5.59.tar.gz --output apache-tomcat-8.5.59.tar.gz
fi

if ! [ -f OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz ]; then
    curl -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz --output OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz
fi

if ! [ -f swagger-ui-v3.35.2.zip ]; then
    curl -L https://github.com/swagger-api/swagger-ui/archive/v3.35.2.zip --output swagger-ui-v3.35.2.zip
fi


if ! [ -f gosu-amd64 ]; then
    curl -L https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64 --output gosu-amd64
fi

if ! [ -f logger_3.1.1.zip ]; then
    curl -L https://github.com/OraOpenSource/Logger/raw/master/releases/logger_3.1.1.zip --output logger_3.1.1.zip
fi

if ! [ -f oos-utils-latest.zip ]; then
    curl -L https://observant-message.glitch.me/oos-utils/latest/oos-utils-latest.zip --output oos-utils-latest.zip
fi

open https://www.oracle.com/tools/downloads/apex-downloads.html

open https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html

open https://www.oracle.com/tools/downloads/sqlcl-downloads.html