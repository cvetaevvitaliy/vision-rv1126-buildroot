#!/bin/bash

REPO_URL="git@gitlab.hard-tech.org.ua:vision/vision-taf.git"
PROJECT_DIR="vision-taf"

if [ -d "$PROJECT_DIR" ]; then
    echo "Directory '$PROJECT_DIR' already exists. Cleaning..."
    sudo rm -rf "$PROJECT_DIR"
else
    echo "Directory '$PROJECT_DIR' does not exist. Creating ..."
    mkdir "$PROJECT_DIR"
fi

echo "Cloning repository from $REPO_URL to $PROJECT_DIR..."
git clone $REPO_URL $PROJECT_DIR/

cd $PROJECT_DIR

# Check if the repository was cloned successfully
if [ $? -ne 0 ]; then
    echo "Failed to clone the repository. Exiting."
    exit 1
fi

# Unpack Java and Maven archives
echo "Unpack Java..."
unzip tools/libs/openlogic-openjdk-8u402-b06-linux-x64.zip -d tools/libs
echo "Unpack Maven..."
unzip tools/libs/apache-maven-3.9.6-bin.zip -d tools/libs

# Set JAVA_HOME
export JAVA_HOME=tools/libs/openlogic-openjdk-8u402-b06-linux-x64
echo $JAVA_HOME
export PATH=$PATH:$JAVA_HOME/bin
echo $PATH
java -version

# Set MAVEN_HOME
export M2_HOME=tools/libs/apache-maven-3.9.6
export MAVEN_HOME=tools/libs/apache-maven-3.9.6
export PATH=${M2_HOME}/bin:${PATH}
mvn -version

# Build and run Java automation tests
echo "Building and running Java automation tests..."
mvn clean test

# Check if the tests ran successfully
if [ $? -eq 0 ]; then
    echo "Java automation tests executed successfully."
else
    echo "Java automation tests failed."
fi
