#!/bin/bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y cmake perf java-1.8.0-openjdk-devel-debug
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -Uvh epel-release-latest-7.noarch.rpm
sudo yum install -y siege
git clone https://github.com/jvm-profiling-tools/perf-map-agent.git
mkdir ~/bin
cd perf-map-agent && cmake CMakeLists.txt && make && bin/create-links-in ~/bin
git clone https://github.com/brendangregg/FlameGraph.git
echo 'export JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+PreserveFramePointer -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints"' > ~/.bash_profile
