def artserver = Artifactory.server('repository.terradue.com')
def buildInfo = Artifactory.newBuildInfo()
buildInfo.env.capture = true

pipeline {


  options {
    // Kepp 5 builds history
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  agent { 
    node { 
      // community builder
      label 'ci-community' 
    }
  }

  stages {

    // Let's go!
    stage('Package S1') {
      steps {
        
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -e -B deploy -D mission=S1'
        }

        script {
          artserver.publishBuildInfo buildInfo
        }
      }
    }
    
    stage('Package ENVISAT') {
      steps {
        
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -B deploy -Dmission=ENVISAT'
        }

        script {
          artserver.publishBuildInfo buildInfo
        }
      }
    }
    
    stage('Package RS2') {
      steps {
        
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -B deploy -Dmission=RS2'
        }

        script {
          artserver.publishBuildInfo buildInfo
        }
      }
    }
    
    stage('Package TSX') {
      steps {
        
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -B deploy -Dmission=TSX'
        }

        script {
          artserver.publishBuildInfo buildInfo
        }
      }
    }
    
  }
}
