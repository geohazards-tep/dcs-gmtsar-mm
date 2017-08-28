def artserver = Artifactory.server('repository.terradue.com')
def buildInfo = Artifactory.newBuildInfo()
buildInfo.env.capture = true

pipeline {

  parameters{
    // mission parameter for end user
    choice(name: 'MISSION', choices: 'S1\nENVISAT\nRS2\nTSX', description: 'mission', )
  }

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
    stage('Package') {
      steps {
        
        withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
          maven: 'apache-maven-3.0.5' ) {
          sh 'mvn -B deploy -Dmission=${params.MISSION}'
        }

        script {
          artserver.publishBuildInfo buildInfo
        }
      }
    }
    
  }
}
