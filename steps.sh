#!/bin/bash

# Define variables
REMOTE_USER="ec2-user"
REMOTE_HOST="oiiooi.yuuy.abcd.nnnn.com"
REMOTE_TMP_DIR="/tmp"
AMQ_ZIP="amq-broker-7.12.3-bin.zip"
AMQ_DIR="/home/ec2-user/amq-binary"
ARTEMIS_VERSION="apache-artemis-2.33.0.redhat-00016"
LOCAL_SETUP_DIR="/Users/Setup/amq712-3m3s-replication"
MAVEN_VERSION="3.9.9"
MAVEN_ZIP="apache-maven-${MAVEN_VERSION}-bin.zip"
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_ZIP}"

# Step 1: Copy AMQ Broker zip to remote server
scp ~/Downloads/$AMQ_ZIP $REMOTE_USER@$REMOTE_HOST:$REMOTE_TMP_DIR

# Step 2: SSH into the remote server and execute setup steps
ssh $REMOTE_USER@$REMOTE_HOST << EOF

  # Step 3: Navigate to temp directory and unzip AMQ Broker
  cd $REMOTE_TMP_DIR
  unzip $AMQ_ZIP

  # Step 4: Create a directory for AMQ binaries
  mkdir -p $AMQ_DIR

  # Step 5: Move extracted files to the target directory
  mv $ARTEMIS_VERSION/* $AMQ_DIR/

  # Step 6: Create Master and Slave instances
  cd $AMQ_DIR/bin
  ./artemis create master1
  ./artemis create slave1

  # Step 7: Download and set up Apache Maven
  cd $REMOTE_TMP_DIR
  wget $MAVEN_URL
  unzip $MAVEN_ZIP

  # Step 8: Update PATH for Maven
  echo 'export PATH=\$PATH:$REMOTE_TMP_DIR/apache-maven-${MAVEN_VERSION}/bin' >> ~/.bashrc
  source ~/.bashrc

  # Step 9: Verify Maven installation
  mvn -version

EOF

# Step 10: Copy broker configuration files to remote server
scp $LOCAL_SETUP_DIR/master1/etc/broker.xml $REMOTE_USER@$REMOTE_HOST:$AMQ_DIR/master1/etc/
scp $LOCAL_SETUP_DIR/slave1/etc/broker.xml $REMOTE_USER@$REMOTE_HOST:$AMQ_DIR/slave1/etc/

# Step 11: Copy bootstrap configuration files to remote server
scp $LOCAL_SETUP_DIR/master1/etc/bootstrap.xml $REMOTE_USER@$REMOTE_HOST:$AMQ_DIR/master1/etc/
scp $LOCAL_SETUP_DIR/slave1/etc/bootstrap.xml $REMOTE_USER@$REMOTE_HOST:$AMQ_DIR/slave1/etc/

# Step 12: SSH back into the server to test Maven build and execution
ssh $REMOTE_USER@$REMOTE_HOST "mvn clean compile exec:java -Dexec.mainClass="org.example.ArtemisPooledProducerEnhanced"
ssh $REMOTE_USER@$REMOTE_HOST "mvn clean compile exec:java -Dexec.mainClass="org.example.ArtemisPooledConsumerEnhanced"

# Step 13: Check for duplicates
./artemis browser --url tcp://localhost:xxxxxx --verbose --destination=xxxxxxx --message-count 100000 --user xxxxxx --password xxxxxx > browsed.txt ; cat browsed.txt | grep browsing | awk '{print $5}' | sort | uniq -c | awk '$1 > 1 {print $2}'

echo "AMQ Broker, Maven setup, and test execution completed successfully!"
